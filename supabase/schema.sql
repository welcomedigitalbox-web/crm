-- Run once in a new Supabase project. All money is integer MMK.
create table public.profiles(id uuid primary key references auth.users(id),name text not null,phone text default '',role text not null default 'customer' check(role in ('customer','staff','admin')),member_code uuid not null default gen_random_uuid() unique,created_at timestamptz default now());
create table public.settings(id int primary key check(id=1),reward_threshold bigint not null default 30000 check(reward_threshold>0),reward_name text not null default 'Special Curry',reward_mode text not null default 'once' check(reward_mode in ('once','multiple')),balance_years int not null default 3 check(balance_years between 1 and 10),reward_years int not null default 1 check(reward_years between 1 and 10),point_unit bigint not null default 1000 check(point_unit>0));
insert into public.settings(id) values(1);
create table public.transactions(id uuid primary key default gen_random_uuid(),request_id uuid not null unique,customer_id uuid not null references public.profiles(id),actor_id uuid not null references public.profiles(id),kind text not null check(kind in ('topup','spend','reward')),amount bigint not null default 0,points bigint not null default 0,payment_method text,reference text not null,created_at timestamptz not null default now());
create table public.credit_lots(id uuid primary key default gen_random_uuid(),customer_id uuid not null references public.profiles(id),transaction_id uuid not null references public.transactions(id),remaining bigint not null check(remaining>=0),expires_at timestamptz not null);
create table public.rewards(id uuid primary key default gen_random_uuid(),customer_id uuid not null references public.profiles(id),name text not null,expires_at timestamptz not null,redeemed_at timestamptz,transaction_id uuid not null references public.transactions(id));
create function public.on_signup() returns trigger language plpgsql security definer set search_path='' as $$begin insert into public.profiles(id,name) values(new.id,coalesce(new.raw_user_meta_data->>'name',split_part(new.email,'@',1),'Member'));return new;end$$;
create trigger signup after insert on auth.users for each row execute function public.on_signup();
create function public.is_staff() returns boolean language sql stable security definer set search_path='' as $$select exists(select 1 from public.profiles where id=auth.uid() and role in ('admin','staff'))$$;
create function public.is_admin() returns boolean language sql stable security definer set search_path='' as $$select exists(select 1 from public.profiles where id=auth.uid() and role='admin')$$;
alter table public.profiles enable row level security;
alter table public.settings enable row level security;
alter table public.transactions enable row level security;
alter table public.credit_lots enable row level security;
alter table public.rewards enable row level security;
create policy profile_read on public.profiles for select to authenticated using(id=auth.uid() or public.is_staff());
create policy settings_read on public.settings for select to authenticated using(true);
create policy settings_edit on public.settings for update to authenticated using(public.is_admin()) with check(public.is_admin());
create policy tx_read on public.transactions for select to authenticated using(customer_id=auth.uid() or public.is_staff());
create policy credits_read on public.credit_lots for select to authenticated using(customer_id=auth.uid() or public.is_staff());
create policy rewards_read on public.rewards for select to authenticated using(customer_id=auth.uid() or public.is_staff());
revoke all on public.profiles,public.transactions,public.credit_lots,public.rewards,public.settings from anon,authenticated;
grant select on public.profiles,public.transactions,public.credit_lots,public.rewards,public.settings to authenticated;
grant update on public.settings to authenticated;
-- Lock one customer for every operation, so concurrent staff requests serialize.
create function public.post_transaction(p_request uuid,p_customer uuid,p_kind text,p_amount bigint,p_method text,p_reference text,p_reward uuid default null) returns uuid language plpgsql security definer set search_path='' as $$
declare s public.settings%rowtype;t uuid;l record;due bigint;n int;i int;r public.rewards%rowtype;
begin
if not public.is_staff() then raise exception 'Staff access required';end if;
perform 1 from public.profiles where id=p_customer and role='customer' for update;
if not found then raise exception 'Customer not found';end if;
select id into t from public.transactions where request_id=p_request;
if t is not null then
if not exists(select 1 from public.transactions where id=t and customer_id=p_customer and actor_id=auth.uid() and kind=p_kind and amount=p_amount and reference=p_reference) then raise exception 'Request ID conflict';end if;return t;end if;
if p_reference is null or length(trim(p_reference))<2 then raise exception 'Receipt or invoice reference required';end if;
select * into s from public.settings where id=1;
if p_kind is null or p_kind not in ('topup','spend','reward') or p_amount is null or p_amount<0 or p_amount>100000000 then raise exception 'Invalid transaction';end if;
if p_kind in ('topup','spend') and p_amount=0 then raise exception 'Amount must be positive';end if;
if p_kind='topup' and (p_method is null or p_method not in ('Cash','KBZPay','Wave')) then raise exception 'Invalid payment method';end if;
if p_kind='reward' and (p_reward is null or p_amount<>0) then raise exception 'Select a reward';end if;
if p_reward is not null then
select * into r from public.rewards where id=p_reward and customer_id=p_customer for update;
if not found or r.redeemed_at is not null or r.expires_at<=now() then raise exception 'Reward unavailable';end if;
if p_kind='topup' then raise exception 'Top-up cannot redeem reward';end if;
end if;
if p_kind='spend' then
select coalesce(sum(remaining),0) into due from public.credit_lots where customer_id=p_customer and expires_at>now();
if due<p_amount then raise exception 'Insufficient unexpired balance';end if;
end if;
insert into public.transactions(request_id,customer_id,actor_id,kind,amount,points,payment_method,reference) values(p_request,p_customer,auth.uid(),p_kind,p_amount,case when p_kind='spend' then p_amount/s.point_unit else 0 end,p_method,trim(p_reference)) returning id into t;
if p_kind='topup' then
insert into public.credit_lots(customer_id,transaction_id,remaining,expires_at) values(p_customer,t,p_amount,now()+make_interval(years=>s.balance_years));
n:=case when p_amount<s.reward_threshold then 0 when s.reward_mode='once' then 1 else (p_amount/s.reward_threshold)::int end;
if n>1000 then raise exception 'Too many rewards';end if;
for i in 1..n loop insert into public.rewards(customer_id,name,expires_at,transaction_id) values(p_customer,s.reward_name,now()+make_interval(years=>s.reward_years),t);end loop;
elsif p_kind='spend' then
due:=p_amount;
for l in select * from public.credit_lots where customer_id=p_customer and expires_at>now() and remaining>0 order by expires_at,id for update loop
exit when due=0;
update public.credit_lots set remaining=remaining-least(l.remaining,due) where id=l.id;
due:=due-least(l.remaining,due);
end loop;
end if;
if p_reward is not null then update public.rewards set redeemed_at=now() where id=p_reward;end if;
return t;
end$$;
revoke all on function public.post_transaction(uuid,uuid,text,bigint,text,text,uuid) from public,anon;
grant execute on function public.post_transaction(uuid,uuid,text,bigint,text,text,uuid) to authenticated;
-- Provision staff/admin ONLY through trusted SQL, never client-editable metadata:
-- update public.profiles set role='admin' where id='<your signed-up user UUID>';

-- Prevent duplicate receipt/invoice posting even with a new request ID.
create unique index receipt_once on public.transactions(customer_id,kind,reference);

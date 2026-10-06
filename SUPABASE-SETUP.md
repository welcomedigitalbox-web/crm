# Supabase ချိတ်ရန်

1. https://supabase.com/dashboard တွင် New Project ဖွင့်ပါ။ CRM အတွက် project အသစ်၊ နာမည် bonsine-crm၊ database password ခိုင်မာတာထားပါ။ Existing project ကိုမသုံးပါနှင့်။
2. SQL Editor > New query > supabase/schema.sql ဖိုင်အကုန်ကူးထည့်ပြီး Run လုပ်ပါ။ Schema အသစ်အတွက် တစ်ကြိမ်သာ run ရန်။
3. Connect မှ Project URL ယူပါ။ Settings > API Keys မှ publishable (သို့မဟုတ် legacy anon) key နှင့် server secret key ယူပါ။
4. Vercel > Project > Settings > Environment Variables:
   - NEXT_PUBLIC_SUPABASE_URL = Project URL
   - NEXT_PUBLIC_SUPABASE_ANON_KEY = publishable / anon key (ဒီ app variable နာမည်)
   - SUPABASE_SERVICE_ROLE_KEY = secret / service_role key (server only)
   - SITE_URL = သင့် https://....vercel.app
   Save ပြီး Deployments > Redeploy လုပ်ပါ။ Secret ကို chat, screenshot, GitHub မှာမတင်ပါနှင့်။
5. Supabase > Authentication > URL Configuration: Site URL = Vercel URL; Redirect URLs မှာ အဲဒီ URL ထည့်ပါ။ App မှာ Create account လုပ်၍ email confirm လုပ်ပါ။
6. Authentication > Users မှ admin account ရဲ့ UUID ကိုယူပြီး SQL Editor မှာ:

```sql
update public.profiles set role='admin' where id='ADMIN-USER-UUID';
```

Staff အတွက်:
```sql
update public.profiles set role='staff' where id='STAFF-USER-UUID';
```
Sign out / Sign in ပြန်လုပ်ပါ။ Customer အတွက် role မပြင်ပါနှင့်။

စမ်းရန်: customer account သီးခြားဖွင့် → admin မှ 30,000 topup → Curry 1 → bill 5,000 spend → balance 25,000, points 5 (default 1000 MMK/point) → Curry redeem။ Customer သည် အခြားသူ balance မမြင်ရ၊ ကိုယ်တိုင် topup မလုပ်ရ။ Hosted database တွင် စမ်းပြီးမှ ငွေအစစ်စသုံးပါ။ Wallet မချိတ်ရသေးလည်း profile သုံးလို့ရပါသည်။ SMS OTP နှင့် Apple automatic updates မပါသေးပါ။

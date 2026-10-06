# Dining Club CRM — Vercel + Supabase

First working version. Without environment variables it runs an in-memory DEMO: no real authentication, no durable records, no real money. Do not use demo for customers.

## Git Bash → GitHub → Vercel
Unzip and open Git Bash in this folder. Create an empty GitHub repository first.

```bash
npm install
npm run build
git init
git add .
git commit -m "Initial dining membership CRM"
git branch -M main
git remote add origin https://github.com/YOUR-USERNAME/YOUR-REPOSITORY.git
git push -u origin main
```
Import the repository in Vercel. Framework: Next.js. Default build settings. Demo runs immediately.

## Connect REAL Supabase
1. Create a NEW Supabase project under your existing account (no new Gmail required). Do not run schema.sql in an existing application's database. Name suggestion: dining-club-crm.
2. Run `supabase/schema.sql` ONCE in its SQL editor.
3. In Vercel environment variables add `NEXT_PUBLIC_SUPABASE_URL` and `NEXT_PUBLIC_SUPABASE_ANON_KEY` using this project's URL and anon/public legacy key. Never expose service-role or secret keys. Redeploy.
4. In Supabase Auth URL Configuration set Site URL to your Vercel URL. Configure permitted redirect URLs and production SMTP/email delivery. Current app uses email/password with signup confirmation; SMS OTP is NOT implemented.
5. Create your account through the app, confirm email, then promote it in Supabase SQL:
   `update public.profiles set role='admin' where id='YOUR-USER-UUID';`
6. A second staff member signs up; promote that UUID to `staff`. Roles must only be changed by trusted project administrators.
7. Customers sign up and automatically get their own profile + QR card. They cannot edit balances, roles or records.

## Implemented
- Admin/staff workspace; customer directory and QR identifier lookup by scanner/paste.
- Manual verified Cash / KBZPay / Wave top-ups; custom amounts and packages.
- Paid dining spend, expiry-first balance deductions, reward-only and combined reward redemption.
- Points only for paid spend (default 1 point / 1000 MMK, provisional editable setting).
- Credit expiry 3 years per top-up; reward expiry 1 year per issued reward.
- Default one Curry reward for each top-up >= 30000; configurable threshold, reward and multiple mode.
- Existing expiry dates unchanged when settings change.
- Customer profile remains usable without Apple/Google Wallet.
- PostgreSQL transaction function, customer row lock, unique request IDs, audit records, RLS.

## NOT yet implemented / production gate
- Apple/Google Wallet signing, issuance and update service: profile shows status, not fake functional buttons.
- SMS OTP; dedicated admin MFA enrollment UI; staff QR camera scanner (external scanner can paste code).
- Refund/reversal with approval, points reward redemption, formal bill line items, exports and full admin reporting.
- Payment gateway callbacks: staff verifies payment manually.
- Full adversarial/database concurrency tests on a real Supabase instance, backup restore test, legal/terms review.
- The wallet pass is a display of the backend balance; never trust pass-displayed balance or QR alone to authorize spending.
- Every time a reward covers an item, staff must enter ONLY remaining paid bill value. Zero paid remainder uses reward-only redemption.
- Rules for special anniversary/leap-day expiry are PostgreSQL calendar-year behavior.

Before real customer funds: validate the database permissions and transactions, provision MFA for staff/admin, configure backups/restore and refund terms, confirm applicable Myanmar prepaid-credit requirements. No security guarantee is implied by selecting a hosting platform.

## Local development
Copy `.env.example` to `.env.local`, set the two public values, `npm run dev`. Never commit credentials.

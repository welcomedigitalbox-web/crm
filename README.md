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

## Wallet integration (this release)
Customer profile has server-authenticated Google and Apple issuance. Google uses a Loyalty class, stored-value display in MMK and secondary points. No payment processing occurs in Wallet. Only the signed-in customer's card can be downloaded. QR identifies membership; it never authorizes spending.

### Google setup
1. Create loyalty class `3388000000023215925.bonsine_members` in your issuer console; use Bon Sine name and a publicly accessible HTTPS logo URL. Disable discoverable enrollment for this release.
2. Enable Google Wallet API in Google Cloud. Create a service account and add its email as Developer in the Wallet issuer console. Obtain its JSON key, keep it private.
3. In Vercel Environment Variables set GOOGLE_SERVICE_ACCOUNT_EMAIL to client_email, GOOGLE_PRIVATE_KEY to private_key, GOOGLE_WALLET_CLASS_ID to the class ID, SITE_URL to the actual HTTPS deployment, and SUPABASE_SERVICE_ROLE_KEY to the server-only Supabase key. Set NEXT_PUBLIC_GOOGLE_WALLET_ENABLED=true when the Google setup is ready. Redeploy.
4. Demo-mode issuance is restricted to approved test users. Complete the business profile and request publishing access before customer rollout.
5. Google sync is attempted after staff transactions; if unavailable, the financial transaction stays recorded and customer can press Add to Google Wallet again. Expiry by time alone does not automatically sync. Profile is the authoritative current balance.

### Apple setup tomorrow
Enroll in Apple Developer Program. For Wallet passes you need a Pass Type ID and its signing certificate; an App Store app submission is not necessary for downloading a web-issued pass.
Create a Pass Type ID (e.g. pass.com.yourbusiness.bonsine), create the certificate with a CSR, retain the corresponding private key, download the matching Apple WWDR intermediate certificate. Export signer cert, private key and WWDR as PEM. Base64 each PEM and put values only in Vercel server variables APPLE_SIGNER_CERT_BASE64, APPLE_SIGNER_KEY_BASE64, APPLE_WWDR_BASE64. Also set APPLE_TEAM_ID, APPLE_PASS_TYPE_ID and APPLE_KEY_PASSPHRASE if key encrypted. Redeploy and test Safari on iPhone.
This release issues signed Apple cards with balance, points, rewards, QR. It does NOT implement Apple background push updates: customers must download again to refresh. Do not promise automatic Apple balance updates. Certificate issuance and real device testing remain required. The bundled BS icon is a placeholder; replace public/wallet-icon.png with client-approved artwork before launch.

### Supabase + Vercel
Use a NEW Supabase project. Run supabase/schema.sql once in SQL Editor. In Vercel add NEXT_PUBLIC_SUPABASE_URL (project URL), NEXT_PUBLIC_SUPABASE_ANON_KEY (publishable key or legacy anon key), and SUPABASE_SERVICE_ROLE_KEY (secret/server key). Names match this app even if Supabase uses newer key labels. Never put the server key in a NEXT_PUBLIC variable or commit any secrets.
Authentication > URL Configuration: Site URL = deployed Vercel URL and add that exact URL to redirect allowlist. Sign up your admin through the app, confirm the email, then promote only that account using SQL in the original setup instructions. Re-login after promotion.

## Release limits
Phone/SMS OTP requires a configured SMS provider and is not implemented in this release. Email/password registration works. No automatic Apple updates, durable Google retry queue, discoverable signup, refund/reversal UI, or automatic points redemption. Do not launch with real funds until hosted Supabase role isolation, concurrent staff transactions, wallet credentials, backup/recovery and local prepaid-credit terms have been reviewed and tested.

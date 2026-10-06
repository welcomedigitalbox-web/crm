Validation completed: Next.js production build and TypeScript checks passed. Embedded PostgreSQL (PGlite) verified schema, top-up, idempotent retry, combined redemption, consumption-only points, insufficient balance rollback, repeat reward denial, customer RLS isolation, role escalation denial, direct balance-write denial. These do not replace real Supabase/concurrency/production tests.

To rerun DB check in a disposable copy: npm install --no-save @electric-sql/pglite; node qa/database-check.mjs.

Browser interaction QA was not executed because no browser binary was installed in the build environment. Mobile/customer/staff flows require manual UAT on the deployed demo before connecting real funds.

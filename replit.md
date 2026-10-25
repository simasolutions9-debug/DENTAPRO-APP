# Dental Pro

Dental Pro is a secure mobile workspace for dental organizations, clinics, and independent practices.

## Run & operate

- Expo mobile app: `pnpm --filter @workspace/dental-pro run dev`
- Express/tRPC API: `pnpm --filter @workspace/api-server run dev`
- Typecheck workspaces: `pnpm run typecheck`
- Test access rules: `pnpm --filter @workspace/api-core test`
- Generate a TiDB/MySQL migration: `pnpm --filter @workspace/db run generate`
- Apply pending migrations: `pnpm --filter @workspace/db run migrate` (requires `TIDB_URL`)
- Grant the first SuperAdmin to a verified Clerk account: `DENTAL_PRO_SUPERADMIN_USER_ID=user_... pnpm --filter @workspace/api-server run grant-superadmin`

Set `TIDB_URL` through Replit Secrets. It must be a TiDB/MySQL `mysql://` connection string. Do not substitute another database, add local/demo records, or expose the connection string to the mobile app. Migrations are not applied automatically.

## Stack

- pnpm workspaces, Node.js 24, TypeScript
- Mobile: Expo Router, React Native, Clerk Expo
- API: Express 5, Clerk Express middleware, tRPC
- Database: TiDB/MySQL, Drizzle ORM, `mysql2`
- Validation: Zod
- Build: Expo and esbuild

## Where things live

- `artifacts/dental-pro` — mobile app, auth screens, workspace UI, theme
- `artifacts/api-server` — Express API, Clerk proxy, tRPC HTTP adapter
- `lib/api-core` — typed tRPC routers and tenant authorization rules
- `lib/db/src/schema` — source-of-truth TiDB/MySQL schema
- `lib/db/drizzle` — generated SQL migrations

## Architecture decisions

- All protected API actions verify the Clerk identity and load roles/memberships from TiDB; client-provided tenant IDs are not authorization.
- Tenant workspaces and independent professional practices have separate ownership scopes.
- TiDB is the only database target. A missing connection is reported explicitly; no fallback or demo data is used.
- Sensitive writes and their audit entries are performed in one database transaction.
- Only the public Clerk publishable key is sent to the mobile bundle. The Clerk secret and TiDB URL stay server-side.

## Current scope

The first build covers authentication, platform/tenant identity, workspace separation, clinic and independent-practice setup, protected server routes, and audit foundations. Clinical records, appointments, payments, notifications, and jurisdiction-specific compliance workflows are not implemented.

## Gotchas

- Run Drizzle migrations only after `TIDB_URL` is configured for the intended environment.
- The initial SuperAdmin is granted by an explicit owner-operated command, not by self-service signup.
- Expo receives the Replit domain at build time; do not hardcode `localhost` or development hosts into app code.

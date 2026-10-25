# TiDB setup for Dental Pro

The mobile and API workspaces are prepared for TiDB/MySQL, but the database is not connected in this environment.

1. Create or select the TiDB database for the intended environment.
2. Add its `mysql://` connection string as the Replit Secret `TIDB_URL`. Do not put it in source files, app configuration, or the mobile bundle.
3. Generate a migration if the schema has changed:

   ```sh
   pnpm --filter @workspace/db run generate
   ```

4. Review the generated SQL, then apply it to the intended database:

   ```sh
   pnpm --filter @workspace/db run migrate
   ```

5. Sign in to Dental Pro with the verified account that should own the platform. An owner can grant that Clerk account the initial SuperAdmin role from the server workspace:

   ```sh
   DENTAL_PRO_SUPERADMIN_USER_ID=user_... pnpm --filter @workspace/api-server run grant-superadmin
   ```

The role-grant command requires `TIDB_URL`, rejects suspended accounts, and records the grant in the audit log. Review the target Clerk user ID before running it. New accounts receive no administrative or clinical roles by default.

The application requires a valid TLS connection and does not fall back to a different database or insert sample records if TiDB is unavailable.

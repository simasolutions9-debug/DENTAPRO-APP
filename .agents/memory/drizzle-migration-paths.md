---
name: Drizzle migration paths
description: A workspace-specific requirement for Drizzle's MySQL migration generator.
---

Keep both Drizzle `schema` and `out` paths relative to the database package. Absolute output paths caused the generator to look for snapshot metadata under a malformed `.//home/...` path even though the initial SQL file had been written.

**Why:** the generated SQL existed, but the next migration-generation run failed to load its snapshot until the config used package-relative paths.

**How to apply:** in `lib/db/drizzle.config.ts`, use paths such as `./src/schema/index.ts` and `./drizzle`; run generation from the database workspace.

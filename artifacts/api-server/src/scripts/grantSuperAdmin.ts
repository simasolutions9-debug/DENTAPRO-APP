import { randomUUID } from "node:crypto";
import {
  closeDatabase,
  getDatabase,
  appUsers,
  auditLogs,
  userRoles,
} from "@workspace/db";
import { and, eq } from "drizzle-orm";

async function main(): Promise<void> {
  const userId = process.env.DENTAL_PRO_SUPERADMIN_USER_ID?.trim();
  if (!userId || !/^user_[A-Za-z0-9]+$/.test(userId)) {
    throw new Error(
      "Set DENTAL_PRO_SUPERADMIN_USER_ID to the verified Clerk user ID before running this command.",
    );
  }

  const db = getDatabase();
  if (!db) {
    throw new Error("TIDB_URL is required to grant the initial SuperAdmin role.");
  }

  try {
    const [user] = await db
      .select({ status: appUsers.status })
      .from(appUsers)
      .where(eq(appUsers.id, userId))
      .limit(1);
    if (user?.status === "suspended") {
      throw new Error("The selected account is suspended; no role was granted.");
    }

    await db
      .insert(appUsers)
      .values({ id: userId })
      .onDuplicateKeyUpdate({ set: { updatedAt: new Date() } });

    const [existingRole] = await db
      .select({ id: userRoles.id })
      .from(userRoles)
      .where(
        and(
          eq(userRoles.userId, userId),
          eq(userRoles.role, "super_admin"),
        ),
      )
      .limit(1);

    if (!existingRole) {
      await db.transaction(async (tx) => {
        await tx.insert(userRoles).values({
          id: randomUUID(),
          userId,
          role: "super_admin",
        });
        await tx.insert(auditLogs).values({
          id: randomUUID(),
          actorUserId: userId,
          scopeType: "platform",
          scopeId: null,
          action: "user.role.granted",
          subjectType: "user",
          subjectId: userId,
          details: { role: "super_admin", source: "owner_cli" },
        });
      });
    }
    process.stdout.write("SuperAdmin access is ready for the verified account.\n");
  } finally {
    await closeDatabase();
  }
}

main().catch((error: unknown) => {
  process.stderr.write(
    `${error instanceof Error ? error.message : "Unable to grant SuperAdmin access."}\n`,
  );
  process.exitCode = 1;
});

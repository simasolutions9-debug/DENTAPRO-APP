import { randomUUID } from "node:crypto";
import { TRPCError, initTRPC } from "@trpc/server";
import { and, desc, eq, inArray, or } from "drizzle-orm";
import { z } from "zod";
import type { DentalDatabase } from "@workspace/db";
import {
  appUsers,
  auditLogs,
  clinics,
  independentPractices,
  tenantMemberships,
  tenants,
  userRoles,
} from "@workspace/db/schema";
import { canManageTenant, type ActorAccess } from "./access";

export type ApiContext = {
  userId: string | null;
  db: DentalDatabase | null;
  databaseConfigured: boolean;
};

const t = initTRPC.context<ApiContext>().create();

const publicProcedure = t.procedure;
const protectedProcedure = t.procedure.use(({ ctx, next }) => {
  if (!ctx.userId) {
    throw new TRPCError({ code: "UNAUTHORIZED" });
  }
  const userId = ctx.userId;
  if (ctx.db) {
    return ctx.db
      .select({ status: appUsers.status })
      .from(appUsers)
      .where(eq(appUsers.id, userId))
      .limit(1)
      .then(async ([user]) => {
        if (!user) {
          await ctx.db!
            .insert(appUsers)
            .values({ id: userId })
            .onDuplicateKeyUpdate({ set: { updatedAt: new Date() } });
        } else if (user.status !== "active") {
          throw new TRPCError({
            code: "FORBIDDEN",
            message: "Esta cuenta está suspendida.",
          });
        }
        return next({ ctx: { ...ctx, userId } });
      });
  }
  return next({ ctx: { ...ctx, userId } });
});

function requireDatabase(ctx: ApiContext): DentalDatabase {
  if (!ctx.db) {
    throw new TRPCError({
      code: "SERVICE_UNAVAILABLE",
      message:
        "La conexión de Dental Pro a TiDB/MySQL no está configurada. No se guardaron cambios.",
    });
  }
  return ctx.db;
}

async function requirePlatformRole(
  db: DentalDatabase,
  userId: string,
  role: "super_admin" | "tenant_admin" | "dentist" | "patient",
): Promise<void> {
  const [grant] = await db
    .select({ id: userRoles.id })
    .from(userRoles)
    .where(and(eq(userRoles.userId, userId), eq(userRoles.role, role)))
    .limit(1);
  if (!grant) {
    throw new TRPCError({
      code: "FORBIDDEN",
      message: "Tu cuenta no tiene el rol necesario para esta acción.",
    });
  }
}

async function requireTenantAdmin(
  db: DentalDatabase,
  userId: string,
  tenantId: string,
): Promise<void> {
  const globalRows = await db
    .select({ role: userRoles.role })
    .from(userRoles)
    .where(
      eq(userRoles.userId, userId),
    );

  const memberships = await db
    .select({
      tenantId: tenantMemberships.tenantId,
      role: tenantMemberships.role,
      status: tenantMemberships.status,
    })
    .from(tenantMemberships)
    .where(eq(tenantMemberships.userId, userId));
  const actor: ActorAccess = {
    globalRoles: globalRows.map((row) => row.role),
    tenantMemberships: memberships,
  };
  if (!canManageTenant(actor, tenantId)) {
    throw new TRPCError({
      code: "FORBIDDEN",
      message: "No tienes permisos de administración para esta clínica.",
    });
  }
}

export const appRouter = t.router({
  system: t.router({
    status: publicProcedure.query(({ ctx }) => ({
      status: "ok" as const,
      database: ctx.databaseConfigured ? "configured" as const : "not_configured" as const,
      databaseProvider: "TiDB/MySQL" as const,
    })),
  }),
  identity: t.router({
    me: protectedProcedure.query(async ({ ctx }) => {
      const db = requireDatabase(ctx);
      const roles = await db
        .select({ role: userRoles.role })
        .from(userRoles)
        .where(eq(userRoles.userId, ctx.userId));
      return {
        userId: ctx.userId,
        roles: roles.map((row) => row.role),
      };
    }),
    grantPlatformRole: protectedProcedure
      .input(
        z
          .object({
            userId: z.string().regex(/^user_[A-Za-z0-9]+$/).max(191),
            role: z.enum(["dentist", "patient"]),
          })
          .strict(),
      )
      .mutation(async ({ ctx, input }) => {
        const db = requireDatabase(ctx);
        await requirePlatformRole(db, ctx.userId, "super_admin");
        const [target] = await db
          .select({ status: appUsers.status })
          .from(appUsers)
          .where(eq(appUsers.id, input.userId))
          .limit(1);
        if (!target || target.status !== "active") {
          throw new TRPCError({
            code: "NOT_FOUND",
            message: "La cuenta no está disponible para recibir permisos.",
          });
        }
        const [existingRole] = await db
          .select({ id: userRoles.id })
          .from(userRoles)
          .where(
            and(
              eq(userRoles.userId, input.userId),
              eq(userRoles.role, input.role),
            ),
          )
          .limit(1);
        if (existingRole) return { granted: false };

        await db.transaction(async (tx) => {
          await tx.insert(userRoles).values({
            id: randomUUID(),
            userId: input.userId,
            role: input.role,
          });
          await tx.insert(auditLogs).values({
            id: randomUUID(),
            actorUserId: ctx.userId,
            scopeType: "platform",
            scopeId: null,
            action: "user.role.granted",
            subjectType: "user",
            subjectId: input.userId,
            details: { role: input.role },
          });
        });
        return { granted: true };
      }),
  }),
  workspace: t.router({
    list: protectedProcedure.query(async ({ ctx }) => {
      const db = requireDatabase(ctx);
      const [superAdmin] = await db
        .select({ id: userRoles.id })
        .from(userRoles)
        .where(
          and(
            eq(userRoles.userId, ctx.userId),
            eq(userRoles.role, "super_admin"),
          ),
        )
        .limit(1);
      if (superAdmin) {
        const allTenants = await db
          .select({
            id: tenants.id,
            name: tenants.name,
            slug: tenants.slug,
          })
          .from(tenants)
          .where(eq(tenants.status, "active"));
        const practices = await db
          .select({
            id: independentPractices.id,
            name: independentPractices.name,
            city: independentPractices.city,
            status: independentPractices.status,
          })
          .from(independentPractices)
          .where(eq(independentPractices.ownerUserId, ctx.userId));
        return {
          tenants: allTenants.map((tenant) => ({
            ...tenant,
            role: "super_admin" as const,
          })),
          independentPractices: practices,
        };
      }
      const tenantRows = await db
        .select({
          id: tenants.id,
          name: tenants.name,
          slug: tenants.slug,
          role: tenantMemberships.role,
        })
        .from(tenantMemberships)
        .innerJoin(tenants, eq(tenantMemberships.tenantId, tenants.id))
        .where(
          and(
            eq(tenantMemberships.userId, ctx.userId),
            eq(tenantMemberships.status, "active"),
            eq(tenants.status, "active"),
          ),
        );
      const practices = await db
        .select({
          id: independentPractices.id,
          name: independentPractices.name,
          city: independentPractices.city,
          status: independentPractices.status,
        })
        .from(independentPractices)
        .where(eq(independentPractices.ownerUserId, ctx.userId));
      return { tenants: tenantRows, independentPractices: practices };
    }),
    clinics: protectedProcedure.query(async ({ ctx }) => {
      const db = requireDatabase(ctx);
      const [superAdmin] = await db
        .select({ id: userRoles.id })
        .from(userRoles)
        .where(
          and(
            eq(userRoles.userId, ctx.userId),
            eq(userRoles.role, "super_admin"),
          ),
        )
        .limit(1);
      if (superAdmin) {
        return db
          .select({
            id: clinics.id,
            tenantId: clinics.tenantId,
            tenantName: tenants.name,
            name: clinics.name,
            city: clinics.city,
          })
          .from(clinics)
          .innerJoin(tenants, eq(clinics.tenantId, tenants.id))
          .where(eq(clinics.status, "active"))
          .orderBy(tenants.name, clinics.name);
      }

      const memberships = await db
        .select({ tenantId: tenantMemberships.tenantId })
        .from(tenantMemberships)
        .where(
          and(
            eq(tenantMemberships.userId, ctx.userId),
            eq(tenantMemberships.status, "active"),
          ),
        );
      const tenantIds = memberships.map((membership) => membership.tenantId);
      if (tenantIds.length === 0) return [];
      return db
        .select({
          id: clinics.id,
          tenantId: clinics.tenantId,
          tenantName: tenants.name,
          name: clinics.name,
          city: clinics.city,
        })
        .from(clinics)
        .innerJoin(tenants, eq(clinics.tenantId, tenants.id))
        .where(
          and(
            inArray(clinics.tenantId, tenantIds),
            eq(clinics.status, "active"),
          ),
        )
        .orderBy(tenants.name, clinics.name);
    }),
    members: protectedProcedure
      .input(z.object({ tenantId: z.string().uuid() }).strict())
      .query(async ({ ctx, input }) => {
        const db = requireDatabase(ctx);
        await requireTenantAdmin(db, ctx.userId, input.tenantId);
        return db
          .select({
            userId: tenantMemberships.userId,
            role: tenantMemberships.role,
            status: tenantMemberships.status,
            createdAt: tenantMemberships.createdAt,
            userStatus: appUsers.status,
          })
          .from(tenantMemberships)
          .innerJoin(appUsers, eq(tenantMemberships.userId, appUsers.id))
          .where(eq(tenantMemberships.tenantId, input.tenantId))
          .orderBy(tenantMemberships.createdAt);
      }),
    addMember: protectedProcedure
      .input(
        z
          .object({
            tenantId: z.string().uuid(),
            userId: z.string().regex(/^user_[A-Za-z0-9]+$/).max(191),
            role: z.enum(["tenant_admin", "staff"]),
          })
          .strict(),
      )
      .mutation(async ({ ctx, input }) => {
        const db = requireDatabase(ctx);
        await requireTenantAdmin(db, ctx.userId, input.tenantId);
        const [tenant] = await db
          .select({ id: tenants.id })
          .from(tenants)
          .where(
            and(
              eq(tenants.id, input.tenantId),
              eq(tenants.status, "active"),
            ),
          )
          .limit(1);
        if (!tenant) {
          throw new TRPCError({
            code: "NOT_FOUND",
            message: "La organización no está disponible.",
          });
        }
        const [target] = await db
          .select({ status: appUsers.status })
          .from(appUsers)
          .where(eq(appUsers.id, input.userId))
          .limit(1);
        if (!target || target.status !== "active") {
          throw new TRPCError({
            code: "NOT_FOUND",
            message: "La cuenta no está disponible para esta organización.",
          });
        }
        await db.transaction(async (tx) => {
          await tx
            .insert(tenantMemberships)
            .values({
              id: randomUUID(),
              tenantId: input.tenantId,
              userId: input.userId,
              role: input.role,
              status: "active",
            })
            .onDuplicateKeyUpdate({
              set: { role: input.role, status: "active" },
            });
          await tx.insert(auditLogs).values({
            id: randomUUID(),
            actorUserId: ctx.userId,
            scopeType: "tenant",
            scopeId: input.tenantId,
            action: "tenant.member.added",
            subjectType: "user",
            subjectId: input.userId,
            details: { role: input.role },
          });
        });
        return { added: true };
      }),
    recentAudit: protectedProcedure.query(async ({ ctx }) => {
      const db = requireDatabase(ctx);
      const [superAdmin] = await db
        .select({ id: userRoles.id })
        .from(userRoles)
        .where(
          and(
            eq(userRoles.userId, ctx.userId),
            eq(userRoles.role, "super_admin"),
          ),
        )
        .limit(1);
      if (superAdmin) {
        return db
          .select({
            id: auditLogs.id,
            action: auditLogs.action,
            scopeType: auditLogs.scopeType,
            scopeId: auditLogs.scopeId,
            subjectType: auditLogs.subjectType,
            createdAt: auditLogs.createdAt,
          })
          .from(auditLogs)
          .where(inArray(auditLogs.scopeType, ["platform", "tenant"]))
          .orderBy(desc(auditLogs.createdAt))
          .limit(50);
      }

      const memberships = await db
        .select({ tenantId: tenantMemberships.tenantId })
        .from(tenantMemberships)
        .where(
          and(
            eq(tenantMemberships.userId, ctx.userId),
            eq(tenantMemberships.role, "tenant_admin"),
            eq(tenantMemberships.status, "active"),
          ),
        );
      const tenantIds = memberships.map((membership) => membership.tenantId);
      const ownedPractices = await db
        .select({ id: independentPractices.id })
        .from(independentPractices)
        .where(eq(independentPractices.ownerUserId, ctx.userId));
      const practiceIds = ownedPractices.map((practice) => practice.id);
      if (tenantIds.length === 0 && practiceIds.length === 0) return [];
      const scopes = [
        ...(tenantIds.length
          ? [
              and(
                eq(auditLogs.scopeType, "tenant"),
                inArray(auditLogs.scopeId, tenantIds),
              ),
            ]
          : []),
        ...(practiceIds.length
          ? [
              and(
                eq(auditLogs.scopeType, "independent_practice"),
                inArray(auditLogs.scopeId, practiceIds),
              ),
            ]
          : []),
      ];
      return db
        .select({
          id: auditLogs.id,
          action: auditLogs.action,
          scopeType: auditLogs.scopeType,
          scopeId: auditLogs.scopeId,
          subjectType: auditLogs.subjectType,
          createdAt: auditLogs.createdAt,
        })
        .from(auditLogs)
        .where(or(...scopes))
        .orderBy(desc(auditLogs.createdAt))
        .limit(50);
    }),
    createTenant: protectedProcedure
      .input(
        z.object({
          name: z.string().trim().min(2).max(160),
          slug: z
            .string()
            .trim()
            .min(2)
            .max(100)
            .regex(/^[a-z0-9]+(?:-[a-z0-9]+)*$/),
        }),
      )
      .mutation(async ({ ctx, input }) => {
        const db = requireDatabase(ctx);
        await requirePlatformRole(db, ctx.userId, "super_admin");
        const tenantId = randomUUID();
        const membershipId = randomUUID();
        const auditId = randomUUID();
        await db.transaction(async (tx) => {
          await tx
            .insert(appUsers)
            .values({ id: ctx.userId })
            .onDuplicateKeyUpdate({ set: { updatedAt: new Date() } });
          await tx.insert(tenants).values({
            id: tenantId,
            name: input.name,
            slug: input.slug,
            createdByUserId: ctx.userId,
          });
          await tx.insert(tenantMemberships).values({
            id: membershipId,
            tenantId,
            userId: ctx.userId,
            role: "tenant_admin",
          });
          await tx.insert(auditLogs).values({
            id: auditId,
            actorUserId: ctx.userId,
            scopeType: "platform",
            scopeId: null,
            action: "tenant.created",
            subjectType: "tenant",
            subjectId: tenantId,
            details: { tenantName: input.name, tenantSlug: input.slug },
          });
        });
        return { id: tenantId, name: input.name, slug: input.slug };
      }),
    createClinic: protectedProcedure
      .input(
        z.object({
          tenantId: z.string().uuid(),
          name: z.string().trim().min(2).max(160),
          slug: z
            .string()
            .trim()
            .min(2)
            .max(100)
            .regex(/^[a-z0-9]+(?:-[a-z0-9]+)*$/),
          city: z.string().trim().max(120).optional(),
        }),
      )
      .mutation(async ({ ctx, input }) => {
        const db = requireDatabase(ctx);
        await requireTenantAdmin(db, ctx.userId, input.tenantId);
        const [tenant] = await db
          .select({ id: tenants.id })
          .from(tenants)
          .where(
            and(
              eq(tenants.id, input.tenantId),
              eq(tenants.status, "active"),
            ),
          )
          .limit(1);
        if (!tenant) {
          throw new TRPCError({
            code: "NOT_FOUND",
            message: "La organización no está disponible.",
          });
        }
        const clinicId = randomUUID();
        await db.transaction(async (tx) => {
          await tx.insert(clinics).values({
            id: clinicId,
            tenantId: input.tenantId,
            name: input.name,
            slug: input.slug,
            city: input.city ?? null,
          });
          await tx.insert(auditLogs).values({
            id: randomUUID(),
            actorUserId: ctx.userId,
            scopeType: "tenant",
            scopeId: input.tenantId,
            action: "clinic.created",
            subjectType: "clinic",
            subjectId: clinicId,
            details: { clinicName: input.name },
          });
        });
        return { id: clinicId, tenantId: input.tenantId, name: input.name };
      }),
    createIndependentPractice: protectedProcedure
      .input(
        z.object({
          name: z.string().trim().min(2).max(160),
          city: z.string().trim().max(120).optional(),
        }),
      )
      .mutation(async ({ ctx, input }) => {
        const db = requireDatabase(ctx);
        await requirePlatformRole(db, ctx.userId, "dentist");
        const [existing] = await db
          .select({ id: independentPractices.id })
          .from(independentPractices)
          .where(eq(independentPractices.ownerUserId, ctx.userId))
          .limit(1);
        if (existing) {
          throw new TRPCError({
            code: "CONFLICT",
            message: "Ya existe una práctica asociada a esta cuenta.",
          });
        }

        const practiceId = randomUUID();
        await db.transaction(async (tx) => {
          await tx.insert(independentPractices).values({
            id: practiceId,
            ownerUserId: ctx.userId,
            name: input.name,
            city: input.city ?? null,
          });
          await tx.insert(auditLogs).values({
            id: randomUUID(),
            actorUserId: ctx.userId,
            scopeType: "independent_practice",
            scopeId: practiceId,
            action: "independent_practice.created",
            subjectType: "independent_practice",
            subjectId: practiceId,
            details: { practiceName: input.name },
          });
        });
        return { id: practiceId, name: input.name };
      }),
  }),
});

export type AppRouter = typeof appRouter;
export type { GlobalRole, TenantMembership } from "./access";
export { canManageTenant, canReadTenant } from "./access";

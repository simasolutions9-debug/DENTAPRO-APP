import {
  index,
  json,
  mysqlEnum,
  mysqlTable,
  timestamp,
  uniqueIndex,
  varchar,
} from "drizzle-orm/mysql-core";

export const appUsers = mysqlTable("app_users", {
  id: varchar("id", { length: 191 }).primaryKey(),
  displayName: varchar("display_name", { length: 160 }),
  status: mysqlEnum("status", ["active", "suspended"])
    .notNull()
    .default("active"),
  createdAt: timestamp("created_at").notNull().defaultNow(),
  updatedAt: timestamp("updated_at").notNull().defaultNow(),
});

export const userRoles = mysqlTable(
  "user_roles",
  {
    id: varchar("id", { length: 36 }).primaryKey(),
    userId: varchar("user_id", { length: 191 })
      .notNull()
      .references(() => appUsers.id),
    role: mysqlEnum("role", [
      "super_admin",
      "tenant_admin",
      "dentist",
      "patient",
    ]).notNull(),
    createdAt: timestamp("created_at").notNull().defaultNow(),
  },
  (table) => [
    uniqueIndex("user_roles_user_role_uq").on(table.userId, table.role),
    index("user_roles_user_idx").on(table.userId),
  ],
);

export const tenants = mysqlTable(
  "tenants",
  {
    id: varchar("id", { length: 36 }).primaryKey(),
    name: varchar("name", { length: 160 }).notNull(),
    slug: varchar("slug", { length: 100 }).notNull(),
    status: mysqlEnum("status", ["active", "suspended", "archived"])
      .notNull()
      .default("active"),
    createdByUserId: varchar("created_by_user_id", { length: 191 })
      .notNull()
      .references(() => appUsers.id),
    createdAt: timestamp("created_at").notNull().defaultNow(),
    updatedAt: timestamp("updated_at").notNull().defaultNow(),
  },
  (table) => [
    uniqueIndex("tenants_slug_uq").on(table.slug),
    index("tenants_status_idx").on(table.status),
  ],
);

export const tenantMemberships = mysqlTable(
  "tenant_memberships",
  {
    id: varchar("id", { length: 36 }).primaryKey(),
    tenantId: varchar("tenant_id", { length: 36 })
      .notNull()
      .references(() => tenants.id),
    userId: varchar("user_id", { length: 191 })
      .notNull()
      .references(() => appUsers.id),
    role: mysqlEnum("role", ["tenant_admin", "staff"]).notNull(),
    status: mysqlEnum("status", ["active", "revoked"])
      .notNull()
      .default("active"),
    createdAt: timestamp("created_at").notNull().defaultNow(),
  },
  (table) => [
    uniqueIndex("tenant_memberships_tenant_user_uq").on(
      table.tenantId,
      table.userId,
    ),
    index("tenant_memberships_user_status_idx").on(table.userId, table.status),
    index("tenant_memberships_tenant_status_idx").on(
      table.tenantId,
      table.status,
    ),
  ],
);

export const clinics = mysqlTable(
  "clinics",
  {
    id: varchar("id", { length: 36 }).primaryKey(),
    tenantId: varchar("tenant_id", { length: 36 })
      .notNull()
      .references(() => tenants.id),
    name: varchar("name", { length: 160 }).notNull(),
    slug: varchar("slug", { length: 100 }).notNull(),
    city: varchar("city", { length: 120 }),
    status: mysqlEnum("status", ["active", "suspended", "archived"])
      .notNull()
      .default("active"),
    createdAt: timestamp("created_at").notNull().defaultNow(),
    updatedAt: timestamp("updated_at").notNull().defaultNow(),
  },
  (table) => [
    uniqueIndex("clinics_tenant_slug_uq").on(table.tenantId, table.slug),
    index("clinics_tenant_status_idx").on(table.tenantId, table.status),
  ],
);

export const clinicMemberships = mysqlTable(
  "clinic_memberships",
  {
    id: varchar("id", { length: 36 }).primaryKey(),
    clinicId: varchar("clinic_id", { length: 36 })
      .notNull()
      .references(() => clinics.id),
    userId: varchar("user_id", { length: 191 })
      .notNull()
      .references(() => appUsers.id),
    role: mysqlEnum("role", ["clinic_admin", "dentist", "staff"]).notNull(),
    status: mysqlEnum("status", ["active", "revoked"])
      .notNull()
      .default("active"),
    createdAt: timestamp("created_at").notNull().defaultNow(),
  },
  (table) => [
    uniqueIndex("clinic_memberships_clinic_user_uq").on(
      table.clinicId,
      table.userId,
    ),
    index("clinic_memberships_user_status_idx").on(
      table.userId,
      table.status,
    ),
    index("clinic_memberships_clinic_status_idx").on(
      table.clinicId,
      table.status,
    ),
  ],
);

export const independentPractices = mysqlTable(
  "independent_practices",
  {
    id: varchar("id", { length: 36 }).primaryKey(),
    ownerUserId: varchar("owner_user_id", { length: 191 })
      .notNull()
      .references(() => appUsers.id),
    name: varchar("name", { length: 160 }).notNull(),
    city: varchar("city", { length: 120 }),
    status: mysqlEnum("status", ["active", "suspended", "archived"])
      .notNull()
      .default("active"),
    createdAt: timestamp("created_at").notNull().defaultNow(),
    updatedAt: timestamp("updated_at").notNull().defaultNow(),
  },
  (table) => [
    uniqueIndex("independent_practices_owner_uq").on(table.ownerUserId),
    index("independent_practices_status_idx").on(table.status),
  ],
);

export const auditLogs = mysqlTable(
  "audit_logs",
  {
    id: varchar("id", { length: 36 }).primaryKey(),
    actorUserId: varchar("actor_user_id", { length: 191 })
      .notNull()
      .references(() => appUsers.id),
    scopeType: mysqlEnum("scope_type", [
      "platform",
      "tenant",
      "clinic",
      "independent_practice",
      "patient",
    ]).notNull(),
    scopeId: varchar("scope_id", { length: 191 }),
    action: varchar("action", { length: 100 }).notNull(),
    subjectType: varchar("subject_type", { length: 100 }).notNull(),
    subjectId: varchar("subject_id", { length: 191 }),
    details: json("details"),
    createdAt: timestamp("created_at").notNull().defaultNow(),
  },
  (table) => [
    index("audit_logs_actor_created_idx").on(
      table.actorUserId,
      table.createdAt,
    ),
    index("audit_logs_scope_created_idx").on(
      table.scopeType,
      table.scopeId,
      table.createdAt,
    ),
  ],
);

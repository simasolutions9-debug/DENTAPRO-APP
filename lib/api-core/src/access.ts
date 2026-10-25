export type GlobalRole =
  | "super_admin"
  | "tenant_admin"
  | "dentist"
  | "patient";

export type TenantMembership = {
  tenantId: string;
  role: "tenant_admin" | "staff";
  status: "active" | "revoked";
};

export type ActorAccess = {
  globalRoles: GlobalRole[];
  tenantMemberships: TenantMembership[];
};

export function canManageTenant(
  actor: ActorAccess,
  tenantId: string,
): boolean {
  return (
    actor.globalRoles.includes("super_admin") ||
    actor.tenantMemberships.some(
      (membership) =>
        membership.tenantId === tenantId &&
        membership.role === "tenant_admin" &&
        membership.status === "active",
    )
  );
}

export function canReadTenant(
  actor: ActorAccess,
  tenantId: string,
): boolean {
  return (
    actor.globalRoles.includes("super_admin") ||
    actor.tenantMemberships.some(
      (membership) =>
        membership.tenantId === tenantId && membership.status === "active",
    )
  );
}

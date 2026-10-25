import { describe, expect, it } from "vitest";
import { canManageTenant, canReadTenant, type ActorAccess } from "./access";

const tenantA = "tenant-a";
const tenantB = "tenant-b";

describe("tenant authorization", () => {
  it("allows an active tenant admin to manage only their own tenant", () => {
    const actor: ActorAccess = {
      globalRoles: [],
      tenantMemberships: [
        { tenantId: tenantA, role: "tenant_admin", status: "active" },
      ],
    };
    expect(canManageTenant(actor, tenantA)).toBe(true);
    expect(canManageTenant(actor, tenantB)).toBe(false);
  });

  it("does not grant access through revoked or staff membership", () => {
    const actor: ActorAccess = {
      globalRoles: [],
      tenantMemberships: [
        { tenantId: tenantA, role: "tenant_admin", status: "revoked" },
        { tenantId: tenantB, role: "staff", status: "active" },
      ],
    };
    expect(canReadTenant(actor, tenantA)).toBe(false);
    expect(canManageTenant(actor, tenantB)).toBe(false);
    expect(canReadTenant(actor, tenantB)).toBe(true);
  });

  it("allows a platform super admin to manage either tenant", () => {
    const actor: ActorAccess = {
      globalRoles: ["super_admin"],
      tenantMemberships: [],
    };
    expect(canManageTenant(actor, tenantA)).toBe(true);
    expect(canManageTenant(actor, tenantB)).toBe(true);
  });
});

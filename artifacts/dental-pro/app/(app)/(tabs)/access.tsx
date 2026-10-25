import { Feather } from "@expo/vector-icons";
import { ActivityIndicator, StyleSheet, Text, View } from "react-native";
import { useState } from "react";
import { Button, Card, EmptyState, Field, Notice, PageTitle, Row } from "@/components/DentalUI";
import { ScreenLayout } from "@/components/ScreenLayout";
import { api } from "@/lib/trpc";
import { useColors } from "@/hooks/useColors";

const roleNames: Record<string, string> = {
  super_admin: "SuperAdmin",
  tenant_admin: "TenantAdmin",
  dentist: "Odontólogo o especialista",
  patient: "Paciente",
};

function formatDate(date: Date | string): string {
  const value = new Date(date);
  if (Number.isNaN(value.getTime())) return "Fecha no disponible";
  return value.toLocaleString("es-EC", {
    month: "short",
    day: "numeric",
    hour: "2-digit",
    minute: "2-digit",
  });
}

export default function AccessScreen() {
  const colors = useColors();
  const [targetUserId, setTargetUserId] = useState("");
  const [platformRole, setPlatformRole] = useState<"dentist" | "patient">("dentist");
  const [tenantTargetUserId, setTenantTargetUserId] = useState("");
  const [tenantRole, setTenantRole] = useState<"tenant_admin" | "staff">("staff");
  const [selectedTenantId, setSelectedTenantId] = useState<string | null>(null);
  const status = api.system.status.useQuery(undefined, { retry: false });
  const identity = api.identity.me.useQuery(undefined, { retry: false });
  const workspaces = api.workspace.list.useQuery(undefined, { retry: false });
  const audit = api.workspace.recentAudit.useQuery(undefined, { retry: false });
  const utils = api.useUtils();
  const isSuperAdmin = identity.data?.roles.includes("super_admin") ?? false;
  const manageableTenants = (workspaces.data?.tenants ?? []).filter(
    (tenant) =>
      tenant.role === "tenant_admin" || tenant.role === "super_admin",
  );
  const selectedTenant =
    manageableTenants.find((tenant) => tenant.id === selectedTenantId) ??
    manageableTenants[0];
  const members = api.workspace.members.useQuery(
    { tenantId: selectedTenant?.id ?? "" },
    { enabled: Boolean(selectedTenant?.id), retry: false },
  );
  const grantRole = api.identity.grantPlatformRole.useMutation({
    onSuccess: async () => {
      setTargetUserId("");
      await utils.workspace.recentAudit.invalidate();
    },
  });
  const addMember = api.workspace.addMember.useMutation({
    onSuccess: async () => {
      setTenantTargetUserId("");
      if (selectedTenant) {
        await utils.workspace.members.invalidate({
          tenantId: selectedTenant.id,
        });
      }
      await utils.workspace.recentAudit.invalidate();
    },
  });
  const canConnect = status.data?.database === "configured";
  const isUnavailable =
    !canConnect ||
    identity.isError ||
    workspaces.isError ||
    audit.isError;

  return (
    <ScreenLayout>
      <PageTitle
        eyebrow="SEGURIDAD"
        title="Tu acceso, siempre delimitado."
        subtitle="Los permisos se asignan en el servidor. Un identificador enviado desde la app nunca basta para abrir información."
      />

      {!status.data?.database || status.data.database !== "configured" ? (
        <Notice
          title="Datos de acceso pendientes"
          body="El historial y los permisos se cargarán desde TiDB/MySQL cuando la conexión esté configurada."
          tone="warning"
          icon="database"
        />
      ) : null}

      <Card style={styles.card}>
        <View style={styles.titleRow}>
          <Feather name="shield" size={17} color={colors.primary} />
          <Text style={[styles.cardTitle, { color: colors.foreground }]}>
            Roles de plataforma
          </Text>
        </View>
        {identity.isLoading ? (
          <ActivityIndicator color={colors.primary} />
        ) : identity.data?.roles.length ? (
          identity.data.roles.map((role) => (
            <Row
              key={role}
              title={roleNames[role] ?? "Rol asignado"}
              detail="Verificado para esta cuenta"
              icon="check-circle"
            />
          ))
        ) : (
          <EmptyState
            icon="user-check"
            title="No hay roles asignados"
            body="Un administrador debe otorgar los permisos adecuados antes de acceder a funciones protegidas."
          />
        )}
      </Card>

      {identity.data?.userId ? (
        <Card style={styles.card}>
          <Text style={[styles.cardTitle, { color: colors.foreground }]}>
            Tu identificador de cuenta
          </Text>
          <Text selectable style={[styles.accountId, { color: colors.primary }]}>
            {identity.data.userId}
          </Text>
          <Text style={[styles.hint, { color: colors.mutedForeground }]}>
            Puedes compartirlo con el administrador que gestionará tu acceso. No es una contraseña.
          </Text>
        </Card>
      ) : null}

      <Card style={styles.card}>
        <View style={styles.titleRow}>
          <Feather name="briefcase" size={17} color={colors.primary} />
          <Text style={[styles.cardTitle, { color: colors.foreground }]}>
            Ámbitos autorizados
          </Text>
        </View>
        {workspaces.isLoading ? (
          <ActivityIndicator color={colors.primary} />
        ) : workspaces.data?.tenants.length ? (
          <>
            {workspaces.data.tenants.map((tenant) => (
              <Row
                key={tenant.id}
                title={tenant.name}
                detail={
                  tenant.role === "tenant_admin"
                    ? "Administración de organización"
                    : tenant.role === "super_admin"
                      ? "SuperAdmin"
                      : "Acceso de equipo"
                }
                icon="key"
              />
            ))}
            {workspaces.data.independentPractices.map((practice) => (
              <Row
                key={practice.id}
                title={practice.name}
                detail={practice.city ?? "Práctica propia"}
                icon="user"
              />
            ))}
          </>
        ) : workspaces.data?.independentPractices.length ? (
          workspaces.data.independentPractices.map((practice) => (
            <Row
              key={practice.id}
              title={practice.name}
              detail={practice.city ?? "Práctica propia"}
              icon="user"
            />
          ))
        ) : (
          <EmptyState
            icon="lock"
            title="Sin organizaciones asociadas"
            body="No tienes acceso a datos de organizaciones. Los perfiles independientes se muestran aquí cuando se configuren."
          />
        )}
      </Card>

      {isSuperAdmin ? (
        <Card style={styles.card}>
          <View style={styles.titleRow}>
            <Feather name="user-plus" size={17} color={colors.primary} />
            <Text style={[styles.cardTitle, { color: colors.foreground }]}>
              Asignar rol profesional
            </Text>
          </View>
          <Text style={[styles.hint, { color: colors.mutedForeground }]}>
            La cuenta debe haber iniciado sesión en Dental Pro. SuperAdmin no se puede asignar desde la app.
          </Text>
          <Field
            label="ID de cuenta Clerk"
            value={targetUserId}
            onChangeText={setTargetUserId}
            autoCapitalize="none"
            placeholder="user_..."
            testID="role-target-user"
          />
          <View style={styles.choiceRow}>
            <Button
              label="Odontólogo"
              kind={platformRole === "dentist" ? "primary" : "outline"}
              onPress={() => setPlatformRole("dentist")}
              style={styles.choice}
            />
            <Button
              label="Paciente"
              kind={platformRole === "patient" ? "primary" : "outline"}
              onPress={() => setPlatformRole("patient")}
              style={styles.choice}
            />
          </View>
          {grantRole.error ? (
            <Notice
              title="No se pudo asignar el rol"
              body="Comprueba el ID, confirma que la cuenta haya iniciado sesión y vuelve a intentar."
              tone="error"
            />
          ) : null}
          <Button
            label="Asignar rol"
            onPress={() =>
              grantRole.mutate({
                userId: targetUserId.trim(),
                role: platformRole,
              })
            }
            loading={grantRole.isPending}
            disabled={!canConnect || !targetUserId.trim()}
            testID="grant-platform-role"
          />
        </Card>
      ) : null}

      {selectedTenant ? (
        <Card style={styles.card}>
          <View style={styles.titleRow}>
            <Feather name="users" size={17} color={colors.primary} />
            <Text style={[styles.cardTitle, { color: colors.foreground }]}>
              Equipo de {selectedTenant.name}
            </Text>
          </View>
          {manageableTenants.length > 1 ? (
            <View style={styles.choiceRow}>
              {manageableTenants.map((tenant) => (
                <Button
                  key={tenant.id}
                  label={tenant.name}
                  kind={tenant.id === selectedTenant.id ? "primary" : "outline"}
                  onPress={() => setSelectedTenantId(tenant.id)}
                  style={styles.choice}
                />
              ))}
            </View>
          ) : null}
          {members.isLoading ? (
            <ActivityIndicator color={colors.primary} />
          ) : members.isError ? (
            <Notice
              title="No se pudo cargar el equipo"
              body="El servidor no pudo verificar los miembros de esta organización."
              tone="error"
            />
          ) : members.data?.length ? (
            members.data.map((member) => (
              <Row
                key={member.userId}
                title={member.userId}
                detail={
                  member.userStatus === "suspended"
                    ? "Cuenta suspendida"
                    : member.status === "revoked"
                      ? "Acceso revocado"
                      : member.role === "tenant_admin"
                        ? "TenantAdmin"
                        : "Staff"
                }
                icon="user"
              />
            ))
          ) : (
            <Text style={[styles.hint, { color: colors.mutedForeground }]}>
              Aún no hay miembros en esta organización.
            </Text>
          )}
          <Text style={[styles.hint, { color: colors.mutedForeground }]}>
            Solo incorpora cuentas que hayan iniciado sesión al menos una vez.
          </Text>
          <Field
            label="ID de cuenta Clerk"
            value={tenantTargetUserId}
            onChangeText={setTenantTargetUserId}
            autoCapitalize="none"
            placeholder="user_..."
            testID="tenant-member-user"
          />
          <View style={styles.choiceRow}>
            <Button
              label="Staff"
              kind={tenantRole === "staff" ? "primary" : "outline"}
              onPress={() => setTenantRole("staff")}
              style={styles.choice}
            />
            <Button
              label="TenantAdmin"
              kind={tenantRole === "tenant_admin" ? "primary" : "outline"}
              onPress={() => setTenantRole("tenant_admin")}
              style={styles.choice}
            />
          </View>
          {addMember.error ? (
            <Notice
              title="No se pudo añadir al equipo"
              body="Comprueba el ID, confirma que la cuenta haya iniciado sesión y vuelve a intentar."
              tone="error"
            />
          ) : null}
          <Button
            label="Añadir al equipo"
            onPress={() =>
              addMember.mutate({
                tenantId: selectedTenant.id,
                userId: tenantTargetUserId.trim(),
                role: tenantRole,
              })
            }
            loading={addMember.isPending}
            disabled={!canConnect || !tenantTargetUserId.trim()}
            testID="add-tenant-member"
          />
        </Card>
      ) : null}

      <Card style={styles.card}>
        <View style={styles.titleRow}>
          <Feather name="clock" size={17} color={colors.primary} />
          <Text style={[styles.cardTitle, { color: colors.foreground }]}>
            Actividad administrativa
          </Text>
        </View>
        {audit.isLoading ? (
          <ActivityIndicator color={colors.primary} />
        ) : audit.data?.length ? (
          audit.data.map((entry) => (
            <Row
              key={entry.id}
              title={entry.action.replaceAll(".", " ")}
              detail={`${entry.subjectType} · ${entry.scopeType}`}
              icon="activity"
              trailing={formatDate(entry.createdAt)}
            />
          ))
        ) : (
          <EmptyState
            icon={isUnavailable ? "database" : "file-text"}
            title={isUnavailable ? "Auditoría pendiente" : "Sin actividad registrada"}
            body={
              isUnavailable
                ? "La auditoría aparecerá aquí al conectar la base de datos."
                : "Las acciones administrativas sensibles quedarán registradas con actor, ámbito y fecha."
            }
          />
        )}
      </Card>
    </ScreenLayout>
  );
}

const styles = StyleSheet.create({
  card: { gap: 7 },
  titleRow: { flexDirection: "row", alignItems: "center", gap: 9, marginBottom: 2 },
  cardTitle: { fontSize: 15, fontWeight: "700" },
  hint: { fontSize: 12, lineHeight: 18 },
  accountId: { fontSize: 13, fontWeight: "600" },
  choiceRow: { flexDirection: "row", gap: 8 },
  choice: { flex: 1, paddingHorizontal: 8 },
});

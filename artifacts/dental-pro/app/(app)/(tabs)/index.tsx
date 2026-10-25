import { Feather } from "@expo/vector-icons";
import { useUser } from "@clerk/expo";
import { ActivityIndicator, StyleSheet, Text, View } from "react-native";
import { ScreenLayout } from "@/components/ScreenLayout";
import { Card, EmptyState, Notice, PageTitle, Row } from "@/components/DentalUI";
import { api } from "@/lib/trpc";
import { useColors } from "@/hooks/useColors";

const roleNames: Record<string, string> = {
  super_admin: "SuperAdmin",
  tenant_admin: "Administración de organización",
  dentist: "Odontólogo",
  patient: "Paciente",
};

export default function DashboardScreen() {
  const colors = useColors();
  const { user } = useUser();
  const status = api.system.status.useQuery(undefined, { retry: false });
  const identity = api.identity.me.useQuery(undefined, { retry: false });
  const workspaces = api.workspace.list.useQuery(undefined, { retry: false });
  const available = status.data?.database === "configured";

  return (
    <ScreenLayout>
      <PageTitle
        eyebrow="PANEL DE CONTROL"
        title="Un espacio de trabajo, a tu medida."
        subtitle="La información que ves depende de tu identidad y de los permisos asignados en cada organización."
      />

      {!available ? (
        <Notice
          title="TiDB/MySQL aún no está conectado"
          body="No se crearán datos de muestra. Cuando se configure la base, Dental Pro cargará tus organizaciones y clínicas desde el servidor."
          tone="warning"
          icon="database"
        />
      ) : status.isError ? (
        <Notice
          title="No pudimos consultar el servidor"
          body="Comprueba tu conexión e intenta de nuevo. No se muestran datos guardados en el dispositivo."
          tone="error"
          icon="wifi-off"
        />
      ) : null}

      {identity.isLoading || workspaces.isLoading ? (
        <Card style={styles.loadingCard}>
          <ActivityIndicator color={colors.primary} />
          <Text style={[styles.loadingText, { color: colors.mutedForeground }]}>
            Cargando tu espacio seguro
          </Text>
        </Card>
      ) : identity.isError || workspaces.isError ? (
        <Card>
          <EmptyState
            icon={available ? "alert-circle" : "database"}
            title={
              available
                ? "No se pudo cargar tu espacio"
                : "Tu espacio de trabajo está pendiente"
            }
            body={
              available
                ? "El servidor no pudo leer tu perfil. Intenta de nuevo más tarde."
                : "La autenticación está lista, pero la información de la organización no se mostrará hasta conectar TiDB/MySQL."
            }
          />
        </Card>
      ) : (
        <>
          <View style={styles.stats}>
            <Card style={styles.statCard}>
              <View style={[styles.statIcon, { backgroundColor: colors.secondary }]}>
                <Feather name="briefcase" size={17} color={colors.primary} />
              </View>
              <Text style={[styles.statValue, { color: colors.foreground }]}>
                {workspaces.data?.tenants.length ?? 0}
              </Text>
              <Text style={[styles.statLabel, { color: colors.mutedForeground }]}>
                Organizaciones
              </Text>
            </Card>
            <Card style={styles.statCard}>
              <View style={[styles.statIcon, { backgroundColor: colors.secondary }]}>
                <Feather name="activity" size={17} color={colors.primary} />
              </View>
              <Text style={[styles.statValue, { color: colors.foreground }]}>
                {workspaces.data?.independentPractices.length ?? 0}
              </Text>
              <Text style={[styles.statLabel, { color: colors.mutedForeground }]}>
                Prácticas propias
              </Text>
            </Card>
          </View>

          <Card style={styles.sectionCard}>
            <Text style={[styles.sectionTitle, { color: colors.foreground }]}>
              Tu acceso
            </Text>
            {identity.data?.roles.length ? (
              identity.data.roles.map((role) => (
                <Row
                  key={role}
                  title={roleNames[role] ?? "Rol asignado"}
                  detail="Permiso verificado en el servidor"
                  icon="shield"
                />
              ))
            ) : (
              <EmptyState
                icon="user-check"
                title="Cuenta creada"
                body="Aún no tienes un rol de Dental Pro asignado. Un administrador debe habilitar tu acceso."
              />
            )}
          </Card>

          <Card style={styles.sectionCard}>
            <Text style={[styles.sectionTitle, { color: colors.foreground }]}>
              Organizaciones recientes
            </Text>
            {workspaces.data?.tenants.length ? (
              workspaces.data.tenants.slice(0, 3).map((tenant) => (
                <Row
                  key={tenant.id}
                  title={tenant.name}
                  detail={
                    tenant.role === "tenant_admin"
                      ? "Administradora"
                      : tenant.role === "super_admin"
                        ? "SuperAdmin"
                        : "Miembro"
                  }
                  icon="briefcase"
                />
              ))
            ) : (
              <EmptyState
                icon="briefcase"
                title="Todavía no hay organizaciones"
                body="Las organizaciones a las que tengas acceso aparecerán aquí."
              />
            )}
          </Card>
        </>
      )}

      <View style={styles.privacy}>
        <Feather name="lock" size={14} color={colors.primary} />
        <Text style={[styles.privacyText, { color: colors.mutedForeground }]}>
          {user?.primaryEmailAddress?.emailAddress
            ? `Sesión activa para ${user.primaryEmailAddress.emailAddress}`
            : "Sesión protegida por autenticación segura"}
        </Text>
      </View>
    </ScreenLayout>
  );
}

const styles = StyleSheet.create({
  loadingCard: { minHeight: 115, alignItems: "center", justifyContent: "center", gap: 10 },
  loadingText: { fontSize: 12 },
  stats: { flexDirection: "row", gap: 11 },
  statCard: { flex: 1, padding: 15, gap: 8 },
  statIcon: { width: 34, height: 34, borderRadius: 12, alignItems: "center", justifyContent: "center" },
  statValue: { fontSize: 24, fontWeight: "700" },
  statLabel: { fontSize: 11 },
  sectionCard: { gap: 4 },
  sectionTitle: { fontSize: 15, fontWeight: "700", marginBottom: 3 },
  privacy: { flexDirection: "row", alignItems: "center", justifyContent: "center", gap: 7 },
  privacyText: { fontSize: 10, textAlign: "center" },
});

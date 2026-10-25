import { useMemo, useState } from "react";
import { ActivityIndicator, Pressable, StyleSheet, Text, View } from "react-native";
import { Button, Card, EmptyState, Field, Notice, PageTitle, Row } from "@/components/DentalUI";
import { ScreenLayout } from "@/components/ScreenLayout";
import { api } from "@/lib/trpc";
import { useColors } from "@/hooks/useColors";

function toSlug(value: string): string {
  return value
    .normalize("NFD")
    .replace(/[\u0300-\u036f]/g, "")
    .toLowerCase()
    .trim()
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-|-$/g, "");
}

export default function ClinicsScreen() {
  const colors = useColors();
  const [form, setForm] = useState<"tenant" | "clinic" | "practice" | null>(null);
  const [selectedTenantId, setSelectedTenantId] = useState<string | null>(null);
  const [tenantName, setTenantName] = useState("");
  const [tenantSlug, setTenantSlug] = useState("");
  const [clinicName, setClinicName] = useState("");
  const [clinicSlug, setClinicSlug] = useState("");
  const [practiceName, setPracticeName] = useState("");
  const [practiceCity, setPracticeCity] = useState("");
  const [city, setCity] = useState("");
  const status = api.system.status.useQuery(undefined, { retry: false });
  const identity = api.identity.me.useQuery(undefined, { retry: false });
  const workspaces = api.workspace.list.useQuery(undefined, { retry: false });
  const clinics = api.workspace.clinics.useQuery(undefined, { retry: false });
  const utils = api.useUtils();
  const canConnect = status.data?.database === "configured";
  const isSuperAdmin = identity.data?.roles.includes("super_admin") ?? false;
  const adminTenants = useMemo(
    () =>
      (workspaces.data?.tenants ?? []).filter(
        (tenant) => tenant.role === "tenant_admin",
      ),
    [workspaces.data?.tenants],
  );
  const canCreateClinic = isSuperAdmin || adminTenants.length > 0;
  const manageableTenants = isSuperAdmin
    ? workspaces.data?.tenants ?? []
    : adminTenants;
  const selectedTenant =
    manageableTenants.find((tenant) => tenant.id === selectedTenantId) ??
    manageableTenants[0];
  const isDentist = identity.data?.roles.includes("dentist") ?? false;

  const createTenant = api.workspace.createTenant.useMutation({
    onSuccess: async () => {
      setForm(null);
      setTenantName("");
      setTenantSlug("");
      await Promise.all([utils.workspace.list.invalidate(), utils.identity.me.invalidate()]);
    },
  });
  const createClinic = api.workspace.createClinic.useMutation({
    onSuccess: async () => {
      setForm(null);
      setClinicName("");
      setClinicSlug("");
      setCity("");
      await Promise.all([utils.workspace.clinics.invalidate(), utils.workspace.list.invalidate()]);
    },
  });
  const createPractice = api.workspace.createIndependentPractice.useMutation({
    onSuccess: async () => {
      setForm(null);
      setPracticeName("");
      setPracticeCity("");
      await Promise.all([
        utils.workspace.list.invalidate(),
        utils.workspace.recentAudit.invalidate(),
      ]);
    },
  });

  const hasLoadError =
    identity.isError || workspaces.isError || clinics.isError || status.isError;

  return (
    <ScreenLayout>
      <PageTitle
        eyebrow="ORGANIZACIÓN"
        title="Organizaciones y sedes"
        subtitle="Administra organizaciones y clínicas, o crea tu práctica profesional independiente con el rol correspondiente."
      />

      {!canConnect ? (
        <Notice
          title="Base de datos pendiente"
          body="La gestión está preparada para TiDB/MySQL. Sin esa conexión, no se mostrarán datos ni se guardarán cambios."
          tone="warning"
          icon="database"
        />
      ) : null}

      {workspaces.data?.independentPractices.length ? (
        <Card style={styles.listCard}>
          <Text style={[styles.sectionTitle, { color: colors.foreground }]}>
            Práctica independiente
          </Text>
          {workspaces.data.independentPractices.map((practice) => (
            <Row
              key={practice.id}
              title={practice.name}
              detail={practice.city ?? "Espacio profesional propio"}
              icon="user"
            />
          ))}
        </Card>
      ) : isDentist ? (
        <View style={styles.actions}>
          <Button
            label="Crear práctica independiente"
            icon="user"
            kind="outline"
            onPress={() => setForm(form === "practice" ? null : "practice")}
            disabled={!canConnect}
            testID="toggle-practice-form"
          />
        </View>
      ) : null}

      {hasLoadError ? (
        <Card>
          <EmptyState
            title={canConnect ? "No se pudieron cargar las clínicas" : "Conecta TiDB/MySQL"}
            body={
              canConnect
                ? "El servidor no pudo completar la consulta."
                : "Cuando el servidor tenga una conexión válida, aquí aparecerán solo las clínicas autorizadas para tu cuenta."
            }
            icon={canConnect ? "alert-circle" : "database"}
          />
        </Card>
      ) : clinics.isLoading ? (
        <Card style={styles.loading}>
          <ActivityIndicator color={colors.primary} />
          <Text style={{ color: colors.mutedForeground, fontSize: 12 }}>
            Cargando clínicas autorizadas
          </Text>
        </Card>
      ) : clinics.data?.length ? (
        <Card style={styles.listCard}>
          <Text style={[styles.sectionTitle, { color: colors.foreground }]}>
            Sedes disponibles
          </Text>
          {clinics.data.map((clinic) => (
            <Row
              key={clinic.id}
              title={clinic.name}
              detail={`${clinic.tenantName}${clinic.city ? ` · ${clinic.city}` : ""}`}
              icon="plus-square"
            />
          ))}
        </Card>
      ) : (
        <Card>
          <EmptyState
            icon="map-pin"
            title="Aún no hay sedes"
            body="Las sedes se mostrarán cuando se creen dentro de una organización que puedas administrar."
          />
        </Card>
      )}

      {isSuperAdmin || canCreateClinic ? (
        <View style={styles.actions}>
          {isSuperAdmin ? (
            <Button
              label="Crear organización"
              icon="plus"
              onPress={() => setForm(form === "tenant" ? null : "tenant")}
              disabled={!canConnect}
              testID="toggle-tenant-form"
            />
          ) : null}
          {canCreateClinic ? (
            <Button
              label="Crear sede"
              icon="plus-square"
              kind={isSuperAdmin ? "outline" : "primary"}
              onPress={() => setForm(form === "clinic" ? null : "clinic")}
              disabled={!canConnect || !selectedTenant}
              testID="toggle-clinic-form"
            />
          ) : null}
        </View>
      ) : null}

      {canCreateClinic && manageableTenants.length > 1 ? (
        <Card style={styles.scopeCard}>
          <Text style={[styles.sectionTitle, { color: colors.foreground }]}>
            Elige una organización
          </Text>
          {manageableTenants.map((tenant) => {
            const selected = tenant.id === selectedTenant?.id;
            return (
              <Pressable
                key={tenant.id}
                accessibilityRole="button"
                accessibilityState={{ selected }}
                onPress={() => setSelectedTenantId(tenant.id)}
                style={[
                  styles.tenantOption,
                  {
                    backgroundColor: selected ? colors.secondary : colors.card,
                    borderColor: selected ? colors.primary : colors.border,
                  },
                ]}
              >
                <Text
                  style={[
                    styles.tenantOptionText,
                    { color: colors.foreground },
                  ]}
                >
                  {tenant.name}
                </Text>
                <Text style={{ color: colors.mutedForeground, fontSize: 11 }}>
                  {selected ? "Seleccionada" : "Usar esta organización"}
                </Text>
              </Pressable>
            );
          })}
        </Card>
      ) : null}

      {form === "tenant" && isSuperAdmin ? (
        <Card style={styles.formCard}>
          <Text style={[styles.sectionTitle, { color: colors.foreground }]}>
            Nueva organización
          </Text>
          <Field
            label="Nombre"
            value={tenantName}
            onChangeText={(value) => {
              setTenantName(value);
              setTenantSlug(toSlug(value));
            }}
            placeholder="Nombre de la organización"
            testID="tenant-name"
          />
          <Field
            label="Identificador"
            value={tenantSlug}
            onChangeText={setTenantSlug}
            autoCapitalize="none"
            placeholder="nombre-organizacion"
            testID="tenant-slug"
          />
          {createTenant.error ? (
            <Notice
              title="No se pudo crear la organización"
              body="Verifica los datos, los permisos y que el identificador no esté en uso."
              tone="error"
            />
          ) : null}
          <Button
            label="Guardar organización"
            onPress={() =>
              createTenant.mutate({ name: tenantName.trim(), slug: tenantSlug.trim() })
            }
            loading={createTenant.isPending}
            disabled={!tenantName.trim() || !tenantSlug.trim() || !canConnect}
            testID="save-tenant"
          />
        </Card>
      ) : null}

      {form === "clinic" && canCreateClinic && selectedTenant ? (
        <Card style={styles.formCard}>
          <Text style={[styles.sectionTitle, { color: colors.foreground }]}>
            Nueva sede
          </Text>
          <Text style={[styles.scope, { color: colors.mutedForeground }]}>
            Organización: {selectedTenant.name}
          </Text>
          <Field
            label="Nombre de la sede"
            value={clinicName}
            onChangeText={(value) => {
              setClinicName(value);
              setClinicSlug(toSlug(value));
            }}
            placeholder="Clínica Central"
            testID="clinic-name"
          />
          <Field
            label="Identificador"
            value={clinicSlug}
            onChangeText={setClinicSlug}
            autoCapitalize="none"
            placeholder="clinica-central"
            testID="clinic-slug"
          />
          <Field
            label="Ciudad (opcional)"
            value={city}
            onChangeText={setCity}
            placeholder="Ciudad"
            testID="clinic-city"
          />
          {createClinic.error ? (
            <Notice
              title="No se pudo crear la sede"
              body="Verifica los datos, tus permisos y que el identificador no esté en uso."
              tone="error"
            />
          ) : null}
          <Button
            label="Guardar sede"
            onPress={() =>
              createClinic.mutate({
                tenantId: selectedTenant.id,
                name: clinicName.trim(),
                slug: clinicSlug.trim(),
                ...(city.trim() ? { city: city.trim() } : {}),
              })
            }
            loading={createClinic.isPending}
            disabled={!clinicName.trim() || !clinicSlug.trim() || !canConnect}
            testID="save-clinic"
          />
        </Card>
      ) : null}

      {form === "practice" && isDentist ? (
        <Card style={styles.formCard}>
          <Text style={[styles.sectionTitle, { color: colors.foreground }]}>
            Nueva práctica profesional
          </Text>
          <Field
            label="Nombre de la práctica"
            value={practiceName}
            onChangeText={setPracticeName}
            placeholder="Nombre profesional"
            testID="practice-name"
          />
          <Field
            label="Ciudad (opcional)"
            value={practiceCity}
            onChangeText={setPracticeCity}
            placeholder="Ciudad"
            testID="practice-city"
          />
          {createPractice.error ? (
            <Notice
              title="No se pudo crear la práctica"
              body="Verifica tus permisos y que aún no exista una práctica asociada a tu cuenta."
              tone="error"
            />
          ) : null}
          <Button
            label="Guardar práctica"
            onPress={() =>
              createPractice.mutate({
                name: practiceName.trim(),
                ...(practiceCity.trim() ? { city: practiceCity.trim() } : {}),
              })
            }
            loading={createPractice.isPending}
            disabled={!practiceName.trim() || !canConnect}
            testID="save-practice"
          />
        </Card>
      ) : null}

      <Card style={styles.scopeCard}>
        <View style={styles.scopeHeading}>
          <Text style={[styles.sectionTitle, { color: colors.foreground }]}>
            Ámbito de acceso
          </Text>
        </View>
        {workspaces.data?.tenants.length ? (
          workspaces.data.tenants.map((tenant) => (
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
              icon="shield"
            />
          ))
        ) : (
          <Text style={[styles.scope, { color: colors.mutedForeground }]}>
            No hay organizaciones asociadas a esta cuenta.
          </Text>
        )}
      </Card>
    </ScreenLayout>
  );
}

const styles = StyleSheet.create({
  actions: { gap: 10 },
  loading: { minHeight: 105, alignItems: "center", justifyContent: "center", gap: 10 },
  listCard: { gap: 5 },
  formCard: { gap: 14 },
  scopeCard: { gap: 7 },
  tenantOption: {
    borderWidth: 1,
    borderRadius: 14,
    paddingHorizontal: 13,
    paddingVertical: 11,
    gap: 3,
  },
  tenantOptionText: { fontSize: 13, fontWeight: "600" },
  sectionTitle: { fontSize: 15, fontWeight: "700" },
  scopeHeading: { marginBottom: 2 },
  scope: { fontSize: 12, lineHeight: 18 },
});

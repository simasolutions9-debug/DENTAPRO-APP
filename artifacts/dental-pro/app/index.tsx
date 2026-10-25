import { useAuth } from "@clerk/expo";
import { Redirect, useRouter } from "expo-router";
import { LinearGradient } from "expo-linear-gradient";
import { Platform, ScrollView, StyleSheet, Text, View } from "react-native";
import { useSafeAreaInsets } from "react-native-safe-area-context";
import { BrandLockup, Button, Card, Mark, Notice } from "@/components/DentalUI";
import { api } from "@/lib/trpc";
import { useColors } from "@/hooks/useColors";

export default function WelcomeScreen() {
  const colors = useColors();
  const insets = useSafeAreaInsets();
  const router = useRouter();
  const { isLoaded, isSignedIn } = useAuth();
  const status = api.system.status.useQuery(undefined, { retry: false });
  const topInset = Platform.OS === "web" ? Math.max(insets.top, 67) : insets.top;
  const bottomInset = Platform.OS === "web" ? 34 : insets.bottom;

  if (isLoaded && isSignedIn) {
    return <Redirect href="/(app)/(tabs)" />;
  }

  return (
    <ScrollView
      style={{ flex: 1, backgroundColor: colors.background }}
      contentContainerStyle={[
        styles.content,
        { paddingTop: topInset + 16, paddingBottom: bottomInset + 20 },
      ]}
      showsVerticalScrollIndicator={false}
    >
      <BrandLockup />
      <LinearGradient
        colors={[colors.primary, colors.heroEnd]}
        start={{ x: 0.1, y: 0 }}
        end={{ x: 0.95, y: 1 }}
        style={styles.hero}
      >
        <View style={styles.heroTop}>
          <View style={[styles.heroMark, { backgroundColor: colors.heroOverlay }]}>
            <Mark size={29} />
          </View>
          <View style={[styles.pill, { backgroundColor: colors.heroOverlaySoft }]}>
            <Text style={[styles.pillText, { color: colors.heroText }]}>
              PLATAFORMA ODONTOLÓGICA
            </Text>
          </View>
        </View>
        <Text style={[styles.heroTitle, { color: colors.heroText }]}>
          Tu práctica dental,{"\n"}en buenas manos.
        </Text>
        <Text style={[styles.heroBody, { color: colors.heroMuted }]}>
          Una plataforma para organizar clínicas y profesionales con acceso
          seguro, desde cualquier lugar.
        </Text>
        <View style={styles.heroFoot}>
          <View style={[styles.heroDot, { backgroundColor: colors.heroAccent }]} />
          <Text style={[styles.heroFootText, { color: colors.heroText }]}>
            Clínica, equipo y operación en un solo espacio
          </Text>
        </View>
      </LinearGradient>

      <View style={styles.intro}>
        <Text style={[styles.heading, { color: colors.foreground }]}>
          Organización clara.{"\n"}Acceso protegido.
        </Text>
        <Text style={[styles.body, { color: colors.mutedForeground }]}>
          Dental Pro separa la información por organización y verifica cada
          sesión antes de mostrar datos del espacio de trabajo.
        </Text>
      </View>

      <View style={styles.actions}>
        <Button
          label="Crear una cuenta"
          onPress={() => router.push("/(auth)/sign-up")}
          testID="create-account"
        />
        <Button
          label="Ya tengo una cuenta"
          kind="outline"
          onPress={() => router.push("/(auth)/sign-in")}
          testID="sign-in"
        />
      </View>

      {status.data?.database === "not_configured" ? (
        <Notice
          title="Conexión de datos pendiente"
          body="El acceso a clínicas y espacios de trabajo se habilitará cuando esté configurada la base TiDB/MySQL."
          tone="warning"
          icon="database"
        />
      ) : status.isError ? (
        <Notice
          title="Servidor no disponible"
          body="No pudimos consultar el estado del servicio. Intenta de nuevo en un momento."
          tone="error"
          icon="wifi-off"
        />
      ) : (
        <Card style={styles.privacyCard}>
          <Text style={[styles.privacyTitle, { color: colors.foreground }]}>
            Datos de salud, con cuidado
          </Text>
          <Text style={[styles.privacyBody, { color: colors.mutedForeground }]}>
            La información solo estará disponible para las personas autorizadas
            en cada ámbito.
          </Text>
        </Card>
      )}

      <Text style={[styles.legal, { color: colors.mutedForeground }]}>
        Dental Pro aplica controles de privacidad. Las obligaciones legales
        dependen de cada jurisdicción y requieren revisión profesional.
      </Text>
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  content: { paddingHorizontal: 22, gap: 23 },
  hero: {
    minHeight: 300,
    borderRadius: 28,
    padding: 24,
    justifyContent: "space-between",
    overflow: "hidden",
  },
  heroTop: {
    flexDirection: "row",
    alignItems: "center",
    justifyContent: "space-between",
  },
  heroMark: {
    padding: 8,
    borderRadius: 18,
  },
  pill: {
    paddingVertical: 7,
    paddingHorizontal: 10,
    borderRadius: 100,
  },
  pillText: { fontSize: 9, letterSpacing: 1, fontWeight: "700" },
  heroTitle: {
    fontSize: 31,
    lineHeight: 37,
    letterSpacing: -0.9,
    fontWeight: "700",
    marginTop: 23,
  },
  heroBody: {
    maxWidth: 295,
    fontSize: 14,
    lineHeight: 21,
    marginTop: 10,
  },
  heroFoot: { flexDirection: "row", alignItems: "center", gap: 8, marginTop: 24 },
  heroDot: { width: 7, height: 7, borderRadius: 4 },
  heroFootText: { fontSize: 11, fontWeight: "500" },
  intro: { gap: 9 },
  heading: { fontSize: 24, lineHeight: 30, fontWeight: "700", letterSpacing: -0.6 },
  body: { fontSize: 14, lineHeight: 21 },
  actions: { gap: 10 },
  privacyCard: { padding: 16, gap: 6 },
  privacyTitle: { fontSize: 14, fontWeight: "700" },
  privacyBody: { fontSize: 12, lineHeight: 18 },
  legal: { fontSize: 10, lineHeight: 15, textAlign: "center", paddingHorizontal: 8 },
});

import { Feather } from "@expo/vector-icons";
import { useClerk, useUser } from "@clerk/expo";
import { Platform, Pressable, ScrollView, StyleSheet, Text, View } from "react-native";
import { useSafeAreaInsets } from "react-native-safe-area-context";
import { useColors } from "@/hooks/useColors";
import { BrandLockup } from "@/components/DentalUI";

export function ScreenLayout({
  children,
  scroll = true,
}: {
  children: React.ReactNode;
  scroll?: boolean;
}) {
  const colors = useColors();
  const insets = useSafeAreaInsets();
  const { user } = useUser();
  const { signOut } = useClerk();
  const topInset = Platform.OS === "web" ? Math.max(insets.top, 67) : insets.top;
  const bottomInset = Platform.OS === "web" ? 34 : insets.bottom;
  const content = (
    <>
      <View style={styles.header}>
        <BrandLockup compact />
        <Pressable
          accessibilityRole="button"
          accessibilityLabel="Cerrar sesión"
          testID="sign-out-button"
          onPress={() => void signOut()}
          style={({ pressed }) => [
            styles.signOut,
            { backgroundColor: colors.secondary, opacity: pressed ? 0.7 : 1 },
          ]}
        >
          <Feather name="log-out" size={17} color={colors.primary} />
        </Pressable>
      </View>
      <View style={styles.greeting}>
        <Text style={[styles.greetingName, { color: colors.foreground }]}>
          {user?.firstName ? `Hola, ${user.firstName}` : "Tu espacio Dental Pro"}
        </Text>
        <Text style={[styles.greetingEmail, { color: colors.mutedForeground }]}>
          {user?.primaryEmailAddress?.emailAddress ?? "Cuenta verificada"}
        </Text>
      </View>
      {children}
      <View style={{ height: bottomInset + 18 }} />
    </>
  );

  return scroll ? (
    <ScrollView
      style={[styles.container, { backgroundColor: colors.background }]}
      contentContainerStyle={[
        styles.content,
        { paddingTop: topInset + 14, paddingBottom: bottomInset + 10 },
      ]}
      keyboardShouldPersistTaps="handled"
      showsVerticalScrollIndicator={false}
    >
      {content}
    </ScrollView>
  ) : (
    <View
      style={[
        styles.container,
        styles.content,
        { backgroundColor: colors.background, paddingTop: topInset + 14 },
      ]}
    >
      {content}
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1 },
  content: { paddingHorizontal: 20, gap: 20 },
  header: {
    flexDirection: "row",
    alignItems: "center",
    justifyContent: "space-between",
  },
  signOut: {
    width: 40,
    height: 40,
    alignItems: "center",
    justifyContent: "center",
    borderRadius: 14,
  },
  greeting: { gap: 3 },
  greetingName: { fontSize: 17, fontWeight: "700" },
  greetingEmail: { fontSize: 12 },
});

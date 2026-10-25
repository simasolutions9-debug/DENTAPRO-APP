import { Feather, MaterialCommunityIcons } from "@expo/vector-icons";
import * as Haptics from "expo-haptics";
import {
  ActivityIndicator,
  Pressable,
  StyleSheet,
  Text,
  TextInput,
  View,
  type TextInputProps,
  type ViewStyle,
} from "react-native";
import { useColors } from "@/hooks/useColors";

export function Mark({ size = 22 }: { size?: number }) {
  const colors = useColors();
  return (
    <View style={[styles.mark, { backgroundColor: colors.primary }]}>
      <MaterialCommunityIcons
        name="tooth"
        size={size}
        color={colors.primaryForeground}
      />
    </View>
  );
}

export function BrandLockup({ compact = false }: { compact?: boolean }) {
  const colors = useColors();
  return (
    <View style={styles.brand}>
      <Mark size={compact ? 20 : 23} />
      <View>
        <Text style={[styles.brandName, { color: colors.foreground }]}>
          Dental Pro
        </Text>
        {!compact && (
          <Text style={[styles.brandSub, { color: colors.mutedForeground }]}>
            Cuidado dental, bien organizado
          </Text>
        )}
      </View>
    </View>
  );
}

export function Button({
  label,
  onPress,
  disabled = false,
  loading = false,
  kind = "primary",
  icon,
  style,
  testID,
}: {
  label: string;
  onPress: () => void;
  disabled?: boolean;
  loading?: boolean;
  kind?: "primary" | "secondary" | "outline";
  icon?: React.ComponentProps<typeof Feather>["name"];
  style?: ViewStyle;
  testID?: string;
}) {
  const colors = useColors();
  const isPrimary = kind === "primary";
  return (
    <Pressable
      accessibilityRole="button"
      accessibilityState={{ disabled: disabled || loading, busy: loading }}
      disabled={disabled || loading}
      onPress={() => {
        void Haptics.selectionAsync();
        onPress();
      }}
      testID={testID}
      style={({ pressed }) => [
        styles.button,
        {
          backgroundColor: isPrimary
            ? colors.primary
            : kind === "secondary"
              ? colors.secondary
              : "transparent",
          borderColor: kind === "outline" ? colors.border : "transparent",
          borderWidth: kind === "outline" ? 1 : 0,
          opacity: disabled || loading ? 0.5 : pressed ? 0.82 : 1,
        },
        style,
      ]}
    >
      {loading ? (
        <ActivityIndicator color={isPrimary ? colors.primaryForeground : colors.primary} />
      ) : (
        <>
          {icon ? (
            <Feather
              name={icon}
              size={17}
              color={isPrimary ? colors.primaryForeground : colors.primary}
            />
          ) : null}
          <Text
            style={[
              styles.buttonLabel,
              {
                color: isPrimary
                  ? colors.primaryForeground
                  : colors.secondaryForeground,
              },
            ]}
          >
            {label}
          </Text>
        </>
      )}
    </Pressable>
  );
}

export function Card({
  children,
  style,
}: {
  children: React.ReactNode;
  style?: ViewStyle;
}) {
  const colors = useColors();
  return (
    <View
      style={[
        styles.card,
        { backgroundColor: colors.card, borderColor: colors.border },
        style,
      ]}
    >
      {children}
    </View>
  );
}

export function Field({
  label,
  error,
  ...props
}: TextInputProps & { label: string; error?: string }) {
  const colors = useColors();
  return (
    <View style={styles.fieldWrap}>
      <Text style={[styles.fieldLabel, { color: colors.foreground }]}>
        {label}
      </Text>
      <TextInput
        {...props}
        placeholderTextColor={colors.mutedForeground}
        style={[
          styles.input,
          {
            backgroundColor: colors.card,
            borderColor: error ? colors.destructive : colors.border,
            color: colors.foreground,
          },
          props.style,
        ]}
      />
      {error ? (
        <Text style={[styles.fieldError, { color: colors.destructive }]}>
          {error}
        </Text>
      ) : null}
    </View>
  );
}

export function PageTitle({
  eyebrow,
  title,
  subtitle,
}: {
  eyebrow: string;
  title: string;
  subtitle: string;
}) {
  const colors = useColors();
  return (
    <View style={styles.pageTitle}>
      <Text style={[styles.eyebrow, { color: colors.primary }]}>{eyebrow}</Text>
      <Text style={[styles.title, { color: colors.foreground }]}>{title}</Text>
      <Text style={[styles.subtitle, { color: colors.mutedForeground }]}>
        {subtitle}
      </Text>
    </View>
  );
}

export function Notice({
  title,
  body,
  tone = "info",
  icon,
}: {
  title: string;
  body: string;
  tone?: "info" | "warning" | "error";
  icon?: React.ComponentProps<typeof Feather>["name"];
}) {
  const colors = useColors();
  const color = tone === "error" ? colors.destructive : colors.primary;
  return (
    <View
      style={[
        styles.notice,
        { backgroundColor: colors.secondary, borderColor: colors.border },
      ]}
    >
      <Feather name={icon ?? "shield"} size={18} color={color} />
      <View style={styles.noticeText}>
        <Text style={[styles.noticeTitle, { color: colors.foreground }]}>
          {title}
        </Text>
        <Text style={[styles.noticeBody, { color: colors.mutedForeground }]}>
          {body}
        </Text>
      </View>
    </View>
  );
}

export function EmptyState({
  title,
  body,
  icon = "inbox",
}: {
  title: string;
  body: string;
  icon?: React.ComponentProps<typeof Feather>["name"];
}) {
  const colors = useColors();
  return (
    <View style={styles.empty}>
      <View style={[styles.emptyIcon, { backgroundColor: colors.secondary }]}>
        <Feather name={icon} size={22} color={colors.primary} />
      </View>
      <Text style={[styles.emptyTitle, { color: colors.foreground }]}>
        {title}
      </Text>
      <Text style={[styles.emptyBody, { color: colors.mutedForeground }]}>
        {body}
      </Text>
    </View>
  );
}

export function Row({
  title,
  detail,
  icon,
  trailing,
}: {
  title: string;
  detail: string;
  icon: React.ComponentProps<typeof Feather>["name"];
  trailing?: string;
}) {
  const colors = useColors();
  return (
    <View style={[styles.row, { borderBottomColor: colors.border }]}>
      <View style={[styles.rowIcon, { backgroundColor: colors.secondary }]}>
        <Feather name={icon} size={17} color={colors.primary} />
      </View>
      <View style={styles.rowCopy}>
        <Text style={[styles.rowTitle, { color: colors.foreground }]}>
          {title}
        </Text>
        <Text style={[styles.rowDetail, { color: colors.mutedForeground }]}>
          {detail}
        </Text>
      </View>
      {trailing ? (
        <Text style={[styles.rowTrailing, { color: colors.mutedForeground }]}>
          {trailing}
        </Text>
      ) : null}
    </View>
  );
}

const styles = StyleSheet.create({
  mark: {
    width: 42,
    height: 42,
    borderRadius: 14,
    alignItems: "center",
    justifyContent: "center",
  },
  brand: { flexDirection: "row", alignItems: "center", gap: 11 },
  brandName: { fontSize: 18, fontWeight: "700", letterSpacing: -0.4 },
  brandSub: { fontSize: 12, marginTop: 2 },
  button: {
    minHeight: 52,
    paddingHorizontal: 18,
    borderRadius: 16,
    alignItems: "center",
    justifyContent: "center",
    flexDirection: "row",
    gap: 9,
  },
  buttonLabel: { fontSize: 15, fontWeight: "700" },
  card: {
    borderWidth: 1,
    borderRadius: 22,
    padding: 18,
  },
  fieldWrap: { gap: 7 },
  fieldLabel: { fontSize: 13, fontWeight: "600" },
  input: {
    minHeight: 52,
    borderWidth: 1,
    borderRadius: 15,
    paddingHorizontal: 15,
    fontSize: 15,
  },
  fieldError: { fontSize: 12, lineHeight: 17 },
  pageTitle: { gap: 7, marginBottom: 21 },
  eyebrow: {
    fontSize: 11,
    fontWeight: "800",
    letterSpacing: 1.25,
    textTransform: "uppercase",
  },
  title: { fontSize: 29, lineHeight: 35, fontWeight: "700", letterSpacing: -0.8 },
  subtitle: { fontSize: 14, lineHeight: 21 },
  notice: {
    flexDirection: "row",
    alignItems: "flex-start",
    gap: 12,
    borderWidth: 1,
    borderRadius: 17,
    padding: 14,
  },
  noticeText: { flex: 1, gap: 3 },
  noticeTitle: { fontSize: 13, fontWeight: "700" },
  noticeBody: { fontSize: 12, lineHeight: 18 },
  empty: { alignItems: "center", paddingVertical: 30, paddingHorizontal: 20 },
  emptyIcon: {
    width: 50,
    height: 50,
    borderRadius: 17,
    alignItems: "center",
    justifyContent: "center",
    marginBottom: 12,
  },
  emptyTitle: { fontSize: 15, fontWeight: "700", textAlign: "center" },
  emptyBody: {
    fontSize: 13,
    lineHeight: 19,
    textAlign: "center",
    marginTop: 5,
    maxWidth: 290,
  },
  row: {
    minHeight: 68,
    flexDirection: "row",
    alignItems: "center",
    gap: 12,
    borderBottomWidth: StyleSheet.hairlineWidth,
  },
  rowIcon: {
    width: 36,
    height: 36,
    borderRadius: 12,
    alignItems: "center",
    justifyContent: "center",
  },
  rowCopy: { flex: 1, gap: 3 },
  rowTitle: { fontSize: 14, fontWeight: "600" },
  rowDetail: { fontSize: 12 },
  rowTrailing: { fontSize: 11, maxWidth: 90, textAlign: "right" },
});

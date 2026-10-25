import { Feather } from "@expo/vector-icons";
import { isLiquidGlassAvailable } from "expo-glass-effect";
import { Tabs } from "expo-router";
import { NativeTabs } from "expo-router/unstable-native-tabs";
import { BlurView } from "expo-blur";
import { SymbolView } from "expo-symbols";
import { Platform, StyleSheet, useColorScheme, View } from "react-native";
import { useSafeAreaInsets } from "react-native-safe-area-context";
import { useColors } from "@/hooks/useColors";

function NativeTabBar() {
  return (
    <NativeTabs>
      <NativeTabs.Trigger name="index">
        <NativeTabs.Trigger.Icon sf={{ default: "house", selected: "house.fill" }} />
        <NativeTabs.Trigger.Label>Inicio</NativeTabs.Trigger.Label>
      </NativeTabs.Trigger>
      <NativeTabs.Trigger name="clinics">
        <NativeTabs.Trigger.Icon sf={{ default: "cross.case", selected: "cross.case.fill" }} />
        <NativeTabs.Trigger.Label>Clínicas</NativeTabs.Trigger.Label>
      </NativeTabs.Trigger>
      <NativeTabs.Trigger name="access">
        <NativeTabs.Trigger.Icon sf={{ default: "lock.shield", selected: "lock.shield.fill" }} />
        <NativeTabs.Trigger.Label>Acceso</NativeTabs.Trigger.Label>
      </NativeTabs.Trigger>
    </NativeTabs>
  );
}

function ClassicTabBar() {
  const colors = useColors();
  const insets = useSafeAreaInsets();
  const colorScheme = useColorScheme();
  const isDark = colorScheme === "dark";
  const isIOS = Platform.OS === "ios";
  const isWeb = Platform.OS === "web";

  return (
    <Tabs
      screenOptions={{
        headerShown: false,
        tabBarActiveTintColor: colors.primary,
        tabBarInactiveTintColor: colors.mutedForeground,
        tabBarStyle: {
          position: "absolute",
          backgroundColor: isIOS ? "transparent" : colors.background,
          borderTopWidth: isWeb ? 1 : 0,
          borderTopColor: colors.border,
          elevation: 0,
          paddingBottom: isWeb ? 0 : insets.bottom,
          ...(isWeb ? { height: 84 } : {}),
        },
        tabBarBackground: () =>
          isIOS ? (
            <BlurView
              intensity={90}
              tint={isDark ? "dark" : "light"}
              style={StyleSheet.absoluteFill}
            />
          ) : isWeb ? (
            <View
              style={[
                StyleSheet.absoluteFill,
                { backgroundColor: colors.background },
              ]}
            />
          ) : null,
      }}
    >
      <Tabs.Screen
        name="index"
        options={{
          title: "Inicio",
          tabBarIcon: ({ color }) =>
            isIOS ? (
              <SymbolView name="house" tintColor={color} size={22} />
            ) : (
              <Feather name="home" size={21} color={color} />
            ),
        }}
      />
      <Tabs.Screen
        name="clinics"
        options={{
          title: "Clínicas",
          tabBarIcon: ({ color }) =>
            isIOS ? (
              <SymbolView name="cross.case" tintColor={color} size={22} />
            ) : (
              <Feather name="plus-square" size={20} color={color} />
            ),
        }}
      />
      <Tabs.Screen
        name="access"
        options={{
          title: "Acceso",
          tabBarIcon: ({ color }) =>
            isIOS ? (
              <SymbolView name="lock.shield" tintColor={color} size={22} />
            ) : (
              <Feather name="shield" size={20} color={color} />
            ),
        }}
      />
    </Tabs>
  );
}

export default function AppTabs() {
  return isLiquidGlassAvailable() ? <NativeTabBar /> : <ClassicTabBar />;
}

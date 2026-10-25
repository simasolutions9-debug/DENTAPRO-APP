import { useCallback, useEffect, useState } from "react";
import * as AuthSession from "expo-auth-session";
import * as WebBrowser from "expo-web-browser";
import { Link, type Href, useRouter } from "expo-router";
import { useSignIn, useSignUp, useSSO } from "@clerk/expo";
import {
  ActivityIndicator,
  Platform,
  Pressable,
  StyleSheet,
  Text,
  View,
} from "react-native";
import { useSafeAreaInsets } from "react-native-safe-area-context";
import { KeyboardAwareScrollViewCompat } from "@/components/KeyboardAwareScrollViewCompat";
import { BrandLockup, Button, Field, Notice } from "@/components/DentalUI";
import { useColors } from "@/hooks/useColors";

WebBrowser.maybeCompleteAuthSession();

type AuthMode = "sign-in" | "sign-up";
type AuthStep = "form" | "verify";

export function AuthScreen({ mode }: { mode: AuthMode }) {
  const colors = useColors();
  const insets = useSafeAreaInsets();
  const router = useRouter();
  const { signIn, fetchStatus: signInStatus } = useSignIn();
  const { signUp, fetchStatus: signUpStatus } = useSignUp();
  const { startSSOFlow } = useSSO();
  const [emailAddress, setEmailAddress] = useState("");
  const [password, setPassword] = useState("");
  const [verificationCode, setVerificationCode] = useState("");
  const [step, setStep] = useState<AuthStep>("form");
  const [errorText, setErrorText] = useState("");
  const [noticeText, setNoticeText] = useState("");
  const [isLoading, setIsLoading] = useState(false);

  const fetching =
    isLoading ||
    signInStatus === "fetching" ||
    signUpStatus === "fetching";
  const topInset = Platform.OS === "web" ? Math.max(insets.top, 67) : insets.top;
  const bottomInset = Platform.OS === "web" ? 34 : insets.bottom;
  const isSignUp = mode === "sign-up";

  useEffect(() => {
    if (Platform.OS !== "android") return;
    void WebBrowser.warmUpAsync();
    return () => {
      void WebBrowser.coolDownAsync();
    };
  }, []);

  const finishAuth = useCallback(async () => {
    router.replace("/(app)/(tabs)" as Href);
  }, [router]);

  const handleEmailAuth = useCallback(async () => {
    setErrorText("");
    setNoticeText("");
    setIsLoading(true);
    try {
      if (isSignUp) {
        const { error } = await signUp.password({ emailAddress, password });
        if (error) {
          setErrorText(error.message ?? "No pudimos crear tu cuenta.");
          return;
        }
        const verification = await signUp.verifications.sendEmailCode();
        if (verification.error) {
          setErrorText(
            verification.error.message ?? "No pudimos enviar el código.",
          );
          return;
        }
        setStep("verify");
        setNoticeText("Te enviamos un código de verificación por correo.");
        return;
      }

      const { error } = await signIn.password({ emailAddress, password });
      if (error) {
        setErrorText(error.message ?? "No pudimos iniciar sesión.");
        return;
      }
      if (signIn.status === "complete") {
        await signIn.finalize({ navigate: finishAuth });
        return;
      }
      if (
        signIn.status === "needs_client_trust" ||
        signIn.status === "needs_second_factor"
      ) {
        const emailFactor = signIn.supportedSecondFactors?.find(
          (factor) => factor.strategy === "email_code",
        );
        if (signIn.status === "needs_client_trust" || emailFactor) {
          const result = await signIn.mfa.sendEmailCode();
          if (result.error) {
            setErrorText(
              result.error.message ?? "No pudimos enviar el código.",
            );
            return;
          }
          setStep("verify");
          setNoticeText("Confirma tu identidad con el código enviado por correo.");
          return;
        }
      }
      setErrorText(
        "Tu cuenta requiere una verificación adicional no configurada en este dispositivo.",
      );
    } catch {
      setErrorText("No pudimos completar la solicitud. Intenta de nuevo.");
    } finally {
      setIsLoading(false);
    }
  }, [
    emailAddress,
    finishAuth,
    isSignUp,
    password,
    signIn,
    signUp,
  ]);

  const handleVerify = useCallback(async () => {
    setErrorText("");
    setIsLoading(true);
    try {
      if (isSignUp) {
        const { error } = await signUp.verifications.verifyEmailCode({
          code: verificationCode,
        });
        if (error) {
          setErrorText(error.message ?? "El código no es válido.");
          return;
        }
        if (signUp.status === "complete") {
          await signUp.finalize({ navigate: finishAuth });
        } else {
          setErrorText("La verificación aún está pendiente.");
        }
        return;
      }

      const { error } = await signIn.mfa.verifyEmailCode({
        code: verificationCode,
      });
      if (error) {
        setErrorText(error.message ?? "El código no es válido.");
        return;
      }
      if (signIn.status === "complete") {
        await signIn.finalize({ navigate: finishAuth });
      } else {
        setErrorText("La verificación aún está pendiente.");
      }
    } catch {
      setErrorText("No pudimos verificar el código. Intenta de nuevo.");
    } finally {
      setIsLoading(false);
    }
  }, [finishAuth, isSignUp, signIn, signUp, verificationCode]);

  const handleGoogle = useCallback(async () => {
    setErrorText("");
    setIsLoading(true);
    try {
      const { createdSessionId, setActive } = await startSSOFlow({
        strategy: "oauth_google",
        redirectUrl: AuthSession.makeRedirectUri(),
      });
      if (createdSessionId) {
        await setActive!({ session: createdSessionId });
        await finishAuth();
      } else {
        setErrorText(
          "La conexión de Google requiere configuración en el panel de autenticación.",
        );
      }
    } catch {
      setErrorText(
        "No pudimos iniciar con Google. Puedes continuar con correo y contraseña.",
      );
    } finally {
      setIsLoading(false);
    }
  }, [finishAuth, startSSOFlow]);

  const resendCode = useCallback(async () => {
    setErrorText("");
    const result = isSignUp
      ? await signUp.verifications.sendEmailCode()
      : await signIn.mfa.sendEmailCode();
    if (result.error) {
      setErrorText(result.error.message ?? "No pudimos enviar otro código.");
      return;
    }
    setNoticeText("Enviamos un nuevo código de verificación.");
  }, [isSignUp, signIn, signUp]);

  return (
    <KeyboardAwareScrollViewCompat
      style={{ flex: 1, backgroundColor: colors.background }}
      contentContainerStyle={[
        styles.content,
        { paddingTop: topInset + 18, paddingBottom: bottomInset + 20 },
      ]}
      bottomOffset={72}
      keyboardShouldPersistTaps="handled"
    >
      <BrandLockup />
      <View style={styles.intro}>
        <Text style={[styles.eyebrow, { color: colors.primary }]}>
          {step === "verify" ? "VERIFICACIÓN SEGURA" : "ACCESO SEGURO"}
        </Text>
        <Text style={[styles.title, { color: colors.foreground }]}>
          {step === "verify"
            ? "Confirma tu correo"
            : isSignUp
              ? "Crea tu cuenta"
              : "Qué bueno verte"}
        </Text>
        <Text style={[styles.subtitle, { color: colors.mutedForeground }]}>
          {step === "verify"
            ? "Introduce el código que enviamos a tu correo."
            : isSignUp
              ? "Empieza con una cuenta segura para acceder a tu espacio de trabajo."
              : "Inicia sesión para continuar a tu espacio Dental Pro."}
        </Text>
      </View>

      {errorText ? (
        <Notice
          title="No se pudo completar"
          body={errorText}
          tone="error"
          icon="alert-circle"
        />
      ) : null}
      {noticeText ? (
        <Notice
          title="Listo"
          body={noticeText}
          icon="check-circle"
        />
      ) : null}

      {step === "verify" ? (
        <View style={styles.form}>
          <Field
            label="Código de verificación"
            value={verificationCode}
            onChangeText={setVerificationCode}
            keyboardType="number-pad"
            autoComplete="one-time-code"
            placeholder="Ingresa el código"
            maxLength={8}
            testID="verification-code"
          />
          <Button
            label="Verificar y continuar"
            onPress={() => void handleVerify()}
            loading={fetching}
            disabled={verificationCode.trim().length < 4}
            testID="verify-email"
          />
          <Button
            label="Enviar otro código"
            kind="outline"
            onPress={() => void resendCode()}
            disabled={fetching}
            testID="resend-code"
          />
        </View>
      ) : (
        <View style={styles.form}>
          <Field
            label="Correo electrónico"
            value={emailAddress}
            onChangeText={setEmailAddress}
            keyboardType="email-address"
            autoCapitalize="none"
            autoComplete="email"
            textContentType="emailAddress"
            placeholder="nombre@correo.com"
            testID="auth-email"
          />
          <Field
            label="Contraseña"
            value={password}
            onChangeText={setPassword}
            secureTextEntry
            autoComplete={isSignUp ? "new-password" : "current-password"}
            textContentType={isSignUp ? "newPassword" : "password"}
            placeholder="Introduce tu contraseña"
            testID="auth-password"
          />
          <Button
            label={isSignUp ? "Crear cuenta" : "Iniciar sesión"}
            onPress={() => void handleEmailAuth()}
            loading={fetching}
            disabled={
              !emailAddress.trim() ||
              password.length < 8 ||
              fetching
            }
            testID="auth-submit"
          />
          <View style={styles.divider}>
            <View style={[styles.rule, { backgroundColor: colors.border }]} />
            <Text style={[styles.dividerText, { color: colors.mutedForeground }]}>
              o continúa con
            </Text>
            <View style={[styles.rule, { backgroundColor: colors.border }]} />
          </View>
          <Button
            label="Google"
            icon="globe"
            kind="outline"
            onPress={() => void handleGoogle()}
            loading={fetching}
            disabled={fetching}
            testID="google-auth"
          />
          {isSignUp ? <View nativeID="clerk-captcha" /> : null}
        </View>
      )}

      <View style={styles.footer}>
        <Text style={[styles.footerText, { color: colors.mutedForeground }]}>
          {isSignUp ? "¿Ya tienes una cuenta?" : "¿Todavía no tienes cuenta?"}
        </Text>
        <Link
          href={isSignUp ? "/(auth)/sign-in" : "/(auth)/sign-up"}
          asChild
        >
          <Pressable
            accessibilityRole="link"
            testID="auth-switch"
            style={({ pressed }) => ({ opacity: pressed ? 0.65 : 1 })}
          >
            <Text style={[styles.footerLink, { color: colors.primary }]}>
              {isSignUp ? "Iniciar sesión" : "Crear cuenta"}
            </Text>
          </Pressable>
        </Link>
      </View>
      {fetching ? (
        <ActivityIndicator color={colors.primary} style={styles.loading} />
      ) : null}
    </KeyboardAwareScrollViewCompat>
  );
}

const styles = StyleSheet.create({
  content: { flexGrow: 1, paddingHorizontal: 22, gap: 25 },
  intro: { gap: 8, marginTop: 9 },
  eyebrow: { fontSize: 10, fontWeight: "800", letterSpacing: 1.35 },
  title: { fontSize: 30, lineHeight: 36, fontWeight: "700", letterSpacing: -0.8 },
  subtitle: { fontSize: 14, lineHeight: 21, maxWidth: 340 },
  form: { gap: 15 },
  divider: { flexDirection: "row", alignItems: "center", gap: 12, marginVertical: 2 },
  rule: { flex: 1, height: StyleSheet.hairlineWidth },
  dividerText: { fontSize: 11 },
  footer: {
    flexDirection: "row",
    alignItems: "center",
    justifyContent: "center",
    gap: 6,
    marginTop: "auto",
    paddingTop: 18,
  },
  footerText: { fontSize: 12 },
  footerLink: { fontSize: 12, fontWeight: "700" },
  loading: { marginTop: 2 },
});

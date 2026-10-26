import "package:flutter/foundation.dart";
import "package:flutter/material.dart";

import "../app_theme.dart";
import "../demo/demo_data.dart";
import "../services/api_client.dart";
import "../services/appointment_service.dart";
import "../services/auth_service.dart";
import "../state/app_provider.dart";
import "../state/app_user.dart";
import "../widgets/dentapro_logo.dart";
import "patient_registration_screen.dart";

class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
    this.authRepository,
    this.appointmentsRepository,
  });

  final AuthRepository? authRepository;
  final AppointmentDashboardRepository? appointmentsRepository;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  late final AuthRepository _authRepository =
      widget.authRepository ?? AuthService();

  bool _isSubmitting = false;
  bool _hidePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    try {
      final session = await _authRepository.login(
        email: _emailController.text,
        password: _passwordController.text,
      );
      if (!mounted) return;
      if (session.role != "paciente" && session.role != "dentista") {
        setState(() => _isSubmitting = false);
        _showMessage("Este tipo de cuenta aún no tiene un panel disponible.");
        return;
      }
      await AppProviderScope.of(context).signIn(
        AppUser(
          id: session.patientId ?? _emailController.text.trim().toLowerCase(),
          name: _nameFromEmail(_emailController.text),
          email: _emailController.text.trim().toLowerCase(),
          phone: "",
          role: session.role,
          isDemo: false,
        ),
      );
      if (mounted) setState(() => _isSubmitting = false);
    } catch (error) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      _showMessage(_messageFor(error));
    }
  }

  String _nameFromEmail(String email) {
    final localPart = email.trim().split("@").first;
    final normalized = localPart.replaceAll(RegExp(r"[._-]+"), " ").trim();
    if (normalized.isEmpty) return "Paciente";
    return normalized
        .split(RegExp(r"\s+"))
        .map(
          (word) => word.isEmpty
              ? word
              : "${word[0].toUpperCase()}${word.substring(1)}",
        )
        .join(" ");
  }

  Future<void> _enterDemoMode() async {
    if (!kDebugMode) return;
    setState(() => _isSubmitting = true);
    try {
      await AppProviderScope.of(context).signIn(
        AppUser(
          id: demoPatient.id,
          name: demoPatient.name,
          email: demoPatient.email,
          phone: demoPatient.phone,
          role: "paciente",
          isDemo: true,
        ),
        initialAppointments: buildDemoAppointments(),
      );
      if (mounted) setState(() => _isSubmitting = false);
    } catch (error) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      _showMessage("No se pudo guardar la sesión local: $error");
    }
  }

  String _messageFor(Object error) {
    if (error is ApiException) return error.message;
    if (error is FormatException) return error.message.toString();
    return "No se pudo conectar con el servidor. Intenta de nuevo.";
  }

  Future<void> _openRegistration() async {
    final registeredEmail = await Navigator.of(context).push<String>(
      MaterialPageRoute<String>(
        builder: (_) => PatientRegistrationScreen(
          authRepository: _authRepository,
        ),
      ),
    );
    if (!mounted || registeredEmail == null) return;
    _emailController.text = registeredEmail;
    _showMessage("Cuenta creada. Inicia sesión.");
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(26, 26, 26, 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 10),
                      const Center(
                        child: DentaproLogo(markSize: 70, wordmarkSize: 27),
                      ),
                      const SizedBox(height: 30),
                      Text(
                        "Bienvenido de nuevo",
                        textAlign: TextAlign.center,
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(
                              fontSize: 25,
                            ),
                      ),
                      const SizedBox(height: 7),
                      Text(
                        "Ingresa con el correo y la contraseña de tu cuenta.",
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 28),
                      TextFormField(
                        key: const Key("login-email-field"),
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.email],
                        decoration: const InputDecoration(
                          labelText: "Correo electrónico",
                          prefixIcon: Icon(Icons.mail_outline_rounded),
                        ),
                        validator: (value) {
                          final email = value?.trim() ?? "";
                          if (email.isEmpty || !email.contains("@")) {
                            return "Ingresa un correo válido.";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        key: const Key("login-password-field"),
                        controller: _passwordController,
                        obscureText: _hidePassword,
                        textInputAction: TextInputAction.done,
                        autofillHints: const [AutofillHints.password],
                        onFieldSubmitted: (_) => _submit(),
                        decoration: InputDecoration(
                          labelText: "Contraseña",
                          prefixIcon: const Icon(Icons.lock_outline_rounded),
                          suffixIcon: IconButton(
                            tooltip: _hidePassword
                                ? "Mostrar contraseña"
                                : "Ocultar contraseña",
                            onPressed: () => setState(
                              () => _hidePassword = !_hidePassword,
                            ),
                            icon: Icon(
                              _hidePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                          ),
                        ),
                        validator: (value) => (value ?? "").isEmpty
                            ? "Ingresa tu contraseña."
                            : null,
                      ),
                      const SizedBox(height: 22),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          key: const Key("login-submit-button"),
                          onPressed: _isSubmitting ? null : _submit,
                          child: _isSubmitting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text("Ingresar"),
                        ),
                      ),
                      if (kDebugMode)
                        TextButton(
                          key: const Key("demo-login-button"),
                          onPressed: _isSubmitting ? null : _enterDemoMode,
                          child: const Text(
                            "Entrar en Modo Demo (Sin conexión)",
                          ),
                        ),
                      const SizedBox(height: 17),
                      Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            "¿Eres nuevo en Dentapro?",
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          TextButton(
                            key: const Key("open-registration-button"),
                            onPressed: _isSubmitting ? null : _openRegistration,
                            child: const Text("Crear cuenta"),
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),
                      Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          const Icon(
                            Icons.verified_user_outlined,
                            size: 15,
                            color: AppColors.teal,
                          ),
                          const SizedBox(width: 7),
                          Text(
                            "Cuidamos de ti y de tu sonrisa",
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

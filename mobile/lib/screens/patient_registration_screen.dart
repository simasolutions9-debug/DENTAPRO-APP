import "package:flutter/material.dart";

import "../app_theme.dart";
import "../services/api_client.dart";
import "../services/auth_service.dart";

class PatientRegistrationScreen extends StatefulWidget {
  const PatientRegistrationScreen({super.key, required this.authRepository});

  final AuthRepository authRepository;

  @override
  State<PatientRegistrationScreen> createState() =>
      _PatientRegistrationScreenState();
}

class _PatientRegistrationScreenState extends State<PatientRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isSubmitting = false;
  bool _hidePassword = true;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    try {
      await widget.authRepository.register(
        firstName: _firstNameController.text,
        lastName: _lastNameController.text,
        email: _emailController.text,
        password: _passwordController.text,
        phone: _phoneController.text,
      );
      if (!mounted) return;
      Navigator.of(context).pop(_emailController.text.trim().toLowerCase());
    } catch (error) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(_messageFor(error)),
            behavior: SnackBarBehavior.floating,
          ),
        );
    }
  }

  String _messageFor(Object error) {
    if (error is ApiException) return error.message;
    if (error is FormatException) return error.message.toString();
    return "No se pudo conectar con el servidor. Intenta de nuevo.";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          tooltip: "Volver",
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: Text(
          "Crear cuenta",
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.navy,
                fontSize: 18,
              ),
        ),
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(22, 8, 22, 28),
          children: [
            Text(
              "Regístrate como paciente",
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontSize: 24,
                  ),
            ),
            const SizedBox(height: 5),
            Text(
              "Completa tus datos para crear tu cuenta.",
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    key: const Key("registration-first-name-field"),
                    controller: _firstNameController,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: "Nombres",
                      prefixIcon: Icon(Icons.person_outline_rounded),
                    ),
                    validator: (value) => (value?.trim().isEmpty ?? true)
                        ? "Ingresa tus nombres."
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    key: const Key("registration-last-name-field"),
                    controller: _lastNameController,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: "Apellidos",
                      prefixIcon: Icon(Icons.person_outline_rounded),
                    ),
                    validator: (value) => (value?.trim().isEmpty ?? true)
                        ? "Ingresa tus apellidos."
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    key: const Key("registration-email-field"),
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: "Correo electrónico",
                      prefixIcon: Icon(Icons.mail_outline_rounded),
                    ),
                    validator: (value) {
                      final email = value?.trim() ?? "";
                      return email.contains("@")
                          ? null
                          : "Ingresa un correo válido.";
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    key: const Key("registration-phone-field"),
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: "Teléfono (opcional)",
                      prefixIcon: Icon(Icons.phone_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    key: const Key("registration-password-field"),
                    controller: _passwordController,
                    obscureText: _hidePassword,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: "Contraseña",
                      helperText: "Mínimo 8 caracteres",
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
                    validator: (value) => (value ?? "").length < 8
                        ? "Usa al menos 8 caracteres."
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    key: const Key("registration-confirm-password-field"),
                    controller: _confirmPasswordController,
                    obscureText: _hidePassword,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _submit(),
                    decoration: const InputDecoration(
                      labelText: "Confirmar contraseña",
                      prefixIcon: Icon(Icons.lock_outline_rounded),
                    ),
                    validator: (value) => value != _passwordController.text
                        ? "Las contraseñas no coinciden."
                        : null,
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      key: const Key("registration-submit-button"),
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
                          : const Text("Crear cuenta"),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import "package:dentapro_mobile/main.dart";
import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:dentapro_mobile/services/auth_service.dart";

class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository({this.role = "paciente", this.failLogin = false});

  final String role;
  final bool failLogin;
  String? submittedEmail;
  String? submittedPassword;
  Map<String, String>? submittedRegistration;

  @override
  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    submittedEmail = email;
    submittedPassword = password;
    if (failLogin) throw Exception("Invalid credentials");
    return AuthSession(
      accessToken: "access",
      refreshToken: "refresh",
      role: role,
      tenantId: "tenant",
    );
  }

  @override
  Future<void> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    String phone = "",
  }) async {
    submittedRegistration = {
      "first_name": firstName,
      "last_name": lastName,
      "email": email,
      "password": password,
      "phone": phone,
    };
  }
}

Future<void> _loginAs(
  WidgetTester tester, {
  String role = "paciente",
  _FakeAuthRepository? repository,
}) async {
  final auth = repository ?? _FakeAuthRepository(role: role);
  await tester.pumpWidget(DentaproApp(authRepository: auth));
  await tester.enterText(
    find.byKey(const Key("login-email-field")),
    "persona@example.com",
  );
  await tester.enterText(
    find.byKey(const Key("login-password-field")),
    "correct-password",
  );
  await tester.tap(find.byKey(const Key("login-submit-button")));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets("login shows email and password fields", (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const DentaproApp());

    expect(find.text("Dentapro"), findsOneWidget);
    expect(find.byKey(const Key("login-email-field")), findsOneWidget);
    expect(find.byKey(const Key("login-password-field")), findsOneWidget);
    expect(find.text("Ingresar"), findsOneWidget);
    expect(find.text("Crear cuenta"), findsOneWidget);
  });

  testWidgets("login sends credentials and routes by role", (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repository = _FakeAuthRepository(role: "dentista");
    await _loginAs(tester, repository: repository);

    expect(repository.submittedEmail, "persona@example.com");
    expect(repository.submittedPassword, "correct-password");
    expect(find.text("Panel odontológico"), findsOneWidget);
  });

  testWidgets("failed login displays the requested error", (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _loginAs(
      tester,
      repository: _FakeAuthRepository(failLogin: true),
    );

    expect(find.text("Credenciales incorrectas"), findsOneWidget);
  });

  testWidgets("patient registration submits data and returns email", (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repository = _FakeAuthRepository();
    await tester.pumpWidget(DentaproApp(authRepository: repository));
    await tester.tap(find.byKey(const Key("open-registration-button")));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key("registration-first-name-field")),
      "Ada",
    );
    await tester.enterText(
      find.byKey(const Key("registration-last-name-field")),
      "Lovelace",
    );
    await tester.enterText(
      find.byKey(const Key("registration-email-field")),
      "ada@example.com",
    );
    await tester.enterText(
      find.byKey(const Key("registration-password-field")),
      "secure-pass-123",
    );
    await tester.enterText(
      find.byKey(const Key("registration-confirm-password-field")),
      "secure-pass-123",
    );
    await tester.tap(find.byKey(const Key("registration-submit-button")));
    await tester.pumpAndSettle();

    expect(repository.submittedRegistration?["first_name"], "Ada");
    expect(repository.submittedRegistration?["last_name"], "Lovelace");
    expect(repository.submittedRegistration?["email"], "ada@example.com");
    expect(find.text("Cuenta creada. Inicia sesión."), findsOneWidget);
  });

  testWidgets("dentist dashboard retains local appointment actions", (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _loginAs(tester, role: "dentista");

    expect(find.text("Panel odontológico"), findsOneWidget);
    expect(find.text("Dra. Valentina Ortiz"), findsOneWidget);
    expect(find.text("INGRESOS DEL DÍA"), findsOneWidget);
    expect(find.text("\$350.00"), findsOneWidget);
    expect(find.byKey(const Key("weekly-appointments-chart")), findsOneWidget);
    expect(find.text("29 esta semana"), findsOneWidget);
    expect(find.text("Pacientes de hoy"), findsOneWidget);
    expect(find.text("María Fernanda López"), findsOneWidget);
    expect(find.text("09:00"), findsOneWidget);
    expect(find.text("Iniciar"), findsWidgets);
    expect(find.text("Completar"), findsOneWidget);

    final mariaAction =
        find.byKey(const ValueKey("appointment-action-María Fernanda López"));
    await tester.tap(mariaAction);
    await tester.pumpAndSettle();

    final mariaCard =
        find.byKey(const ValueKey("appointment-card-María Fernanda López"));
    expect(
      find.descendant(of: mariaCard, matching: find.text("Completada")),
      findsOneWidget,
    );
  });

  testWidgets("patient entry opens the sample dashboard", (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _loginAs(tester);

    expect(find.text("Hola, Camila"), findsOneWidget);
    expect(find.text("Limpieza y revisión"), findsOneWidget);
    expect(find.text("Accesos rápidos"), findsOneWidget);
  });

  testWidgets("patient quick access opens the mock odontogram and history", (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _loginAs(tester);
    await tester.tap(find.text("Odontograma"));
    await tester.pumpAndSettle();

    expect(find.text("Odontograma"), findsOneWidget);
    expect(find.byKey(const Key("odontogram-chart")), findsOneWidget);

    await tester.tap(find.byTooltip("Volver"));
    await tester.pumpAndSettle();
    await tester.tap(find.text("Historial"));
    await tester.pumpAndSettle();

    expect(find.text("Odontograma"), findsOneWidget);
    expect(find.byKey(const Key("odontogram-chart")), findsOneWidget);
    expect(find.text("ARCADA SUPERIOR"), findsOneWidget);
    expect(find.text("Sanos"), findsOneWidget);
    expect(find.text("Revisión"), findsNWidgets(2));
    expect(find.text("Urgencia"), findsNWidgets(2));
    expect(find.text("Historial de Tratamientos"), findsOneWidget);
    expect(find.text("Limpieza dental"), findsOneWidget);
    expect(find.text("Dra. Valentina Ortiz"), findsWidgets);
    expect(find.text("24 oct 2026"), findsOneWidget);
  });

  testWidgets("dashboard search opens the clinic catalog", (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _loginAs(tester);
    await tester.tap(find.byTooltip("Buscar clínicas"));
    await tester.pumpAndSettle();

    expect(find.text("Encuentra tu clínica"), findsOneWidget);
    expect(find.text("Clínica Sonríe"), findsOneWidget);
    expect(find.text("Dra. Valentina Ortiz"), findsOneWidget);
  });

  testWidgets("clinic search filters the sample listings", (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _loginAs(tester);
    await tester.tap(find.byTooltip("Buscar clínicas"));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key("clinic-search-field")),
      "Mateo Ruiz",
    );
    await tester.pumpAndSettle();

    expect(find.text("Clínica Nova"), findsOneWidget);
    expect(find.text("Clínica Sonríe"), findsNothing);
    expect(find.text("Sonrisa Kids"), findsNothing);
  });

  testWidgets("reservation screen shows calendar, slots, and mock summary", (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _loginAs(tester);
    await tester.tap(find.byTooltip("Buscar clínicas"));
    await tester.pumpAndSettle();
    await tester.tap(find.text("Reservar cita").first);
    await tester.pumpAndSettle();

    expect(find.byType(CalendarDatePicker), findsOneWidget);
    expect(find.text("Horarios disponibles"), findsOneWidget);
    expect(find.text("09:00"), findsOneWidget);
    expect(find.text("10:30"), findsNWidgets(2));
    expect(find.text("Resumen de reserva"), findsOneWidget);
    expect(find.text("Confirmar y Pagar"), findsOneWidget);

    await tester.tap(find.text("09:00"));
    await tester.pumpAndSettle();
    await tester.tap(find.text("Confirmar y Pagar"));
    await tester.pump();

    expect(
      find.text("Vista previa: no se realizó ningún cobro."),
      findsOneWidget,
    );
  });
}

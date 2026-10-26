import "dart:async";

import "package:dentapro_mobile/main.dart";
import "package:dentapro_mobile/screens/booking_checkout_screen.dart";
import "package:dentapro_mobile/screens/clinic_catalog_screen.dart";
import "package:dentapro_mobile/screens/patient_dashboard_screen.dart";
import "package:dentapro_mobile/services/appointment_service.dart";
import "package:dentapro_mobile/services/api_client.dart";
import "package:dentapro_mobile/services/clinic_service.dart";
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
  int loginCalls = 0;

  @override
  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    loginCalls++;
    submittedEmail = email;
    submittedPassword = password;
    if (failLogin) {
      throw const ApiException("Credenciales incorrectas", statusCode: 401);
    }
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

class _FakeClinicRepository implements ClinicRepository {
  _FakeClinicRepository({
    this.clinics = const [],
    this.error,
    this.fetch,
  });

  final List<ClinicListing> clinics;
  final Object? error;
  final Future<List<ClinicListing>> Function()? fetch;

  @override
  Future<List<ClinicListing>> fetchClinics() async {
    if (error != null) throw error!;
    if (fetch != null) return fetch!();
    return clinics;
  }
}

class _FakeClinicAvailabilityRepository
    implements ClinicAvailabilityRepository {
  _FakeClinicAvailabilityRepository(this.slots);

  final List<ClinicSlot> slots;

  @override
  Future<List<ClinicSlot>> fetchAvailability({
    required String clinicSlug,
    required DateTime date,
  }) async =>
      slots;
}

class _FakeAppointmentDashboardRepository
    implements AppointmentDashboardRepository {
  _FakeAppointmentDashboardRepository({
    this.upcoming = const [],
    this.clinicAppointments = const [],
  });

  final List<AppointmentSummary> upcoming;
  final List<AppointmentSummary> clinicAppointments;
  @override
  Future<List<AppointmentSummary>> fetchUpcomingAppointments() async {
    return upcoming;
  }

  @override
  Future<List<AppointmentSummary>> fetchClinicAppointments({
    required DateTime from,
    required DateTime to,
  }) async {
    return clinicAppointments
        .where(
          (appointment) =>
              !appointment.scheduledAt.isBefore(from) &&
              appointment.scheduledAt.isBefore(to.add(const Duration(days: 1))),
        )
        .toList(growable: false);
  }
}

AppointmentSummary _appointment({
  required String id,
  required String patientName,
  required DateTime scheduledAt,
  String clinicName = "Clínica Norte",
  double? estimatedFee,
  String status = "scheduled",
  String reason = "",
}) {
  return AppointmentSummary(
    id: id,
    patientId: "patient-$id",
    patientName: patientName,
    clinicSlug: "clinica-norte",
    clinicName: clinicName,
    scheduledAt: scheduledAt,
    durationMinutes: 30,
    status: status,
    reason: reason,
    estimatedFee: estimatedFee,
  );
}

Future<void> _loginAs(
  WidgetTester tester, {
  String role = "paciente",
  _FakeAuthRepository? repository,
  AppointmentDashboardRepository? appointmentsRepository,
}) async {
  final auth = repository ?? _FakeAuthRepository(role: role);
  await tester.pumpWidget(
    DentaproApp(
      authRepository: auth,
      appointmentsRepository:
          appointmentsRepository ?? _FakeAppointmentDashboardRepository(),
    ),
  );
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
    expect(find.text("Entrar en Modo Demo (Sin conexión)"), findsOneWidget);
  });

  testWidgets("demo login bypasses HTTP and opens a mocked patient dashboard", (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final authRepository = _FakeAuthRepository(failLogin: true);
    await tester.pumpWidget(DentaproApp(authRepository: authRepository));

    await tester.tap(find.byKey(const Key("demo-login-button")));
    await tester.pumpAndSettle();

    expect(authRepository.loginCalls, 0);
    expect(find.text("Hola, Paciente Demo"), findsOneWidget);
    expect(find.text("Clínica Sonrisa"), findsOneWidget);
    expect(find.text("Control de rutina"), findsOneWidget);
  });

  testWidgets("demo bottom navigation switches tabs and selection state", (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const DentaproApp());
    await tester.tap(find.byKey(const Key("demo-login-button")));
    await tester.pumpAndSettle();

    final navigationBar = find.byType(NavigationBar);
    expect(tester.widget<NavigationBar>(navigationBar).selectedIndex, 0);

    await tester.tap(find.text("Citas"));
    await tester.pumpAndSettle();
    expect(find.text("Mis citas"), findsOneWidget);
    expect(tester.widget<NavigationBar>(navigationBar).selectedIndex, 1);
    expect(find.text("Control de rutina"), findsOneWidget);

    await tester.tap(find.text("Perfil"));
    await tester.pumpAndSettle();
    expect(find.text("Mi perfil"), findsOneWidget);
    expect(find.text("Paciente Demo"), findsOneWidget);
    expect(tester.widget<NavigationBar>(navigationBar).selectedIndex, 2);

    await tester.tap(find.text("Inicio"));
    await tester.pumpAndSettle();
    expect(find.text("Hola, Paciente Demo"), findsOneWidget);
    expect(tester.widget<NavigationBar>(navigationBar).selectedIndex, 0);
  });

  testWidgets("patient profile edits are saved in app state", (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const DentaproApp());
    await tester.tap(find.byKey(const Key("demo-login-button")));
    await tester.pumpAndSettle();
    await tester.tap(find.text("Perfil"));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key("edit-profile-button")));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key("profile-name-field")),
      "Paciente Actualizado",
    );
    await tester.enterText(
      find.byKey(const Key("profile-phone-field")),
      "0987654321",
    );
    await tester.tap(find.byKey(const Key("profile-save-button")));
    await tester.pumpAndSettle();

    expect(find.text("Paciente Actualizado"), findsOneWidget);
    expect(find.text("0987654321"), findsOneWidget);
  });

  testWidgets("demo quick actions push local screens and return to dashboard", (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const DentaproApp());
    await tester.tap(find.byKey(const Key("demo-login-button")));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text("Odontograma"));
    await tester.tap(find.text("Odontograma"));
    await tester.pumpAndSettle();
    expect(find.text("Paciente Demo · 2 citas de ejemplo"), findsOneWidget);
    await tester.tap(find.byTooltip("Volver"));
    await tester.pumpAndSettle();
    expect(find.text("Hola, Paciente Demo"), findsOneWidget);

    await tester.ensureVisible(find.text("Historial"));
    await tester.tap(find.text("Historial"));
    await tester.pumpAndSettle();
    expect(find.text("Historial de Paciente Demo"), findsOneWidget);
    expect(find.text("Limpieza y revisión"), findsOneWidget);
    await tester.tap(find.byTooltip("Volver"));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text("Pagos"));
    await tester.tap(find.text("Pagos"));
    await tester.pumpAndSettle();
    expect(find.text("Pagos de Paciente Demo"), findsOneWidget);
    expect(
      find.text("Vista de demostración. No se realizan cobros."),
      findsOneWidget,
    );
    await tester.tap(find.byTooltip("Volver"));
    await tester.pumpAndSettle();
    expect(find.text("Hola, Paciente Demo"), findsOneWidget);
  });

  testWidgets("demo clinic booking stays on injected local data",
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const DentaproApp());
    await tester.tap(find.byKey(const Key("demo-login-button")));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip("Buscar clínicas"));
    await tester.pumpAndSettle();
    expect(find.text("Clínica Sonrisa"), findsOneWidget);

    await tester.tap(find.text("Clínica Sonrisa"));
    await tester.pumpAndSettle();
    expect(find.text("Reserva tu cita"), findsOneWidget);
    expect(find.text("10:00"), findsOneWidget);

    await tester.tap(find.text("10:00"));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text("Confirmar cita"));
    await tester.tap(find.text("Confirmar cita"));
    await tester.pumpAndSettle();
    expect(find.text("¡Cita confirmada!"), findsOneWidget);
    expect(find.text("Selecciona un horario"), findsOneWidget);

    await tester.tap(find.byTooltip("Volver"));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip("Volver"));
    await tester.pumpAndSettle();
    await tester.tap(find.text("Citas"));
    await tester.pumpAndSettle();
    expect(find.text("Consulta dental"), findsOneWidget);
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

  testWidgets("dentist dashboard renders clinic appointments and estimates", (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final today = DateUtils.dateOnly(DateTime.now());
    final appointments = [
      _appointment(
        id: "a1",
        patientName: "María Fernanda López",
        scheduledAt: DateTime(today.year, today.month, today.day, 9),
        estimatedFee: 100,
      ),
      _appointment(
        id: "a2",
        patientName: "Carlos Andrade",
        scheduledAt: DateTime(today.year, today.month, today.day, 10, 30),
        estimatedFee: 100,
        status: "confirmed",
      ),
      _appointment(
        id: "a3",
        patientName: "Sofía Reyes",
        scheduledAt: DateTime(today.year, today.month, today.day, 12),
        estimatedFee: 75,
        status: "completed",
      ),
      _appointment(
        id: "a4",
        patientName: "Andrés Viteri",
        scheduledAt: DateTime(today.year, today.month, today.day, 14, 30),
        estimatedFee: 75,
      ),
    ];
    await _loginAs(
      tester,
      role: "dentista",
      appointmentsRepository: _FakeAppointmentDashboardRepository(
        clinicAppointments: appointments,
      ),
    );

    expect(find.text("Panel odontológico"), findsOneWidget);
    expect(find.text("INGRESOS PREVISTOS HOY"), findsOneWidget);
    expect(find.text("\$350.00"), findsOneWidget);
    expect(find.byKey(const Key("weekly-appointments-chart")), findsOneWidget);
    expect(find.text("4 esta semana"), findsOneWidget);
    expect(find.text("Pacientes de hoy"), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text("María Fernanda López"),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text("María Fernanda López"), findsOneWidget);
    expect(find.text("09:00"), findsOneWidget);
    expect(find.text("Confirmada"), findsOneWidget);
    expect(find.text("Completada"), findsOneWidget);
  });

  testWidgets("patient dashboard renders the next appointment from API data", (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final nextAppointment = _appointment(
      id: "next",
      patientName: "Paciente",
      scheduledAt: DateTime.now().add(const Duration(days: 3)),
      clinicName: "Clínica Norte",
      reason: "Limpieza y revisión",
    );
    await tester.pumpWidget(
      MaterialApp(
        home: PatientDashboardScreen(
          appointmentsRepository: _FakeAppointmentDashboardRepository(
            upcoming: [nextAppointment],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text("Hola"), findsOneWidget);
    expect(find.text("Limpieza y revisión"), findsOneWidget);
    expect(find.text("Clínica Norte"), findsOneWidget);
    expect(find.text("Accesos rápidos"), findsOneWidget);
  });

  testWidgets("patient quick access opens odontogram and appointment history", (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: PatientDashboardScreen(
          appointmentsRepository: _FakeAppointmentDashboardRepository(
            upcoming: [
              _appointment(
                id: "history",
                patientName: "Paciente",
                scheduledAt: DateTime.now().add(const Duration(days: 3)),
                reason: "Limpieza y revisión",
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text("Odontograma"));
    await tester.pumpAndSettle();

    expect(find.text("Odontograma"), findsOneWidget);
    expect(find.byKey(const Key("odontogram-chart")), findsOneWidget);

    await tester.tap(find.byTooltip("Volver"));
    await tester.pumpAndSettle();
    await tester.tap(find.text("Historial"));
    await tester.pumpAndSettle();

    expect(find.text("Historial de citas"), findsOneWidget);
    expect(find.text("Limpieza y revisión"), findsOneWidget);
    expect(find.text("Clínica Norte"), findsOneWidget);
  });

  testWidgets("clinic catalog loads clinics from its repository", (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final response = Completer<List<ClinicListing>>();
    await tester.pumpWidget(
      MaterialApp(
        home: ClinicCatalogScreen(
          clinicRepository: _FakeClinicRepository(
            fetch: () => response.future,
          ),
        ),
      ),
    );

    expect(find.byKey(const Key("clinic-loading-indicator")), findsOneWidget);
    response.complete([
      const ClinicListing(
        slug: "clinica-norte",
        name: "Clínica Norte",
      ),
      const ClinicListing(
        slug: "clinica-sur",
        name: "Clínica Sur",
      ),
    ]);
    await tester.pumpAndSettle();
    expect(find.text("Encuentra tu clínica"), findsOneWidget);
    expect(find.text("Clínica Norte"), findsOneWidget);
    expect(find.text("Clínica Sur"), findsOneWidget);
  });

  testWidgets("clinic search filters the returned clinic list", (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: ClinicCatalogScreen(
          clinicRepository: _FakeClinicRepository(
            clinics: const [
              ClinicListing(
                slug: "clinica-nova",
                name: "Clínica Nova",
              ),
              ClinicListing(
                slug: "clinica-rio",
                name: "Clínica Río",
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key("clinic-search-field")),
      "nova",
    );
    await tester.pumpAndSettle();

    expect(find.text("Clínica Nova"), findsOneWidget);
    expect(find.text("Clínica Río"), findsNothing);
  });

  testWidgets("clinic catalog shows the backend error and retry", (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ClinicCatalogScreen(
          clinicRepository: _FakeClinicRepository(
            error: const ApiException(
              "La base de datos no está disponible.",
              statusCode: 503,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text("La base de datos no está disponible."), findsOneWidget);
    expect(find.byKey(const Key("clinic-retry-button")), findsOneWidget);
  });

  testWidgets("reservation screen displays published clinic slots", (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final today = DateUtils.dateOnly(DateTime.now());
    await tester.pumpWidget(
      MaterialApp(
        home: BookingCheckoutScreen(
          clinicSlug: "clinica-norte",
          clinicName: "Clínica Norte",
          availabilityRepository: _FakeClinicAvailabilityRepository([
            ClinicSlot(
              id: "slot-1",
              startsAt: DateTime(today.year, today.month, today.day, 9),
              durationMinutes: 30,
            ),
            ClinicSlot(
              id: "slot-2",
              startsAt: DateTime(today.year, today.month, today.day, 10, 30),
              durationMinutes: 30,
            ),
          ]),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(CalendarDatePicker), findsOneWidget);
    expect(find.text("Horarios disponibles"), findsOneWidget);
    expect(find.text("09:00"), findsOneWidget);
    expect(find.text("10:30"), findsOneWidget);
    expect(find.text("Resumen de reserva"), findsOneWidget);
    expect(find.text("Confirmar cita"), findsOneWidget);
    expect(find.text("Los horarios mostrados son de ejemplo."), findsNothing);
  });
}

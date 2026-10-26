import "package:flutter/widgets.dart";

import "../demo/demo_data.dart";
import "../services/appointment_service.dart";
import "../services/local_app_storage.dart";
import "app_user.dart";

class AppProvider extends ChangeNotifier {
  AppProvider({
    required LocalAppStorage storage,
    bool ready = true,
  })  : _storage = storage,
        _isReady = ready;

  final LocalAppStorage _storage;
  AppUser? _currentUser;
  List<AppointmentSummary> _appointments = const [];
  bool _isReady;

  AppUser? get currentUser => _currentUser;
  List<AppointmentSummary> get appointments => List.unmodifiable(_appointments);
  bool get isReady => _isReady;
  bool get isDemoMode => _currentUser?.isDemo ?? false;

  DemoPatient? get currentPatient {
    final user = _currentUser;
    if (user == null || user.role != "paciente") return null;
    return DemoPatient(
      id: user.id,
      name: user.name,
      email: user.email,
      phone: user.phone,
    );
  }

  static AppProvider inMemory() =>
      AppProvider(storage: MemoryLocalAppStorage());

  static Future<AppProvider> openHive() async {
    final provider = AppProvider(
      storage: await HiveLocalAppStorage.openFlutter(),
      ready: false,
    );
    await provider.restore();
    return provider;
  }

  Future<void> restore() async {
    _currentUser = await _storage.readCurrentUser();
    if (_currentUser case final user? when user.role == "paciente") {
      _appointments = await _storage.readAppointments(user.id);
    } else {
      _appointments = const [];
    }
    _isReady = true;
    notifyListeners();
  }

  Future<void> signIn(
    AppUser user, {
    List<AppointmentSummary> initialAppointments = const [],
  }) async {
    await _storage.saveCurrentUser(user);
    if (user.role == "paciente") {
      final savedAppointments = await _storage.readAppointments(user.id);
      if (savedAppointments.isEmpty) {
        for (final appointment in initialAppointments) {
          await _storage.saveAppointment(appointment);
        }
      }
      _appointments = await _storage.readAppointments(user.id);
    } else {
      _appointments = const [];
    }
    _currentUser = user;
    _isReady = true;
    notifyListeners();
  }

  Future<void> updatePatientProfile({
    required String name,
    required String phone,
  }) async {
    final currentUser = _currentUser;
    if (currentUser == null || currentUser.role != "paciente") {
      throw StateError("No hay un perfil de paciente activo.");
    }
    final updatedUser = currentUser.copyWith(
      name: name.trim(),
      phone: phone.trim(),
    );
    await _storage.saveCurrentUser(updatedUser);
    _currentUser = updatedUser;
    notifyListeners();
  }

  Future<AppointmentSummary> createLocalAppointment({
    required String clinicSlug,
    required String clinicName,
    required DateTime startsAt,
    required int durationMinutes,
    double? estimatedFee,
  }) async {
    final user = _currentUser;
    if (user == null || user.role != "paciente") {
      throw StateError("Inicia sesión como paciente para guardar la cita.");
    }
    final appointment = AppointmentSummary(
      id: "local-${DateTime.now().microsecondsSinceEpoch}",
      patientId: user.id,
      patientName: user.name,
      clinicSlug: clinicSlug,
      clinicName: clinicName,
      scheduledAt: startsAt,
      durationMinutes: durationMinutes,
      status: "confirmed",
      estimatedFee: estimatedFee,
      reason: "Consulta dental",
    );
    await _storage.saveAppointment(appointment);
    _appointments = [..._appointments, appointment]
      ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
    notifyListeners();
    return appointment;
  }

  Future<void> reloadAppointments() async {
    final user = _currentUser;
    if (user == null || user.role != "paciente") return;
    _appointments = await _storage.readAppointments(user.id);
    notifyListeners();
  }
}

class AppProviderScope extends InheritedNotifier<AppProvider> {
  const AppProviderScope({
    super.key,
    required AppProvider provider,
    required super.child,
  }) : super(notifier: provider);

  static AppProvider? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<AppProviderScope>()
        ?.notifier;
  }

  static AppProvider of(BuildContext context) {
    final provider = maybeOf(context);
    assert(provider != null, "AppProviderScope no está disponible.");
    return provider!;
  }
}

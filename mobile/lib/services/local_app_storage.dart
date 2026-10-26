import "package:hive_flutter/hive_flutter.dart";

import "../state/app_user.dart";
import "appointment_service.dart";

abstract interface class LocalAppStorage {
  Future<AppUser?> readCurrentUser();

  Future<void> saveCurrentUser(AppUser user);

  Future<void> clearCurrentUser();

  Future<List<AppointmentSummary>> readAppointments(String patientId);

  Future<void> saveAppointment(AppointmentSummary appointment);
}

class MemoryLocalAppStorage implements LocalAppStorage {
  AppUser? _currentUser;
  final Map<String, AppointmentSummary> _appointments = {};

  @override
  Future<AppUser?> readCurrentUser() async => _currentUser;

  @override
  Future<void> saveCurrentUser(AppUser user) async {
    _currentUser = user;
  }

  @override
  Future<void> clearCurrentUser() async {
    _currentUser = null;
  }

  @override
  Future<List<AppointmentSummary>> readAppointments(String patientId) async {
    return _appointments.values
        .where((appointment) => appointment.patientId == patientId)
        .toList(growable: false);
  }

  @override
  Future<void> saveAppointment(AppointmentSummary appointment) async {
    _appointments["${appointment.patientId}:${appointment.id}"] = appointment;
  }
}

class HiveLocalAppStorage implements LocalAppStorage {
  HiveLocalAppStorage._({
    required Box<Map> profiles,
    required Box<String> session,
    required Box<Map> appointments,
  })  : _profiles = profiles,
        _session = session,
        _appointments = appointments;

  static const _profilesBoxName = "dentapro.local_profiles";
  static const _sessionBoxName = "dentapro.local_session";
  static const _appointmentsBoxName = "dentapro.local_appointments";
  static const _activeUserKey = "active_user_id";

  final Box<Map> _profiles;
  final Box<String> _session;
  final Box<Map> _appointments;

  static Future<HiveLocalAppStorage> openFlutter() async {
    await Hive.initFlutter();
    return open();
  }

  static Future<HiveLocalAppStorage> open() async {
    final profiles = await Hive.openBox<Map>(_profilesBoxName);
    final session = await Hive.openBox<String>(_sessionBoxName);
    final appointments = await Hive.openBox<Map>(_appointmentsBoxName);
    return HiveLocalAppStorage._(
      profiles: profiles,
      session: session,
      appointments: appointments,
    );
  }

  @override
  Future<AppUser?> readCurrentUser() async {
    final userId = _session.get(_activeUserKey);
    if (userId == null) return null;
    final profile = _profiles.get(userId);
    return profile == null ? null : AppUser.fromMap(profile);
  }

  @override
  Future<void> saveCurrentUser(AppUser user) async {
    await _profiles.put(user.id, user.toMap());
    await _session.put(_activeUserKey, user.id);
  }

  @override
  Future<void> clearCurrentUser() async {
    await _session.delete(_activeUserKey);
  }

  @override
  Future<List<AppointmentSummary>> readAppointments(String patientId) async {
    final records = _appointments.values
        .where((record) => record["patient_id"] == patientId)
        .map((record) => AppointmentSummary.fromJson(
              Map<String, dynamic>.from(record),
            ))
        .toList(growable: false);
    records.sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
    return records;
  }

  @override
  Future<void> saveAppointment(AppointmentSummary appointment) async {
    await _appointments.put(
      "${appointment.patientId}:${appointment.id}",
      {
        "id": appointment.id,
        "patient_id": appointment.patientId,
        "patient_name": appointment.patientName,
        "clinic_slug": appointment.clinicSlug,
        "clinic_name": appointment.clinicName,
        "scheduled_at": appointment.scheduledAt.toIso8601String(),
        "duration_minutes": appointment.durationMinutes,
        "status": appointment.status,
        "estimated_fee": appointment.estimatedFee,
        "reason": appointment.reason,
      },
    );
  }
}

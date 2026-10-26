import "package:dio/dio.dart";

import "api_client.dart";
import "auth_service.dart";

abstract interface class AppointmentRepository {
  Future<void> createAppointment({
    required String clinicSlug,
    required String slotId,
    required DateTime startsAt,
  });
}

abstract interface class AppointmentDashboardRepository {
  Future<List<AppointmentSummary>> fetchUpcomingAppointments();

  Future<List<AppointmentSummary>> fetchClinicAppointments({
    required DateTime from,
    required DateTime to,
  });
}

class AppointmentSummary {
  const AppointmentSummary({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.clinicSlug,
    required this.clinicName,
    required this.scheduledAt,
    required this.durationMinutes,
    required this.status,
    this.estimatedFee,
    this.reason = "",
  });

  final String id;
  final String patientId;
  final String patientName;
  final String clinicSlug;
  final String clinicName;
  final DateTime scheduledAt;
  final int durationMinutes;
  final String status;
  final String reason;
  final double? estimatedFee;

  factory AppointmentSummary.fromJson(Map<String, dynamic> json) {
    final id = json["id"];
    final patientId = json["patient_id"];
    final patientName = json["patient_name"];
    final clinicSlug = json["clinic_slug"];
    final clinicName = json["clinic_name"];
    final scheduledAtValue = json["scheduled_at"];
    final durationMinutes = json["duration_minutes"];
    final status = json["status"];
    final reason = json["reason"];
    final scheduledAt =
        scheduledAtValue is String ? DateTime.tryParse(scheduledAtValue) : null;
    final feeValue = json["estimated_fee"];
    final fee =
        feeValue is num ? feeValue.toDouble() : double.tryParse("$feeValue");

    if (id is! String ||
        patientId is! String ||
        patientName is! String ||
        clinicSlug is! String ||
        clinicName is! String ||
        scheduledAt == null ||
        durationMinutes is! int ||
        status is! String ||
        (feeValue != null && (fee == null || !fee.isFinite || fee < 0)) ||
        (reason != null && reason is! String)) {
      throw const FormatException(
        "El servidor devolvió una cita con formato no válido.",
      );
    }
    return AppointmentSummary(
      id: id,
      patientId: patientId,
      patientName: patientName,
      clinicSlug: clinicSlug,
      clinicName: clinicName,
      scheduledAt: scheduledAt.toLocal(),
      durationMinutes: durationMinutes,
      status: status,
      reason: reason is String ? reason : "",
      estimatedFee: fee,
    );
  }
}

class AppointmentService
    implements AppointmentRepository, AppointmentDashboardRepository {
  AppointmentService({
    ApiClient? apiClient,
    AuthTokenStore? tokenStore,
  })  : _apiClient = apiClient ?? ApiClient(),
        _tokenStore = tokenStore ?? SecureAuthTokenStore();

  final ApiClient _apiClient;
  final AuthTokenStore _tokenStore;

  @override
  Future<List<AppointmentSummary>> fetchUpcomingAppointments() =>
      _fetchAppointments();

  @override
  Future<List<AppointmentSummary>> fetchClinicAppointments({
    required DateTime from,
    required DateTime to,
  }) {
    return _fetchAppointments(
      queryParameters: {
        "from": _dateParameter(from),
        "to": _dateParameter(to),
      },
    );
  }

  Future<List<AppointmentSummary>> _fetchAppointments({
    Map<String, String>? queryParameters,
  }) async {
    final accessToken = await _tokenStore.readAccessToken();
    if (accessToken == null || accessToken.isEmpty) {
      throw const ApiException(
        "Tu sesión no está disponible. Inicia sesión de nuevo.",
      );
    }

    try {
      final response = await _apiClient.dio.get(
        "v1/appointments/",
        queryParameters: queryParameters,
        options: Options(
          headers: {"Authorization": "Bearer $accessToken"},
        ),
      );
      if (response.data is! List) {
        throw const FormatException(
          "El servidor devolvió una lista de citas con formato no válido.",
        );
      }
      return (response.data as List).map((item) {
        if (item is! Map) {
          throw const FormatException(
            "El servidor devolvió una cita con formato no válido.",
          );
        }
        return AppointmentSummary.fromJson(Map<String, dynamic>.from(item));
      }).toList(growable: false);
    } on DioException catch (exception) {
      throw ApiException.fromDio(exception);
    }
  }

  String _dateParameter(DateTime date) =>
      "${date.year.toString().padLeft(4, "0")}-"
      "${date.month.toString().padLeft(2, "0")}-"
      "${date.day.toString().padLeft(2, "0")}";

  @override
  Future<void> createAppointment({
    required String clinicSlug,
    required String slotId,
    required DateTime startsAt,
  }) async {
    final accessToken = await _tokenStore.readAccessToken();
    final patientId = await _tokenStore.readPatientId();
    if (accessToken == null || accessToken.isEmpty || patientId == null) {
      throw const ApiException(
        "Tu sesión de paciente no está disponible. Inicia sesión de nuevo.",
      );
    }

    try {
      final response = await _apiClient.dio.post<Map<String, dynamic>>(
        "v1/appointments/",
        data: {
          "clinic_slug": clinicSlug,
          "slot_id": slotId,
          "patient_id": patientId,
          "starts_at": startsAt.toUtc().toIso8601String(),
        },
        options: Options(
          headers: {"Authorization": "Bearer $accessToken"},
        ),
      );
      if (response.statusCode != 201) {
        throw ApiException(
          "El servidor no confirmó la cita (HTTP ${response.statusCode ?? "?"}).",
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (exception) {
      throw ApiException.fromDio(exception);
    }
  }
}

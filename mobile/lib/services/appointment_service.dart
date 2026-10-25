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

class AppointmentService implements AppointmentRepository {
  AppointmentService({
    ApiClient? apiClient,
    AuthTokenStore? tokenStore,
  })  : _apiClient = apiClient ?? ApiClient(),
        _tokenStore = tokenStore ?? SecureAuthTokenStore();

  final ApiClient _apiClient;
  final AuthTokenStore _tokenStore;

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

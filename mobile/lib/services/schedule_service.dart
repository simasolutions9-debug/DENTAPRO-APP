import "package:dio/dio.dart";

import "api_client.dart";
import "auth_service.dart";

abstract interface class SchedulePublisher {
  Future<void> publishSlot({
    required String clinicSlug,
    required DateTime startsAt,
    required int durationMinutes,
    required String estimatedFee,
  });
}

class ScheduleService implements SchedulePublisher {
  ScheduleService({
    ApiClient? apiClient,
    AuthTokenStore? tokenStore,
  })  : _apiClient = apiClient ?? ApiClient(),
        _tokenStore = tokenStore ?? SecureAuthTokenStore();

  final ApiClient _apiClient;
  final AuthTokenStore _tokenStore;

  @override
  Future<void> publishSlot({
    required String clinicSlug,
    required DateTime startsAt,
    required int durationMinutes,
    required String estimatedFee,
  }) async {
    final accessToken = await _tokenStore.readAccessToken();
    if (accessToken == null || accessToken.isEmpty) {
      throw const ApiException(
        "Tu sesión no está disponible. Inicia sesión de nuevo.",
      );
    }

    try {
      final response = await _apiClient.dio.post(
        "v1/clinics/${Uri.encodeComponent(clinicSlug)}/availability/",
        data: {
          "starts_at": startsAt.toUtc().toIso8601String(),
          "duration_minutes": durationMinutes,
          "estimated_fee": estimatedFee,
        },
        options: Options(
          headers: {"Authorization": "Bearer $accessToken"},
        ),
      );
      if (response.statusCode != 201) {
        throw ApiException(
          "El servidor no publicó el horario (HTTP ${response.statusCode ?? "?"}).",
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (exception) {
      throw ApiException.fromDio(exception);
    }
  }
}

import "dart:convert";
import "dart:typed_data";

import "package:dentapro_mobile/services/api_client.dart";
import "package:dentapro_mobile/services/clinic_service.dart";
import "package:dio/dio.dart";
import "package:flutter_test/flutter_test.dart";

class _ClinicApiAdapter implements HttpClientAdapter {
  _ClinicApiAdapter({
    required this.statusCode,
    required this.responseJson,
  });

  final int statusCode;
  final String responseJson;
  RequestOptions? requestOptions;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requestOptions = options;
    return ResponseBody.fromString(
      responseJson,
      statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  test("fetchClinics requests the Django directory and parses real fields",
      () async {
    final adapter = _ClinicApiAdapter(
      statusCode: 200,
      responseJson: jsonEncode([
        {
          "tenant_id": "tenant-1",
          "slug": "clinica-norte",
          "name": "Clínica Norte",
          "logo_url": "https://example.test/norte.png",
          "primary_color": "#123456",
          "secondary_color": "#654321",
        },
      ]),
    );
    final dio = Dio(BaseOptions(baseUrl: "http://localhost:8000/api/"))
      ..httpClientAdapter = adapter;
    final service = ClinicService(apiClient: ApiClient(dio: dio));

    final clinics = await service.fetchClinics();

    expect(adapter.requestOptions?.method, "GET");
    expect(adapter.requestOptions?.uri.path, "/api/v1/clinics/");
    expect(clinics, hasLength(1));
    expect(clinics.single.name, "Clínica Norte");
    expect(clinics.single.slug, "clinica-norte");
    expect(clinics.single.logoUrl, "https://example.test/norte.png");
  });

  test("fetchClinics exposes the backend error", () async {
    final adapter = _ClinicApiAdapter(
      statusCode: 503,
      responseJson: jsonEncode({"detail": "Catálogo no disponible."}),
    );
    final dio = Dio(BaseOptions(baseUrl: "http://localhost:8000/api/"))
      ..httpClientAdapter = adapter;
    final service = ClinicService(apiClient: ApiClient(dio: dio));

    await expectLater(
      service.fetchClinics(),
      throwsA(
        isA<ApiException>()
            .having(
                (error) => error.message, "message", "Catálogo no disponible.")
            .having((error) => error.statusCode, "statusCode", 503),
      ),
    );
  });
}

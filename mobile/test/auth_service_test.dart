import "dart:convert";
import "dart:typed_data";

import "package:dio/dio.dart";
import "package:flutter_test/flutter_test.dart";
import "package:dentapro_mobile/services/api_client.dart";
import "package:dentapro_mobile/services/auth_service.dart";

class _RecordingAdapter implements HttpClientAdapter {
  _RecordingAdapter({
    required this.statusCode,
    required this.responseJson,
  });

  final int statusCode;
  final String responseJson;
  RequestOptions? requestOptions;
  Map<String, dynamic>? requestData;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requestOptions = options;
    final data = options.data;
    if (data is String) {
      requestData = Map<String, dynamic>.from(jsonDecode(data) as Map);
    } else if (data is Map) {
      requestData = Map<String, dynamic>.from(data);
    }
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

class _MemoryTokenStore implements AuthTokenStore {
  String? accessToken;
  String? refreshToken;

  @override
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    this.accessToken = accessToken;
    this.refreshToken = refreshToken;
  }
}

String _jwt(Map<String, Object> claims) {
  final payload =
      base64Url.encode(utf8.encode(jsonEncode(claims))).replaceAll("=", "");
  return "header.$payload.signature";
}

void main() {
  test("login sends tenant id and saves both JWTs", () async {
    final access = _jwt({
      "role": "paciente",
      "tenant_id": ApiClient.demoTenantId,
    });
    final adapter = _RecordingAdapter(
      statusCode: 200,
      responseJson: jsonEncode({
        "access": access,
        "refresh": "refresh-token",
      }),
    );
    final dio = Dio(BaseOptions(baseUrl: "http://localhost:8000/api/"))
      ..httpClientAdapter = adapter;
    final store = _MemoryTokenStore();
    final service = AuthService(
      apiClient: ApiClient(dio: dio),
      tokenStore: store,
    );

    final session = await service.login(
      email: " Patient@Example.com ",
      password: "secret",
    );

    expect(adapter.requestOptions?.uri.path, "/api/auth/token/");
    expect(adapter.requestData, {
      "email": "patient@example.com",
      "password": "secret",
      "tenant_id": ApiClient.demoTenantId,
    });
    expect(session.role, "paciente");
    expect(session.tenantId, ApiClient.demoTenantId);
    expect(store.accessToken, access);
    expect(store.refreshToken, "refresh-token");
  });

  test("registration sends patient fields to the registration endpoint",
      () async {
    final adapter = _RecordingAdapter(
      statusCode: 201,
      responseJson: "{}",
    );
    final dio = Dio(BaseOptions(baseUrl: "http://localhost:8000/api/"))
      ..httpClientAdapter = adapter;
    final service = AuthService(apiClient: ApiClient(dio: dio));

    await service.register(
      firstName: " Ada ",
      lastName: "Lovelace",
      email: " ADA@example.com ",
      password: "secure-pass-123",
      phone: " 555-0100 ",
    );

    expect(adapter.requestOptions?.uri.path, "/api/auth/register/");
    expect(adapter.requestData, {
      "first_name": "Ada",
      "last_name": "Lovelace",
      "email": "ada@example.com",
      "password": "secure-pass-123",
      "phone": "555-0100",
    });
  });
}

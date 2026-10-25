import "package:dio/dio.dart";
import "package:flutter/foundation.dart";

class ApiClient {
  ApiClient({Dio? dio, String? baseUrl})
      : dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: _normalizeBaseUrl(baseUrl ?? _defaultBaseUrl()),
                connectTimeout: const Duration(seconds: 10),
                receiveTimeout: const Duration(seconds: 15),
                headers: const {
                  "Accept": "application/json",
                  "Content-Type": "application/json",
                },
              ),
            );

  static const demoTenantId = String.fromEnvironment(
    "DENTAPRO_TENANT_ID",
    defaultValue: "00000000-0000-0000-0000-000000000001",
  );

  final Dio dio;

  static String _defaultBaseUrl() {
    const configured = String.fromEnvironment("DENTAPRO_API_BASE_URL");
    if (configured.trim().isNotEmpty) {
      return configured;
    }

    if (kIsWeb) {
      final page = Uri.base;
      return Uri(
        scheme: page.scheme.isEmpty ? "http" : page.scheme,
        host: page.host.isEmpty ? "127.0.0.1" : page.host,
        port: 8000,
        path: "/api/",
      ).toString();
    }

    if (defaultTargetPlatform == TargetPlatform.android) {
      return "http://10.0.2.2:8000/api/";
    }

    return "http://127.0.0.1:8000/api/";
  }

  static String _normalizeBaseUrl(String value) {
    final normalized = value.trim();
    return normalized.endsWith("/") ? normalized : "$normalized/";
  }
}

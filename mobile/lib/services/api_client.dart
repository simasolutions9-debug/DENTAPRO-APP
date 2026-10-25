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

  static const defaultTenantId = String.fromEnvironment(
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

class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  factory ApiException.fromDio(DioException exception) {
    final statusCode = exception.response?.statusCode;
    final serverMessage = _readServerMessage(exception.response?.data);
    if (serverMessage != null) {
      return ApiException(serverMessage, statusCode: statusCode);
    }

    final message = switch (exception.type) {
      DioExceptionType.connectionTimeout =>
        "Se agotó el tiempo para conectar con el servidor.",
      DioExceptionType.sendTimeout =>
        "Se agotó el tiempo al enviar la solicitud.",
      DioExceptionType.receiveTimeout =>
        "El servidor tardó demasiado en responder.",
      DioExceptionType.connectionError =>
        "No se pudo conectar con el servidor. Verifica tu conexión.",
      DioExceptionType.badCertificate =>
        "No se pudo establecer una conexión segura con el servidor.",
      DioExceptionType.cancel => "La solicitud fue cancelada.",
      _ when statusCode != null =>
        "El servidor rechazó la solicitud (HTTP $statusCode).",
      _ => "No se pudo completar la solicitud. Intenta de nuevo.",
    };
    return ApiException(message, statusCode: statusCode);
  }

  static String? _readServerMessage(Object? data) {
    if (data is Map) {
      for (final key in ["detail", "message", "error", "non_field_errors"]) {
        final message = _firstText(data[key]);
        if (message != null) return message;
      }
      for (final entry in data.entries) {
        final message = _firstText(entry.value);
        if (message != null) return "${entry.key}: $message";
      }
    }
    if (data is String) {
      final message = data.trim();
      if (message.isNotEmpty &&
          message.length <= 500 &&
          !message.toLowerCase().contains("<html")) {
        return message;
      }
    }
    return null;
  }

  static String? _firstText(Object? value) {
    if (value is String && value.trim().isNotEmpty) return value.trim();
    if (value is Iterable) {
      for (final item in value) {
        final message = _firstText(item);
        if (message != null) return message;
      }
    }
    return null;
  }

  @override
  String toString() => message;
}

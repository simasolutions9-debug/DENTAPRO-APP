import "dart:convert";

import "package:dio/dio.dart";
import "package:flutter_secure_storage/flutter_secure_storage.dart";

import "api_client.dart";

abstract interface class AuthRepository {
  Future<AuthSession> login({
    required String email,
    required String password,
  });

  Future<void> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    String phone,
  });
}

abstract interface class AuthTokenStore {
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  });
}

class SecureAuthTokenStore implements AuthTokenStore {
  SecureAuthTokenStore({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  static const _accessTokenKey = "dentapro.access_token";
  static const _refreshTokenKey = "dentapro.refresh_token";

  final FlutterSecureStorage _storage;

  @override
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _storage.write(key: _accessTokenKey, value: accessToken);
    await _storage.write(key: _refreshTokenKey, value: refreshToken);
  }
}

class AuthSession {
  const AuthSession({
    required this.accessToken,
    required this.refreshToken,
    required this.role,
    required this.tenantId,
  });

  final String accessToken;
  final String refreshToken;
  final String role;
  final String tenantId;
}

class AuthService implements AuthRepository {
  AuthService({
    ApiClient? apiClient,
    AuthTokenStore? tokenStore,
  })  : _apiClient = apiClient ?? ApiClient(),
        _tokenStore = tokenStore ?? SecureAuthTokenStore();

  final ApiClient _apiClient;
  final AuthTokenStore _tokenStore;

  @override
  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    late final Response<Map<String, dynamic>> response;
    try {
      response = await _apiClient.dio.post<Map<String, dynamic>>(
        "auth/token/",
        data: {
          "email": email.trim().toLowerCase(),
          "password": password,
          "tenant_id": ApiClient.defaultTenantId,
        },
      );
    } on DioException catch (exception) {
      throw ApiException.fromDio(exception);
    }
    final accessToken = response.data?["access"] as String?;
    final refreshToken = response.data?["refresh"] as String?;
    if (accessToken == null || refreshToken == null) {
      throw const FormatException(
          "La respuesta de autenticación está incompleta.");
    }

    final claims = _decodeJwtClaims(accessToken);
    final role = claims["role"] as String?;
    final tenantId = claims["tenant_id"] as String?;
    if (role == null || tenantId == null) {
      throw const FormatException("El token no contiene el rol del usuario.");
    }

    await _tokenStore.saveTokens(
      accessToken: accessToken,
      refreshToken: refreshToken,
    );
    return AuthSession(
      accessToken: accessToken,
      refreshToken: refreshToken,
      role: role,
      tenantId: tenantId,
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
    try {
      await _apiClient.dio.post<void>(
        "auth/register/",
        data: {
          "first_name": firstName.trim(),
          "last_name": lastName.trim(),
          "email": email.trim().toLowerCase(),
          "password": password,
          "phone": phone.trim(),
        },
      );
    } on DioException catch (exception) {
      throw ApiException.fromDio(exception);
    }
  }

  Map<String, dynamic> _decodeJwtClaims(String token) {
    final parts = token.split(".");
    if (parts.length != 3) {
      throw const FormatException("El token recibido no es válido.");
    }
    final payload = utf8.decode(
      base64Url.decode(base64Url.normalize(parts[1])),
    );
    final decoded = jsonDecode(payload);
    if (decoded is! Map) {
      throw const FormatException("El contenido del token no es válido.");
    }
    return Map<String, dynamic>.from(decoded);
  }
}

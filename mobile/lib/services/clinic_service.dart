import "package:dio/dio.dart";

import "api_client.dart";

abstract interface class ClinicRepository {
  Future<List<ClinicListing>> fetchClinics();
}

class ClinicListing {
  const ClinicListing({
    required this.tenantId,
    required this.slug,
    required this.name,
    this.logoUrl,
  });

  final String tenantId;
  final String slug;
  final String name;
  final String? logoUrl;

  factory ClinicListing.fromJson(Map<String, dynamic> json) {
    final tenantId = json["tenant_id"];
    final slug = json["slug"];
    final name = json["name"];
    final logoUrl = json["logo_url"];
    if (tenantId is! String || slug is! String || name is! String) {
      throw const FormatException(
        "La respuesta del catálogo no contiene los datos requeridos.",
      );
    }
    if (logoUrl != null && logoUrl is! String) {
      throw const FormatException(
          "La URL del logo de la clínica no es válida.");
    }
    final normalizedLogoUrl = logoUrl is String ? logoUrl.trim() : "";
    return ClinicListing(
      tenantId: tenantId,
      slug: slug,
      name: name,
      logoUrl: normalizedLogoUrl.isEmpty ? null : normalizedLogoUrl,
    );
  }
}

class ClinicService implements ClinicRepository {
  ClinicService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  @override
  Future<List<ClinicListing>> fetchClinics() async {
    try {
      final response = await _apiClient.dio.get("v1/clinics/");
      final data = response.data;
      if (data is! List) {
        throw const FormatException(
          "El servidor devolvió un catálogo con formato no válido.",
        );
      }
      return data.map((item) {
        if (item is! Map) {
          throw const FormatException(
            "El servidor devolvió una clínica con formato no válido.",
          );
        }
        return ClinicListing.fromJson(Map<String, dynamic>.from(item));
      }).toList(growable: false);
    } on DioException catch (exception) {
      throw ApiException.fromDio(exception);
    }
  }
}

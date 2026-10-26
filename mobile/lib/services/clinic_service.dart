import "package:dio/dio.dart";

import "api_client.dart";

abstract interface class ClinicRepository {
  Future<List<ClinicListing>> fetchClinics();
}

abstract interface class ClinicAvailabilityRepository {
  Future<List<ClinicSlot>> fetchAvailability({
    required String clinicSlug,
    required DateTime date,
  });
}

class ClinicListing {
  const ClinicListing({
    required this.slug,
    required this.name,
    this.logoUrl,
  });

  final String slug;
  final String name;
  final String? logoUrl;

  factory ClinicListing.fromJson(Map<String, dynamic> json) {
    final slug = json["slug"];
    final name = json["name"];
    final logoUrl = json["logo_url"];
    if (slug is! String || name is! String) {
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
      slug: slug,
      name: name,
      logoUrl: normalizedLogoUrl.isEmpty ? null : normalizedLogoUrl,
    );
  }
}

class ClinicSlot {
  const ClinicSlot({
    required this.id,
    required this.startsAt,
    required this.durationMinutes,
    this.estimatedFee,
  });

  final String id;
  final DateTime startsAt;
  final int durationMinutes;
  final double? estimatedFee;

  factory ClinicSlot.fromJson(Map<String, dynamic> json) {
    final id = json["id"];
    final startsAtValue = json["starts_at"];
    final durationMinutes = json["duration_minutes"];
    final fee = _parseMoney(json["estimated_fee"]);
    final startsAt =
        startsAtValue is String ? DateTime.tryParse(startsAtValue) : null;
    if (id is! String ||
        startsAt == null ||
        durationMinutes is! int ||
        durationMinutes <= 0) {
      throw const FormatException(
        "El servidor devolvió un horario con formato no válido.",
      );
    }
    return ClinicSlot(
      id: id,
      startsAt: startsAt.toLocal(),
      durationMinutes: durationMinutes,
      estimatedFee: fee,
    );
  }

  static double? _parseMoney(Object? value) {
    if (value == null) return null;
    final amount = value is num ? value.toDouble() : double.tryParse("$value");
    if (amount == null || !amount.isFinite || amount < 0) {
      throw const FormatException(
        "El servidor devolvió una tarifa estimada no válida.",
      );
    }
    return amount;
  }
}

class ClinicService implements ClinicRepository, ClinicAvailabilityRepository {
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

  @override
  Future<List<ClinicSlot>> fetchAvailability({
    required String clinicSlug,
    required DateTime date,
  }) async {
    final formattedDate = "${date.year.toString().padLeft(4, "0")}-"
        "${date.month.toString().padLeft(2, "0")}-"
        "${date.day.toString().padLeft(2, "0")}";
    try {
      final response = await _apiClient.dio.get(
        "v1/clinics/${Uri.encodeComponent(clinicSlug)}/availability/",
        queryParameters: {"date": formattedDate},
      );
      final data = response.data;
      if (data is! Map || data["slots"] is! List) {
        throw const FormatException(
          "El servidor devolvió una disponibilidad con formato no válido.",
        );
      }
      return (data["slots"] as List).map((item) {
        if (item is! Map) {
          throw const FormatException(
            "El servidor devolvió un horario con formato no válido.",
          );
        }
        return ClinicSlot.fromJson(Map<String, dynamic>.from(item));
      }).toList(growable: false);
    } on DioException catch (exception) {
      throw ApiException.fromDio(exception);
    }
  }
}

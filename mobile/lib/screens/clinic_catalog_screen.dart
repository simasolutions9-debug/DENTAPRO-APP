import "package:flutter/material.dart";

import "../app_theme.dart";
import "../demo/demo_data.dart";
import "../services/api_client.dart";
import "../services/appointment_service.dart";
import "../services/clinic_service.dart";
import "booking_checkout_screen.dart";

class ClinicCatalogScreen extends StatefulWidget {
  const ClinicCatalogScreen({
    super.key,
    this.clinicRepository,
    this.availabilityRepository,
    this.appointmentRepository,
    this.demoPatient,
    this.demoAppointments,
  });

  final ClinicRepository? clinicRepository;
  final ClinicAvailabilityRepository? availabilityRepository;
  final AppointmentRepository? appointmentRepository;
  final DemoPatient? demoPatient;
  final List<AppointmentSummary>? demoAppointments;

  @override
  State<ClinicCatalogScreen> createState() => _ClinicCatalogScreenState();
}

class _ClinicCatalogScreenState extends State<ClinicCatalogScreen> {
  final _searchController = TextEditingController();
  late final ClinicRepository _clinicRepository =
      widget.clinicRepository ?? ClinicService();

  List<ClinicListing> _clinics = const [];
  String _query = "";
  String? _errorMessage;
  bool _isLoading = true;

  List<ClinicListing> get _visibleClinics {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return _clinics;
    return _clinics
        .where(
          (clinic) =>
              clinic.name.toLowerCase().contains(query) ||
              clinic.slug.toLowerCase().contains(query),
        )
        .toList(growable: false);
  }

  @override
  void initState() {
    super.initState();
    _loadClinics();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadClinics() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final clinics = await _clinicRepository.fetchClinics();
      if (!mounted) return;
      setState(() {
        _clinics = clinics;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = switch (error) {
          ApiException(:final message) => message,
          FormatException(:final message) => message.toString(),
          _ => "No se pudo cargar el catálogo. Intenta de nuevo.",
        };
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final clinics = _visibleClinics;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          tooltip: "Volver",
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: Text(
          "Explorar clínicas",
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.navy,
                fontSize: 18,
              ),
        ),
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
      ),
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          onRefresh: _loadClinics,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(22, 10, 22, 30),
            children: [
              Text(
                "Encuentra tu clínica",
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontSize: 25,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                "Explora los perfiles de clínicas disponibles.",
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 20),
              TextField(
                key: const Key("clinic-search-field"),
                controller: _searchController,
                onChanged: (value) => setState(() => _query = value),
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: "Buscar clínica",
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: AppColors.teal,
                  ),
                  suffixIcon: _query.isEmpty
                      ? null
                      : IconButton(
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _query = "");
                          },
                          tooltip: "Limpiar búsqueda",
                          icon: const Icon(Icons.close_rounded),
                        ),
                ),
              ),
              const SizedBox(height: 23),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      "Clínicas",
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontSize: 17,
                          ),
                    ),
                  ),
                  if (!_isLoading && _errorMessage == null)
                    Text(
                      "${clinics.length} ${clinics.length == 1 ? "resultado" : "resultados"}",
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                ],
              ),
              const SizedBox(height: 13),
              if (_isLoading)
                const _LoadingState()
              else if (_errorMessage case final error?)
                _RequestErrorState(
                  message: error,
                  onRetry: _loadClinics,
                )
              else if (_clinics.isEmpty)
                const _EmptyCatalogState(
                  icon: Icons.storefront_outlined,
                  title: "No hay clínicas disponibles",
                  message: "Los perfiles publicados aparecerán aquí.",
                )
              else if (clinics.isEmpty)
                const _EmptyCatalogState(
                  icon: Icons.search_off_rounded,
                  title: "No encontramos resultados",
                  message: "Prueba con otro nombre de clínica.",
                )
              else
                for (final clinic in clinics) ...[
                  _ClinicCard(
                    clinic: clinic,
                    availabilityRepository: widget.availabilityRepository,
                    appointmentRepository: widget.appointmentRepository,
                    demoPatient: widget.demoPatient,
                    demoAppointments: widget.demoAppointments,
                  ),
                  const SizedBox(height: 16),
                ],
            ],
          ),
        ),
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 50),
      child: Center(
        child: CircularProgressIndicator(
          color: AppColors.teal,
          key: Key("clinic-loading-indicator"),
        ),
      ),
    );
  }
}

class _RequestErrorState extends StatelessWidget {
  const _RequestErrorState({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.cloud_off_outlined,
            color: AppColors.muted,
            size: 32,
          ),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            key: const Key("clinic-retry-button"),
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text("Reintentar"),
          ),
        ],
      ),
    );
  }
}

class _EmptyCatalogState extends StatelessWidget {
  const _EmptyCatalogState({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 34),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.teal, size: 32),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 5),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _ClinicCard extends StatelessWidget {
  const _ClinicCard({
    required this.clinic,
    this.availabilityRepository,
    this.appointmentRepository,
    this.demoPatient,
    this.demoAppointments,
  });

  final ClinicListing clinic;
  final ClinicAvailabilityRepository? availabilityRepository;
  final AppointmentRepository? appointmentRepository;
  final DemoPatient? demoPatient;
  final List<AppointmentSummary>? demoAppointments;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(23),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.8)),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withValues(alpha: 0.055),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(23),
        child: Material(
          color: Colors.white,
          child: InkWell(
            borderRadius: BorderRadius.circular(23),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => BookingCheckoutScreen(
                  clinicSlug: clinic.slug,
                  clinicName: clinic.name,
                  availabilityRepository: availabilityRepository,
                  appointmentRepository: appointmentRepository,
                  demoPatient: demoPatient,
                  demoAppointments: demoAppointments,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: 154,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      _ClinicArtwork(clinic: clinic),
                      const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.transparent, Color(0xAA062B4E)],
                            stops: [0.45, 1],
                          ),
                        ),
                      ),
                      Positioned(
                        left: 16,
                        right: 16,
                        bottom: 14,
                        child: Text(
                          clinic.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.2,
                            shadows: [
                              Shadow(
                                color: Color(0x66000000),
                                blurRadius: 8,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.verified_outlined,
                        color: AppColors.teal,
                        size: 19,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "Perfil de clínica en DENTAPRO",
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppColors.ink,
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.teal,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ClinicArtwork extends StatelessWidget {
  const _ClinicArtwork({required this.clinic});

  final ClinicListing clinic;

  @override
  Widget build(BuildContext context) {
    final logoUrl = clinic.logoUrl;
    if (logoUrl == null) {
      return const ColoredBox(
        color: Color(0xFFE7F6F5),
        child: Icon(
          Icons.local_hospital_outlined,
          color: AppColors.teal,
          size: 48,
        ),
      );
    }
    return Image.network(
      logoUrl,
      fit: BoxFit.cover,
      semanticLabel: "Logo de ${clinic.name}",
      errorBuilder: (context, error, stackTrace) => const ColoredBox(
        color: Color(0xFFE7F6F5),
        child: Icon(
          Icons.local_hospital_outlined,
          color: AppColors.teal,
          size: 48,
        ),
      ),
    );
  }
}

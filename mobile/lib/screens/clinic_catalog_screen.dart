import "package:flutter/material.dart";

import "../app_theme.dart";

class ClinicCatalogScreen extends StatefulWidget {
  const ClinicCatalogScreen({super.key});

  @override
  State<ClinicCatalogScreen> createState() => _ClinicCatalogScreenState();
}

class _ClinicCatalogScreenState extends State<ClinicCatalogScreen> {
  static const _categories = ["Todas", "General", "Ortodoncia", "Infantil"];
  final _searchController = TextEditingController();

  String _query = "";
  String _selectedCategory = "Todas";

  List<_ClinicListing> get _visibleClinics {
    final normalizedQuery = _query.trim().toLowerCase();

    return _sampleClinics.where((clinic) {
      final matchesCategory =
          _selectedCategory == "Todas" || clinic.category == _selectedCategory;
      final searchableContent = [
        clinic.name,
        clinic.doctor,
        clinic.specialty,
        clinic.location,
      ].join(" ").toLowerCase();
      final matchesQuery = normalizedQuery.isEmpty ||
          searchableContent.contains(normalizedQuery);

      return matchesCategory && matchesQuery;
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
        child: ListView(
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
              "Profesionales de confianza, cerca de ti.",
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            TextField(
              key: const Key("clinic-search-field"),
              controller: _searchController,
              onChanged: (value) => setState(() => _query = value),
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: "Clínica, doctor o especialidad",
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
            const SizedBox(height: 15),
            const _LocationLabel(),
            const SizedBox(height: 23),
            Row(
              children: [
                Expanded(
                  child: Text(
                    "Clínicas destacadas",
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontSize: 17,
                        ),
                  ),
                ),
                Text(
                  "${clinics.length} ${clinics.length == 1 ? "opción" : "opciones"}",
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ],
            ),
            const SizedBox(height: 13),
            SizedBox(
              height: 39,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _categories.length,
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final category = _categories[index];
                  final selected = category == _selectedCategory;

                  return ChoiceChip(
                    label: Text(category),
                    selected: selected,
                    showCheckmark: false,
                    onSelected: (_) {
                      setState(() => _selectedCategory = category);
                    },
                    backgroundColor: Colors.white,
                    selectedColor: AppColors.teal.withValues(alpha: 0.14),
                    side: BorderSide(
                      color: selected ? AppColors.teal : AppColors.border,
                    ),
                    labelStyle: TextStyle(
                      color: selected ? AppColors.navy : AppColors.muted,
                      fontSize: 12,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  );
                },
              ),
            ),
            const SizedBox(height: 15),
            if (clinics.isEmpty)
              const _EmptySearchState()
            else
              for (final clinic in clinics) ...[
                _ClinicCard(clinic: clinic),
                const SizedBox(height: 16),
              ],
            const SizedBox(height: 2),
            Text(
              "Clínicas y precios de ejemplo para esta vista previa.",
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontSize: 10,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LocationLabel extends StatelessWidget {
  const _LocationLabel();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(
          Icons.location_on_outlined,
          size: 18,
          color: AppColors.teal,
        ),
        const SizedBox(width: 6),
        Text(
          "Guayaquil, Ecuador",
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.ink,
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(width: 3),
        const Icon(
          Icons.keyboard_arrow_down_rounded,
          size: 18,
          color: AppColors.muted,
        ),
      ],
    );
  }
}

class _ClinicCard extends StatelessWidget {
  const _ClinicCard({required this.clinic});

  final _ClinicListing clinic;

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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 166,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    clinic.photoAsset,
                    fit: BoxFit.cover,
                    semanticLabel: "Foto de ${clinic.name}",
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: AppColors.teal.withValues(alpha: 0.12),
                      child: const Icon(
                        Icons.local_hospital_outlined,
                        color: AppColors.teal,
                        size: 40,
                      ),
                    ),
                  ),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Color(0xAA062B4E),
                        ],
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
                      maxLines: 1,
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
              padding: const EdgeInsets.fromLTRB(15, 14, 15, 15),
              child: Column(
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 21,
                        backgroundColor: AppColors.teal.withValues(alpha: 0.14),
                        child: Text(
                          clinic.initials,
                          style: const TextStyle(
                            color: AppColors.navy,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              clinic.doctor,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontSize: 14),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              clinic.specialty,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.star_rounded,
                        size: 16,
                        color: AppColors.gold,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        clinic.rating,
                        style: const TextStyle(
                          color: AppColors.ink,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Divider(height: 1, color: AppColors.border),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            const Icon(
                              Icons.place_outlined,
                              size: 16,
                              color: AppColors.muted,
                            ),
                            const SizedBox(width: 5),
                            Flexible(
                              child: Text(
                                clinic.location,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(fontSize: 11),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            "Consulta desde",
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(fontSize: 9),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            clinic.price,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  color: AppColors.navy,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptySearchState extends StatelessWidget {
  const _EmptySearchState();

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
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.teal.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.search_off_rounded,
              color: AppColors.teal,
              size: 27,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            "No encontramos resultados",
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 5),
          Text(
            "Prueba con otra clínica, doctor o especialidad.",
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _ClinicListing {
  const _ClinicListing({
    required this.name,
    required this.doctor,
    required this.specialty,
    required this.location,
    required this.price,
    required this.rating,
    required this.initials,
    required this.category,
    required this.photoAsset,
  });

  final String name;
  final String doctor;
  final String specialty;
  final String location;
  final String price;
  final String rating;
  final String initials;
  final String category;
  final String photoAsset;
}

const _sampleClinics = [
  _ClinicListing(
    name: "Clínica Sonríe",
    doctor: "Dra. Valentina Ortiz",
    specialty: "Odontología general",
    location: "Urdesa, Guayaquil",
    price: "\$28",
    rating: "4.9",
    initials: "VO",
    category: "General",
    photoAsset: "assets/images/clinic-sonrie.jpg",
  ),
  _ClinicListing(
    name: "Clínica Nova",
    doctor: "Dr. Mateo Ruiz",
    specialty: "Ortodoncia",
    location: "Kennedy, Guayaquil",
    price: "\$35",
    rating: "4.8",
    initials: "MR",
    category: "Ortodoncia",
    photoAsset: "assets/images/clinic-nova.jpg",
  ),
  _ClinicListing(
    name: "Sonrisa Kids",
    doctor: "Dra. Paula Arias",
    specialty: "Odontopediatría",
    location: "Samborondón",
    price: "\$30",
    rating: "4.9",
    initials: "PA",
    category: "Infantil",
    photoAsset: "assets/images/clinic-kids.jpg",
  ),
];

import 'package:flutter/material.dart';
import '../models/animal.dart';
import '../utils/constants.dart';
import '../utils/currency_converter.dart';

class AnimalCatalogueCard extends StatelessWidget {
  final Animal animal;
  final bool showDetails;
  final bool showPhotos;
  final bool showHealth;
  final bool showVaccinations;
  final bool showProduction;
  final bool showGenetics;
  final bool showPrices;
  final String currency;
  final double? priceOverride;
  final String? notes;
  final bool compactMode;
  final VoidCallback? onRemove;

  const AnimalCatalogueCard({
    super.key,
    required this.animal,
    this.showDetails = true,
    this.showPhotos = true,
    this.showHealth = false,
    this.showVaccinations = false,
    this.showProduction = false,
    this.showGenetics = false,
    this.showPrices = false,
    this.currency = 'TND',
    this.priceOverride,
    this.notes,
    this.compactMode = false,
    this.onRemove,
  });

  // ── Resolve relative /uploads/... paths to full URL ──────────────────────
  static String? resolveImage(String? path) {
    if (path == null || path.isEmpty) return null;
    if (path.startsWith('http://') || path.startsWith('https://')) return path;
    final host = AppConfig.serverHost;
    final port = AppConfig.serverPort;
    final slash = path.startsWith('/') ? '' : '/';
    return 'http://$host:$port$slash$path';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Photo — always first, full width
          if (showPhotos) _buildPhoto(),
          Padding(
            padding: EdgeInsets.all(compactMode ? 12 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                if (showDetails) ...[const SizedBox(height: 10), _buildDetails()],
                if (showHealth) ...[const SizedBox(height: 10), _buildHealth()],
                if (showVaccinations) ...[const SizedBox(height: 10), _buildVaccinations()],
                if (showProduction) ...[const SizedBox(height: 10), _buildProduction()],
                if (showGenetics) ...[const SizedBox(height: 10), _buildGenetics()],
                if (showPrices) ...[const SizedBox(height: 10), _buildPrice()],
                if (notes != null && notes!.isNotEmpty) ...[const SizedBox(height: 10), _buildNotes()],
                if (onRemove != null) ...[const SizedBox(height: 6), _buildRemoveBtn()],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Photo ─────────────────────────────────────────────────────────────────

  Widget _buildPhoto() {
    final url = resolveImage(animal.profileImage);
    final height = compactMode ? 130.0 : 200.0;

    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(16),
        topRight: Radius.circular(16),
      ),
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: url != null
            ? Image.network(
                url,
                fit: BoxFit.cover,
                loadingBuilder: (_, child, progress) {
                  if (progress == null) return child;
                  return _photoPlaceholder();
                },
                errorBuilder: (_, __, ___) => _photoPlaceholder(),
              )
            : _photoPlaceholder(),
      ),
    );
  }

  Widget _photoPlaceholder() {
    final emojis = {'cow': '🐄', 'horse': '🐴', 'sheep': '🐑', 'dog': '🐕'};
    final emoji = emojis[animal.animalType.toLowerCase()] ?? '🐾';
    return Container(
      color: const Color(0xFFF0F4F0),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 48)),
            const SizedBox(height: 6),
            Text(
              animal.animalType.toUpperCase(),
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF9E9E9E),
                fontWeight: FontWeight.w600,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    final isMale = animal.sex.toLowerCase() == 'male';
    final typeEmojis = {'cow': '🐄', 'horse': '🐴', 'sheep': '🐑', 'dog': '🐕'};
    final typeLabels = {'cow': 'Cattle', 'horse': 'Horse', 'sheep': 'Sheep', 'dog': 'Dog'};
    final emoji = typeEmojis[animal.animalType.toLowerCase()] ?? '🐾';
    final typeLabel = typeLabels[animal.animalType.toLowerCase()] ?? animal.animalType;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    animal.name.isNotEmpty ? animal.name : (animal.tagNumber ?? 'Unnamed'),
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  if (animal.tagNumber != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Tag: ${animal.tagNumber}',
                      style: const TextStyle(fontSize: 11, color: Color(0xFF9E9E9E)),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Sex badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: isMale ? const Color(0xFFE3F2FD) : const Color(0xFFFCE4EC),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isMale ? const Color(0xFF90CAF9) : const Color(0xFFF48FB1),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isMale ? Icons.male : Icons.female,
                    size: 13,
                    color: isMale ? const Color(0xFF1565C0) : const Color(0xFFC2185B),
                  ),
                  const SizedBox(width: 3),
                  Text(
                    isMale ? 'Male' : 'Female',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isMale ? const Color(0xFF1565C0) : const Color(0xFFC2185B),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            // Type badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFA5D6A7)),
              ),
              child: Text(
                '$emoji $typeLabel',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2E7D32),
                ),
              ),
            ),
            if (animal.breed != null && animal.breed!.isNotEmpty) ...[
              const SizedBox(width: 8),
              Text(
                animal.breed!,
                style: const TextStyle(fontSize: 12, color: Color(0xFF757575)),
              ),
            ],
          ],
        ),
      ],
    );
  }

  // ── Details ───────────────────────────────────────────────────────────────

  Widget _buildDetails() {
    final rows = <_Row>[];
    rows.add(_Row('Age', _age()));
    if (animal.weight != null) rows.add(_Row('Weight', '${animal.weight!.toStringAsFixed(0)} kg'));
    if (animal.isFattening == true) rows.add(_Row('Fattening', '✓ In progress'));
    if (animal.isPregnant == true) rows.add(_Row('Pregnant', '✓ Yes'));
    if (animal.expectedBirthDate != null) rows.add(_Row('Expected birth', _date(animal.expectedBirthDate!)));
    if (rows.isEmpty) return const SizedBox.shrink();
    return _infoBox(rows.map((r) => _row(r.label, r.value)).toList());
  }

  // ── Health ────────────────────────────────────────────────────────────────

  Widget _buildHealth() {
    final c = _healthColor(animal.healthStatus);
    return _section('Health', Icons.health_and_safety, c, [
      _row('Status', animal.healthStatus, valueColor: c),
      _row('Vitality', '${animal.vitalityScore}/100'),
      if (animal.bodyTemp != null) _row('Temperature', '${animal.bodyTemp!.toStringAsFixed(1)} °C'),
      if (animal.lastVetCheck != null) _row('Last vet check', _date(animal.lastVetCheck!)),
      // Vaccination status is shown in the dedicated Vaccinations section — not duplicated here
    ]);
  }

  Color _healthColor(String s) {
    switch (s.toUpperCase()) {
      case 'OPTIMAL': return const Color(0xFF2E7D32);
      case 'WARNING': return const Color(0xFFE65100);
      case 'CRITICAL': return const Color(0xFFC62828);
      default: return const Color(0xFF757575);
    }
  }

  // ── Vaccinations ──────────────────────────────────────────────────────────

  Widget _buildVaccinations() {
    final records = animal.vaccineRecords;

    // Cas 1 : données détaillées disponibles (chargées depuis l'API avec include)
    if (records != null && records.isNotEmpty) {
      return _section(
        'Vaccinations (${records.length})',
        Icons.vaccines,
        const Color(0xFF388E3C),
        records.take(3).map((v) {
          // Afficher le nom du vaccin — jamais l'ID
          final vaccineName = v.vaccine?.nameEn?.isNotEmpty == true
              ? v.vaccine!.nameEn!
              : (v.vaccine?.nameFr?.isNotEmpty == true
                  ? v.vaccine!.nameFr!
                  : (v.vaccine?.code?.isNotEmpty == true
                      ? v.vaccine!.code!
                      : 'Vaccine'));
          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(children: [
              const Icon(Icons.check_circle, size: 13, color: Color(0xFF2E7D32)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  vaccineName,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF212121)),
                ),
              ),
              Text(
                _date(v.administeredAt),
                style: const TextStyle(fontSize: 11, color: Color(0xFF9E9E9E)),
              ),
            ]),
          );
        }).toList(),
      );
    }

    // Cas 2 : pas de détails — fallback sur le booléen vaccination
    return _section('Vaccinations', Icons.vaccines, const Color(0xFF388E3C), [
      Row(children: [
        Icon(
          animal.vaccination ? Icons.check_circle : Icons.cancel,
          size: 14,
          color: animal.vaccination ? const Color(0xFF2E7D32) : const Color(0xFFC62828),
        ),
        const SizedBox(width: 6),
        Text(
          animal.vaccination ? 'Up to date' : 'Not vaccinated',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: animal.vaccination ? const Color(0xFF2E7D32) : const Color(0xFFC62828),
          ),
        ),
      ]),
    ]);
  }

  // ── Production ────────────────────────────────────────────────────────────

  Widget _buildProduction() {
    final rows = <_Row>[];
    final t = animal.animalType.toLowerCase();
    if (t == 'cow') {
      if (animal.dailyMilkAvgL != null) rows.add(_Row('Avg milk/day', '${animal.dailyMilkAvgL!.toStringAsFixed(1)} L'));
      if (animal.lactationNumber != null) rows.add(_Row('Lactation #', '${animal.lactationNumber}'));
    } else if (t == 'sheep') {
      if (animal.meatGrade != null) rows.add(_Row('Meat grade', animal.meatGrade!));
      if (animal.woolLastShearDate != null) rows.add(_Row('Last shearing', _date(animal.woolLastShearDate!)));
    } else if (t == 'horse') {
      if (animal.raceCategory != null) rows.add(_Row('Category', animal.raceCategory!));
      if (animal.trainingLevel != null) rows.add(_Row('Training', animal.trainingLevel!));
    }
    if (rows.isEmpty) return const SizedBox.shrink();
    return _section('Production', Icons.trending_up, const Color(0xFF0277BD),
        rows.map((r) => _row(r.label, r.value)).toList());
  }

  // ── Genetics ──────────────────────────────────────────────────────────────

  Widget _buildGenetics() {
    final rows = <_Row>[];
    if (animal.motherId != null) rows.add(_Row('Mother ID', animal.motherId!));
    if (animal.fatherId != null) rows.add(_Row('Father ID', animal.fatherId!));
    if (animal.birthCount > 0) rows.add(_Row('Birth count', '${animal.birthCount}'));
    rows.add(_Row('Origin', animal.origin == 'purchased' ? 'Purchased' : 'Born on farm'));
    return _section('Genetics', Icons.account_tree, const Color(0xFF6A1B9A),
        rows.map((r) => _row(r.label, r.value)).toList());
  }

  // ── Price ─────────────────────────────────────────────────────────────────

  Widget _buildPrice() {
    // Raw price is always stored in TND
    final rawTND = priceOverride ?? animal.estimatedValue ?? animal.salePrice;
    if (rawTND == null) return const SizedBox.shrink();

    final isTND = currency.toUpperCase() == 'TND';
    final displayText = isTND
        ? '${rawTND.round()} TND'
        : CurrencyConverter.formatWithOriginal(rawTND, currency);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFA5D6A7)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.sell_rounded, color: Color(0xFF2E7D32), size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Main price in selected currency
                Text(
                  isTND
                      ? '${rawTND.round()} TND'
                      : CurrencyConverter.formatPrice(rawTND, currency),
                  style: const TextStyle(
                    color: Color(0xFF1B5E20),
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                // Show TND equivalent when currency is not TND
                if (!isTND) ...[
                  const SizedBox(height: 2),
                  Text(
                    '≈ ${rawTND.round()} TND',
                    style: const TextStyle(
                      color: Color(0xFF757575),
                      fontSize: 11,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (priceOverride != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: const Color(0xFFFFCC80)),
              ),
              child: const Text('Custom',
                  style: TextStyle(fontSize: 10, color: Color(0xFFE65100))),
            ),
        ],
      ),
    );
  }

  // ── Notes ─────────────────────────────────────────────────────────────────

  Widget _buildNotes() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFDE7),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFFF176)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.sticky_note_2, color: Color(0xFFF9A825), size: 16),
          const SizedBox(width: 8),
          Expanded(child: Text(notes!, style: const TextStyle(color: Color(0xFF33691E), fontSize: 12))),
        ],
      ),
    );
  }

  // ── Remove ────────────────────────────────────────────────────────────────

  Widget _buildRemoveBtn() {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton.icon(
        onPressed: onRemove,
        icon: const Icon(Icons.remove_circle_outline, color: Color(0xFFD32F2F), size: 16),
        label: const Text('Remove', style: TextStyle(color: Color(0xFFD32F2F), fontSize: 12)),
        style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2)),
      ),
    );
  }

  // ── Shared builders ───────────────────────────────────────────────────────

  Widget _infoBox(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Column(children: children),
    );
  }

  Widget _section(String title, IconData icon, Color color, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 5),
            Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
          ]),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }

  Widget _row(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text('$label:', style: const TextStyle(fontSize: 12, color: Color(0xFF9E9E9E), fontWeight: FontWeight.w500)),
          ),
          Expanded(
            child: Text(value,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                    color: valueColor ?? const Color(0xFF212121))),
          ),
        ],
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  String _age() {
    final m = animal.age;
    if (m <= 0) return 'Unknown';
    final y = m ~/ 12;
    final r = m % 12;
    if (y > 0 && r > 0) return '$y yr $r mo';
    if (y > 0) return '$y yr${y > 1 ? 's' : ''}';
    return '$m mo';
  }

  String _date(DateTime d) =>
      '${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}/${d.year}';
}

class _Row {
  final String label;
  final String value;
  const _Row(this.label, this.value);
}

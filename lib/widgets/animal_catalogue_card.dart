import 'package:flutter/material.dart';
import '../models/animal.dart';
import '../services/api_service.dart';

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

  String? _resolveImageUrl(String? path) {
    if (path == null || path.isEmpty) return null;
    if (path.startsWith('http://') || path.startsWith('https://')) return path;
    final base = ApiService.mediaBaseUrl;
    return '$base${path.startsWith('/') ? '' : '/'}$path';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
      ),
      padding: EdgeInsets.all(compactMode ? 12 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showPhotos) _buildPhotoSection(context),
          _buildBasicInfo(context),
          if (showDetails) _buildDetailsSection(context),
          if (showHealth) _buildHealthSection(context),
          if (showVaccinations) _buildVaccinationsSection(context),
          if (showProduction) _buildProductionSection(context),
          if (showGenetics) _buildGeneticsSection(context),
          if (showPrices) _buildPriceSection(context),
          if (notes != null && notes!.isNotEmpty) _buildNotesSection(context),
          if (onRemove != null) _buildRemoveButton(context),
        ],
      ),
    );
  }

  // ── Photo ──────────────────────────────────────────────────

  Widget _buildPhotoSection(BuildContext context) {
    final imageUrl = _resolveImageUrl(animal.profileImage);
    if (imageUrl == null) return const SizedBox.shrink();

    return Container(
      height: compactMode ? 120 : 180,
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: const Color(0xFFEEEEEE),
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.network(
        imageUrl,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return const Center(child: CircularProgressIndicator());
        },
        errorBuilder: (context, error, stackTrace) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.pets, size: 48, color: Color(0xFFBDBDBD)),
              const SizedBox(height: 8),
              Text(
                animal.animalType.toUpperCase(),
                style: const TextStyle(color: Color(0xFF9E9E9E), fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Basic Info ─────────────────────────────────────────────

  Widget _buildBasicInfo(BuildContext context) {
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
                  // Name — always dark text on white background
                  Text(
                    animal.name.isNotEmpty
                        ? animal.name
                        : (animal.tagNumber ?? 'Unnamed'),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A1A), // near-black, always readable
                    ),
                  ),
                  if (animal.tagNumber != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Tag: ${animal.tagNumber}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF757575),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            _buildSexBadge(),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _buildTypeBadge(),
            if (animal.breed != null && animal.breed!.isNotEmpty) ...[
              const SizedBox(width: 8),
              Text(
                animal.breed!,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF616161),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  Widget _buildSexBadge() {
    final isMale = animal.sex.toLowerCase() == 'male';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
            size: 14,
            color: isMale ? const Color(0xFF1565C0) : const Color(0xFFC2185B),
          ),
          const SizedBox(width: 4),
          Text(
            isMale ? 'Male' : 'Female',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isMale ? const Color(0xFF1565C0) : const Color(0xFFC2185B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeBadge() {
    final icons = {
      'cow': '🐄',
      'horse': '🐴',
      'sheep': '🐑',
      'dog': '🐕',
    };
    final labels = {
      'cow': 'Cattle',
      'horse': 'Horse',
      'sheep': 'Sheep',
      'dog': 'Dog',
    };
    final emoji = icons[animal.animalType.toLowerCase()] ?? '🐾';
    final label = labels[animal.animalType.toLowerCase()] ?? animal.animalType;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFA5D6A7)),
      ),
      child: Text(
        '$emoji $label',
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Color(0xFF2E7D32),
        ),
      ),
    );
  }

  // ── Details ────────────────────────────────────────────────

  Widget _buildDetailsSection(BuildContext context) {
    final rows = <_DetailItem>[];

    rows.add(_DetailItem('Age', _formatAge()));
    if (animal.weight != null) {
      rows.add(_DetailItem('Weight', '${animal.weight!.toStringAsFixed(1)} kg'));
    }
    if (animal.isFattening == true) {
      rows.add(_DetailItem('Fattening', '✓ In progress'));
    }
    if (animal.isPregnant == true) {
      rows.add(_DetailItem('Pregnant', '✓ Yes'));
    }
    if (animal.expectedBirthDate != null) {
      rows.add(_DetailItem('Expected birth', _formatDate(animal.expectedBirthDate!)));
    }

    if (rows.isEmpty) return const SizedBox.shrink();

    return _buildInfoBox(
      rows.map((item) => _buildDetailRow(item.label, item.value)).toList(),
    );
  }

  // ── Health ─────────────────────────────────────────────────

  Widget _buildHealthSection(BuildContext context) {
    final statusColor = _healthColor(animal.healthStatus);
    return _buildSection(
      'Health',
      Icons.health_and_safety,
      [
        _buildDetailRow('Status', animal.healthStatus),
        _buildDetailRow('Vitality score', '${animal.vitalityScore}/100'),
        if (animal.bodyTemp != null)
          _buildDetailRow('Temperature', '${animal.bodyTemp!.toStringAsFixed(1)} °C'),
        if (animal.lastVetCheck != null)
          _buildDetailRow('Last vet check', _formatDate(animal.lastVetCheck!)),
        _buildDetailRow(
          'Vaccination',
          animal.vaccination ? '✓ Up to date' : '✗ Not up to date',
        ),
      ],
      accentColor: statusColor,
    );
  }

  Color _healthColor(String status) {
    switch (status.toUpperCase()) {
      case 'OPTIMAL':
        return const Color(0xFF2E7D32);
      case 'WARNING':
        return const Color(0xFFE65100);
      case 'CRITICAL':
        return const Color(0xFFC62828);
      default:
        return const Color(0xFF757575);
    }
  }

  // ── Vaccinations ───────────────────────────────────────────

  Widget _buildVaccinationsSection(BuildContext context) {
    final records = animal.vaccineRecords;
    if (records == null || records.isEmpty) {
      return _buildSection(
        'Vaccinations',
        Icons.vaccines,
        [
          const Text(
            'No vaccination records',
            style: TextStyle(
              color: Color(0xFF9E9E9E),
              fontStyle: FontStyle.italic,
              fontSize: 13,
            ),
          ),
        ],
      );
    }

    return _buildSection(
      'Vaccinations (${records.length})',
      Icons.vaccines,
      records.take(3).map((v) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            children: [
              const Icon(Icons.check_circle, size: 14, color: Color(0xFF2E7D32)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  v.vaccine?.nameEn ?? v.vaccine?.code ?? 'Vaccine',
                  style: const TextStyle(fontSize: 13, color: Color(0xFF212121)),
                ),
              ),
              Text(
                _formatDate(v.administeredAt),
                style: const TextStyle(fontSize: 12, color: Color(0xFF757575)),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // ── Production ─────────────────────────────────────────────

  Widget _buildProductionSection(BuildContext context) {
    final items = <_DetailItem>[];

    if (animal.animalType.toLowerCase() == 'cow') {
      if (animal.dailyMilkAvgL != null) {
        items.add(_DetailItem('Avg. milk/day', '${animal.dailyMilkAvgL!.toStringAsFixed(1)} L'));
      }
      if (animal.lactationNumber != null) {
        items.add(_DetailItem('Lactation #', '${animal.lactationNumber}'));
      }
    }
    if (animal.animalType.toLowerCase() == 'sheep') {
      if (animal.meatGrade != null) {
        items.add(_DetailItem('Meat grade', animal.meatGrade!));
      }
      if (animal.woolLastShearDate != null) {
        items.add(_DetailItem('Last shearing', _formatDate(animal.woolLastShearDate!)));
      }
    }
    if (animal.animalType.toLowerCase() == 'horse') {
      if (animal.raceCategory != null) {
        items.add(_DetailItem('Category', animal.raceCategory!));
      }
      if (animal.trainingLevel != null) {
        items.add(_DetailItem('Training level', animal.trainingLevel!));
      }
    }

    if (items.isEmpty) return const SizedBox.shrink();

    return _buildSection(
      'Production',
      Icons.trending_up,
      items.map((i) => _buildDetailRow(i.label, i.value)).toList(),
    );
  }

  // ── Genetics ───────────────────────────────────────────────

  Widget _buildGeneticsSection(BuildContext context) {
    final items = <_DetailItem>[];
    if (animal.motherId != null) items.add(_DetailItem('Mother ID', animal.motherId!));
    if (animal.fatherId != null) items.add(_DetailItem('Father ID', animal.fatherId!));
    if (animal.birthCount > 0) {
      items.add(_DetailItem('Birth count', '${animal.birthCount}'));
    }
    if (animal.origin.isNotEmpty) {
      items.add(_DetailItem(
        'Origin',
        animal.origin == 'purchased' ? 'Purchased' : 'Born on farm',
      ));
    }

    if (items.isEmpty) return const SizedBox.shrink();

    return _buildSection(
      'Genetics',
      Icons.account_tree,
      items.map((i) => _buildDetailRow(i.label, i.value)).toList(),
    );
  }

  // ── Price ──────────────────────────────────────────────────

  Widget _buildPriceSection(BuildContext context) {
    final price = priceOverride ?? animal.estimatedValue ?? animal.salePrice;
    if (price == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      margin: const EdgeInsets.only(top: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFA5D6A7)),
      ),
      child: Row(
        children: [
          const Icon(Icons.sell_rounded, color: Color(0xFF2E7D32), size: 20),
          const SizedBox(width: 10),
          const Text(
            'Price: ',
            style: TextStyle(
              color: Color(0xFF388E3C),
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
          Text(
            '${price.toStringAsFixed(2)} $currency',
            style: const TextStyle(
              color: Color(0xFF1B5E20),
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          if (priceOverride != null) ...[
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: const Color(0xFFFFCC80)),
              ),
              child: const Text(
                'Custom',
                style: TextStyle(fontSize: 10, color: Color(0xFFE65100)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Notes ──────────────────────────────────────────────────

  Widget _buildNotesSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(top: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFDE7),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFFF176)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.sticky_note_2, color: Color(0xFFF9A825), size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              notes!,
              style: const TextStyle(
                color: Color(0xFF33691E),
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Remove button ──────────────────────────────────────────

  Widget _buildRemoveButton(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton.icon(
        onPressed: onRemove,
        icon: const Icon(Icons.remove_circle_outline,
            color: Color(0xFFD32F2F), size: 18),
        label: const Text(
          'Remove',
          style: TextStyle(color: Color(0xFFD32F2F)),
        ),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        ),
      ),
    );
  }

  // ── Shared builders ────────────────────────────────────────

  Widget _buildInfoBox(List<Widget> children) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSection(
    String title,
    IconData icon,
    List<Widget> children, {
    Color? accentColor,
  }) {
    final color = accentColor ?? const Color(0xFF388E3C);
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF757575),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF212121),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────

  String _formatAge() {
    final months = animal.age;
    if (months <= 0) return 'Unknown';
    final years = months ~/ 12;
    final rem = months % 12;
    if (years > 0 && rem > 0) return '$years yr $rem mo';
    if (years > 0) return '$years yr${years > 1 ? 's' : ''}';
    return '$months mo';
  }

  String _formatDate(DateTime date) {
    return '${date.month.toString().padLeft(2, '0')}/'
        '${date.day.toString().padLeft(2, '0')}/'
        '${date.year}';
  }
}

class _DetailItem {
  final String label;
  final String value;
  const _DetailItem(this.label, this.value);
}

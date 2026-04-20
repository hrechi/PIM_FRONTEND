import 'package:flutter/material.dart';
import '../models/animal.dart';

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

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(compactMode ? 12 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showPhotos && animal.profileImage != null)
              _buildPhotoSection(context),
            _buildBasicInfo(context),
            if (showDetails) _buildDetailsSection(context),
            if (showHealth) _buildHealthSection(context),
            if (showVaccinations) _buildVaccinationsSection(context),
            if (showProduction) _buildProductionSection(context),
            if (showGenetics) _buildGeneticsSection(context),
            if (showPrices) _buildPriceSection(context),
            if (notes?.isNotEmpty == true) _buildNotesSection(context),
            if (onRemove != null) _buildRemoveButton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoSection(BuildContext context) {
    return Container(
      height: compactMode ? 120 : 160,
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        image: DecorationImage(
          image: NetworkImage(animal.profileImage!),
          fit: BoxFit.cover,
        ),
      ),
      child: const SizedBox.shrink(),
    );
  }

  Widget _buildBasicInfo(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                animal.tagNumber ?? 'No Tag',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ),
            if (animal.sex != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: animal.sex!.toLowerCase() == 'male'
                      ? Colors.blue[100]
                      : Colors.pink[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  animal.sex!.toUpperCase(),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: animal.sex!.toLowerCase() == 'male'
                        ? Colors.blue[800]
                        : Colors.pink[800],
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        if (animal.animalType.isNotEmpty)
          Text(
            animal.animalType,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.grey[700],
            ),
          ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildDetailsSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          _buildDetailRow('Age', _formatAge()),
          if (animal.weight != null) _buildDetailRow('Weight', '${animal.weight} kg'),
          if (animal.breed != null) _buildDetailRow('Breed', animal.breed!),
          if (animal.lastBirthDate != null) _buildDetailRow('Birth Date', _formatDate(animal.lastBirthDate!)),
        ],
      ),
    );
  }

  Widget _buildHealthSection(BuildContext context) {
    return _buildSection(
      context,
      'Health Status',
      Icons.health_and_safety,
      [
        _buildDetailRow('Current Health', animal.healthStatus ?? 'Unknown'),
        // Add more health details as available in the model
      ],
    );
  }

  Widget _buildVaccinationsSection(BuildContext context) {
    return _buildSection(
      context,
      'Vaccinations',
      Icons.vaccines,
      [
        const Text('Vaccination history would be displayed here'),
        // Add vaccination details as available in the model
      ],
    );
  }

  Widget _buildProductionSection(BuildContext context) {
    return _buildSection(
      context,
      'Production Records',
      Icons.trending_up,
      [
        const Text('Production data would be displayed here'),
        // Add production details as available in the model
      ],
    );
  }

  Widget _buildGeneticsSection(BuildContext context) {
    return _buildSection(
      context,
      'Genetic Information',
      Icons.science,
      [
        const Text('Genetic and pedigree information would be displayed here'),
        // Add genetic details as available in the model
      ],
    );
  }

  Widget _buildPriceSection(BuildContext context) {
    final price = priceOverride ?? animal.estimatedValue ?? animal.salePrice;
    if (price == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green[200]!),
      ),
      child: Row(
        children: [
          const Icon(Icons.attach_money, color: Colors.green),
          const SizedBox(width: 8),
          Text(
            'Price: ${price.toStringAsFixed(2)} $currency',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.green[800],
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.note, color: Colors.blue, size: 16),
              const SizedBox(width: 4),
              Text(
                'Notes',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Colors.blue[800],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            notes!,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.blue[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRemoveButton(BuildContext context) {
    return Container(
      alignment: Alignment.centerRight,
      margin: const EdgeInsets.only(top: 8),
      child: TextButton.icon(
        onPressed: onRemove,
        icon: const Icon(Icons.remove_circle, color: Colors.red),
        label: const Text('Remove', style: TextStyle(color: Colors.red)),
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, IconData icon, List<Widget> children) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: Theme.of(context).primaryColor),
              const SizedBox(width: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
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
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatAge() {
    final birthDate = animal.lastBirthDate ?? animal.createdAt;
    if (birthDate == null) return 'Unknown';

    final now = DateTime.now();
    final age = now.difference(birthDate);
    final years = age.inDays ~/ 365;
    final months = (age.inDays % 365) ~/ 30;

    if (years > 0) {
      return '$years year${years > 1 ? 's' : ''} ${months > 0 ? '$months month${months > 1 ? 's' : ''}' : ''}'.trim();
    } else {
      return '$months month${months > 1 ? 's' : ''}';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
import 'package:flutter/material.dart';
import '../../models/animal.dart';
import '../../services/animal_service.dart';
import '../../utils/constants.dart';
import '../../widgets/status_chip.dart';

class AnimalDetailsScreen extends StatefulWidget {
  final Animal animal;
  const AnimalDetailsScreen({super.key, required this.animal});

  @override
  State<AnimalDetailsScreen> createState() => _AnimalDetailsScreenState();
}

class _AnimalDetailsScreenState extends State<AnimalDetailsScreen> {
  final AnimalService _animalService = AnimalService();
  late Animal _animal;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _animal = widget.animal;
  }

  Future<void> _deleteAnimal() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text('Are you sure you want to delete ${_animal.name}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isDeleting = true);
    try {
      await _animalService.deleteAnimal(_animal.nodeId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Animal deleted')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(_animal.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: _isDeleting ? null : _deleteAnimal,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildHeader(isDark),
            const SizedBox(height: 24),
            _buildInfoGrid(isDark),
            const SizedBox(height: 24),
            _buildNotesSection(isDark),
            if (_animal.milkYield != null) ...[
              const SizedBox(height: 24),
              _buildProductionSection(isDark),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: isDark ? AppColors.cardGradientDark : AppColors.cardGradientLight,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 51 : 13),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: _getAnimalColor(_animal.animalType).withAlpha(51),
            child: Icon(
              _getAnimalIcon(_animal.animalType),
              size: 50,
              color: _getAnimalColor(_animal.animalType),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _animal.name,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          Text(
            '${_animal.animalType} • ${_animal.breed ?? "Common"}',
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 12),
          StatusChip(
            label: _animal.healthStatus,
            color: _getHealthColor(_animal.healthStatus),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoGrid(bool isDark) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 2.5,
      children: [
        _buildInfoItem('Sex', _animal.sex, Icons.person_outline),
        _buildInfoItem('Age', '${_animal.age} Months', Icons.calendar_today),
        _buildInfoItem('Tag', _animal.tagNumber ?? 'N/A', Icons.label_outlined),
        _buildInfoItem('Vitality', '${_animal.vitalityScore}%', Icons.monitor_heart),
      ],
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withAlpha(26)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.mistyBlue),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                Text(
                  value,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesSection(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withAlpha(26)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.notes, size: 20, color: AppColors.mistyBlue),
              SizedBox(width: 8),
              Text('Observations', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _animal.notes ?? 'No special observations recorded.',
            style: TextStyle(color: Colors.grey[700]),
          ),
        ],
      ),
    );
  }

  Widget _buildProductionSection(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withAlpha(26)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.opacity, size: 20, color: AppColors.mistyBlue),
              SizedBox(width: 8),
              Text('Production Stats', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildProductionItem('Milk Yield', '${_animal.milkYield}L'),
              _buildProductionItem('Fat Content', '${_animal.fatContent}%'),
              _buildProductionItem('Protein', '${_animal.protein}%'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProductionItem(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  IconData _getAnimalIcon(String type) {
    switch (type) {
      case 'COW': return Icons.agriculture;
      case 'SHEEP': return Icons.cloud;
      case 'HORSE': return Icons.directions_run;
      case 'GOAT': return Icons.eco;
      case 'BIRD': return Icons.flutter_dash;
      default: return Icons.pets;
    }
  }

  Color _getAnimalColor(String type) {
    switch (type) {
      case 'COW': return AppColors.cowColor;
      case 'SHEEP': return AppColors.sheepColor;
      case 'HORSE': return AppColors.horseColor;
      case 'GOAT': return AppColors.goatColor;
      case 'BIRD': return AppColors.birdColor;
      default: return AppColors.otherColor;
    }
  }

  Color _getHealthColor(String status) {
    switch (status) {
      case 'OPTIMAL': return AppColors.healthOptimal;
      case 'WARNING': return AppColors.healthWarning;
      case 'CRITICAL': return AppColors.healthCritical;
      default: return Colors.grey;
    }
  }
}

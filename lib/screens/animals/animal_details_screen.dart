import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:intl/intl.dart';
import '../../models/animal.dart';
import '../../services/animal_service.dart';
import '../../utils/constants.dart';
import '../../utils/animal_utils.dart';
import 'add_animal_screen.dart';
import 'animal_finance_screen.dart';
import 'sell_animal_screen.dart';

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
  final DateFormat _df = DateFormat('dd MMM yyyy');
  final NumberFormat _nf = NumberFormat.currency(symbol: '€', decimalDigits: 2);

  @override
  void initState() {
    super.initState();
    _animal = widget.animal;
  }

  String _calculateFormattedAge() {
    final months = _animal.age;
    if (months < 12) return '$months months';
    final years = months ~/ 12;
    final remainingMonths = months % 12;
    if (remainingMonths == 0) return '$years ${years == 1 ? 'year' : 'years'}';
    return '$years ${years == 1 ? 'year' : 'years'}, $remainingMonths months';
  }

  Future<void> _deleteAnimal() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm deletion'),
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
          const SnackBar(content: Text('Animal deleted'), backgroundColor: Color(0xFFEF4444)),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  void _showMarkFatteningDialog() {
    DateTime? selectedStartDate = _animal.fatteningStartDate ?? DateTime.now();
    DateTime? selectedTargetDate = _animal.targetSaleDate;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Marquer comme en engraissement'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Date de début d\'engraissement:', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedStartDate ?? DateTime.now(),
                      firstDate: DateTime.now().subtract(const Duration(days: 365)),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      setDialogState(() => selectedStartDate = picked);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.mistBlue),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      selectedStartDate != null
                          ? DateFormat('dd MMM yyyy').format(selectedStartDate!)
                          : 'Sélectionner',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Date de vente prévue (optionnel):', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedTargetDate ?? DateTime.now().add(const Duration(days: 30)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) {
                      setDialogState(() => selectedTargetDate = picked);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      selectedTargetDate != null
                          ? DateFormat('dd MMM yyyy').format(selectedTargetDate!)
                          : 'Sélectionner',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.grey),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await _markAnimalAsFattening(selectedStartDate, selectedTargetDate);
              },
              child: const Text('Confirmer'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _markAnimalAsFattening(DateTime? startDate, DateTime? targetDate) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final fatteningData = {
        'fatteningStartDate': startDate?.toIso8601String(),
        'targetSaleDate': targetDate?.toIso8601String(),
        'notes': 'Animal marked as fattening',
      };

      final updated = await _animalService.markAnimalAsFattening(_animal.nodeId, fatteningData);

      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        setState(() => _animal = updated);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Animal marqué comme en engraissement'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.sageTint,
      body: Container(
        color: AppColors.sageTint,
        child: Stack(
          children: [

          SafeArea(
            child: Column(
              children: [
                _buildAppBar(),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.only(bottom: 140),
                    child: Column(
                      children: [
                        _buildHeroImage(),
                        _buildIdentitySection(),
                        _buildHealthRiskBanner(),
                        _buildStatusAndAgeTiles(),
                        _buildGenealogySection(),
                        _buildSpeciesSpecificInfo(),
                        if (_animal.isFattening == true) _buildFatteningSection(),
                        _buildFinanceSection(),
                        _buildMedicalSection(),
                        _buildNotesSection(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          _buildBottomActions(),
        ],
      ),
    ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              _buildCircleIconButton(Symbols.arrow_back_ios_new, onPressed: () => Navigator.pop(context)),
            ],
          ),
          Text(
            'Profile: ${_animal.name}',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1E293B)),
          ),
          _buildCircleIconButton(Symbols.more_horiz, onPressed: () {}),
        ],
      ),
    );
  }

  Widget _buildCircleIconButton(IconData icon, {VoidCallback? onPressed}) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [
        BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2)),
      ]),
      child: IconButton(icon: Icon(icon, color: AppColors.mistyBlue, size: 20), onPressed: onPressed),
    );
  }

  Widget _buildHeroImage() {
    return Container(
      margin: const EdgeInsets.all(24),
      height: 240,
      width: double.infinity,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(32)),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(32),
            child: _animal.profileImage != null
                ? Image.network(_animal.profileImage!, fit: BoxFit.cover, width: double.infinity, height: double.infinity)
                : Container(
                    color: AppColors.mistyBlue.withValues(alpha: 0.1),
                    child: Center(
                      child: Icon(AnimalUtils.getAnimalIcon(_animal.animalType), size: 100, color: AppColors.mistyBlue.withValues(alpha: 0.2)),
                    ),
                  ),
          ),
          Positioned(
            top: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(20)),
              child: Text(
                _animal.status.toUpperCase(),
                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIdentitySection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_animal.name, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                    Text('Node ID: ${_animal.nodeId}', style: const TextStyle(fontSize: 14, color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppColors.mistyBlue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
                child: Text(AnimalUtils.getAnimalEmoji(_animal.animalType), style: const TextStyle(fontSize: 24)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              _buildChip(_animal.breed ?? 'Unknown breed', Symbols.pets),
              _buildChip(_animal.sex == 'female' ? 'Female' : 'Male', _animal.sex == 'female' ? Symbols.female : Symbols.male),
              _buildChip(_animal.origin == 'born' ? 'Born on Farm' : 'Purchased', _animal.origin == 'born' ? Symbols.child_care : Symbols.shopping_cart),
              if (_animal.tagNumber != null) _buildChip(_animal.tagNumber!, Symbols.sell),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChip(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFF1F5F9))),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFF64748B)),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569))),
        ],
      ),
    );
  }

  Widget _buildHealthRiskBanner() {
    final score = _animal.healthRiskScore ?? 0.0;
    Color color = Colors.green;
    String label = 'Low Risk';
    if (score > 0.6) { color = Colors.red; label = 'High Risk'; }
    else if (score > 0.3) { color = Colors.orange; label = 'Moderate Risk'; }

    return Container(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(Symbols.analytics, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('AI HEALTH RISK SCORE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                Text(label, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: color)),
              ],
            ),
          ),
          Text('${(score * 100).toInt()}%', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: color)),
        ],
      ),
    );
  }

  Widget _buildStatusAndAgeTiles() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          _buildInfoTile('Age', _calculateFormattedAge(), Symbols.calendar_today, Colors.blue),
          const SizedBox(width: 16),
          _buildInfoTile('Weight', _animal.weight != null ? '${_animal.weight} kg' : 'N/A', Symbols.weight, Colors.orange),
        ],
      ),
    );
  }

  Widget _buildGenealogySection() {
    if (_animal.motherId == null && _animal.fatherId == null) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28), border: Border.all(color: const Color(0xFFF1F5F9))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Genealogy 🧬'),
          if (_animal.motherId != null) _buildParentLink('Mother', _animal.motherId!),
          if (_animal.fatherId != null) _buildParentLink('Father', _animal.fatherId!),
        ],
      ),
    );
  }

  Widget _buildParentLink(String label, String parentId) {
    return FutureBuilder<Animal>(
      future: _animalService.getAnimalById(parentId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
                const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
              ],
            ),
          );
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return _buildDetailRow(label, 'Unknown ID'); 
        }
        final parentAnimal = snapshot.data!;
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
              GestureDetector(
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => AnimalDetailsScreen(animal: parentAnimal)));
                },
                child: Text(
                  parentAnimal.name, 
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Colors.blue, decoration: TextDecoration.underline, decorationColor: Colors.blue)
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoTile(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: const Color(0xFFF1F5F9))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 12),
            Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8), fontWeight: FontWeight.bold)),
            Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF1E293B))),
          ],
        ),
      ),
    );
  }

  Widget _buildSpeciesSpecificInfo() {
    final type = _animal.animalType.toLowerCase();
    final isFemale = _animal.sex == 'female';

    List<Widget> children = [];

    if (type == 'cow' && isFemale) {
      children.add(_buildSectionTitle('Reproduction & Milk 🐄'));
      children.add(_buildDetailRow('Pregnant', _animal.isPregnant == true ? 'YES' : (_animal.isPregnant == false ? 'NO' : 'UNKNOWN')));
      if (_animal.expectedBirthDate != null) children.add(_buildDetailRow('Expected birth date', _df.format(_animal.expectedBirthDate!)));
      children.add(_buildDetailRow('Litters', '${_animal.birthCount}'));
      children.add(_buildDetailRow('Avg production', _animal.dailyMilkAvgL != null ? '${_animal.dailyMilkAvgL} L/day' : 'N/A'));
      children.add(_buildDetailRow('Lactation #', _animal.lactationNumber?.toString() ?? 'N/A'));
    } else if (type == 'horse') {
      children.add(_buildSectionTitle('Performance 🐎'));
      children.add(_buildDetailRow('Category', _animal.raceCategory?.toUpperCase() ?? 'N/A'));
      children.add(_buildDetailRow('Best time', _animal.bestRaceTime != null ? '${_animal.bestRaceTime}s' : 'N/A'));
      children.add(_buildDetailRow('Training', _animal.trainingLevel?.toUpperCase() ?? 'N/A'));
    } else if (type == 'sheep') {
      children.add(_buildSectionTitle('Production & Quality 🐑'));
      children.add(_buildDetailRow('Last shear', _animal.woolLastShearDate != null ? _df.format(_animal.woolLastShearDate!) : 'N/A'));
      children.add(_buildDetailRow('Meat grade', _animal.meatGrade ?? 'N/A'));
    } else if (type == 'dog') {
      children.add(_buildSectionTitle('Usage 🐕'));
      children.add(_buildDetailRow('Role', _animal.dogRole?.toUpperCase() ?? 'N/A'));
    }

    if (children.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28), border: Border.all(color: const Color(0xFFF1F5F9))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }

  Widget _buildFatteningSection() {
    final daysInFat = _animal.fatteningStartDate != null
        ? DateTime.now().difference(_animal.fatteningStartDate!).inDays
        : 0;
    final daysUntilSale = _animal.targetSaleDate != null
        ? _animal.targetSaleDate!.difference(DateTime.now()).inDays
        : null;

    return Container(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F9FF),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFBAE6FD), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Engraissement / Préparation Vente'),
          const SizedBox(height: 8),
          _buildDetailRow('Début d\'engraissement', _animal.fatteningStartDate != null ? _df.format(_animal.fatteningStartDate!) : 'N/A'),
          _buildDetailRow('Jours en engraissement', '$daysInFat jours'),
          if (_animal.targetSaleDate != null) ...[
            _buildDetailRow('Date de vente prévue', _df.format(_animal.targetSaleDate!)),
            _buildDetailRow('Jours avant vente', daysUntilSale != null ? '$daysUntilSale jours' : 'N/A'),
          ],
        ],
      ),
    );
  }

  Widget _buildFinanceSection() {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => AnimalFinanceScreen(animal: _animal)));
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28), border: Border.all(color: const Color(0xFFF1F5F9))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSectionTitle('Finance & Value 💰'),
                const Icon(Symbols.arrow_forward_ios, size: 16, color: Colors.grey),
              ],
            ),
          if (_animal.origin == 'purchased') ...[
            _buildDetailRow('Purchase price', _animal.purchasePrice != null ? _nf.format(_animal.purchasePrice) : 'N/A'),
            _buildDetailRow('Purchase date', _animal.purchaseDate != null ? _df.format(_animal.purchaseDate!) : 'N/A'),
          ] else ...[
            _buildDetailRow('Birth cost', _animal.birthCost != null ? _nf.format(_animal.birthCost) : 'N/A'),
            _buildDetailRow('Birth weight', _animal.birthWeightKg != null ? '${_animal.birthWeightKg} kg' : 'N/A'),
          ],
          _buildDetailRow('Estimated value', _animal.estimatedValue != null ? _nf.format(_animal.estimatedValue) : 'N/A'),
          
        ],
      ),
    ),
  );
}

  Widget _buildMedicalSection() {
    return Container(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28), border: Border.all(color: const Color(0xFFF1F5F9))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSectionTitle('Medical History 🩺'),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                child: Text('${_animal.diseaseHistoryCount} Events', style: const TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_animal.vaccineRecords == null || _animal.vaccineRecords!.isEmpty)
            const Text('No vaccines recorded.', style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)))
          else
            ..._animal.vaccineRecords!.map((v) => _buildMedicalItem(
              (v.vaccine?.code == 'OTHER' ? v.notes : v.vaccine?.nameFr) ?? v.notes ?? 'Vaccine', 
              _df.format(v.administeredAt), 
              Symbols.vaccines, 
              Colors.amber
            )),
          
          if (_animal.medicalEvents != null && _animal.medicalEvents!.isNotEmpty) ...[
            const Divider(height: 32),
            ..._animal.medicalEvents!.map((e) => _buildMedicalItem(
              e.eventType.toUpperCase(), 
              _df.format(e.eventDate), 
              Symbols.medical_services, 
              Colors.blue, 
              subtitle: e.diagnosis
            )),
          ],
        ],
      ),
    );
  }

  Widget _buildMedicalItem(String title, String date, IconData icon, Color color, {String? subtitle}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle), child: Icon(icon, size: 16, color: color)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF1E293B))),
                if (subtitle != null) Text(subtitle, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
              ],
            ),
          ),
          Text(date, style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
        ],
      ),
    );
  }

  Widget _buildNotesSection() {
    if (_animal.notes == null || _animal.notes!.isEmpty) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: const Color(0xFFFFFBEB), borderRadius: BorderRadius.circular(28), border: Border.all(color: const Color(0xFFFEF3C7))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('NOTES 📝', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFFD97706))),
          const SizedBox(height: 12),
          Text(_animal.notes!, style: const TextStyle(fontSize: 14, color: Color(0xFF92400E), height: 1.5)),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(title.toUpperCase(), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF1E293B), letterSpacing: 0.5)),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF1E293B))),
        ],
      ),
    );
  }

  Widget _buildBottomActions() {
    return Positioned(
      bottom: 0, left: 0, right: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.9),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -5))],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_animal.status == 'active' && _animal.isFattening == true)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0F2FE),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFBAE6FD), width: 1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Statut: En engraissement',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0369A1),
                        ),
                      ),
                      const SizedBox(height: 6),
                      if (_animal.targetSaleDate != null)
                        Text(
                          'Date de vente prévue: ${DateFormat('dd MMM yyyy').format(_animal.targetSaleDate!)}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF0369A1),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            Row(
              children: [
                Expanded(
                  flex: 1,
                  child: GestureDetector(
                    onTap: _isDeleting ? null : _deleteAnimal,
                    child: Container(
                      height: 56,
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFE2E8F0), width: 2)),
                      child: const Center(child: Icon(Symbols.delete, color: Color(0xFF64748B))),
                    ),
                  ),
                ),
                if (_animal.status == 'active' && _animal.isFattening != true) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 1,
                    child: GestureDetector(
                      onTap: _showMarkFatteningDialog,
                      child: Container(
                        height: 56,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFCD34D),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [BoxShadow(color: const Color(0xFFFCD34D).withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 5))],
                        ),
                        child: const Center(
                          child: Icon(Symbols.trending_up, color: Color(0xFF78350F), size: 22),
                        ),
                      ),
                    ),
                  ),
                ],
                if (_animal.status == 'active') ...[
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 1,
                    child: GestureDetector(
                      onTap: () async {
                        final updated = await Navigator.push(context, MaterialPageRoute(builder: (context) => SellAnimalScreen(animal: _animal)));
                        if (updated == true && mounted) Navigator.pop(context, true);
                      },
                      child: Container(
                        height: 56,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [BoxShadow(color: Colors.green.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 5))],
                        ),
                        child: const Center(child: Text('Sell', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white))),
                      ),
                    ),
                  ),
                ],
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: GestureDetector(
                    onTap: () async {
                      final updated = await Navigator.push(context, MaterialPageRoute(builder: (context) => AddAnimalScreen(animal: _animal)));
                      if (updated == true && mounted) Navigator.pop(context, true);
                    },
                    child: Container(
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [AppColors.mistBlue, const Color(0xFF32ADE6)]),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [BoxShadow(color: AppColors.mistBlue.withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 8))],
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Symbols.edit, color: Colors.white, size: 20),
                          SizedBox(width: 8),
                          Text('Edit', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

}

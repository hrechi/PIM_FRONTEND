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

class _AnimalDetailsScreenState extends State<AnimalDetailsScreen> with SingleTickerProviderStateMixin {
  final AnimalService _animalService = AnimalService();
  late Animal _animal;
  bool _isDeleting = false;
  final DateFormat _df = DateFormat('dd MMM yyyy');
  final NumberFormat _nf = NumberFormat.currency(symbol: '€', decimalDigits: 2);
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _animal = widget.animal;
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
                  _buildHeroImage(),
                  _buildIdentitySection(),
                  _buildTabBar(),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildOverviewTab(),
                        _buildHealthTab(),
                        _buildFinanceTab(),
                        _buildMedicalTab(),
                      ],
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

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        labelColor: AppColors.mistBlue,
        unselectedLabelColor: const Color(0xFF94A3B8),
        indicatorColor: AppColors.mistBlue,
        indicatorWeight: 3,
        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        unselectedLabelStyle: const TextStyle(fontSize: 13),
        tabs: const [
          Tab(text: 'Overview'),
          Tab(text: 'Health'),
          Tab(text: 'Finance'),
          Tab(text: 'Medical'),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 140),
      child: Column(
        children: [
          _buildHealthRiskBanner(),
          _buildBasicInfoCards(),
          _buildGenealogySection(),
          _buildSpeciesSpecificInfo(),
          if (_animal.isFattening == true) _buildFatteningSection(),
          _buildNotesSection(),
        ],
      ),
    );
  }

  Widget _buildHealthTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 140),
      child: Column(
        children: [
          _buildVitalStatsCards(),
          _buildActivityLevelCard(),
          _buildBodyConditionCard(),
          _buildVaccinationStatusCard(),
          _buildVetVisitCard(),
        ],
      ),
    );
  }

  Widget _buildFinanceTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 140),
      child: Column(
        children: [
          _buildFinanceSection(),
          if (_animal.status == 'sold') _buildSalesDetailsCard(),
          _buildFinanceBreakdownCard(),
        ],
      ),
    );
  }

  Widget _buildMedicalTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 140),
      child: _buildMedicalSection(),
    );
  }

  Widget _buildBasicInfoCards() {
    return Column(
      children: [
        Row(
          children: [
            _buildInfoTile('Age', _calculateFormattedAge(), Symbols.calendar_today, Colors.blue),
            const SizedBox(width: 12),
            _buildInfoTile('Weight', _animal.weight != null ? '${_animal.weight} kg' : 'N/A', Symbols.weight, Colors.orange),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildInfoTile('Sex', _animal.sex == 'female' ? 'Female' : 'Male', Symbols.female, Colors.pink),
            const SizedBox(width: 12),
            _buildInfoTile('Origin', _animal.origin == 'born' ? 'Born' : 'Purchased', Symbols.shopping_cart, Colors.purple),
          ],
        ),
      ],
    );
  }

  Widget _buildVitalStatsCards() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Vital Statistics', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20),border: Border.all(color: const Color(0xFFF1F5F9))),
          child: Column(
            children: [
              _buildStatRow('Temperature', _animal.bodyTemp != null ? '${_animal.bodyTemp!.toStringAsFixed(1)} °C' : 'N/A', Colors.red, Symbols.thermostat),
              const Divider(height: 20),
              _buildStatRow('Health Status', _animal.healthStatus, _getHealthStatusColor(_animal.healthStatus), Symbols.health_and_safety),
              const Divider(height: 20),
              _buildStatRow('Vitality Score', '${_animal.vitalityScore}%', Colors.amber, Symbols.favorite),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActivityLevelCard() {
    Color activityColor = Colors.blue;
    String activityEmoji = '💤';
    if (_animal.activityLevel.toUpperCase() == 'HIGH') {
      activityColor = Colors.green;
      activityEmoji = '🏃';
    } else if (_animal.activityLevel.toUpperCase() == 'MODERATE') {
      activityColor = Colors.amber;
      activityEmoji = '🚶';
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [activityColor.withValues(alpha: 0.1), activityColor.withValues(alpha: 0.05)]),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: activityColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Activity Level', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
              Text(activityEmoji, style: const TextStyle(fontSize: 24)),
            ],
          ),
          const SizedBox(height: 12),
          Text(_animal.activityLevel, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: activityColor)),
        ],
      ),
    );
  }

  Widget _buildBodyConditionCard() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFF1F5F9))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Body Condition', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              if (_animal.weight != null) _buildBodyMeter('Weight', '${_animal.weight} kg', _animal.weight! / 100 / 3),
              if (_animal.fatContent != null) _buildBodyMeter('Fat %', '${_animal.fatContent}%', (_animal.fatContent ?? 0) / 100),
              if (_animal.protein != null) _buildBodyMeter('Protein %', '${_animal.protein}%', (_animal.protein ?? 0) / 100),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBodyMeter(String label, String value, double? progress) {
    return Expanded(
      child: Column(
        children: [
          Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF94A3B8))),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value, Color color, IconData icon) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 12),
            Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
          ],
        ),
        Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  Widget _buildVaccinationStatusCard() {
    final isVaccinated = _animal.vaccination;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isVaccinated ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isVaccinated ? Colors.green.withValues(alpha: 0.3) : Colors.red.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Symbols.vaccines, size: 24, color: isVaccinated ? Colors.green : Colors.red),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Vaccination Status', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
                Text(isVaccinated ? 'Up to date' : 'Not vaccinated', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isVaccinated ? Colors.green : Colors.red)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVetVisitCard() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFF1F5F9))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Last Veterinary Check', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
          const SizedBox(height: 12),
          if (_animal.lastVetCheck != null)
            Row(
              children: [
                Icon(Symbols.medical_services, size: 20, color: AppColors.mistBlue),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_df.format(_animal.lastVetCheck!), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                    Text('${DateTime.now().difference(_animal.lastVetCheck!).inDays} days ago', style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
                  ],
                ),
              ],
            )
          else
            const Text('No record', style: TextStyle(fontSize: 14, color: Color(0xFF94A3B8))),
        ],
      ),
    );
  }

  Widget _buildSalesDetailsCard() {
    if (_animal.salePrice == null) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Sales Information', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
          const SizedBox(height: 16),
          _buildDetailRow('Sale Price', _nf.format(_animal.salePrice)),
          _buildDetailRow('Sale Date', _animal.saleDate != null ? _df.format(_animal.saleDate!) : 'N/A'),
          if (_animal.buyerName != null) _buildDetailRow('Buyer', _animal.buyerName!),
          if (_animal.saleWeightKg != null) _buildDetailRow('Sale Weight', '${_animal.saleWeightKg} kg'),
        ],
      ),
    );
  }

  Widget _buildFinanceBreakdownCard() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFF1F5F9))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Financial Summary', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
          const SizedBox(height: 16),
          if (_animal.origin == 'purchased')
            Column(
              children: [
                _buildDetailRow('Purchase Price', _animal.purchasePrice != null ? _nf.format(_animal.purchasePrice) : 'N/A'),
                const Divider(height: 16),
                _buildDetailRow('Purchase Date', _animal.purchaseDate != null ? _df.format(_animal.purchaseDate!) : 'N/A'),
              ],
            )
          else
            Column(
              children: [
                _buildDetailRow('Birth Cost', _animal.birthCost != null ? _nf.format(_animal.birthCost) : 'N/A'),
                const Divider(height: 16),
                _buildDetailRow('Birth Weight', _animal.birthWeightKg != null ? '${_animal.birthWeightKg} kg' : 'N/A'),
              ],
            ),
          const Divider(height: 16),
          _buildDetailRow('Current Value', _animal.estimatedValue != null ? _nf.format(_animal.estimatedValue) : 'N/A'),
        ],
      ),
    );
  }

  Color _getHealthStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'OPTIMAL':
        return Colors.green;
      case 'WARNING':
        return Colors.orange;
      case 'CRITICAL':
        return Colors.red;
      default:
        return Colors.blue;
    }
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
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
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
                    Text('ID: ${_animal.nodeId}', style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8), fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [AppColors.mistyBlue.withValues(alpha: 0.2), AppColors.mistyBlue.withValues(alpha: 0.05)]),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(AnimalUtils.getAnimalEmoji(_animal.animalType), style: const TextStyle(fontSize: 28)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildChip(_animal.breed ?? 'Unknown breed', Symbols.pets),
              _buildChip(_animal.sex == 'female' ? '♀ Female' : '♂ Male', _animal.sex == 'female' ? Symbols.female : Symbols.male),
              _buildChip(_animal.origin == 'born' ? 'Born on Farm' : 'Purchased', _animal.origin == 'born' ? Symbols.child_care : Symbols.shopping_cart),
              if (_animal.tagNumber != null) _buildChip('Tag: ${_animal.tagNumber}', Symbols.label),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChip(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 4, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.mistBlue),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569))),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w800,
          color: Color(0xFF0F172A),
        ),
      ),
    );
  }

  Widget _buildHealthRiskBanner() {
    final score = _animal.healthRiskScore ?? 0.0;
    Color color = Colors.green;
    String label = '✅ Low Risk';
    IconData icon = Symbols.check_circle;
    
    if (score > 0.6) { 
      color = Colors.red; 
      label = '⚠️ High Risk';
      icon = Symbols.error;
    }
    else if (score > 0.3) { 
      color = Colors.orange; 
      label = '⚠️ Moderate Risk';
      icon = Symbols.warning;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [color.withValues(alpha: 0.15), color.withValues(alpha: 0.05)]),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 2),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('AI HEALTH RISK ASSESSMENT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                Text(label, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: color)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)),
            child: Text('${(score * 100).toInt()}%', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: color)),
          ),
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
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [Colors.white, Colors.white.withValues(alpha: 0.8)]),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFF1F5F9)),
          boxShadow: [
            BoxShadow(color: color.withValues(alpha: 0.08), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(height: 12),
            Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8), fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
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
      children.add(const Text('🐄 Dairy Production', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))));
      children.add(const SizedBox(height: 16));
      children.add(_buildDetailRow('Pregnant', _animal.isPregnant == true ? '✅ YES' : (_animal.isPregnant == false ? '❌ NO' : '❓ UNKNOWN')));
      if (_animal.expectedBirthDate != null) children.add(_buildDetailRow('Expected birth date', _df.format(_animal.expectedBirthDate!)));
      children.add(_buildDetailRow('Birth Count', '${_animal.birthCount}'));
      children.add(_buildDetailRow('Avg Milk Production', _animal.dailyMilkAvgL != null ? '${_animal.dailyMilkAvgL} L/day' : 'N/A'));
      children.add(_buildDetailRow('Lactation Number', _animal.lactationNumber?.toString() ?? 'N/A'));
    } else if (type == 'horse') {
      children.add(const Text('🐎 Performance Data', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))));
      children.add(const SizedBox(height: 16));
      children.add(_buildDetailRow('Category', _animal.raceCategory?.toUpperCase() ?? 'N/A'));
      children.add(_buildDetailRow('Best Time', _animal.bestRaceTime != null ? '${_animal.bestRaceTime}s' : 'N/A'));
      children.add(_buildDetailRow('Training Level', _animal.trainingLevel?.toUpperCase() ?? 'N/A'));
    } else if (type == 'sheep') {
      children.add(const Text('🐑 Production Info', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))));
      children.add(const SizedBox(height: 16));
      children.add(_buildDetailRow('Last Shearing', _animal.woolLastShearDate != null ? _df.format(_animal.woolLastShearDate!) : 'N/A'));
      children.add(_buildDetailRow('Meat Grade', _animal.meatGrade ?? 'N/A'));
    } else if (type == 'dog') {
      children.add(const Text('🐕 Working Dog Info', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))));
      children.add(const SizedBox(height: 16));
      children.add(_buildDetailRow('Role', _animal.dogRole?.toUpperCase() ?? 'N/A'));
    }

    if (children.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }

  Widget _buildFatteningSection() {
    final daysInFat = _animal.fatteningStartDate != null
        ? DateTime.now().difference(_animal.fatteningStartDate!).inDays
        : 0;
    final daysUntilSale = _animal.targetSaleDate?.difference(DateTime.now()).inDays;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [const Color(0xFFFCD34D).withValues(alpha: 0.2), const Color(0xFFFCD34D).withValues(alpha: 0.05)]),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFCD34D).withValues(alpha: 0.5), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('📊', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 12),
              const Text('Fattening Progress', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
            ],
          ),
          const SizedBox(height: 16),
          _buildDetailRow('Started on', _animal.fatteningStartDate != null ? _df.format(_animal.fatteningStartDate!) : 'N/A'),
          _buildDetailRow('Days in fattening', '$daysInFat days'),
          if (_animal.targetSaleDate != null) ...[
            _buildDetailRow('Target Sale Date', _df.format(_animal.targetSaleDate!)),
            _buildDetailRow('Days to Sale', daysUntilSale != null && daysUntilSale >= 0 ? '$daysUntilSale days' : 'Ready for sale'),
          ],
        ],
      ),
    );
  }

  Widget _buildFinanceSection() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.amber.withValues(alpha: 0.1), Colors.amber.withValues(alpha: 0.05)]),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('💰 Financial Overview', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
              GestureDetector(
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => AnimalFinanceScreen(animal: _animal)));
                },
                child: const Icon(Symbols.arrow_forward_ios, size: 16, color: Colors.amber),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_animal.origin == 'purchased') ...[
            _buildDetailRow('💵 Purchase Price', _animal.purchasePrice != null ? _nf.format(_animal.purchasePrice) : 'N/A'),
            _buildDetailRow('📅 Purchase Date', _animal.purchaseDate != null ? _df.format(_animal.purchaseDate!) : 'N/A'),
          ] else ...[
            _buildDetailRow('💵 Birth Cost', _animal.birthCost != null ? _nf.format(_animal.birthCost) : 'N/A'),
            _buildDetailRow('⚖️ Birth Weight', _animal.birthWeightKg != null ? '${_animal.birthWeightKg} kg' : 'N/A'),
          ],
          const Divider(height: 16),
          _buildDetailRow('📊 Current Value', _animal.estimatedValue != null ? _nf.format(_animal.estimatedValue) : 'N/A'),
        ],
      ),
    );
  }


  Widget _buildMedicalSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('🩺 Medical History', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                child: Text('${_animal.diseaseHistoryCount} Events', style: const TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_animal.vaccineRecords != null && _animal.vaccineRecords!.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('💉 Vaccinations', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                  const SizedBox(height: 12),
                  ..._animal.vaccineRecords!.map((v) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _buildMedicalItem(
                      (v.vaccine?.code == 'OTHER' ? v.notes : v.vaccine?.nameFr) ?? v.notes ?? 'Vaccine', 
                      _df.format(v.administeredAt), 
                      Symbols.vaccines, 
                      Colors.amber
                    ),
                  )),
                ],
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Text('No vaccinations recorded', style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8))),
            ),
          
          if (_animal.medicalEvents != null && _animal.medicalEvents!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('🏥 Medical Events', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                  const SizedBox(height: 12),
                  ..._animal.medicalEvents!.map((e) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _buildMedicalItem(
                      e.eventType.toUpperCase(), 
                      _df.format(e.eventDate), 
                      Symbols.medical_services, 
                      Colors.blue, 
                      subtitle: e.diagnosis
                    ),
                  )),
                ],
              ),
            ),
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
      margin: const EdgeInsets.symmetric(vertical: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [const Color(0xFFFFFBEB), const Color(0xFFFEF9E7)]),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFEF3C7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('📝 Notes & Comments', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFFD97706))),
          const SizedBox(height: 12),
          Text(_animal.notes!, style: const TextStyle(fontSize: 13, color: Color(0xFF92400E), height: 1.6)),
        ],
      ),
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

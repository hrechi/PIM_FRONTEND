import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:material_symbols_icons/symbols.dart';
import '../../models/animal.dart';
import '../../services/animal_service.dart';
import '../../utils/constants.dart';
import 'add_animal_screen.dart';

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

  String _calculateFormattedAge() {
    final months = _animal.age;
    if (months < 12) {
      return '$months Months';
    }
    final years = months ~/ 12;
    final remainingMonths = months % 12;
    if (remainingMonths == 0) {
      return '$years ${years == 1 ? 'Year' : 'Years'}';
    }
    return '$years ${years == 1 ? 'Year' : 'Years'}, $remainingMonths ${remainingMonths == 1 ? 'Month' : 'Months'}';
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
          const SnackBar(
            content: Text('Animal deleted'),
            backgroundColor: Color(0xFFEF4444),
          ),
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
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFF8FAFC), Color(0xFFEFF6FF)],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildAppBar(),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.only(bottom: 120),
                    child: Column(
                      children: [
                        _buildHeroImage(),
                        _buildIdentitySection(),
                        _buildHealthDashboard(),
                        if (_animal.animalType == 'DOG') _buildDogRoleSection(),
                        _buildVaccinationList(),
                        _buildSpecializedSections(),
                        _buildTimeline(),
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
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildCircleIconButton(
            Symbols.arrow_back_ios_new,
            onPressed: () => Navigator.pop(context),
          ),
          const Text(
            'Animal Details',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1E293B),
            ),
          ),
          _buildCircleIconButton(
            Symbols.more_horiz,
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildCircleIconButton(IconData icon, {VoidCallback? onPressed}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(icon, color: AppColors.mistyBlue, size: 20),
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildHeroImage() {
    return Container(
      margin: const EdgeInsets.all(24),
      height: 280,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(32),
            child: _animal.profileImage != null
              ? Image.network(_animal.profileImage!, fit: BoxFit.cover, width: double.infinity, height: double.infinity)
              : Container(
                  color: AppColors.mistyBlue.withValues(alpha: 0.1),
                  child: Center(
                    child: Icon(
                      _getAnimalIcon(_animal.animalType),
                      size: 80,
                      color: AppColors.mistyBlue.withValues(alpha: 0.3),
                    ),
                  ),
                ),
          ),
          Positioned(
            bottom: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Symbols.photo_camera, size: 16, color: AppColors.mistyBlue),
                  SizedBox(width: 6),
                  Text(
                    'Update Photo',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ],
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _animal.name,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 4),
              RichText(
                text: TextSpan(
                  style: const TextStyle(fontSize: 14, color: Color(0xFF64748B)),
                  children: [
                    const TextSpan(text: 'Node ID: '),
                    TextSpan(
                      text: _animal.nodeId,
                      style: const TextStyle(
                        color: AppColors.mistyBlue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.mistyBlue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Symbols.pets, size: 16, color: AppColors.mistyBlue),
                const SizedBox(width: 6),
                Text(
                  '${_animal.breed ?? "Common"} ${_animal.animalType}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppColors.mistyBlue,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthDashboard() {
    return Container(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Symbols.favorite, size: 20, color: Color(0xFF22C55E)),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Health Status',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ],
              ),
              StatusBadge(status: _animal.healthStatus),
            ],
          ),
          const SizedBox(height: 24),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 20,
            crossAxisSpacing: 20,
            childAspectRatio: 2.2,
            children: [
              _buildSimpleMetric('Current Age', _calculateFormattedAge(), isPrimary: true),
              _buildSimpleMetric('Body Temp', _animal.formattedTemperature),
              _buildSimpleMetric('Activity Level', _animal.activityLevel, isPrimary: true),
              _buildSimpleMetric('Last Vet Check', _animal.lastVetCheck != null ? _animal.lastVetCheck!.toString().split(' ')[0] : 'Never'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleMetric(String label, String value, {bool isPrimary = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8), fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: isPrimary ? AppColors.mistyBlue : const Color(0xFF1E293B),
          ),
        ),
      ],
    );
  }

  Widget _buildVaccinationList() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Symbols.vaccines, size: 20, color: Color(0xFFD97706)),
              ),
              const SizedBox(width: 12),
              const Text(
                'Vaccinations',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (_animal.vaccines == null || _animal.vaccines!.isEmpty)
            const Text(
              'No vaccination records found.',
              style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
            )
          else
            Column(
              children: _animal.vaccines!.map((v) => _buildVaccineItem(v)).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildVaccineItem(Map<String, dynamic> vaccine) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                vaccine['name'] ?? 'Unknown',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
              ),
              Text(
                vaccine['date'] ?? 'N/A',
                style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
              ),
            ],
          ),
          const Icon(Symbols.check_circle, size: 20, color: Color(0xFF22C55E)),
        ],
      ),
    );
  }

  Widget _buildBirthHistory() {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFDF2F8),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Symbols.child_care, size: 20, color: Color(0xFFDB2777)),
              ),
              const SizedBox(width: 12),
              const Text(
                'Birth History',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ..._animal.birthHistory!.map((b) => _buildBirthItem(b)),
        ],
      ),
    );
  }

  Widget _buildBirthItem(Map<String, dynamic> birth) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFDB2777),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Delivery on ${birth['date']}',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
                    ),
                    Text(
                      birth['health'] ?? 'N/A',
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFFDB2777)),
                    ),
                  ],
                ),
                Text(
                  'Offspring Weight: ${birth['weight'] ?? "N/A"} kg',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecializedSections() {
    final sex = _animal.sex;
    final type = _animal.animalType;
    final widgets = <Widget>[];

    if (type == 'COW') {
      if (sex == 'FEMALE') {
        widgets.add(_buildMilkProductionSection());
        widgets.add(_buildReproductionSection());
      } else {
        widgets.add(_buildMaleReproductionSection());
        widgets.add(_buildGrowthSection());
      }
    } else if (type == 'SHEEP') {
      if (sex == 'FEMALE') {
        widgets.add(_buildMilkProductionSection()); // This method will be renamed/generalized
        widgets.add(_buildReproductionSection());
      } else {
        widgets.add(_buildMaleReproductionSection());
        widgets.add(_buildGrowthSection());
      }
    } else if (type == 'HORSE') {
      widgets.add(_buildActivitySection());
      if (sex == 'FEMALE') {
        widgets.add(_buildReproductionSection());
      }
    } else if (type == 'DOG') {
      widgets.add(_buildActivitySection());
    }

    return Column(children: widgets);
  }

  Widget _buildDogRoleSection() {
    final isShepherd = _animal.role == 'SHEPHERD';
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isShepherd 
            ? [const Color(0xFF6366F1), const Color(0xFF818CF8)] 
            : [const Color(0xFFF59E0B), const Color(0xFFFBBF24)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: (isShepherd ? const Color(0xFF6366F1) : const Color(0xFFF59E0B)).withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isShepherd ? Symbols.groups : Symbols.shield,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'ASSIGNED ROLE',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white70, letterSpacing: 1),
              ),
              Text(
                isShepherd ? 'SHEPHERD DOG' : 'GUARD DOG',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMilkProductionSection() {
    final isSheep = _animal.animalType == 'SHEEP';
    return _buildProductionSection(
      title: isSheep ? 'Wool Production' : 'Milk Production',
      icon: isSheep ? Symbols.waves : Symbols.avg_pace,
      unit: isSheep ? 'kg' : 'L/day',
      value: isSheep ? (_animal.woolYield?.toString() ?? 'N/A') : (_animal.milkYield?.toString() ?? 'N/A'),
      extra: isSheep ? 'Annual Yield' : 'Last Calving: ${_animal.lastBirthDate?.toString().split(' ')[0] ?? "Never"}',
    );
  }

  Widget _buildReproductionSection() {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFDF2F8),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Symbols.child_care, size: 20, color: Color(0xFFDB2777)),
              ),
              const SizedBox(width: 12),
              const Text(
                'Reproduction History',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF1E293B)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildReproMetric('Status', _animal.isPregnant == true ? 'PREGNANT' : 'NON-GESTANTE', isHighlight: _animal.isPregnant == true),
              _buildReproMetric('Last Insemination', _animal.lastInseminationDate?.toString().split(' ')[0] ?? 'N/A'),
            ],
          ),
          if (_animal.birthHistory != null && _animal.birthHistory!.isNotEmpty) ...[
            const Divider(height: 32),
            const Text('RECENT BIRTHS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF94A3B8))),
            const SizedBox(height: 12),
            ..._animal.birthHistory!.take(2).map((b) => _buildBirthItem(b)),
          ],
        ],
      ),
    );
  }

  Widget _buildReproMetric(String label, String value, {bool isHighlight = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14, 
            fontWeight: FontWeight.w800, 
            color: isHighlight ? const Color(0xFFDB2777) : const Color(0xFF1E293B),
          ),
        ),
      ],
    );
  }

  Widget _buildMaleReproductionSection() {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: const Icon(Symbols.biotech, color: Colors.blue, size: 24),
          ),
          const SizedBox(width: 16),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('REPRODUCTION MÂLE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF64748B))),
              Text('Section Saillie Active', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF1E293B))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGrowthSection() {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Symbols.trending_up, size: 20, color: Color(0xFF22C55E)),
              SizedBox(width: 8),
              Text('Growth Analysis', style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF1E293B))),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSimpleMetric('Weight Gain', '+2.4kg/week', isPrimary: true),
              _buildSimpleMetric('Target Weight', '850kg'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActivitySection() {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F9FF),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFBAE6FD)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Symbols.directions_run, color: Color(0xFF0284C7)),
              const SizedBox(width: 8),
              Text(
                '${_animal.animalType} Activity',
                style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF0369A1)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'High endurance activity detected. Vital signs remain within optimal ranges for active work.',
            style: TextStyle(fontSize: 13, color: Color(0xFF075985)),
          ),
        ],
      ),
    );
  }

  Widget _buildProductionSection({
    String title = 'Production Data',
    IconData icon = Symbols.analytics,
    String unit = 'L',
    String? value,
    String? extra,
  }) {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, size: 20, color: const Color(0xFF3B82F6)),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    title,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF1E293B)),
                  ),
                ],
              ),
              if (extra != null) 
                Text(extra, style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8), fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 24),
          _buildProgressMetric('$title ($unit)', value ?? '${_animal.milkYield ?? 0} $unit', 0.85),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.only(top: 20),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: Color(0xFFF1F5F9))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildCompactMetric('Fat Content', '${_animal.fatContent ?? 3.8}%'),
                _buildCompactMetric('Protein', '${_animal.protein ?? 3.2}%', isEnd: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressMetric(String label, String value, double progress) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
            Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor: const Color(0xFFF1F5F9),
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF3B82F6)),
          ),
        ),
      ],
    );
  }

  Widget _buildCompactMetric(String label, String value, {bool isEnd = false}) {
    return Column(
      crossAxisAlignment: isEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8), fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF1E293B))),
      ],
    );
  }

  Widget _buildTimeline() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Recent Timeline',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: Color(0xFF1E293B),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 20),
          _buildTimelineItem(
            'Feed Intake Recorded',
            '${_animal.name} consumed 12kg of standard silage mix.',
            '2h ago',
            Symbols.water_drop,
            const Color(0xFF22C55E),
          ),
          _buildTimelineItem(
            'Scheduled Deworming',
            'Routine quarterly treatment completed.',
            'Yesterday',
            Symbols.medication,
            const Color(0xFF3B82F6),
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(String title, String desc, String time, IconData icon, Color color, {bool isLast = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Container(
            padding: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              border: isLast ? null : const Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF1E293B))),
                    Text(time, style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8), fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(desc, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.4)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomActions() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        height: 120,
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.6),
          boxShadow: [
             BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: ClipRRect(
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Row(
              children: [
                Expanded(
                  flex: 1,
                  child: GestureDetector(
                    onTap: _isDeleting ? null : _deleteAnimal,
                    child: Container(
                      height: 56,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFE2E8F0), width: 2),
                      ),
                      child: const Center(
                        child: Text(
                          'Delete',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: GestureDetector(
                    onTap: () async {
                      final updated = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AddAnimalScreen(animal: _animal),
                        ),
                      );
                      if (updated == true && mounted) {
                        // In a real app we might fetch from service, 
                        // but for now we expect the user to return to the list 
                        // or we could fetch by nodeId if we wanted to stay on this screen.
                        // Let's just pop back to list to reflect changes for simplicity 
                        // as the list will refresh anyway.
                        Navigator.pop(context, true);
                      }
                    },
                    child: Container(
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF34C759), Color(0xFF32ADE6)],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF34C759).withValues(alpha: 0.3),
                            blurRadius: 15,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Symbols.edit, color: Colors.white, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Edit Profile',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getAnimalIcon(String type) {
    switch (type) {
      case 'COW': return Symbols.cruelty_free;
      case 'SHEEP': return Symbols.pest_control_rodent;
      case 'HORSE': return Symbols.emoji_nature;
      case 'GOAT': return Symbols.sound_detection_dog_barking;
      case 'BIRD': return Symbols.flutter_dash;
      default: return Symbols.pets;
    }
  }
}

class StatusBadge extends StatelessWidget {
  final String status;
  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status) {
      case 'OPTIMAL': color = const Color(0xFF22C55E); break;
      case 'WARNING': color = const Color(0xFFF59E0B); break;
      case 'CRITICAL': color = const Color(0xFFEF4444); break;
      default: color = const Color(0xFF94A3B8);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w900,
          color: color,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

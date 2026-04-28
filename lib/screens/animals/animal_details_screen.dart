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

const _kGreen = Color(0xFF309448);
const _kDark = Color(0xFF0F172A);
const _kMid = Color(0xFF475569);
const _kLight = Color(0xFF94A3B8);
const _kBg = Color(0xFFF8FAFC);

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
  final DateFormat _df = DateFormat('MMM dd, yyyy');
  final NumberFormat _nf = NumberFormat.currency(symbol: 'TND ', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _animal = widget.animal;
  }

  String _formattedAge() {
    final m = _animal.age;
    if (m <= 0) return 'Unknown';
    final y = m ~/ 12;
    final rem = m % 12;
    if (y > 0 && rem > 0) return '$y yr $rem mo';
    if (y > 0) return '$y yr${y > 1 ? "s" : ""}';
    return '$m mo';
  }

  Color _healthColor(String s) {
    switch (s.toUpperCase()) {
      case 'OPTIMAL': return const Color(0xFF16A34A);
      case 'WARNING': return const Color(0xFFD97706);
      case 'CRITICAL': return const Color(0xFFDC2626);
      default: return _kLight;
    }
  }

  String? _resolveImage(String? p) {
    if (p == null || p.isEmpty) return null;
    if (p.startsWith('http')) return p;
    return 'http://${AppConfig.serverHost}:${AppConfig.serverPort}${p.startsWith("/") ? "" : "/"}$p';
  }

  Future<void> _deleteAnimal() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Animal'),
        content: Text('Delete ${_animal.name}? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _isDeleting = true);
    try {
      await _animalService.deleteAnimal(_animal.nodeId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Animal deleted'), backgroundColor: Color(0xFFEF4444)));
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  void _showMarkFatteningDialog() {
    DateTime? startDate = _animal.fatteningStartDate ?? DateTime.now();
    DateTime? targetDate = _animal.targetSaleDate;
    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: const Text('Mark as Fattening'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Start date:', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                _datePicker(ctx, startDate, DateTime.now().subtract(const Duration(days: 365)), DateTime.now(), (d) => setS(() => startDate = d)),
                const SizedBox(height: 16),
                const Text('Target sale date (optional):', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                _datePicker(ctx, targetDate, DateTime.now(), DateTime.now().add(const Duration(days: 730)), (d) => setS(() => targetDate = d)),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(onPressed: () async { Navigator.pop(ctx); await _markAsFattening(startDate, targetDate); }, child: const Text('Confirm')),
          ],
        ),
      ),
    );
  }

  Widget _datePicker(BuildContext ctx, DateTime? current, DateTime first, DateTime last, ValueChanged<DateTime> onPicked) {
    return GestureDetector(
      onTap: () async {
        final d = await showDatePicker(context: ctx, initialDate: current ?? DateTime.now(), firstDate: first, lastDate: last);
        if (d != null) onPicked(d);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(border: Border.all(color: _kGreen), borderRadius: BorderRadius.circular(8)),
        child: Text(current != null ? _df.format(current) : 'Select date',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: current != null ? _kDark : _kLight)),
      ),
    );
  }

  Future<void> _markAsFattening(DateTime? start, DateTime? target) async {
    try {
      showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
      final updated = await _animalService.markAnimalAsFattening(_animal.nodeId, {
        'fatteningStartDate': start?.toIso8601String(),
        'targetSaleDate': target?.toIso8601String(),
        'notes': 'Marked as fattening',
      });
      if (mounted) {
        Navigator.pop(context);
        setState(() => _animal = updated);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Marked as fattening'), backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    }
  }

  // ── BUILD ────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              _buildSliverAppBar(),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 140),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
                      _buildQuickStats(),
                      const SizedBox(height: 16),
                      _buildHealthRiskBanner(),
                      const SizedBox(height: 16),
                      _buildHealthCard(),
                      const SizedBox(height: 16),
                      _buildSpeciesCard(),
                      if (_animal.isFattening == true) ...[
                        const SizedBox(height: 16),
                        _buildFatteningCard(),
                      ],
                      if (_animal.motherId != null || _animal.fatherId != null) ...[
                        const SizedBox(height: 16),
                        _buildGenealogyCard(),
                      ],
                      const SizedBox(height: 16),
                      _buildFinanceCard(),
                      const SizedBox(height: 16),
                      _buildMedicalCard(),
                      if (_animal.notes != null && _animal.notes!.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        _buildNotesCard(),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
          _buildBottomBar(),
        ],
      ),
    );
  }

  // ── SLIVER APP BAR ───────────────────────────────────────

  Widget _buildSliverAppBar() {
    final imageUrl = _resolveImage(_animal.profileImage);
    return SliverAppBar(
      expandedHeight: 320,
      pinned: true,
      backgroundColor: _kGreen,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.parallax,
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Hero image
            imageUrl != null
                ? Image.network(imageUrl, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _buildImagePlaceholder())
                : _buildImagePlaceholder(),
            // Gradient overlay
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.transparent, Color(0xCC000000)],
                  stops: [0.0, 0.5, 1.0],
                ),
              ),
            ),
            // Animal info overlay at bottom
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        AnimalUtils.getAnimalEmoji(_animal.animalType),
                        style: const TextStyle(fontSize: 28),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _animal.name,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            shadows: [Shadow(color: Colors.black54, blurRadius: 8)],
                          ),
                        ),
                      ),
                      _statusBadge(_animal.status),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${_animal.breed ?? _animal.animalType}  •  ${_animal.tagNumber != null ? "Tag: ${_animal.tagNumber}" : _animal.nodeId}',
                    style: const TextStyle(fontSize: 13, color: Color(0xCCFFFFFF), fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ],
        ),
        title: Text(
          _animal.name,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
        ),
        titlePadding: const EdgeInsets.only(left: 56, bottom: 16),
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      color: const Color(0xFF1B5E20),
      child: Center(
        child: Icon(
          AnimalUtils.getAnimalIcon(_animal.animalType),
          size: 100,
          color: Colors.white.withAlpha(60),
        ),
      ),
    );
  }

  Widget _statusBadge(String status) {
    Color bg;
    String label;
    switch (status.toLowerCase()) {
      case 'sold': bg = const Color(0xFF1565C0); label = 'SOLD'; break;
      case 'deceased': bg = const Color(0xFF424242); label = 'DECEASED'; break;
      default: bg = const Color(0xFF2E7D32); label = 'ACTIVE';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }

  // ── QUICK STATS ──────────────────────────────────────────

  Widget _buildQuickStats() {
    return Row(
      children: [
        _statCard('Age', _formattedAge(), Icons.cake_outlined, const Color(0xFF1565C0), const Color(0xFFE3F2FD)),
        const SizedBox(width: 10),
        _statCard('Weight', _animal.weight != null ? '${_animal.weight!.toStringAsFixed(0)} kg' : 'N/A', Icons.monitor_weight_outlined, const Color(0xFFE65100), const Color(0xFFFFF3E0)),
        const SizedBox(width: 10),
        _statCard('Sex', _animal.sex == 'female' ? 'Female' : 'Male', _animal.sex == 'female' ? Icons.female : Icons.male, const Color(0xFFC2185B), const Color(0xFFFCE4EC)),
        const SizedBox(width: 10),
        _statCard('Origin', _animal.origin == 'born' ? 'Born' : 'Bought', Icons.home_outlined, const Color(0xFF6A1B9A), const Color(0xFFF3E5F5)),
      ],
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color, Color bg) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withAlpha(60)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color), textAlign: TextAlign.center),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF757575)), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  // ── HEALTH RISK BANNER ───────────────────────────────────

  Widget _buildHealthRiskBanner() {
    final score = _animal.healthRiskScore ?? 0.0;
    Color color;
    String label;
    IconData icon;
    if (score > 0.6) { color = const Color(0xFFDC2626); label = 'High Risk'; icon = Symbols.error; }
    else if (score > 0.3) { color = const Color(0xFFD97706); label = 'Moderate Risk'; icon = Symbols.warning; }
    else { color = const Color(0xFF16A34A); label = 'Low Risk'; icon = Symbols.check_circle; }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withAlpha(80), width: 1.5),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('AI HEALTH RISK', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF757575), letterSpacing: 1)),
                Text(label, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: color)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(color: color.withAlpha(30), borderRadius: BorderRadius.circular(12)),
            child: Text('${(score * 100).toInt()}%', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: color)),
          ),
        ],
      ),
    );
  }

  // ── HEALTH CARD ──────────────────────────────────────────

  Widget _buildHealthCard() {
    final hc = _healthColor(_animal.healthStatus);
    return _sectionCard(
      title: 'Health & Vitals',
      icon: Symbols.health_and_safety,
      color: const Color(0xFF16A34A),
      child: Column(
        children: [
          _infoRow('Status', _animal.healthStatus, valueColor: hc),
          _divider(),
          _buildVitalityBar(),
          _divider(),
          _infoRow('Temperature', _animal.bodyTemp != null ? '${_animal.bodyTemp!.toStringAsFixed(1)} °C' : 'N/A'),
          _divider(),
          _infoRow('Activity', _animal.activityLevel),
          _divider(),
          _infoRow('Vaccination', _animal.vaccination ? '✓ Up to date' : '✗ Not vaccinated',
              valueColor: _animal.vaccination ? const Color(0xFF16A34A) : const Color(0xFFDC2626)),
          if (_animal.lastVetCheck != null) ...[
            _divider(),
            _infoRow('Last vet check', _df.format(_animal.lastVetCheck!)),
          ],
        ],
      ),
    );
  }

  Widget _buildVitalityBar() {
    final score = _animal.vitalityScore.clamp(0, 100);
    final color = score >= 70 ? const Color(0xFF16A34A) : score >= 40 ? const Color(0xFFD97706) : const Color(0xFFDC2626);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Vitality Score', style: TextStyle(fontSize: 13, color: Color(0xFF757575), fontWeight: FontWeight.w500)),
              Text('$score%', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: score / 100,
              minHeight: 8,
              backgroundColor: const Color(0xFFE0E0E0),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }

  // ── SPECIES CARD ─────────────────────────────────────────

  Widget _buildSpeciesCard() {
    final type = _animal.animalType.toLowerCase();
    final isFemale = _animal.sex == 'female';
    final rows = <Widget>[];

    if (type == 'cow' && isFemale) {
      rows.add(_infoRow('Pregnant', _animal.isPregnant == true ? '✓ Yes' : _animal.isPregnant == false ? '✗ No' : 'Unknown',
          valueColor: _animal.isPregnant == true ? const Color(0xFF16A34A) : null));
      if (_animal.expectedBirthDate != null) rows.add(_infoRow('Expected birth', _df.format(_animal.expectedBirthDate!)));
      rows.add(_infoRow('Birth count', '${_animal.birthCount}'));
      if (_animal.dailyMilkAvgL != null) rows.add(_infoRow('Avg milk/day', '${_animal.dailyMilkAvgL!.toStringAsFixed(1)} L'));
      if (_animal.lactationNumber != null) rows.add(_infoRow('Lactation #', '${_animal.lactationNumber}'));
    } else if (type == 'horse') {
      if (_animal.raceCategory != null) rows.add(_infoRow('Category', _animal.raceCategory!.toUpperCase()));
      if (_animal.bestRaceTime != null) rows.add(_infoRow('Best time', '${_animal.bestRaceTime}s'));
      if (_animal.trainingLevel != null) rows.add(_infoRow('Training level', _animal.trainingLevel!.toUpperCase()));
    } else if (type == 'sheep') {
      if (_animal.woolLastShearDate != null) rows.add(_infoRow('Last shearing', _df.format(_animal.woolLastShearDate!)));
      if (_animal.meatGrade != null) rows.add(_infoRow('Meat grade', _animal.meatGrade!));
    } else if (type == 'dog') {
      if (_animal.dogRole != null) rows.add(_infoRow('Role', _animal.dogRole!.toUpperCase()));
    }

    if (rows.isEmpty) return const SizedBox.shrink();

    final emoji = {'cow': '🐄', 'horse': '🐴', 'sheep': '🐑', 'dog': '🐕'}[type] ?? '🐾';
    final label = {'cow': 'Dairy & Reproduction', 'horse': 'Performance', 'sheep': 'Production', 'dog': 'Working Dog'}[type] ?? 'Species Info';

    return _sectionCard(
      title: '$emoji $label',
      icon: Symbols.pets,
      color: const Color(0xFF0277BD),
      child: Column(children: _intersperse(rows, _divider())),
    );
  }

  // ── FATTENING CARD ───────────────────────────────────────

  Widget _buildFatteningCard() {
    final daysIn = _animal.fatteningStartDate != null
        ? DateTime.now().difference(_animal.fatteningStartDate!).inDays
        : 0;
    final daysLeft = _animal.targetSaleDate?.difference(DateTime.now()).inDays;

    return _sectionCard(
      title: '📊 Fattening Progress',
      icon: Symbols.trending_up,
      color: const Color(0xFFE65100),
      child: Column(
        children: [
          if (_animal.fatteningStartDate != null) _infoRow('Started', _df.format(_animal.fatteningStartDate!)),
          _divider(),
          _infoRow('Days in fattening', '$daysIn days'),
          if (_animal.targetSaleDate != null) ...[
            _divider(),
            _infoRow('Target sale date', _df.format(_animal.targetSaleDate!)),
            _divider(),
            _infoRow('Days remaining', daysLeft != null && daysLeft >= 0 ? '$daysLeft days' : 'Ready for sale',
                valueColor: daysLeft != null && daysLeft <= 7 ? const Color(0xFFDC2626) : null),
          ],
        ],
      ),
    );
  }

  // ── GENEALOGY CARD ───────────────────────────────────────

  Widget _buildGenealogyCard() {
    return _sectionCard(
      title: 'Genealogy',
      icon: Symbols.account_tree,
      color: const Color(0xFF6A1B9A),
      child: Column(
        children: [
          if (_animal.motherId != null) _buildParentRow('Mother', _animal.motherId!),
          if (_animal.motherId != null && _animal.fatherId != null) _divider(),
          if (_animal.fatherId != null) _buildParentRow('Father', _animal.fatherId!),
          _divider(),
          _infoRow('Birth count', '${_animal.birthCount}'),
        ],
      ),
    );
  }

  Widget _buildParentRow(String label, String parentId) {
    return FutureBuilder<Animal>(
      future: _animalService.getAnimalById(parentId),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF757575))),
                const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
              ],
            ),
          );
        }
        if (!snap.hasData) return _infoRow(label, 'Unknown');
        final p = snap.data!;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF757575), fontWeight: FontWeight.w500)),
              GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AnimalDetailsScreen(animal: p))),
                child: Text(p.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1565C0), decoration: TextDecoration.underline, decorationColor: Color(0xFF1565C0))),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── FINANCE CARD ─────────────────────────────────────────

  Widget _buildFinanceCard() {
    return _sectionCard(
      title: 'Finance',
      icon: Symbols.payments,
      color: const Color(0xFFD97706),
      trailing: GestureDetector(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AnimalFinanceScreen(animal: _animal))),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Details', style: TextStyle(fontSize: 12, color: Color(0xFFD97706), fontWeight: FontWeight.w600)),
            SizedBox(width: 4),
            Icon(Symbols.arrow_forward_ios, size: 14, color: Color(0xFFD97706)),
          ],
        ),
      ),
      child: Column(
        children: [
          if (_animal.origin == 'purchased') ...[
            _infoRow('Purchase price', _animal.purchasePrice != null ? _nf.format(_animal.purchasePrice) : 'N/A'),
            _divider(),
            _infoRow('Purchase date', _animal.purchaseDate != null ? _df.format(_animal.purchaseDate!) : 'N/A'),
          ] else ...[
            _infoRow('Birth cost', _animal.birthCost != null ? _nf.format(_animal.birthCost) : 'N/A'),
            _divider(),
            _infoRow('Birth weight', _animal.birthWeightKg != null ? '${_animal.birthWeightKg} kg' : 'N/A'),
          ],
          _divider(),
          _infoRow('Estimated value', _animal.estimatedValue != null ? _nf.format(_animal.estimatedValue) : 'N/A',
              valueColor: const Color(0xFF16A34A)),
          if (_animal.status == 'sold') ...[
            _divider(),
            _infoRow('Sale price', _animal.salePrice != null ? _nf.format(_animal.salePrice) : 'N/A', valueColor: const Color(0xFF1565C0)),
            if (_animal.saleDate != null) ...[_divider(), _infoRow('Sale date', _df.format(_animal.saleDate!))],
            if (_animal.buyerName != null) ...[_divider(), _infoRow('Buyer', _animal.buyerName!)],
          ],
        ],
      ),
    );
  }

  // ── MEDICAL CARD ─────────────────────────────────────────

  Widget _buildMedicalCard() {
    return _sectionCard(
      title: 'Medical History',
      icon: Symbols.medical_services,
      color: const Color(0xFF1565C0),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(color: const Color(0xFFFFEBEE), borderRadius: BorderRadius.circular(12)),
        child: Text('${_animal.diseaseHistoryCount} events', style: const TextStyle(fontSize: 11, color: Color(0xFFDC2626), fontWeight: FontWeight.bold)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Vaccines
          if (_animal.vaccineRecords != null && _animal.vaccineRecords!.isNotEmpty) ...[
            _subHeader('Vaccinations', Icons.vaccines, const Color(0xFF2E7D32)),
            const SizedBox(height: 8),
            ..._animal.vaccineRecords!.map((v) => _medicalItem(
              v.vaccine?.nameEn ?? v.vaccine?.code ?? 'Vaccine',
              _df.format(v.administeredAt),
              Icons.vaccines,
              const Color(0xFF2E7D32),
            )),
          ] else
            _emptyMedical('No vaccinations recorded'),
          // Medical events
          if (_animal.medicalEvents != null && _animal.medicalEvents!.isNotEmpty) ...[
            const SizedBox(height: 16),
            _subHeader('Medical Events', Symbols.medical_services, const Color(0xFF1565C0)),
            const SizedBox(height: 8),
            ..._animal.medicalEvents!.map((e) => _medicalItem(
              e.eventType.toUpperCase(),
              _df.format(e.eventDate),
              Symbols.medical_services,
              const Color(0xFF1565C0),
              subtitle: e.diagnosis,
            )),
          ],
        ],
      ),
    );
  }

  Widget _subHeader(String title, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  Widget _emptyMedical(String msg) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: const Color(0xFFF5F5F5), borderRadius: BorderRadius.circular(8)),
      child: Text(msg, style: const TextStyle(fontSize: 13, color: Color(0xFF9E9E9E), fontStyle: FontStyle.italic)),
    );
  }

  Widget _medicalItem(String title, String date, IconData icon, Color color, {String? subtitle}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withAlpha(25), shape: BoxShape.circle),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF212121))),
                if (subtitle != null) Text(subtitle, style: const TextStyle(fontSize: 12, color: Color(0xFF757575))),
              ],
            ),
          ),
          Text(date, style: const TextStyle(fontSize: 11, color: Color(0xFF9E9E9E))),
        ],
      ),
    );
  }

  // ── NOTES CARD ───────────────────────────────────────────

  Widget _buildNotesCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFDE7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFF176)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.sticky_note_2, color: Color(0xFFF9A825), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Notes', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFFE65100))),
                const SizedBox(height: 6),
                Text(_animal.notes!, style: const TextStyle(fontSize: 13, color: Color(0xFF33691E), height: 1.6)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── BOTTOM BAR ───────────────────────────────────────────

  Widget _buildBottomBar() {
    return Positioned(
      bottom: 0, left: 0, right: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withAlpha(20), blurRadius: 16, offset: const Offset(0, -4))],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_animal.status == 'active' && _animal.isFattening == true)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFE3F2FD),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF90CAF9)),
                ),
                child: Row(
                  children: [
                    const Icon(Symbols.trending_up, size: 16, color: Color(0xFF1565C0)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _animal.targetSaleDate != null
                            ? 'Fattening — target: ${_df.format(_animal.targetSaleDate!)}'
                            : 'Fattening in progress',
                        style: const TextStyle(fontSize: 12, color: Color(0xFF1565C0), fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            Row(
              children: [
                // Delete
                _actionBtn(
                  icon: Symbols.delete,
                  color: const Color(0xFF757575),
                  bg: const Color(0xFFF5F5F5),
                  border: const Color(0xFFE0E0E0),
                  onTap: _isDeleting ? null : _deleteAnimal,
                  flex: 1,
                ),
                // Fattening (only if active and not already fattening)
                if (_animal.status == 'active' && _animal.isFattening != true) ...[
                  const SizedBox(width: 8),
                  _actionBtn(
                    icon: Symbols.trending_up,
                    color: const Color(0xFF78350F),
                    bg: const Color(0xFFFCD34D),
                    border: const Color(0xFFFCD34D),
                    onTap: _showMarkFatteningDialog,
                    flex: 1,
                  ),
                ],
                // Sell (only if active)
                if (_animal.status == 'active') ...[
                  const SizedBox(width: 8),
                  _actionBtn(
                    label: 'Sell',
                    color: Colors.white,
                    bg: const Color(0xFF16A34A),
                    border: const Color(0xFF16A34A),
                    onTap: () async {
                      final updated = await Navigator.push(context, MaterialPageRoute(builder: (_) => SellAnimalScreen(animal: _animal)));
                      if (updated == true && mounted) Navigator.pop(context, true);
                    },
                    flex: 1,
                  ),
                ],
                const SizedBox(width: 8),
                // Edit
                _actionBtn(
                  icon: Symbols.edit,
                  label: 'Edit',
                  color: Colors.white,
                  bg: _kGreen,
                  border: _kGreen,
                  onTap: () async {
                    final updated = await Navigator.push(context, MaterialPageRoute(builder: (_) => AddAnimalScreen(animal: _animal)));
                    if (updated == true && mounted) Navigator.pop(context, true);
                  },
                  flex: 2,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionBtn({IconData? icon, String? label, required Color color, required Color bg, required Color border, VoidCallback? onTap, required int flex}) {
    return Expanded(
      flex: flex,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: border),
            boxShadow: [BoxShadow(color: bg.withAlpha(80), blurRadius: 8, offset: const Offset(0, 4))],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) Icon(icon, color: color, size: 20),
              if (icon != null && label != null) const SizedBox(width: 6),
              if (label != null) Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 15)),
            ],
          ),
        ),
      ),
    );
  }

  // ── SHARED HELPERS ───────────────────────────────────────

  Widget _sectionCard({
    required String title,
    required IconData icon,
    required Color color,
    required Widget child,
    Widget? trailing,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(12), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            decoration: BoxDecoration(
              color: color.withAlpha(18),
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
              border: Border(bottom: BorderSide(color: color.withAlpha(40))),
            ),
            child: Row(
              children: [
                Icon(icon, size: 18, color: color),
                const SizedBox(width: 8),
                Expanded(child: Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color))),
                if (trailing != null) trailing,
              ],
            ),
          ),
          // Body
          Padding(padding: const EdgeInsets.all(16), child: child),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF757575), fontWeight: FontWeight.w500)),
          Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: valueColor ?? _kDark)),
        ],
      ),
    );
  }

  Widget _divider() => const Divider(height: 1, color: Color(0xFFF0F0F0));

  List<Widget> _intersperse(List<Widget> items, Widget separator) {
    final result = <Widget>[];
    for (int i = 0; i < items.length; i++) {
      result.add(items[i]);
      if (i < items.length - 1) result.add(separator);
    }
    return result;
  }
}

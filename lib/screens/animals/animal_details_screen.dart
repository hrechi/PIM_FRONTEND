import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/animal.dart';
import '../../services/animal_service.dart';
import '../../utils/constants.dart';
import '../../utils/animal_utils.dart';
import '../../l10n/l10n_extensions.dart';
import '../../models/vaccine_models.dart' as vms;
import '../../models/animal_health_models.dart';
import '../../providers/animal_health_provider.dart';
import '../../providers/vaccine_provider.dart';
import '../../services/animal_health_service.dart';
import '../../services/sensor_simulator_service.dart';
import '../../theme/app_colors.dart';
import 'add_animal_screen.dart';
import 'animal_finance_screen.dart';
import 'sell_animal_screen.dart';
import 'medical_event_form_screen.dart';
import '../../services/medical_event_service.dart';
import 'diagnosis_detail_screen.dart';
import '../animal_health/sensor_graph_screen.dart';
import 'weight_tracking_screen.dart';
import '../../widgets/animal_qr_dialog.dart'; // QR code de l'animal

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
  bool _isRefreshing = false;
  final DateFormat _df = DateFormat('MMM dd, yyyy');
  final NumberFormat _nf = NumberFormat.currency(symbol: 'TND ', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _animal = widget.animal;
    // Recharge les données fraîches depuis l'API au démarrage
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _refreshAnimal();
      // Charge les vaccins via VaccineProvider
      try {
        context.read<VaccineProvider>().loadForAnimal(_animal.id, forceRefresh: true);
      } catch (_) {}
    });
  }

  /// Recharge l'animal complet depuis l'API (health, vaccins, events à jour)
  Future<void> _refreshAnimal() async {
    if (!mounted) return;
    setState(() => _isRefreshing = true);
    try {
      final updated = await _animalService.getAnimalById(_animal.id);
      if (mounted) setState(() => _animal = updated);
    } catch (_) {
      // Silently fail — keep existing data
    } finally {
      if (mounted) setState(() => _isRefreshing = false);
    }
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
    return FieldlyColors.healthStatus(s);
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
        title: Text(context.l10n.deleteAnimal),
        content: Text(context.l10n.deleteAnimalConfirm(_animal.name)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(context.l10n.cancel)),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text(context.l10n.delete, style: const TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _isDeleting = true);
    try {
      await _animalService.deleteAnimal(_animal.nodeId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.l10n.animalDeleted), backgroundColor: const Color(0xFFEF4444)));
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${context.l10n.error}: $e')));
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  Future<void> _confirmMarkDeceased() async {
    final notesController = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.heart_broken, color: Color(0xFF616161)),
            SizedBox(width: 8),
            Text('Mark as Deceased', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Mark ${_animal.name} as deceased? This cannot be undone easily.'),
            const SizedBox(height: 12),
            TextField(
              controller: notesController,
              decoration: InputDecoration(
                labelText: 'Cause / notes (optional)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(context.l10n.cancel)),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF616161), foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await _animalService.markAsDeceased(_animal.nodeId, notes: notesController.text.trim().isEmpty ? null : notesController.text.trim());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${_animal.name} marked as deceased'), backgroundColor: const Color(0xFF616161)),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    }
  }

  void _showMarkFatteningDialog() {
    DateTime? startDate = _animal.fatteningStartDate ?? DateTime.now();
    DateTime? targetDate = _animal.targetSaleDate;
    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: Text(context.l10n.markAsFattening),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(context.l10n.startDate, style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                _datePicker(ctx, startDate, DateTime.now().subtract(const Duration(days: 365)), DateTime.now(), (d) => setS(() => startDate = d)),
                const SizedBox(height: 16),
                Text(context.l10n.targetSaleDate, style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                _datePicker(ctx, targetDate, DateTime.now(), DateTime.now().add(const Duration(days: 730)), (d) => setS(() => targetDate = d)),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(context.l10n.cancel)),
            ElevatedButton(onPressed: () async { Navigator.pop(ctx); await _markAsFattening(startDate, targetDate); }, child: Text(context.l10n.confirm)),
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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.l10n.markedAsFattening), backgroundColor: Colors.green));
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
                      // ── AI health features: cows only ──────────────
                      if (_animal.animalType.toLowerCase() == 'cow') ...[
                        const SizedBox(height: 16),
                        _buildHealthRiskBanner(),
                      ],
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
      // ── Bouton QR code dans l'AppBar ──────────────────────────────────
      // Permet d'afficher le QR de l'animal à tout moment depuis sa fiche
      actions: [
        IconButton(
          tooltip: 'QR Code',
          icon: const Icon(Icons.qr_code_2_rounded, color: Colors.white, size: 26),
          onPressed: () => AnimalQrDialog.show(context, _animal),
        ),
      ],
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
        child: Text(
          AnimalUtils.getAnimalEmoji(_animal.animalType),
          style: TextStyle(fontSize: 80, color: Colors.white.withAlpha(180)),
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
        _statCard(context.l10n.age, _formattedAge(), Icons.cake_outlined, const Color(0xFF1565C0), const Color(0xFFE3F2FD)),
        const SizedBox(width: 10),
        _statCard(context.l10n.weight, _animal.weight != null ? '${_animal.weight!.toStringAsFixed(0)} kg' : 'N/A', Icons.monitor_weight_outlined, const Color(0xFFE65100), const Color(0xFFFFF3E0)),
        const SizedBox(width: 10),
        _statCard(context.l10n.sex, _animal.sex == 'female' ? context.l10n.female : context.l10n.male, _animal.sex == 'female' ? Icons.female : Icons.male, const Color(0xFFC2185B), const Color(0xFFFCE4EC)),
        const SizedBox(width: 10),
        _statCard(context.l10n.origin, _animal.origin == 'born' ? 'Born' : 'Bought', Icons.home_outlined, const Color(0xFF6A1B9A), const Color(0xFFF3E5F5)),
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
    final provider = context.watch<AnimalHealthProvider>();
    final diagResult = provider.resultFor(_animal.id);
    final isLoading  = provider.isLoading(_animal.id);
    final error      = provider.errorFor(_animal.id);

    // Score en temps réel depuis le provider, sinon depuis l'animal.
    // NB: _animal.healthRiskScore vient de la DB comme un health score (0-100,
    // 100 = sain). On le convertit en risk score (0-1) pour l'affichage.
    final score = diagResult != null
        ? diagResult.riskScore
        : ((_animal.healthRiskScore != null)
            ? ((100.0 - _animal.healthRiskScore!) / 100.0).clamp(0.0, 1.0)
            : 0.0);

    Color color;
    String label;
    IconData icon;
    if (score > 0.6)      { color = const Color(0xFFDC2626); label = 'High Risk';     icon = Symbols.error; }
    else if (score > 0.3) { color = const Color(0xFFD97706); label = 'Moderate Risk'; icon = Symbols.warning; }
    else                  { color = const Color(0xFF16A34A); label = 'Low Risk';      icon = Symbols.check_circle; }

    return Column(
      children: [
        // ── Score banner ──────────────────────────────────
        Container(
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
                    Text(
                      context.l10n.aiHealthRisk,
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF757575), letterSpacing: 1),
                    ),
                    Text(label, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: color)),
                    if (diagResult?.predictedDisease != null)
                      Text(
                        '🦠 ${diagResult!.predictedDisease}',
                        style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600),
                      ),
                    if (diagResult?.isStaticFallback == true)
                      const Text(
                        '⚠ Based on static fields — add sensors for precision',
                        style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8), fontStyle: FontStyle.italic),
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(color: color.withAlpha(30), borderRadius: BorderRadius.circular(12)),
                child: Text(
                  '${(score * 100).toInt()}%',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: color),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 10),

        // ── Bouton diagnostic ─────────────────────────────
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: isLoading ? const Color(0xFF64748B) : _kGreen,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: isLoading ? null : () => _runDiagnostic(),
            icon: isLoading
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Icon(Symbols.biotech, size: 18),
            label: Text(
              isLoading ? 'Analysing...' : 'Run AI Diagnostic',
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
            ),
          ),
        ),

        const SizedBox(height: 8),

        // ── Bouton simulateur (test sans IoT) ─────────────
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF6A1B9A),
              side: const BorderSide(color: Color(0xFF6A1B9A)),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: isLoading ? null : () => _showSimulatorSheet(),
            icon: const Icon(Symbols.science, size: 18),
            label: const Text('Simulate Sensor Data', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
          ),
        ),

        // ── Bouton "See explanation" (visible après diagnostic) ──
        if (diagResult != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: _kGreen,
                  side: const BorderSide(color: _kGreen),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DiagnosisDetailScreen(
                      result: diagResult,
                      animalName: _animal.name,
                    ),
                  ),
                ),
                icon: const Icon(Symbols.info, size: 18),
                label: const Text('See full explanation', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
              ),
            ),
          ),

        // ── Erreur ────────────────────────────────────────
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFECACA)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Color(0xFFDC2626), size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      error.contains('FastAPI') ? 'AI service offline — start pastureai-ai server' : error,
                      style: const TextStyle(fontSize: 12, color: Color(0xFFDC2626)),
                    ),
                  ),
                ],
              ),
            ),
          ),

        // ── Détail probabilités ───────────────────────────
        if (diagResult != null && diagResult.allProbabilities.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: _buildProbabilityBars(diagResult),
          ),
      ],
    );
  }

  // ── SIMULATOR BOTTOM SHEET ───────────────────────────────

  void _showSimulatorSheet() {
    SimulatorScenario _selectedScenario = SimulatorScenario.saine;
    int _selectedDays = 2;
    bool _isRunning = false;
    String? _statusMessage;
    bool _success = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheet) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: EdgeInsets.fromLTRB(
                20, 16, 20,
                MediaQuery.of(ctx).viewInsets.bottom + 28,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle
                  Center(
                    child: Container(
                      width: 40, height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Title
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6A1B9A).withValues(alpha: 0.078),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.science, color: Color(0xFF6A1B9A), size: 20),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Sensor Simulator',
                              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                            ),
                            Text(
                              'Inject synthetic sensor data & run AI diagnostic',
                              style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Scenario picker
                  const Text(
                    'SCENARIO',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF64748B), letterSpacing: 1),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: SimulatorScenario.values.map((s) {
                      final selected = _selectedScenario == s;
                      return GestureDetector(
                        onTap: _isRunning ? null : () => setSheet(() => _selectedScenario = s),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                          decoration: BoxDecoration(
                            color: selected ? const Color(0xFF6A1B9A) : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: selected ? const Color(0xFF6A1B9A) : const Color(0xFFE2E8F0),
                              width: selected ? 1.5 : 1,
                            ),
                          ),
                          child: Text(
                            s.label,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: selected ? Colors.white : const Color(0xFF475569),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  // Scenario description
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6A1B9A).withValues(alpha: 0.047),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF6A1B9A).withValues(alpha: 0.156)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, size: 14, color: Color(0xFF6A1B9A)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _selectedScenario.description,
                            style: const TextStyle(fontSize: 12, color: Color(0xFF475569), height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Days picker
                  Row(
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'HISTORY (DAYS)',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF64748B), letterSpacing: 1),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'More days = richer AI context',
                              style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          _dayBtn(1, _selectedDays, _isRunning, (d) => setSheet(() => _selectedDays = d)),
                          const SizedBox(width: 6),
                          _dayBtn(2, _selectedDays, _isRunning, (d) => setSheet(() => _selectedDays = d)),
                          const SizedBox(width: 6),
                          _dayBtn(5, _selectedDays, _isRunning, (d) => setSheet(() => _selectedDays = d)),
                          const SizedBox(width: 6),
                          _dayBtn(7, _selectedDays, _isRunning, (d) => setSheet(() => _selectedDays = d)),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Status message
                  if (_statusMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: _success ? const Color(0xFFF0FDF4) : const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: _success ? const Color(0xFF86EFAC) : const Color(0xFFFECACA),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _success ? Icons.check_circle_outline : Icons.error_outline,
                              size: 16,
                              color: _success ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _statusMessage!,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: _success ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Launch button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isRunning ? const Color(0xFF64748B) : const Color(0xFF6A1B9A),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: _isRunning
                          ? null
                          : () async {
                              setSheet(() {
                                _isRunning = true;
                                _statusMessage = null;
                                _success = false;
                              });

                              try {
                                // 1. Generate simulated sensor history
                                await SensorSimulatorService.generateHistory(
                                  animalId: _animal.id,
                                  scenario: _selectedScenario,
                                  days: _selectedDays,
                                );

                                setSheet(() => _statusMessage = '✓ ${_selectedDays}d of ${_selectedScenario.label} data injected — running AI...');

                                // 2. Run diagnostic automatically
                                final provider = context.read<AnimalHealthProvider>();
                                final result = await provider.runDiagnostic(_animal.id);

                                setSheet(() {
                                  _isRunning = false;
                                  _success = true;
                                  _statusMessage = result != null
                                      ? '✓ Diagnostic complete — ${result.predictedDisease ?? 'saine'} (${(result.riskScore * 100).toInt()}% risk)'
                                      : '✓ Data injected. Tap "Run AI Diagnostic" to analyse.';
                                });

                                // Close sheet after short delay and refresh
                                await Future.delayed(const Duration(seconds: 2));
                                if (ctx.mounted) Navigator.pop(ctx);
                              } catch (e) {
                                setSheet(() {
                                  _isRunning = false;
                                  _success = false;
                                  _statusMessage = 'Error: ${e.toString().replaceAll('Exception: ', '')}';
                                });
                              }
                            },
                      icon: _isRunning
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.play_arrow_rounded, size: 20),
                      label: Text(
                        _isRunning ? 'Simulating & Diagnosing...' : 'Launch Simulation + Diagnostic',
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _dayBtn(int days, int selected, bool disabled, ValueChanged<int> onTap) {
    final isSelected = days == selected;
    return GestureDetector(
      onTap: disabled ? null : () => onTap(days),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 42,
        height: 38,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF6A1B9A) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? const Color(0xFF6A1B9A) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Center(
          child: Text(
            '$days',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: isSelected ? Colors.white : const Color(0xFF475569),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _runDiagnostic() async {
    final provider = context.read<AnimalHealthProvider>();
    final result = await provider.runDiagnostic(_animal.id);
    if (result != null && mounted) {
      // Mettre à jour les champs locaux immédiatement depuis le résultat du diagnostic
      setState(() {
        _animal = Animal(
          id: _animal.id,
          nodeId: _animal.nodeId,
          farmerId: _animal.farmerId,
          fieldId: _animal.fieldId,
          name: _animal.name,
          animalType: _animal.animalType,
          breed: _animal.breed,
          age: _animal.age,
          ageYears: _animal.ageYears,
          sex: _animal.sex,
          weight: _animal.weight,
          healthStatus: result.alertLevel == 'critical' ? 'CRITICAL'
              : result.alertLevel == 'medium' ? 'WARNING' : 'OPTIMAL',
          vitalityScore: result.healthScore.round().clamp(0, 100),
          bodyTemp: _animal.bodyTemp,
          activityLevel: _animal.activityLevel,
          lastVetCheck: _animal.lastVetCheck,
          vaccination: _animal.vaccination,
          profileImage: _animal.profileImage,
          tagNumber: _animal.tagNumber,
          notes: _animal.notes,
          isPregnant: _animal.isPregnant,
          lastInseminationDate: _animal.lastInseminationDate,
          lastBirthDate: _animal.lastBirthDate,
          expectedBirthDate: _animal.expectedBirthDate,
          birthCount: _animal.birthCount,
          status: _animal.status,
          healthRiskScore: result.riskScore,
          diseaseHistoryCount: _animal.diseaseHistoryCount,
          fatContent: _animal.fatContent,
          protein: _animal.protein,
          feedIntakeRecorded: _animal.feedIntakeRecorded,
          dewormingScheduled: _animal.dewormingScheduled,
          productionHabit: _animal.productionHabit,
          vaccines: _animal.vaccines,
          birthHistory: _animal.birthHistory,
          dailyMilkAvgL: _animal.dailyMilkAvgL,
          milkPeakDate: _animal.milkPeakDate,
          lactationNumber: _animal.lactationNumber,
          raceCategory: _animal.raceCategory,
          bestRaceTime: _animal.bestRaceTime,
          trainingLevel: _animal.trainingLevel,
          woolLastShearDate: _animal.woolLastShearDate,
          meatGrade: _animal.meatGrade,
          dogRole: _animal.dogRole,
          purchasePrice: _animal.purchasePrice,
          purchaseDate: _animal.purchaseDate,
          estimatedValue: _animal.estimatedValue,
          salePrice: _animal.salePrice,
          saleDate: _animal.saleDate,
          buyerName: _animal.buyerName,
          saleWeightKg: _animal.saleWeightKg,
          isFattening: _animal.isFattening,
          fatteningStartDate: _animal.fatteningStartDate,
          targetSaleDate: _animal.targetSaleDate,
          origin: _animal.origin,
          motherId: _animal.motherId,
          fatherId: _animal.fatherId,
          birthWeightKg: _animal.birthWeightKg,
          birthCost: _animal.birthCost,
          createdAt: _animal.createdAt,
          updatedAt: _animal.updatedAt,
          vaccineRecords: _animal.vaccineRecords,
          medicalEvents: _animal.medicalEvents,
        );
      });
      // Recharger l'animal depuis l'API pour récupérer bodyTemp et activityLevel
      // mis à jour par le backend après le diagnostic (données capteurs simulées)
      _refreshAnimal();
    }
  }

  Widget _buildProbabilityBars(DiagnosisResult result) {
    final sorted = result.allProbabilities.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final diseaseColors = {
      'saine':            const Color(0xFF16A34A),
      'mammite':          const Color(0xFFDC2626),
      'fievre':           const Color(0xFFEF4444),
      'boiterie':         const Color(0xFFD97706),
      'stress_thermique': const Color(0xFFF59E0B),
    };

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'DISEASE PROBABILITIES',
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF64748B), letterSpacing: 1),
          ),
          const SizedBox(height: 10),
          ...sorted.map((e) {
            final color = diseaseColors[e.key] ?? _kGreen;
            final pct   = (e.value * 100).toInt();
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  SizedBox(
                    width: 100,
                    child: Text(
                      e.key,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                    ),
                  ),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: e.value,
                        minHeight: 8,
                        backgroundColor: const Color(0xFFF1F5F9),
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 36,
                    child: Text(
                      '$pct%',
                      textAlign: TextAlign.right,
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ── HEALTH CARD ──────────────────────────────────────────

  Widget _buildHealthCard() {
    final hc = _healthColor(_animal.healthStatus);
    return _sectionCard(
      title: context.l10n.healthAndVitals,
      icon: Symbols.health_and_safety,
      color: const Color(0xFF16A34A),
      trailing: _isRefreshing
          ? const SizedBox(
              width: 14, height: 14,
              child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF16A34A)),
            )
          : GestureDetector(
              onTap: _refreshAnimal,
              child: const Icon(Icons.refresh_rounded, size: 18, color: Color(0xFF16A34A)),
            ),
      child: Column(
        children: [
          // Health Status — dynamique depuis l'API
          _infoRow(
            context.l10n.healthStatus,
            _animal.healthStatus,
            valueColor: hc,
          ),
          _divider(),

          // Vitality Score — dynamique
          _buildVitalityBar(),
          _divider(),

          // Body Temperature — dynamique (mis à jour par le diagnostic IA)
          _infoRow(
            context.l10n.temperature,
            _animal.bodyTemp != null
                ? '${_animal.bodyTemp!.toStringAsFixed(1)} °C'
                : 'N/A',
            valueColor: _animal.bodyTemp != null && _animal.bodyTemp! > 39.5
                ? const Color(0xFFDC2626)
                : null,
          ),
          _divider(),

          // Activity Level — dynamique
          _infoRow(
            context.l10n.activityLevel,
            _animal.activityLevel,
            valueColor: _animal.activityLevel == 'LOW'
                ? const Color(0xFFDC2626)
                : _animal.activityLevel == 'HIGH'
                    ? const Color(0xFF16A34A)
                    : null,
          ),
          _divider(),

          // Deworming — dynamique
          if (_animal.dewormingScheduled != null) ...[
            _infoRow(
              'Deworming',
              _df.format(_animal.dewormingScheduled!),
              valueColor: _animal.dewormingScheduled!.isBefore(DateTime.now())
                  ? const Color(0xFFDC2626)
                  : null,
            ),
            _divider(),
          ],

          // Last vet check — dynamique
          if (_animal.lastVetCheck != null) ...[
            _divider(),
            _infoRow(
              context.l10n.lastVetCheck,
              _df.format(_animal.lastVetCheck!),
              valueColor: DateTime.now().difference(_animal.lastVetCheck!).inDays > 180
                  ? const Color(0xFFD97706)
                  : null,
            ),
          ],

          // ── Boutons accès rapide ──────────────────────────
          const SizedBox(height: 14),
          Row(
            children: [
              // Graphiques capteurs — vaches uniquement (modèle IA cow-only)
              if (_animal.animalType.toLowerCase() == 'cow') ...[
                Expanded(
                  child: _quickAccessBtn(
                    icon: Symbols.monitoring,
                    label: 'Sensor Charts',
                    color: const Color(0xFF7C3AED),
                    bg: const Color(0xFFF5F3FF),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SensorGraphScreen(
                          animalId: _animal.id,
                          animalName: _animal.name,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
              ],
              // Courbe de poids — tous les animaux
              Expanded(
                child: _quickAccessBtn(
                  icon: Symbols.scale,
                  label: 'Weight Curve',
                  color: const Color(0xFFE65100),
                  bg: const Color(0xFFFFF3E0),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => WeightTrackingScreen(animal: _animal),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _quickAccessBtn({
    required IconData icon,
    required String label,
    required Color color,
    required Color bg,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withAlpha(60)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Symbols.arrow_forward_ios, size: 11, color: color),
          ],
        ),
      ),
    );
  }

  Widget _buildVitalityBar() {
    final score = _animal.vitalityScore.clamp(0, 100);
    final color = score >= 70
        ? const Color(0xFF16A34A)
        : score >= 40
            ? const Color(0xFFD97706)
            : const Color(0xFFDC2626);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                context.l10n.vitalityScore,
                style: const TextStyle(fontSize: 13, color: Color(0xFF757575), fontWeight: FontWeight.w500),
              ),
              Text(
                '$score%',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color),
              ),
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
    final l = context.l10n;

    if (type == 'cow' && isFemale) {
      rows.add(_infoRow(l.pregnant, _animal.isPregnant == true ? '✓ ${l.yes}' : _animal.isPregnant == false ? '✗ ${l.no}' : l.unknown,
          valueColor: _animal.isPregnant == true ? const Color(0xFF16A34A) : null));
      if (_animal.expectedBirthDate != null) rows.add(_infoRow('Expected birth', _df.format(_animal.expectedBirthDate!)));
      rows.add(_infoRow(l.birthCount, '${_animal.birthCount}'));
      if (_animal.dailyMilkAvgL != null) rows.add(_infoRow(l.avgMilkPerDay, '${_animal.dailyMilkAvgL!.toStringAsFixed(1)} L'));
      if (_animal.lactationNumber != null) rows.add(_infoRow(l.lactationNumber, '${_animal.lactationNumber}'));
    } else if (type == 'horse') {
      if (_animal.raceCategory != null) rows.add(_infoRow(l.category, _animal.raceCategory!.toUpperCase()));
      if (_animal.bestRaceTime != null) rows.add(_infoRow(l.bestTime, '${_animal.bestRaceTime}s'));
      if (_animal.trainingLevel != null) rows.add(_infoRow(l.trainingLevel, _animal.trainingLevel!.toUpperCase()));
    } else if (type == 'sheep') {
      if (_animal.woolLastShearDate != null) rows.add(_infoRow(l.lastShearing, _df.format(_animal.woolLastShearDate!)));
      if (_animal.meatGrade != null) rows.add(_infoRow(l.meatGrade, _animal.meatGrade!));
    } else if (type == 'dog') {
      if (_animal.dogRole != null) rows.add(_infoRow(l.role, _animal.dogRole!.toUpperCase()));
    }

    if (rows.isEmpty) return const SizedBox.shrink();

    final emoji = {'cow': '🐄', 'horse': '🐴', 'sheep': '🐑', 'dog': '🐕'}[type] ?? '🐾';
    final sectionLabel = {
      'cow': l.dairyAndReproduction,
      'horse': l.performance,
      'sheep': l.productionRecords,
      'dog': 'Working Dog',
    }[type] ?? l.species;

    return _sectionCard(
      title: '$emoji $sectionLabel',
      icon: Symbols.pets,
      color: const Color(0xFF0277BD),
      child: Column(children: _intersperse(rows, _divider())),
    );
  }

  // ── FATTENING CARD ───────────────────────────────────────

  Widget _buildFatteningCard() {
    final daysIn = _animal.fatteningStartDate != null
        ? DateTime.now().difference(_animal.fatteningStartDate!).inDays : 0;
    final daysLeft = _animal.targetSaleDate?.difference(DateTime.now()).inDays;
    final l = context.l10n;
    return _sectionCard(
      title: '📊 ${l.fatteningProgress}',
      icon: Symbols.trending_up,
      color: const Color(0xFFE65100),
      child: Column(
        children: [
          if (_animal.fatteningStartDate != null) _infoRow(l.started, _df.format(_animal.fatteningStartDate!)),
          _divider(),
          _infoRow(l.daysInFattening, '$daysIn days'),
          if (_animal.targetSaleDate != null) ...[
            _divider(),
            _infoRow(l.targetSaleDate, _df.format(_animal.targetSaleDate!)),
            _divider(),
            _infoRow(l.daysRemaining,
                daysLeft != null && daysLeft >= 0 ? '$daysLeft days' : l.readyForSale,
                valueColor: daysLeft != null && daysLeft <= 7 ? const Color(0xFFDC2626) : null),
          ],
        ],
      ),
    );
  }

  // ── GENEALOGY CARD ───────────────────────────────────────

  Widget _buildGenealogyCard() {
    return _sectionCard(
      title: context.l10n.genealogy,
      icon: Symbols.account_tree,
      color: const Color(0xFF6A1B9A),
      child: Column(
        children: [
          if (_animal.motherId != null) _buildParentRow(context.l10n.mother, _animal.motherId!),
          if (_animal.motherId != null && _animal.fatherId != null) _divider(),
          if (_animal.fatherId != null) _buildParentRow(context.l10n.father, _animal.fatherId!),
          _divider(),
          _infoRow(context.l10n.birthCount, '${_animal.birthCount}'),
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
        if (!snap.hasData) return _infoRow(label, context.l10n.unknown);
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
    final l = context.l10n;
    return _sectionCard(
      title: l.finance,
      icon: Symbols.payments,
      color: const Color(0xFFD97706),
      trailing: GestureDetector(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AnimalFinanceScreen(animal: _animal))),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l.financeDetails, style: const TextStyle(fontSize: 12, color: Color(0xFFD97706), fontWeight: FontWeight.w600)),
            const SizedBox(width: 4),
            const Icon(Symbols.arrow_forward_ios, size: 14, color: Color(0xFFD97706)),
          ],
        ),
      ),
      child: Column(
        children: [
          if (_animal.origin == 'purchased') ...[
            _infoRow(l.purchasePrice, _animal.purchasePrice != null ? _nf.format(_animal.purchasePrice) : 'N/A'),
            _divider(),
            _infoRow(l.purchaseDate, _animal.purchaseDate != null ? _df.format(_animal.purchaseDate!) : 'N/A'),
          ] else ...[
            _infoRow(l.birthCost, _animal.birthCost != null ? _nf.format(_animal.birthCost) : 'N/A'),
            _divider(),
            _infoRow(l.birthWeight, _animal.birthWeightKg != null ? '${_animal.birthWeightKg} kg' : 'N/A'),
          ],
          _divider(),
          _infoRow(l.estimatedValue, _animal.estimatedValue != null ? _nf.format(_animal.estimatedValue) : 'N/A',
              valueColor: const Color(0xFF16A34A)),
          if (_animal.status == 'sold') ...[
            _divider(),
            _infoRow(l.salePrice, _animal.salePrice != null ? _nf.format(_animal.salePrice) : 'N/A', valueColor: const Color(0xFF1565C0)),
            if (_animal.saleDate != null) ...[_divider(), _infoRow(l.saleDate, _df.format(_animal.saleDate!))],
            if (_animal.buyerName != null) ...[_divider(), _infoRow(l.buyerName, _animal.buyerName!)],
          ],
        ],
      ),
    );
  }

  // ── MEDICAL CARD ─────────────────────────────────────────

  Widget _buildMedicalCard() {
    final l = context.l10n;
    // Vaccins dynamiques depuis VaccineProvider
    final vaccProv = context.watch<VaccineProvider>();
    final liveRecords = vaccProv.records;
    final vaccLoading = vaccProv.isLoading;

    return _sectionCard(
      title: l.medicalHistory,
      icon: Symbols.medical_services,
      color: const Color(0xFF1565C0),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: const Color(0xFFFFEBEE), borderRadius: BorderRadius.circular(12)),
            child: Text(
              '${_animal.diseaseHistoryCount} events',
              style: const TextStyle(fontSize: 11, color: Color(0xFFDC2626), fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () async {
              final added = await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  builder: (_) => MedicalEventFormScreen(
                    animalId: _animal.id,
                    animalName: _animal.name,
                  ),
                ),
              );
              if (added == true && mounted) {
                final updated = await _animalService.getAnimalById(_animal.id);
                setState(() => _animal = updated);
              }
            },
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF1565C0).withAlpha(20),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.add, size: 16, color: Color(0xFF1565C0)),
            ),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // ── Vaccinations — données live depuis VaccineProvider ──
          Row(
            children: [
              _subHeader(l.vaccinations, Icons.vaccines, const Color(0xFF2E7D32)),
              const Spacer(),
              if (vaccLoading)
                const SizedBox(
                  width: 12, height: 12,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF2E7D32)),
                )
              else
                GestureDetector(
                  onTap: () => context.read<VaccineProvider>().loadForAnimal(_animal.id, forceRefresh: true),
                  child: const Icon(Icons.refresh_rounded, size: 14, color: Color(0xFF2E7D32)),
                ),
            ],
          ),
          const SizedBox(height: 8),

          if (vaccLoading && liveRecords.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF2E7D32))),
            )
          else if (liveRecords.isNotEmpty)
            ...liveRecords.map((v) => _vaccineRecordItem(v))
          else
            _emptyMedical(l.noVaccinationsRecorded),

          // ── Upcoming vaccine schedules ──────────────────────
          if (vaccProv.mandatorySchedules.isNotEmpty || vaccProv.overdueSchedules.isNotEmpty) ...[
            const SizedBox(height: 12),
            _subHeader('Upcoming Vaccines', Icons.event_available, const Color(0xFFF59E0B)),
            const SizedBox(height: 8),
            ...vaccProv.overdueSchedules.take(2).map((s) => _scheduleItem(s, isOverdue: true)),
            ...vaccProv.mandatorySchedules
                .where((s) => !s.isOverdue)
                .take(3)
                .map((s) => _scheduleItem(s, isOverdue: false)),
          ],

          // ── Medical Events — données live depuis l'animal rechargé ──
          const SizedBox(height: 16),
          if (_animal.medicalEvents != null && _animal.medicalEvents!.isNotEmpty) ...[
            _subHeader(l.medicalEvents, Symbols.medical_services, const Color(0xFF1565C0)),
            const SizedBox(height: 8),
            ..._animal.medicalEvents!.map((e) => _buildMedicalEventItem(e)),
          ] else ...[
            _emptyMedical('No medical events yet — tap + to add one'),
          ],
        ],
      ),
    );
  }

  Widget _vaccineRecordItem(vms.VaccineRecord v) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: const Color(0xFF2E7D32).withAlpha(20),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.vaccines, size: 14, color: Color(0xFF2E7D32)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  (v.vaccine?.code == 'OTHER' ? v.notes : v.vaccine?.nameEn ?? v.vaccine?.nameFr)
                      ?? v.notes ?? 'Vaccine',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF212121)),
                ),
                if (v.administeredBy.isNotEmpty)
                  Text(
                    'By ${v.administeredBy}${v.doseGiven > 0 ? ' · ${v.doseGiven} ${v.doseUnit}' : ''}',
                    style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                  ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _df.format(v.administeredAt),
                style: const TextStyle(fontSize: 11, color: Color(0xFF9E9E9E)),
              ),
              if (v.nextDueDate != null)
                Text(
                  'Next: ${_df.format(v.nextDueDate!)}',
                  style: TextStyle(
                    fontSize: 10,
                    color: v.nextDueDate!.isBefore(DateTime.now())
                        ? const Color(0xFFDC2626)
                        : const Color(0xFF16A34A),
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _scheduleItem(vms.VaccineSchedule s, {required bool isOverdue}) {
    final color = isOverdue ? const Color(0xFFDC2626) : const Color(0xFFF59E0B);
    final daysLeft = s.daysUntil;
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withAlpha(15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withAlpha(60)),
      ),
      child: Row(
        children: [
          Icon(
            isOverdue ? Icons.warning_amber_rounded : Icons.schedule_rounded,
            size: 14, color: color,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              s.vaccine?.nameEn ?? s.vaccine?.nameFr ?? 'Vaccine',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color),
            ),
          ),
          Text(
            isOverdue
                ? 'Overdue ${-daysLeft}d'
                : daysLeft == 0
                    ? 'Due today'
                    : 'In ${daysLeft}d',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicalEventItem(vms.MedicalEvent e) {
    final color = _eventTypeColor(e.eventType);
    final icon  = _eventTypeIcon(e.eventType);
    return Dismissible(
      key: Key(e.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFDC2626).withAlpha(20),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete_outline, color: Color(0xFFDC2626)),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Delete event?'),
            content: const Text('This action cannot be undone.'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Delete', style: TextStyle(color: Color(0xFFDC2626))),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) async {
        try {
          await MedicalEventService.delete(_animal.id, e.id);
          final updated = await _animalService.getAnimalById(_animal.id);
          if (mounted) setState(() => _animal = updated);
        } catch (err) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error: $err'), backgroundColor: Colors.red),
            );
          }
        }
      },
      child: GestureDetector(
        onTap: () async {
          final updated = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (_) => MedicalEventFormScreen(
                animalId: _animal.id,
                animalName: _animal.name,
                existingEvent: e,
              ),
            ),
          );
          if (updated == true && mounted) {
            final refreshed = await _animalService.getAnimalById(_animal.id);
            setState(() => _animal = refreshed);
          }
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withAlpha(12),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withAlpha(40)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: color.withAlpha(30), shape: BoxShape.circle),
                child: Icon(icon, size: 16, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _eventTypeLabel(e.eventType),
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color),
                    ),
                    if (e.diagnosis != null && e.diagnosis!.isNotEmpty)
                      Text(e.diagnosis!, style: const TextStyle(fontSize: 12, color: Color(0xFF475569)), maxLines: 1, overflow: TextOverflow.ellipsis),
                    if (e.vetName != null && e.vetName!.isNotEmpty)
                      Text(e.vetName!, style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(_df.format(e.eventDate), style: const TextStyle(fontSize: 11, color: Color(0xFF9E9E9E))),
                  if (e.cost != null)
                    Text('${e.cost!.toStringAsFixed(0)} TND', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
                ],
              ),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right, size: 16, color: Color(0xFFCBD5E1)),
            ],
          ),
        ),
      ),
    );
  }

  Color _eventTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'disease':   return const Color(0xFFDC2626);
      case 'surgery':   return const Color(0xFF7B1FA2);
      case 'treatment': return const Color(0xFFE65100);
      case 'checkup':   return const Color(0xFF2E7D32);
      case 'visit':     return const Color(0xFF1565C0);
      default:          return const Color(0xFF546E7A);
    }
  }

  IconData _eventTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'disease':   return Icons.coronavirus;
      case 'surgery':   return Icons.healing;
      case 'treatment': return Icons.medication;
      case 'checkup':   return Icons.fact_check;
      case 'visit':     return Icons.medical_services;
      default:          return Icons.more_horiz;
    }
  }

  String _eventTypeLabel(String type) {
    switch (type.toLowerCase()) {
      case 'disease':   return 'Disease';
      case 'surgery':   return 'Surgery';
      case 'treatment': return 'Treatment';
      case 'checkup':   return 'Checkup';
      case 'visit':     return 'Vet Visit';
      default:          return 'Other';
    }
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
                Text(context.l10n.notes, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFFE65100))),
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
                            ? '${context.l10n.fattening} — ${context.l10n.targetSaleDate}: ${_df.format(_animal.targetSaleDate!)}'
                            : '${context.l10n.fattening} in progress',
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
                // Fattening (only for cow and sheep — seasonal sales)
                if (_animal.status == 'active' &&
                    _animal.isFattening != true &&
                    ['cow', 'sheep'].contains(_animal.animalType.toLowerCase())) ...[
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
                    label: context.l10n.sellAnimal,
                    color: Colors.white,
                    bg: const Color(0xFF16A34A),
                    border: const Color(0xFF16A34A),
                    onTap: () async {
                      final updated = await Navigator.push(context, MaterialPageRoute(builder: (_) => SellAnimalScreen(animal: _animal)));
                      if (updated == true && mounted) Navigator.pop(context, true);
                    },
                    flex: 1,
                  ),
                  const SizedBox(width: 8),
                  _actionBtn(
                    icon: Symbols.heart_broken,
                    label: '',
                    color: Colors.white,
                    bg: const Color(0xFF616161),
                    border: const Color(0xFF616161),
                    onTap: _confirmMarkDeceased,
                    flex: 1,
                  ),
                ],
                const SizedBox(width: 8),
                // Edit
                _actionBtn(
                  icon: Symbols.edit,
                  label: context.l10n.edit,
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
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) Icon(icon, color: color, size: 18),
                if (icon != null && label != null) const SizedBox(width: 5),
                if (label != null)
                  Flexible(
                    child: Text(
                      label,
                      style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flexible(
            flex: 2,
            child: Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF757575), fontWeight: FontWeight.w500)),
          ),
          const SizedBox(width: 8),
          Flexible(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: valueColor ?? _kDark),
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
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

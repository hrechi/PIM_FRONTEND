import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/parcel.dart';
import '../providers/parcel_provider.dart';
import '../services/parcel_crud_service.dart';
import 'add_parcel_screen.dart';

// ─────────────────────────────────────────────────────────────
// COLOR CONSTANTS (local)
// ─────────────────────────────────────────────────────────────
const _kGreen1 = Color(0xFF1A4731);
const _kGreen2 = Color(0xFF2ECC71);
const _kGreen3 = Color(0xFFE8F8EF);
const _kBg = Color(0xFFF2F5F0);
const _kCard = Colors.white;

class ParcelDetailScreen extends StatefulWidget {
  final Parcel parcel;
  const ParcelDetailScreen({super.key, required this.parcel});

  @override
  State<ParcelDetailScreen> createState() => _ParcelDetailScreenState();
}

class _ParcelDetailScreenState extends State<ParcelDetailScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoadingAi = false;
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  // ─── AI Advice ───────────────────────────────────
  Future<void> _showAiAdvice(Parcel parcel) async {
    setState(() => _isLoadingAi = true);
    String advice = '';
    try {
      advice = await ParcelCrudService().getAiAdvice(parcel.id);
    } catch (e) {
      advice = 'Error fetching advice: $e';
    } finally {
      setState(() => _isLoadingAi = false);
    }
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          _AiAdviceSheet(advice: advice, parcelName: parcel.location),
    );
  }

  // ─── Delete ──────────────────────────────────────
  Future<void> _deleteParcel() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(children: [
          Icon(Icons.warning_amber_rounded, color: Colors.red),
          SizedBox(width: 8),
          Text('Delete Parcel'),
        ]),
        content: const Text(
            'This will permanently delete the parcel and all its data. Are you sure?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    try {
      await Provider.of<ParcelProvider>(context, listen: false)
          .deleteParcel(widget.parcel.id);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Parcel deleted')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  // ─── Add Crop Dialog ─────────────────────────────
  Future<void> _showAddCropDialog() async {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController();
    final varietyCtrl = TextEditingController();
    DateTime? plantingDate;
    DateTime? harvestDate;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSB) => _StyledDialog(
          title: '🌱 Add Crop',
          formKey: formKey,
          onSave: () async {
            if (formKey.currentState!.validate() &&
                plantingDate != null &&
                harvestDate != null) {
              Navigator.pop(ctx);
              await Provider.of<ParcelProvider>(context, listen: false)
                  .addCropToParcel(widget.parcel.id, {
                'cropName': nameCtrl.text,
                'variety': varietyCtrl.text,
                'plantingDate': plantingDate!.toIso8601String(),
                'expectedHarvestDate': harvestDate!.toIso8601String(),
              });
            }
          },
          fields: [
            _inputField(nameCtrl, 'Crop Name', Icons.eco, required: true),
            _inputField(varietyCtrl, 'Variety', Icons.category,
                required: true),
            _dateTile('Planting Date *', plantingDate, (d) => setSB(() => plantingDate = d), ctx),
            _dateTile('Expected Harvest *', harvestDate, (d) => setSB(() => harvestDate = d), ctx),
          ],
        ),
      ),
    );
  }

  // ─── Add Fertilization Dialog ────────────────────
  Future<void> _showAddFertilizationDialog() async {
    final formKey = GlobalKey<FormState>();
    final typeCtrl = TextEditingController();
    final qtyCtrl = TextEditingController();
    DateTime? appDate;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSB) => _StyledDialog(
          title: '🧪 Add Fertilization',
          formKey: formKey,
          onSave: () async {
            if (formKey.currentState!.validate() && appDate != null) {
              Navigator.pop(ctx);
              await Provider.of<ParcelProvider>(context, listen: false)
                  .addFertilizationToParcel(widget.parcel.id, {
                'fertilizerType': typeCtrl.text,
                'quantityUsed': double.parse(qtyCtrl.text),
                'applicationDate': appDate!.toIso8601String(),
              });
            }
          },
          fields: [
            _inputField(typeCtrl, 'Fertilizer Type', Icons.science,
                required: true),
            _inputField(qtyCtrl, 'Quantity (units)', Icons.numbers,
                required: true, isNumber: true),
            _dateTile('Application Date *', appDate, (d) => setSB(() => appDate = d), ctx),
          ],
        ),
      ),
    );
  }

  // ─── Add Pest Dialog ─────────────────────────────
  Future<void> _showAddPestDialog() async {
    final formKey = GlobalKey<FormState>();
    final issueCtrl = TextEditingController();
    final treatmentCtrl = TextEditingController();
    DateTime? treatDate;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSB) => _StyledDialog(
          title: '🐛 Add Pest / Disease',
          formKey: formKey,
          onSave: () async {
            Navigator.pop(ctx);
            await Provider.of<ParcelProvider>(context, listen: false)
                .addPestToParcel(widget.parcel.id, {
              if (issueCtrl.text.isNotEmpty) 'issueType': issueCtrl.text,
              if (treatmentCtrl.text.isNotEmpty)
                'treatmentUsed': treatmentCtrl.text,
              if (treatDate != null)
                'treatmentDate': treatDate!.toIso8601String(),
            });
          },
          fields: [
            _inputField(issueCtrl, 'Issue Type (optional)', Icons.bug_report),
            _inputField(treatmentCtrl, 'Treatment Used (optional)',
                Icons.medical_services),
            _dateTile('Treatment Date (optional)', treatDate,
                (d) => setSB(() => treatDate = d), ctx,
                optional: true),
          ],
        ),
      ),
    );
  }

  // ─── Add Harvest Dialog ──────────────────────────
  Future<void> _showAddHarvestDialog() async {
    final formKey = GlobalKey<FormState>();
    final totalCtrl = TextEditingController();
    final yieldCtrl = TextEditingController();
    DateTime? harvestDate;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSB) => _StyledDialog(
          title: '🌾 Record Harvest',
          formKey: formKey,
          onSave: () async {
            Navigator.pop(ctx);
            await Provider.of<ParcelProvider>(context, listen: false)
                .addHarvestToParcel(widget.parcel.id, {
              if (totalCtrl.text.isNotEmpty)
                'totalYield': double.parse(totalCtrl.text),
              if (yieldCtrl.text.isNotEmpty)
                'yieldPerHectare': double.parse(yieldCtrl.text),
              if (harvestDate != null)
                'harvestDate': harvestDate!.toIso8601String(),
            });
          },
          fields: [
            _inputField(totalCtrl, 'Total Yield (optional)', Icons.scale,
                isNumber: true),
            _inputField(yieldCtrl, 'Yield Per Hectare (optional)',
                Icons.area_chart,
                isNumber: true),
            _dateTile('Harvest Date (optional)', harvestDate,
                (d) => setSB(() => harvestDate = d), ctx,
                optional: true),
          ],
        ),
      ),
    );
  }

  // ─── Helpers ─────────────────────────────────────
  TextFormField _inputField(
      TextEditingController ctrl, String label, IconData icon,
      {bool required = false, bool isNumber = false}) {
    return TextFormField(
      controller: ctrl,
      keyboardType: isNumber
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: _kGreen2, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      ),
      validator: required
          ? (v) => v == null || v.isEmpty ? 'Required' : null
          : null,
    );
  }

  Widget _dateTile(String label, DateTime? date, ValueChanged<DateTime> onPick,
      BuildContext ctx,
      {bool optional = false}) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () async {
        final d = await showDatePicker(
            context: ctx,
            initialDate: DateTime.now(),
            firstDate: DateTime(2000),
            lastDate: DateTime(2100));
        if (d != null) onPick(d);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade400),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(children: [
          Icon(Icons.calendar_today, color: _kGreen2, size: 20),
          const SizedBox(width: 12),
          Text(
            date == null ? label : DateFormat.yMMMd().format(date),
            style: TextStyle(
                color: date == null ? Colors.grey.shade600 : _kGreen1,
                fontSize: 14),
          ),
        ]),
      ),
    );
  }

  // ─── BUILD ───────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ParcelProvider>(context);
    if (provider.isLoading) {
      return const Scaffold(
          body: Center(
              child: CircularProgressIndicator(color: _kGreen2)));
    }
    final p = provider.parcels.firstWhere(
        (x) => x.id == widget.parcel.id,
        orElse: () => widget.parcel);

    return Scaffold(
      backgroundColor: _kBg,
      body: CustomScrollView(
        slivers: [
          _buildHeroAppBar(p),
          SliverToBoxAdapter(child: _buildAiBanner(p)),
          SliverToBoxAdapter(child: _buildInfoCard(p)),
          SliverToBoxAdapter(
            child: _buildTabBar(),
          ),
          SliverToBoxAdapter(child: _buildTabContent(p)),
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }

  // ─── HERO APPBAR ─────────────────────────────────
  Widget _buildHeroAppBar(Parcel p) {
    return SliverAppBar(
      expandedHeight: 220,
      pinned: true,
      stretch: true,
      backgroundColor: _kGreen1,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.edit_rounded, color: Colors.white),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => AddParcelScreen(existingParcel: p)),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.delete_outline_rounded,
              color: Colors.redAccent),
          onPressed: _deleteParcel,
        ),
        const SizedBox(width: 8),
      ],
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [StretchMode.zoomBackground],
        background: Stack(fit: StackFit.expand, children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0D3320), _kGreen1, Color(0xFF27AE60)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          // decorative circles
          Positioned(
            right: -50, top: -50,
            child: Container(
              width: 220, height: 220,
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.05)),
            ),
          ),
          Positioned(
            left: -30, bottom: 10,
            child: Container(
              width: 130, height: 130,
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.04)),
            ),
          ),
          // Content
          Positioned(
            bottom: 20, left: 20, right: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Text('🌿',
                        style: TextStyle(fontSize: 26)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      p.location,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ]),
                const SizedBox(height: 12),
                // stat pills
                Row(children: [
                  _heroPill(
                      '${p.areaSize} ha', Icons.square_foot_rounded),
                  const SizedBox(width: 8),
                  _heroPill(p.soilType, Icons.terrain),
                  const SizedBox(width: 8),
                  _heroPill(p.irrigationMethod, Icons.water_drop),
                ]),
              ],
            ),
          ),
        ]),
        title: Text(p.location,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16)),
        titlePadding:
            const EdgeInsets.symmetric(horizontal: 60, vertical: 16),
      ),
    );
  }

  Widget _heroPill(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: Colors.white, size: 13),
        const SizedBox(width: 4),
        Text(label,
            style:
                const TextStyle(color: Colors.white, fontSize: 12)),
      ]),
    );
  }

  // ─── AI BANNER ───────────────────────────────────
  Widget _buildAiBanner(Parcel p) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1A4731), Color(0xFF2ECC71)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color: _kGreen2.withValues(alpha: 0.35),
                blurRadius: 18,
                offset: const Offset(0, 6)),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: _isLoadingAi ? null : () => _showAiAdvice(p),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(children: [
                // icon circle
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                      child: Text('🤖',
                          style: TextStyle(fontSize: 30))),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('AI Agronomist',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(
                        'Get personalized farm recommendations',
                        style: TextStyle(
                            color:
                                Colors.white.withValues(alpha: 0.8),
                            fontSize: 13),
                      ),
                    ],
                  ),
                ),
                if (_isLoadingAi)
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2.5),
                  )
                else
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle),
                    child: const Icon(Icons.auto_awesome,
                        color: Colors.white, size: 22),
                  ),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  // ─── INFO CARD ───────────────────────────────────
  Widget _buildInfoCard(Parcel p) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 16,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Section title
        _sectionHeader('📋 Parcel Info'),
        const SizedBox(height: 12),
        // 2-col grid of stats
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          childAspectRatio: 2.8,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          children: [
            _infoChip(Icons.square_foot, 'Area', '${p.areaSize} ha'),
            _infoChip(Icons.terrain, 'Soil', p.soilType),
            _infoChip(Icons.science, 'pH',
                p.soilPh != null ? '${p.soilPh}' : 'N/A'),
            _infoChip(Icons.water_drop, 'Water', p.waterSource),
            _infoChip(Icons.shower, 'Irrigation', p.irrigationMethod),
            _infoChip(Icons.schedule, 'Frequency', p.irrigationFrequency),
          ],
        ),
        if (p.nitrogenLevel != null ||
            p.phosphorusLevel != null ||
            p.potassiumLevel != null) ...[
          const SizedBox(height: 14),
          _sectionHeader('🧪 Soil Nutrients (NPK)'),
          const SizedBox(height: 10),
          Row(children: [
            _npkBar('N', p.nitrogenLevel, const Color(0xFF3498DB)),
            const SizedBox(width: 8),
            _npkBar('P', p.phosphorusLevel, const Color(0xFFE74C3C)),
            const SizedBox(width: 8),
            _npkBar('K', p.potassiumLevel, const Color(0xFFE67E22)),
          ]),
        ],
      ]),
    );
  }

  Widget _infoChip(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _kGreen3,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(children: [
        Icon(icon, color: _kGreen2, size: 16),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(label,
                  style:
                      TextStyle(fontSize: 10, color: Colors.grey.shade600)),
              Text(value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _kGreen1)),
            ],
          ),
        ),
      ]),
    );
  }

  Widget _npkBar(String label, double? value, Color color) {
    final pct = ((value ?? 0).clamp(0, 100)) / 100;
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label,
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: color,
                      fontSize: 13)),
              Text(value != null ? '$value' : '-',
                  style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: pct.toDouble(),
              backgroundColor: color.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  // ─── TABS ────────────────────────────────────────
  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 2)),
        ],
      ),
      child: TabBar(
        controller: _tabCtrl,
        labelColor: _kGreen1,
        unselectedLabelColor: Colors.grey,
        indicatorColor: _kGreen2,
        indicatorSize: TabBarIndicatorSize.label,
        labelStyle:
            const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
        tabs: const [
          Tab(text: '🌱 Crops'),
          Tab(text: '🧪 Fert.'),
          Tab(text: '🐛 Pests'),
          Tab(text: '🌾 Harvest'),
        ],
      ),
    );
  }

  Widget _buildTabContent(Parcel p) {
    return SizedBox(
      height: 340,
      child: TabBarView(
        controller: _tabCtrl,
        children: [
          _tabSection(p.crops, _showAddCropDialog, '🌱', 'No crops yet',
              (c) => c.cropName,
              (c) =>
                  '${c.variety} • Planted ${DateFormat.yMMMd().format(c.plantingDate)}'),
          _tabSection(p.fertilizations, _showAddFertilizationDialog, '🧪',
              'No fertilizations',
              (f) => f.fertilizerType,
              (f) =>
                  '${f.quantityUsed} units • ${DateFormat.yMMMd().format(f.applicationDate)}'),
          _tabSection(p.pests, _showAddPestDialog, '🐛', 'No pest records',
              (d) => d.issueType ?? 'Unknown Issue',
              (d) => d.treatmentUsed ?? 'No treatment recorded'),
          _tabSection(p.harvests, _showAddHarvestDialog, '🌾', 'No harvests',
              (h) =>
                  h.harvestDate != null
                      ? DateFormat.yMMMd().format(h.harvestDate!)
                      : 'Unknown date',
              (h) =>
                  'Yield: ${h.totalYield ?? "?"} | Per Ha: ${h.yieldPerHectare ?? "?"}'),
        ],
      ),
    );
  }

  Widget _tabSection<T>(
    List<T> items,
    VoidCallback onAdd,
    String emoji,
    String emptyLabel,
    String Function(T) title,
    String Function(T) subtitle,
  ) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(children: [
        // Add button row
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 12, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('$emoji ${items.length} records',
                  style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: _kGreen1)),
              TextButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add_circle_outline, size: 18),
                label: const Text('Add'),
                style: TextButton.styleFrom(foregroundColor: _kGreen2),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        if (items.isEmpty)
          Padding(
            padding: const EdgeInsets.all(32),
            child: Column(children: [
              Text(emoji, style: const TextStyle(fontSize: 36)),
              const SizedBox(height: 8),
              Text(emptyLabel,
                  style: TextStyle(color: Colors.grey.shade500)),
            ]),
          )
        else
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 4),
              itemCount: items.length,
              separatorBuilder: (_, _a) =>
                  const Divider(height: 1, indent: 16),
              itemBuilder: (_, i) {
                final item = items[i];
                return ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _kGreen3,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                        child: Text(emoji,
                            style: const TextStyle(fontSize: 18))),
                  ),
                  title: Text(title(item),
                      style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: _kGreen1)),
                  subtitle: Text(subtitle(item),
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey.shade600)),
                );
              },
            ),
          ),
      ]),
    );
  }

  // ─── Helpers ─────────────────────────────────────
  Widget _sectionHeader(String title) {
    return Text(title,
        style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: _kGreen1));
  }
}

// ─────────────────────────────────────────────────────────────
// STYLED DIALOG
// ─────────────────────────────────────────────────────────────
class _StyledDialog extends StatelessWidget {
  final String title;
  final GlobalKey<FormState> formKey;
  final VoidCallback onSave;
  final List<Widget> fields;

  const _StyledDialog({
    required this.title,
    required this.formKey,
    required this.onSave,
    required this.fields,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _kGreen1)),
                const SizedBox(height: 16),
                ...fields
                    .expand((w) => [w, const SizedBox(height: 12)]),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel')),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: onSave,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _kGreen2,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Save'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// AI ADVICE BOTTOM SHEET
// ─────────────────────────────────────────────────────────────
class _AiAdviceSheet extends StatelessWidget {
  final String advice;
  final String parcelName;
  const _AiAdviceSheet({required this.advice, required this.parcelName});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      minChildSize: 0.5,
      maxChildSize: 0.96,
      builder: (_, ctrl) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 44, height: 4,
            decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2)),
          ),

          // Header card
          Container(
            margin: const EdgeInsets.fromLTRB(20, 4, 20, 0),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1A4731), Color(0xFF2ECC71)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                    color: _kGreen2.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4)),
              ],
            ),
            child: Row(children: [
              Container(
                width: 52, height: 52,
                decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle),
                child: const Center(
                    child: Text('🤖', style: TextStyle(fontSize: 26))),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('AI Agronomist',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 3),
                    Text(parcelName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 13)),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ]),
          ),

          const SizedBox(height: 8),

          // Sub-pills
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: Row(children: [
              _pill('🌱 Soil', const Color(0xFFE8F8EF),
                  const Color(0xFF27AE60)),
              const SizedBox(width: 8),
              _pill('💧 Irrigation', const Color(0xFFEBF5FD),
                  const Color(0xFF2980B9)),
              const SizedBox(width: 8),
              _pill('🌾 Yield', const Color(0xFFFEF9EC),
                  const Color(0xFFF39C12)),
            ]),
          ),

          const Divider(height: 16),

          // Content
          Expanded(
            child: SingleChildScrollView(
              controller: ctrl,
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FFF9),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                      color: _kGreen2.withValues(alpha: 0.25)),
                ),
                child: SelectableText(
                  advice,
                  style: const TextStyle(
                      fontSize: 15, height: 1.7, color: Color(0xFF1A2E1A)),
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _pill(String label, Color bg, Color fg) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 7),
        decoration:
            BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
        child: Text(label,
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.w700, color: fg)),
      ),
    );
  }
}

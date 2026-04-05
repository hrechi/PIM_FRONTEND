import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/parcel.dart';
import '../models/soil_measurement.dart';
import '../providers/parcel_provider.dart';
import '../providers/weather_provider.dart';
import '../services/soil_repository.dart';
import '../theme/color_palette.dart';
import '../theme/text_styles.dart';
import '../widgets/soil/status_badge.dart';
import 'add_parcel_screen.dart';
import 'parcel_detail_screen.dart';
import '../widgets/app_drawer.dart';

class ParcelListScreen extends StatefulWidget {
  const ParcelListScreen({super.key});

  @override
  State<ParcelListScreen> createState() => _ParcelListScreenState();
}

class _ParcelListScreenState extends State<ParcelListScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  List<Parcel> _dedupeParcels(List<Parcel> parcels) {
    final seen = <String>{};
    final unique = <Parcel>[];
    for (final parcel in parcels) {
      if (seen.add(parcel.id)) {
        unique.add(parcel);
      }
    }
    return unique;
  }

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ParcelProvider>(context, listen: false).fetchParcels();
    });
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final prov = Provider.of<ParcelProvider>(context);
    final displayParcels = _dedupeParcels(prov.parcels);

    return Scaffold(
      backgroundColor: AppColorPalette.wheatWarmClay,
      drawer: const AppDrawer(),
      body: CustomScrollView(
        slivers: [
          _buildHeroAppBar(displayParcels),
          SliverToBoxAdapter(child: _buildQuickStats(displayParcels)),
          if (prov.isLoading)
            const SliverFillRemaining(
                child: Center(
                    child: CircularProgressIndicator(
                  color: Color(0xFF2ECC71))))
          else if (prov.error != null)
            SliverFillRemaining(child: _buildErrorView(prov))
          else if (displayParcels.isEmpty)
            SliverFillRemaining(child: _buildEmptyState())
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) => FadeTransition(
                    opacity: _fadeAnim,
                    child: _ParcelCard(
                      parcel: displayParcels[i],
                      index: i,
                      onTap: () => Navigator.push(ctx,
                          MaterialPageRoute(
                              builder: (_) =>
                                  ParcelDetailScreen(parcel: displayParcels[i]))),
                    ),
                  ),
                  childCount: displayParcels.length,
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: _buildFab(context),
    );
  }

  Widget _buildHeroAppBar(List<Parcel> parcels) {
    return SliverAppBar(
      pinned: true,
      toolbarHeight: 72,
      backgroundColor: AppColorPalette.wheatWarmClay,
      surfaceTintColor: Colors.transparent,
      leading: Builder(
        builder: (context) => IconButton(
          icon: const Icon(Icons.menu_rounded),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('My Parcels', style: AppTextStyles.h3()),
          Text(
            '${parcels.length} parcel${parcels.length == 1 ? '' : 's'} registered',
            style: AppTextStyles.caption(color: AppColorPalette.softSlate),
          ),
        ],
      ),
      actions: [
        IconButton(
          onPressed: () => context.read<ParcelProvider>().fetchParcels(),
          icon: const Icon(Icons.refresh_rounded),
          tooltip: 'Refresh',
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildQuickStats(List<Parcel> parcels) {
    final totalArea =
        parcels.fold<double>(0, (sum, p) => sum + p.areaSize);
    final totalCrops =
        parcels.fold<int>(0, (sum, p) => sum + p.crops.length);
    final totalHarvests =
        parcels.fold<int>(0, (sum, p) => sum + p.harvests.length);

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          _statCol('🗺️', totalArea.toStringAsFixed(1), 'Total ha'),
          _divider(),
          _statCol('🌱', '$totalCrops', 'Crops'),
          _divider(),
          _statCol('🌾', '$totalHarvests', 'Harvests'),
          _divider(),
          _statCol('📋', '${parcels.length}', 'Parcels'),
        ],
      ),
    );
  }

  Widget _statCol(String emoji, String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 4),
          Text(value,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                color: Color(0xFF2C3E50))),
          Text(label,
              style: const TextStyle(fontSize: 11, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _divider() {
    return Container(width: 1, height: 40, color: Colors.grey.shade200);
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF2ECC71).withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Text('🌾', style: TextStyle(fontSize: 56)),
          ),
          const SizedBox(height: 20),
          const Text('No parcels yet',
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50))),
          const SizedBox(height: 8),
          Text('Tap + to add your first parcel',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
        ],
      ),
    );
  }

  Widget _buildErrorView(ParcelProvider prov) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.wifi_off_rounded, size: 48, color: Colors.grey),
          const SizedBox(height: 12),
          const Text('Failed to load parcels',
              style:
                  TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () => prov.fetchParcels(),
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildFab(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: () => Navigator.push(
          context, MaterialPageRoute(builder: (_) => const AddParcelScreen())),
      icon: const Icon(Icons.add),
      label: const Text('Add Parcel'),
      backgroundColor: const Color(0xFF2ECC71),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// PARCEL CARD
// ─────────────────────────────────────────────────────────────
class _ParcelCard extends StatefulWidget {
  final Parcel parcel;
  final int index;
  final VoidCallback onTap;

  const _ParcelCard(
      {required this.parcel, required this.index, required this.onTap});

  @override
  State<_ParcelCard> createState() => _ParcelCardState();
}

class _ParcelCardState extends State<_ParcelCard> {
  late Future<SoilMeasurement?> _latestSoilFuture;
  final SoilRepository _soilRepository = SoilRepository();

  String _displayParcelTitle() {
    final rawLocation = widget.parcel.location.trim();
    final locationMatch = RegExp(r'^location\s*\((.+)\)$', caseSensitive: false)
        .firstMatch(rawLocation);
    if (locationMatch != null) {
      final parsed = (locationMatch.group(1) ?? '').trim();
      if (parsed.isNotEmpty) {
        return parsed;
      }
    }

    if (!rawLocation.toLowerCase().startsWith('location')) {
      return rawLocation;
    }

    final selectedFieldName = context.read<WeatherProvider>().selectedField?.name;
    if (selectedFieldName != null && selectedFieldName.trim().isNotEmpty) {
      return selectedFieldName.trim();
    }

    return rawLocation;
  }

  @override
  void initState() {
    super.initState();
    _latestSoilFuture =
        _soilRepository.getLatestMeasurementByParcelId(widget.parcel.id);
  }

  Color get _cardAccent {
    final colors = [
      const Color(0xFF2ECC71),
      const Color(0xFF27AE60),
      const Color(0xFF1F8F4C),
      const Color(0xFF6FCF97),
      const Color(0xFF145A32),
    ];
    return colors[widget.index % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final displayTitle = _displayParcelTitle();
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: widget.onTap,
          child: Column(
            children: [
              // Color bar top
              Container(
                height: 6,
                decoration: BoxDecoration(
                  color: _cardAccent,
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        // Icon
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: _cardAccent.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Center(
                            child: Text('🌿', style: TextStyle(fontSize: 26)),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                displayTitle,
                                style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1A2E1A)),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 3),
                              Row(
                                children: [
                                  Icon(Icons.straighten,
                                      size: 13, color: Colors.grey.shade500),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${widget.parcel.areaSize} ha  •  ${widget.parcel.soilType}',
                                    style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey.shade600),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF4F6F0),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.arrow_forward_ios_rounded,
                              size: 14, color: Color(0xFF1A4731)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    // Chips row with soil status
                    _buildChipsWithSoilStatus(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build chips row including soil status badge
  Widget _buildChipsWithSoilStatus() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top row with standard chips
        SizedBox(
          height: 32,
          child: Row(
            children: [
              _chip('🌱 ${widget.parcel.crops.length} Crops',
                  const Color(0xFFE8F8EF), const Color(0xFF27AE60)),
              const SizedBox(width: 8),
              _chip('💧 ${widget.parcel.irrigationMethod}',
                  const Color(0xFFEAF7F0), const Color(0xFF1F8F4C)),
              const SizedBox(width: 8),
              _chip('🌾 ${widget.parcel.harvests.length} Harvests',
                  const Color(0xFFE3F5EA), const Color(0xFF145A32)),
            ],
          ),
        ),
        const SizedBox(height: 10),
        // Soil status badge
        FutureBuilder<SoilMeasurement?>(
          future: _latestSoilFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2ECC71)),
                ),
              );
            }

            if (snapshot.hasData && snapshot.data != null) {
              final soilMeasurement = snapshot.data!;
              return SizedBox(
                height: 24,
                child: Row(
                  children: [
                    const Icon(Icons.science,
                        size: 16, color: Color(0xFF1A4731)),
                    const SizedBox(width: 6),
                    StatusBadge.health(
                      isHealthy: soilMeasurement.isHealthy,
                      compact: true,
                    ),
                  ],
                ),
              );
            }

            // No soil data
            return SizedBox(
              height: 24,
              child: Row(
                children: [
                  const Icon(Icons.science,
                      size: 16, color: Colors.grey),
                  const SizedBox(width: 6),
                  Text(
                    'No soil data',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _chip(String label, Color bg, Color fg) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style:
              TextStyle(fontSize: 11, color: fg, fontWeight: FontWeight.w600),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

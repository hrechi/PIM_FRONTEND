import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/parcel.dart';
import '../providers/parcel_provider.dart';
import 'add_parcel_screen.dart';
import 'parcel_detail_screen.dart';

class ParcelListScreen extends StatefulWidget {
  const ParcelListScreen({super.key});

  @override
  State<ParcelListScreen> createState() => _ParcelListScreenState();
}

class _ParcelListScreenState extends State<ParcelListScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

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

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F0),
      body: CustomScrollView(
        slivers: [
          _buildHeroAppBar(prov.parcels),
          SliverToBoxAdapter(child: _buildQuickStats(prov.parcels)),
          if (prov.isLoading)
            const SliverFillRemaining(
                child: Center(
                    child: CircularProgressIndicator(
                        color: Color(0xFF2ECC71))))
          else if (prov.error != null)
            SliverFillRemaining(child: _buildErrorView(prov))
          else if (prov.parcels.isEmpty)
            SliverFillRemaining(child: _buildEmptyState())
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) => FadeTransition(
                    opacity: _fadeAnim,
                    child: _ParcelCard(
                      parcel: prov.parcels[i],
                      index: i,
                      onTap: () => Navigator.push(ctx,
                          MaterialPageRoute(
                              builder: (_) =>
                                  ParcelDetailScreen(parcel: prov.parcels[i]))),
                    ),
                  ),
                  childCount: prov.parcels.length,
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
      expandedHeight: 200,
      pinned: true,
      stretch: true,
      backgroundColor: const Color(0xFF1A4731),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [StretchMode.zoomBackground],
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Background
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1A4731), Color(0xFF2ECC71)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            // Decorative circles
            Positioned(
              right: -40, top: -40,
              child: Container(
                width: 200, height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.06),
                ),
              ),
            ),
            Positioned(
              left: -30, bottom: -30,
              child: Container(
                width: 150, height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.05),
                ),
              ),
            ),
            // Text
            Positioned(
              bottom: 20, left: 24,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(children: [
                    const Text('🌾', style: TextStyle(fontSize: 28)),
                    const SizedBox(width: 10),
                    const Text('My Parcels',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                        )),
                  ]),
                  const SizedBox(height: 4),
                  Text(
                    '${parcels.length} parcel${parcels.length == 1 ? '' : 's'} registered',
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
        title: const Text('My Parcels',
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
        titlePadding:
            const EdgeInsets.symmetric(horizontal: 60, vertical: 16),
      ),
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
                  color: Color(0xFF1A4731))),
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
              color: const Color(0xFF2ECC71).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Text('🌾', style: TextStyle(fontSize: 56)),
          ),
          const SizedBox(height: 20),
          const Text('No parcels yet',
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A4731))),
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
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2ECC71), Color(0xFF1A8A45)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: const Color(0xFF2ECC71).withValues(alpha: 0.4),
              blurRadius: 16,
              offset: const Offset(0, 6)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const AddParcelScreen())),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add_rounded, color: Colors.white, size: 22),
                SizedBox(width: 8),
                Text('Add Parcel',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// PARCEL CARD
// ─────────────────────────────────────────────────────────────
class _ParcelCard extends StatelessWidget {
  final Parcel parcel;
  final int index;
  final VoidCallback onTap;

  const _ParcelCard(
      {required this.parcel, required this.index, required this.onTap});

  Color get _cardAccent {
    final colors = [
      const Color(0xFF2ECC71),
      const Color(0xFF3498DB),
      const Color(0xFFE67E22),
      const Color(0xFF9B59B6),
      const Color(0xFF1ABC9C),
    ];
    return colors[index % colors.length];
  }

  @override
  Widget build(BuildContext context) {
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
          onTap: onTap,
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
                                parcel.location,
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
                                    '${parcel.areaSize} ha  •  ${parcel.soilType}',
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
                    // Chips row
                    Row(
                      children: [
                        _chip('🌱 ${parcel.crops.length} Crops',
                            const Color(0xFFE8F8EF), const Color(0xFF27AE60)),
                        const SizedBox(width: 8),
                        _chip('💧 ${parcel.irrigationMethod}',
                            const Color(0xFFEBF5FD), const Color(0xFF2980B9)),
                        const SizedBox(width: 8),
                        _chip('🌾 ${parcel.harvests.length} Harvests',
                            const Color(0xFFFEF9EC), const Color(0xFFF39C12)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
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

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../theme/color_palette.dart';
import '../theme/text_styles.dart';

// Top-level / Account
import '../screens/home_screen.dart';
import '../widgets/rating_dialog.dart';
import '../screens/farmer_home_screen_v2.dart';
import '../screens/profile_screen.dart';
import '../screens/signin_screen.dart';

// Farm
import '../screens/parcel_list_screen.dart';
import '../screens/soil/soil_measurements_list_screen.dart';
import '../screens/plant_doctor_screen.dart';
import '../screens/harvest_analytics_screen.dart';
import '../screens/aerotwin_screen.dart';
import '../screens/crop_calendar_screen.dart';
import '../screens/weather_screen.dart';
import '../screens/irrigation_scheduler_screen.dart';
import '../screens/agricultural_news_screen.dart';
import '../screens/shorts_screen.dart';
import '../screens/community_feed_screen.dart';
import '../screens/farm_quiz_screen.dart';

// Animals
import '../screens/animals/animal_list_screen.dart';
import '../screens/animals/add_animal_screen.dart';
import '../screens/animals/planned_sales_screen.dart';
import '../screens/animals/milk_production_screen.dart';
import '../screens/animals/milk_analytics_screen.dart';

// Health
import '../screens/vaccines/vaccine_dashboard_screen.dart';

// Finance & Catalogue
import '../screens/finance/finance_dashboard_screen.dart';
import '../screens/catalogue/catalogue_list_screen.dart';

// Security
import '../screens/staff_list_screen.dart';
import '../screens/add_staff_screen.dart';
import '../screens/security/incident_history_screen.dart';
import '../screens/live_feed_screen.dart';
import '../screens/security/daily_report_screen.dart';
import '../screens/security/acoustic_monitor_screen.dart';

// ─────────────────────────────────────────────────────────────────────────
//  Models
// ─────────────────────────────────────────────────────────────────────────

class _DrawerItem {
  final IconData icon;
  final String title;
  final WidgetBuilder? builder;
  final String? routeName;

  const _DrawerItem({
    required this.icon,
    required this.title,
    this.builder,
    this.routeName,
  });
}

class _DrawerCategory {
  final IconData icon;
  final String title;
  final List<_DrawerItem> items;

  const _DrawerCategory({
    required this.icon,
    required this.title,
    required this.items,
  });
}

class _DrawerGroup {
  final String label; // e.g. "General", "Profile"
  final List<_DrawerCategory> categories;
  final List<_DrawerItem> flatItems;

  const _DrawerGroup({
    required this.label,
    this.categories = const [],
    this.flatItems = const [],
  });
}

// ─────────────────────────────────────────────────────────────────────────
//  Drawer
// ─────────────────────────────────────────────────────────────────────────

/// Unified application drawer.
///
/// • Curved gradient header with avatar / name / tagline.
/// • Section labels (no harsh dividers) — categories collapse so children
///   only appear after a tap.
/// • Staggered slide-in animation each time the drawer opens.
class AppDrawer extends StatefulWidget {
  const AppDrawer({super.key});

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  static const _bgColor = Color(0xFFFAFAF7);
  static const _hairline = Color(0xFFEEEAE2);
  static const _muted = Color(0xFF9AA0A6);
  static const _ink = Color(0xFF1F2933);
  static const _selectedFill = Color(0xFFF4EFE7);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1900),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final role = user?.role.toUpperCase() ?? 'OWNER';
    final isWorker = role == 'WORKER';

    final groups = isWorker ? _workerGroups() : _ownerGroups();

    final mediaWidth = MediaQuery.of(context).size.width;
    final drawerWidth = mediaWidth * 0.84;

    return Drawer(
      backgroundColor: _bgColor,
      elevation: 24,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      width: drawerWidth.clamp(280, 360),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(
              context,
              displayName: user?.name ?? (isWorker ? 'Worker' : 'Farmer'),
              tagline: isWorker
                  ? 'Material operations'
                  : ((user?.farmName.isNotEmpty ?? false)
                      ? user!.farmName
                      : 'Smart Farm System'),
              avatar: user?.profilePicture,
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                children: [
                  for (var g = 0; g < groups.length; g++) ...[
                    _animatedRow(
                      index: g * 5,
                      child: _sectionLabel(groups[g].label),
                    ),
                    for (var i = 0;
                        i < groups[g].categories.length;
                        i++)
                      _animatedRow(
                        index: g * 5 + i + 1,
                        child: _CollapsibleCategory(
                          category: groups[g].categories[i],
                          onItemTap: (item) => _navigate(item),
                          ink: _ink,
                          muted: _muted,
                          selectedFill: _selectedFill,
                        ),
                      ),
                    for (var i = 0; i < groups[g].flatItems.length; i++)
                      _animatedRow(
                        index: g * 5 + groups[g].categories.length + i + 1,
                        child: _LeafTile(
                          item: groups[g].flatItems[i],
                          onTap: () => _navigate(groups[g].flatItems[i]),
                          ink: _ink,
                          muted: _muted,
                          danger: groups[g].flatItems[i].title == 'Sign Out',
                        ),
                      ),
                    if (g != groups.length - 1)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Container(height: 1, color: _hairline),
                      ),
                  ],
                  const SizedBox(height: 16),
                  _animatedRow(
                    index: 30,
                    child: _SignOutTile(onTap: () => _signOut(context)),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
            _buildFooter(context),
          ],
        ),
      ),
    );
  }

  // ───────────────────────────── Helpers ───────────────────────────────────

  String _resolveAvatarUrl(String raw) {
    if (raw.startsWith('http://') || raw.startsWith('https://')) return raw;
    final base = ApiService.mediaBaseUrl;
    return raw.startsWith('/') ? '$base$raw' : '$base/$raw';
  }

  // ───────────────────────────── Animation helpers ─────────────────────────

  Widget _animatedRow({required int index, required Widget child}) {
    // Slower stagger so each row's bounce is clearly visible.
    final start = (0.15 + index * 0.06).clamp(0.0, 0.7);
    final end = (start + 0.6).clamp(0.0, 1.0);

    final fade = CurvedAnimation(
      parent: _controller,
      curve: Interval(start, end, curve: Curves.easeOut),
    );
    final slide = CurvedAnimation(
      parent: _controller,
      curve: Interval(start, end, curve: Curves.elasticOut),
    );
    final scale = CurvedAnimation(
      parent: _controller,
      curve: Interval(start, end, curve: Curves.easeOutBack),
    );

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, c) {
        final dx = -64 * (1 - slide.value);
        final s = 0.92 + 0.08 * scale.value.clamp(0.0, 1.2);
        return Opacity(
          opacity: fade.value.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(dx, 0),
            child: Transform.scale(
              scale: s,
              alignment: Alignment.centerLeft,
              child: c,
            ),
          ),
        );
      },
      child: child,
    );
  }

  // ───────────────────────────── Header ────────────────────────────────────

  Widget _buildHeader(
    BuildContext context, {
    required String displayName,
    required String tagline,
    String? avatar,
  }) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        // Stretch the elastic header drop over the first ~60% of the timeline.
        final raw = (_controller.value / 0.6).clamp(0.0, 1.0);
        final bounce = Curves.elasticOut.transform(raw);
        final fade = Curves.easeOut.transform(
          (_controller.value / 0.4).clamp(0.0, 1.0),
        );
        final scale = 0.9 + 0.1 * bounce.clamp(0.0, 1.2);
        return Opacity(
          opacity: fade,
          child: Transform.translate(
            offset: Offset(0, -34 * (1 - bounce)),
            child: Transform.scale(
              scale: scale,
              alignment: Alignment.topCenter,
              child: child,
            ),
          ),
        );
      },
      child: ClipPath(
        clipper: _HeaderClipper(),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 36),
          decoration: const BoxDecoration(
            gradient: AppColorPalette.fieldFreshGradient,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.asset(
                      'assets/images/agricole_icon2.gif', // logo asset
                      width: 28,
                      height: 28,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Fieldly',
                    style: AppTextStyles.bodyLarge(
                      color: AppColorPalette.white,
                    ).copyWith(fontWeight: FontWeight.w700),
                  ),
                  const Spacer(),
                  IconButton(
                    splashRadius: 18,
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(
                      Icons.close_rounded,
                      color: AppColorPalette.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Center(
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColorPalette.white.withValues(alpha: 0.6),
                      width: 2,
                    ),
                  ),
                  padding: const EdgeInsets.all(2),
                  child: CircleAvatar(
                    radius: 30,
                    backgroundColor:
                        AppColorPalette.white.withValues(alpha: 0.2),
                    backgroundImage: (avatar != null && avatar.isNotEmpty)
                        ? NetworkImage(_resolveAvatarUrl(avatar))
                        : null,
                    child: (avatar == null || avatar.isEmpty)
                        ? const Icon(
                            Icons.person,
                            color: AppColorPalette.white,
                            size: 32,
                          )
                        : null,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Center(
                child: Text(
                  displayName,
                  style: AppTextStyles.h3(color: AppColorPalette.white)
                      .copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(height: 2),
              Center(
                child: Text(
                  tagline,
                  style: AppTextStyles.bodySmall(
                    color: AppColorPalette.white.withValues(alpha: 0.85),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ───────────────────────────── Footer ────────────────────────────────────

  Widget _buildFooter(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ProfileScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.workspace_premium_rounded, size: 18),
              label: const Text('Go Pro'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColorPalette.fieldFreshStart,
                foregroundColor: AppColorPalette.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: OutlinedButton(
              onPressed: () {
                Navigator.pop(context); // close drawer first
                RatingDialog.show(context);
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: _ink,
                side: const BorderSide(color: _hairline),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
              ),
              child: const Text('Rate App'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 14, 8, 6),
      child: Text(
        text,
        style: AppTextStyles.bodySmall(color: _muted)
            .copyWith(fontWeight: FontWeight.w600, letterSpacing: 0.4),
      ),
    );
  }

  // ───────────────────────────── Navigation ────────────────────────────────

  void _navigate(_DrawerItem item) {
    Navigator.pop(context);
    if (item.routeName != null) {
      Navigator.pushNamed(context, item.routeName!);
      return;
    }
    if (item.builder != null) {
      Navigator.push(context, MaterialPageRoute(builder: item.builder!));
    }
  }

  Future<void> _signOut(BuildContext context) async {
    Navigator.pop(context);
    await context.read<AuthProvider>().signOut();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const SignInScreen()),
      (route) => false,
    );
  }

  // ───────────────────────────── Content ───────────────────────────────────

  List<_DrawerGroup> _ownerGroups() => [
        _DrawerGroup(
          label: 'General',
          flatItems: [
            _DrawerItem(
              icon: Icons.home_outlined,
              title: 'Home',
              builder: (_) => const HomeScreen(),
            ),
          ],
          categories: [
            _DrawerCategory(
              icon: Icons.agriculture_outlined,
              title: 'Farm',
              items: [
                _DrawerItem(
                  icon: Icons.grass_outlined,
                  title: 'My Parcels',
                  builder: (_) => const ParcelListScreen(),
                ),
                _DrawerItem(
                  icon: Icons.science_outlined,
                  title: 'Soil Health',
                  builder: (_) => const SoilMeasurementsListScreen(),
                ),
                _DrawerItem(
                  icon: Icons.local_florist_outlined,
                  title: 'AI Plant Doctor',
                  builder: (_) => const PlantDoctorScreen(),
                ),
                _DrawerItem(
                  icon: Icons.bar_chart_outlined,
                  title: 'Harvest Analytics',
                  builder: (_) => const HarvestAnalyticsScreen(),
                ),
                _DrawerItem(
                  icon: Icons.map_outlined,
                  title: 'Aero-Twin NDVI',
                  builder: (_) => const AeroTwinScreen(),
                ),
                _DrawerItem(
                  icon: Icons.calendar_month_outlined,
                  title: 'Crop Calendar',
                  builder: (_) => const CropCalendarScreen(),
                ),
                _DrawerItem(
                  icon: Icons.cloud_outlined,
                  title: 'Weather & Advice',
                  builder: (_) => const WeatherScreen(),
                ),
                _DrawerItem(
                  icon: Icons.water_drop_outlined,
                  title: 'Irrigation Scheduler',
                  builder: (_) => const IrrigationSchedulerScreen(),
                ),
                _DrawerItem(
                  icon: Icons.article_outlined,
                  title: 'Agricultural News',
                  builder: (_) => AgriculturalNewsScreen(),
                ),
                _DrawerItem(
                  icon: Icons.play_circle_outline,
                  title: 'Farm Reels',
                  builder: (_) => const ShortsScreen(),
                ),
                _DrawerItem(
                  icon: Icons.forum_outlined,
                  title: 'Community Feed',
                  builder: (_) => const CommunityFeedScreen(),
                ),
                _DrawerItem(
                  icon: Icons.quiz_outlined,
                  title: 'Farm Quiz',
                  builder: (_) => const FarmQuizScreen(),
                ),
              ],
            ),
            _DrawerCategory(
              icon: Icons.pets_outlined,
              title: 'Animals',
              items: [
                _DrawerItem(
                  icon: Icons.list_alt_outlined,
                  title: 'Animal List',
                  builder: (_) => const AnimalListScreen(),
                ),
                _DrawerItem(
                  icon: Icons.add_circle_outline,
                  title: 'Add Animal',
                  builder: (_) => const AddAnimalScreen(),
                ),
                _DrawerItem(
                  icon: Icons.sell_outlined,
                  title: 'Planned Sales',
                  builder: (_) => const PlannedSalesScreen(),
                ),
                _DrawerItem(
                  icon: Icons.water_drop_outlined,
                  title: 'Milk Production',
                  builder: (_) => const MilkProductionScreen(),
                ),
                _DrawerItem(
                  icon: Icons.show_chart_outlined,
                  title: 'Milk Analytics',
                  builder: (_) => const MilkAnalyticsScreen(),
                ),
              ],
            ),
            _DrawerCategory(
              icon: Icons.health_and_safety_outlined,
              title: 'Health',
              items: [
                _DrawerItem(
                  icon: Icons.vaccines_outlined,
                  title: 'Vaccination',
                  builder: (_) => const VaccineDashboardScreen(),
                ),
              ],
            ),
            _DrawerCategory(
              icon: Icons.payments_outlined,
              title: 'Finance & Catalogue',
              items: [
                _DrawerItem(
                  icon: Icons.attach_money_rounded,
                  title: 'Finance Dashboard',
                  builder: (_) => const FinanceDashboardScreen(),
                ),
                _DrawerItem(
                  icon: Icons.menu_book_outlined,
                  title: 'Product Catalogue',
                  builder: (_) => const CatalogueListScreen(),
                ),
              ],
            ),
            _DrawerCategory(
              icon: Icons.shield_outlined,
              title: 'Security',
              items: [
                _DrawerItem(
                  icon: Icons.shield_outlined,
                  title: 'Security Whitelist',
                  builder: (_) => const StaffListScreen(),
                ),
                _DrawerItem(
                  icon: Icons.person_add_outlined,
                  title: 'Add Staff',
                  builder: (_) => const AddStaffScreen(),
                ),
                _DrawerItem(
                  icon: Icons.history_outlined,
                  title: 'Incident History',
                  builder: (_) => const IncidentHistoryScreen(),
                ),
                _DrawerItem(
                  icon: Icons.videocam_outlined,
                  title: 'Live Feed',
                  builder: (_) => const LiveFeedScreen(),
                ),
                _DrawerItem(
                  icon: Icons.assessment_outlined,
                  title: 'Daily Reports',
                  builder: (_) => const DailyReportScreen(),
                ),
                _DrawerItem(
                  icon: Icons.graphic_eq_outlined,
                  title: 'Acoustic Monitor',
                  builder: (_) => const AcousticMonitorScreen(),
                ),
              ],
            ),
            const _DrawerCategory(
              icon: Icons.precision_manufacturing_outlined,
              title: 'Operations',
              items: [
                _DrawerItem(
                  icon: Icons.videogame_asset_outlined,
                  title: 'Control Room',
                  routeName: '/control_room',
                ),
                _DrawerItem(
                  icon: Icons.workspace_premium_outlined,
                  title: 'Skill Certification',
                  routeName: '/skill_certification',
                ),
              ],
            ),
          ],
        ),
        _DrawerGroup(
          label: 'Profile',
          flatItems: [
            _DrawerItem(
              icon: Icons.settings_outlined,
              title: 'Settings',
              builder: (_) => const ProfileScreen(),
            ),
            _DrawerItem(
              icon: Icons.account_circle_outlined,
              title: 'Account',
              builder: (_) => const ProfileScreen(),
            ),
          ],
        ),
      ];

  List<_DrawerGroup> _workerGroups() => [
        _DrawerGroup(
          label: 'General',
          flatItems: [
            _DrawerItem(
              icon: Icons.home_outlined,
              title: 'Home',
              builder: (_) => const FarmerHomeScreenV2(),
            ),
          ],
          categories: const [
            _DrawerCategory(
              icon: Icons.precision_manufacturing_outlined,
              title: 'Operations',
              items: [
                _DrawerItem(
                  icon: Icons.videogame_asset_outlined,
                  title: 'Control Room',
                  routeName: '/control_room',
                ),
                _DrawerItem(
                  icon: Icons.workspace_premium_outlined,
                  title: 'Skill Certification',
                  routeName: '/skill_certification',
                ),
              ],
            ),
          ],
        ),
        _DrawerGroup(
          label: 'Profile',
          flatItems: [
            _DrawerItem(
              icon: Icons.account_circle_outlined,
              title: 'Account',
              builder: (_) => const ProfileScreen(),
            ),
          ],
        ),
      ];
}

// ─────────────────────────────────────────────────────────────────────────
//  Header curve
// ─────────────────────────────────────────────────────────────────────────

class _HeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final p = Path();
    p.lineTo(0, size.height - 28);
    p.quadraticBezierTo(
      size.width / 2,
      size.height + 24,
      size.width,
      size.height - 28,
    );
    p.lineTo(size.width, 0);
    p.close();
    return p;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

// ─────────────────────────────────────────────────────────────────────────
//  Tiles
// ─────────────────────────────────────────────────────────────────────────

class _LeafTile extends StatelessWidget {
  final _DrawerItem item;
  final VoidCallback onTap;
  final Color ink;
  final Color muted;
  final bool danger;

  const _LeafTile({
    required this.item,
    required this.onTap,
    required this.ink,
    required this.muted,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = danger ? AppColorPalette.alertError : ink;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(28),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Icon(item.icon, size: 22, color: color),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  item.title,
                  style: AppTextStyles.bodyLarge(color: color)
                      .copyWith(fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CollapsibleCategory extends StatefulWidget {
  final _DrawerCategory category;
  final ValueChanged<_DrawerItem> onItemTap;
  final Color ink;
  final Color muted;
  final Color selectedFill;

  const _CollapsibleCategory({
    required this.category,
    required this.onItemTap,
    required this.ink,
    required this.muted,
    required this.selectedFill,
  });

  @override
  State<_CollapsibleCategory> createState() => _CollapsibleCategoryState();
}

class _CollapsibleCategoryState extends State<_CollapsibleCategory>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _turn;

  bool _open = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );
    _turn = Tween<double>(begin: 0, end: 0.5).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _open = !_open;
      if (_open) {
        _ctrl.forward();
      } else {
        _ctrl.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(28),
          child: InkWell(
            borderRadius: BorderRadius.circular(28),
            onTap: _toggle,
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Icon(widget.category.icon, size: 22, color: widget.ink),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      widget.category.title,
                      style: AppTextStyles.bodyLarge(color: widget.ink)
                          .copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                  RotationTransition(
                    turns: _turn,
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: widget.muted,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        ClipRect(
          child: AnimatedAlign(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            heightFactor: _open ? 1.0 : 0.0,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 220),
              opacity: _open ? 1 : 0,
              child: Padding(
                padding: const EdgeInsets.only(left: 18, top: 2, bottom: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final item in widget.category.items)
                      _LeafTile(
                        item: item,
                        onTap: () => widget.onItemTap(item),
                        ink: widget.ink,
                        muted: widget.muted,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SignOutTile extends StatelessWidget {
  final VoidCallback onTap;
  const _SignOutTile({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(28),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              const Icon(
                Icons.logout_rounded,
                size: 22,
                color: AppColorPalette.alertError,
              ),
              const SizedBox(width: 14),
              Text(
                'Sign Out',
                style: AppTextStyles.bodyLarge(
                  color: AppColorPalette.alertError,
                ).copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

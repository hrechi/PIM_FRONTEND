
import 'package:flutter/material.dart';
import '../theme/color_palette.dart';
import '../theme/text_styles.dart';
import '../services/billing_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'signin_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  GoProScreen  –  Fieldly subscription upgrade modal
//  Flow:
//    1. Pick plan + billing cycle
//    2. Add robot add-ons with quantity stepper
//    3. Review live order summary
//    4. Tap CTA → backend creates Stripe Checkout session → opens in browser
//    5. Stripe redirects back via deep-link fieldly://billing/success
//    6. Webhook activates subscription server-side
// ─────────────────────────────────────────────────────────────────────────────

void showGoProSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const GoProScreen(),
  );
}

class GoProScreen extends StatefulWidget {
  const GoProScreen({super.key});
  @override
  State<GoProScreen> createState() => _GoProScreenState();
}

// ─── Plan data ───────────────────────────────────────────────────────────────

class _Plan {
  final PlanId id;
  final String name;
  final int monthlyPrice;
  final String? badge;
  final bool highlighted;

  const _Plan({
    required this.id,
    required this.name,
    required this.monthlyPrice,
    this.badge,
    this.highlighted = false,
  });

  String displayPrice(bool annual) {
    if (id == PlanId.enterprise) return 'Custom';
    final p = annual ? (monthlyPrice * 0.82).round() : monthlyPrice;
    return '\$$p';
  }
}

const _plans = [
  _Plan(id: PlanId.essential,     name: 'Essential', monthlyPrice: 29),
  _Plan(id: PlanId.growth,        name: 'Growth',    monthlyPrice: 89,  badge: 'Most popular'),
  _Plan(id: PlanId.operationsPro, name: 'Ops Pro',   monthlyPrice: 199, badge: 'Best value', highlighted: true),
  _Plan(id: PlanId.enterprise,    name: 'Enterprise',monthlyPrice: 0,   badge: 'Contact us'),
];

const _featuresByPlan = {
  PlanId.essential: [
    'Core dashboard & parcels (up to 10)',
    'Animal tracking (up to 30)',
    'Weather data integration',
    'Community access',
    '200 AI credits / month',
    '5 GB storage · 2 users',
  ],
  PlanId.growth: [
    'Everything in Essential',
    'AI Agronomist 🤖 & Plant Doctor 🌿',
    'Irrigation scheduler 💧',
    'Milk analytics & vaccination planning',
    'Mission / task management',
    '1,500 AI credits · 50 GB · 6 users',
  ],
  PlanId.operationsPro: [
    'Everything in Growth',
    'Advanced analytics & dashboards 📊',
    'Security incident monitoring 🚨',
    'Live feed + whitelist access control',
    'Export PDF / CSV · Priority support',
    '5,000 AI credits · 200 GB · 15 users',
  ],
  PlanId.enterprise: [
    'Everything in Ops Pro',
    'Multi-site management',
    'API access & SSO',
    'Custom integrations & SLA',
    'Dedicated onboarding & support',
    'Unlimited credits · storage · users',
  ],
};

// ─── Robot option display data ────────────────────────────────────────────────

class _RobotOption {
  final RobotTierId tier;
  final String description;
  final Color color;
  const _RobotOption({required this.tier, required this.description, required this.color});
}

const _robotOptions = [
  _RobotOption(
    tier: RobotTierId.robotConnect,
    description: 'Live status, mission logs, basic alerts',
    color: AppColorPalette.fieldFreshStart,
  ),
  _RobotOption(
    tier: RobotTierId.robotAutonomy,
    description: 'Autonomous scheduling, route optimization',
    color: AppColorPalette.fieldFreshMid,
  ),
  _RobotOption(
    tier: RobotTierId.robotFleet,
    description: 'Fleet dashboard, KPIs, audit logs',
    color: AppColorPalette.fieldFreshEnd,
  ),
];

const _robotPrices = {
  RobotTierId.robotConnect:  49,
  RobotTierId.robotAutonomy: 99,
  RobotTierId.robotFleet:    299,
};

// ─── State ───────────────────────────────────────────────────────────────────

class _GoProScreenState extends State<GoProScreen>
    with SingleTickerProviderStateMixin {
  PlanId _selected = PlanId.operationsPro;
  bool   _annual   = true;
  bool   _loading  = false;

  final Map<RobotTierId, int> _robotQty = {
    RobotTierId.robotConnect:  0,
    RobotTierId.robotAutonomy: 0,
    RobotTierId.robotFleet:    0,
  };

  late final AnimationController _ac;
  late final Animation<double>   _fadeSlide;

  @override
  void initState() {
    super.initState();
    _ac = AnimationController(vsync: this, duration: const Duration(milliseconds: 520))
      ..forward();
    _fadeSlide = CurvedAnimation(parent: _ac, curve: Curves.easeOutCubic);
  }

  @override
  void dispose() {
    _ac.dispose();
    super.dispose();
  }

  // ── Computed ──────────────────────────────────────────────────────────────

  int get _totalMonthly {
    if (_selected == PlanId.enterprise) return 0;
    final plan  = _plans.firstWhere((p) => p.id == _selected);
    final base  = _annual ? (plan.monthlyPrice * 0.82).round() : plan.monthlyPrice;
    int robots  = 0;
    for (final e in _robotQty.entries) {
      robots += (_robotPrices[e.key] ?? 0) * e.value;
    }
    return base + robots;
  }

  List<RobotAddon> get _selectedRobots => _robotQty.entries
      .where((e) => e.value > 0)
      .map((e) => RobotAddon(tier: e.key, quantity: e.value))
      .toList();

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final sheetH = MediaQuery.of(context).size.height * 0.92;

    return AnimatedBuilder(
      animation: _fadeSlide,
      builder: (ctx, child) => Opacity(
        opacity: _fadeSlide.value,
        child: Transform.translate(
          offset: Offset(0, 40 * (1 - _fadeSlide.value)),
          child: child,
        ),
      ),
      child: Container(
        height: sheetH,
        decoration: const BoxDecoration(
          color: Color(0xFFFAFAF7),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            _handle(),
            _header(context),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 4),
                    _billingToggle(),
                    const SizedBox(height: 20),
                    _planCards(),
                    const SizedBox(height: 24),
                    _featureList(),
                    const SizedBox(height: 28),
                    _robotAddOns(),
                    const SizedBox(height: 20),
                    _orderSummary(),
                    const SizedBox(height: 20),
                    _trialBanner(),
                    const SizedBox(height: 28),
                    _ctaButton(context),
                    const SizedBox(height: 14),
                    _footerLinks(context),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Handle ────────────────────────────────────────────────────────────────

  Widget _handle() => Padding(
        padding: const EdgeInsets.only(top: 12, bottom: 4),
        child: Center(
          child: Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFDDD9D0),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
      );

  // ── Header ────────────────────────────────────────────────────────────────

  Widget _header(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 12, 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ⚡ Pro badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      gradient: AppColorPalette.fieldFreshGradient,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.bolt_rounded, color: Colors.white, size: 14),
                        const SizedBox(width: 4),
                        Text('Pro', style: AppTextStyles.buttonSmall(color: Colors.white)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text('Upgrade to Pro',
                      style: AppTextStyles.h2(color: const Color(0xFF1F2933))),
                  const SizedBox(height: 4),
                  Text('Unlock the full power of your farm',
                      style: AppTextStyles.bodyMedium(color: const Color(0xFF9AA0A6))),
                ],
              ),
            ),
            IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close_rounded, color: Color(0xFF9AA0A6)),
            ),
          ],
        ),
      );

  // ── Billing toggle ────────────────────────────────────────────────────────

  Widget _billingToggle() => Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: const Color(0xFFEEEAE2),
          borderRadius: BorderRadius.circular(28),
        ),
        child: Row(
          children: [
            _toggleChip('Monthly',     !_annual),
            _toggleChip('Annual  –18%', _annual),
          ],
        ),
      );

  Widget _toggleChip(String label, bool active) => Expanded(
        child: GestureDetector(
          onTap: () => setState(() => _annual = label.startsWith('Annual')),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              gradient: active ? AppColorPalette.fieldFreshGradient : null,
              borderRadius: BorderRadius.circular(24),
              boxShadow: active
                  ? [BoxShadow(
                      color: AppColorPalette.fieldFreshStart.withValues(alpha: 0.25),
                      blurRadius: 8, offset: const Offset(0, 3))]
                  : null,
            ),
            child: Center(
              child: Text(label,
                  style: AppTextStyles.bodyMedium(
                    color: active ? Colors.white : const Color(0xFF9AA0A6),
                    fontWeight: FontWeight.w600,
                  )),
            ),
          ),
        ),
      );

  // ── Plan cards ────────────────────────────────────────────────────────────

  Widget _planCards() => SizedBox(
        height: 130,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: _plans.length,
          separatorBuilder: (context, index) => const SizedBox(width: 10),
          itemBuilder: (ctx, i) => _PlanCard(
            plan:     _plans[i],
            selected: _plans[i].id == _selected,
            annual:   _annual,
            onTap:    () => setState(() => _selected = _plans[i].id),
          ),
        ),
      );

  // ── Feature list ──────────────────────────────────────────────────────────

  Widget _featureList() {
    final features = _featuresByPlan[_selected] ?? [];
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 280),
      child: Column(
        key: ValueKey(_selected),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text("What's included",
              style: AppTextStyles.h4(color: const Color(0xFF1F2933))),
          const SizedBox(height: 12),
          ...features.map((f) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 22, height: 22,
                      decoration: const BoxDecoration(
                        gradient: AppColorPalette.fieldFreshGradient,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check_rounded,
                          color: Colors.white, size: 14),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(f,
                          style: AppTextStyles.bodyMedium(
                              color: const Color(0xFF1F2933))),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  // ── Robot add-ons (interactive quantity steppers) ─────────────────────────

  Widget _robotAddOns() => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFEEEAE2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12, offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: AppColorPalette.robotTechGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.precision_manufacturing_rounded,
                      color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Robot Add-Ons',
                          style: AppTextStyles.bodyLarge(
                              color: const Color(0xFF1F2933),
                              fontWeight: FontWeight.w700)),
                      Text('Per robot · billed with your plan',
                          style: AppTextStyles.bodySmall(
                              color: const Color(0xFF9AA0A6))),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // One row per robot tier
            ..._robotOptions.map((opt) => _RobotRow(
                  option:    opt,
                  quantity:  _robotQty[opt.tier] ?? 0,
                  onChanged: (qty) => setState(() => _robotQty[opt.tier] = qty),
                )),
          ],
        ),
      );

  // ── Order summary ─────────────────────────────────────────────────────────

  Widget _orderSummary() {
    if (_selected == PlanId.enterprise) return const SizedBox.shrink();

    final plan      = _plans.firstWhere((p) => p.id == _selected);
    final basePrice = _annual
        ? (plan.monthlyPrice * 0.82).round()
        : plan.monthlyPrice;
    final hasRobots = _robotQty.values.any((q) => q > 0);

    return AnimatedSize(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColorPalette.fieldFreshStart.withValues(alpha: 0.07),
              AppColorPalette.fieldFreshEnd.withValues(alpha: 0.04),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColorPalette.fieldFreshStart.withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Order summary',
                style: AppTextStyles.bodyLarge(
                    color: const Color(0xFF1F2933),
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            _SummaryRow(label: '${plan.name} plan', value: '\$$basePrice / mo'),
            if (hasRobots) ...[
              const SizedBox(height: 4),
              ..._robotQty.entries.where((e) => e.value > 0).map((e) {
                final opt   = _robotOptions.firstWhere((o) => o.tier == e.key);
                final price = (_robotPrices[e.key] ?? 0) * e.value;
                return _SummaryRow(
                  label: '${opt.tier.label} × ${e.value}',
                  value: '\$$price / mo',
                );
              }),
            ],
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Divider(color: Color(0xFFDDD9D0), height: 1),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total',
                    style: AppTextStyles.bodyLarge(
                        color: const Color(0xFF1F2933),
                        fontWeight: FontWeight.w700)),
                Text('\$$_totalMonthly / mo',
                    style: AppTextStyles.bodyLarge(
                        color: AppColorPalette.fieldFreshMid,
                        fontWeight: FontWeight.w800)),
              ],
            ),
            if (_annual) ...[
              const SizedBox(height: 4),
              Text('Billed annually · 18% saved vs monthly',
                  style: AppTextStyles.bodySmall(
                      color: AppColorPalette.fieldFreshMid)),
            ],
          ],
        ),
      ),
    );
  }

  // ── Trial banner ──────────────────────────────────────────────────────────

  Widget _trialBanner() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColorPalette.fieldFreshStart.withValues(alpha: 0.12),
              AppColorPalette.fieldFreshEnd.withValues(alpha: 0.08),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColorPalette.fieldFreshStart.withValues(alpha: 0.25),
          ),
        ),
        child: Row(
          children: [
            const Text('💳', style: TextStyle(fontSize: 28)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Payment starts on checkout',
                      style: AppTextStyles.bodyLarge(
                          color: const Color(0xFF1F2933),
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text('You will be sent to Stripe to complete payment',
                      style: AppTextStyles.bodySmall(
                          color: const Color(0xFF9AA0A6))),
                ],
              ),
            ),
          ],
        ),
      );

  // ── CTA button ────────────────────────────────────────────────────────────

  Widget _ctaButton(BuildContext context) {
    final isEnterprise = _selected == PlanId.enterprise;
    final label = isEnterprise ? 'Contact Sales'
        : (_loading ? 'Opening Stripe…' : 'Pass to Pay');

    return GestureDetector(
      onTap: _loading ? null : () => _handleCTA(context),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 56,
        decoration: BoxDecoration(
          gradient: _loading
              ? const LinearGradient(
                  colors: [Color(0xFFBDC3C7), Color(0xFFBDC3C7)])
              : AppColorPalette.fieldFreshGradient,
          borderRadius: BorderRadius.circular(28),
          boxShadow: _loading ? [] : [
            BoxShadow(
              color: AppColorPalette.fieldFreshStart.withValues(alpha: 0.35),
              blurRadius: 16, offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Center(
          child: _loading
              ? const SizedBox(
                  width: 22, height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation(Colors.white),
                  ),
                )
              : Text(label,
                  style: AppTextStyles.buttonLarge(color: Colors.white)),
        ),
      ),
    );
  }

  Future<void> _handleCTA(BuildContext context) async {
    // Enterprise → open email
    if (_selected == PlanId.enterprise) {
      final uri = Uri.parse(
          'mailto:sales@fieldly.app?subject=Enterprise%20Plan%20Inquiry');
      if (await canLaunchUrl(uri)) await launchUrl(uri);
      return;
    }

    // Require authentication before creating a Checkout session
    final auth = context.read<AuthProvider>();
    if (!auth.isAuthenticated) {
      final shouldSignIn = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Sign in required'),
          content: const Text('You need to sign in to start a subscription.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Sign in'),
            ),
          ],
        ),
      );

      if (shouldSignIn == true && context.mounted) {
        await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SignInScreen()));
      }
      return;
    }

    // Show loading dialog
    if (context.mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: const Text('Opening Stripe Checkout...'),
          content: const SizedBox(
            height: 40,
            child: Center(
              child: CircularProgressIndicator(),
            ),
          ),
        ),
      );
    }

    setState(() => _loading = true);
    try {
      // ignore: avoid_print
      print('[Go Pro] Creating checkout session: plan=$_selected, annual=$_annual');
      
      final url = await BillingService.createCheckoutSession(
        plan:   _selected,
        annual: _annual,
        robots: _selectedRobots,
      );

      // ignore: avoid_print
      print('[Go Pro] Checkout URL received: $url');

      if (url != null && context.mounted) {
        final uri = Uri.parse(url);
        Navigator.of(context).pop(); // Close loading dialog
        
        try {
          // Try to launch in in-app WebView (more reliable on mobile)
          await launchUrl(uri, mode: LaunchMode.inAppWebView);
          if (!context.mounted) return;
          Navigator.of(context).pop(); // Close GoProScreen
        } catch (e) {
          // If in-app fails, try external browser
          print('[Go Pro] In-app launch failed: $e, trying external browser');
          try {
            if (await canLaunchUrl(uri)) {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
              if (!context.mounted) return;
              Navigator.of(context).pop(); // Close GoProScreen
            } else {
              if (!context.mounted) return;
              _showErrorDialog(context, 'Could not open Stripe checkout. Please check your internet connection.');
            }
          } catch (externalError) {
            print('[Go Pro] External launch also failed: $externalError');
            if (!context.mounted) return;
            _showErrorDialog(context, 'Could not open Stripe checkout: ${externalError.toString()}');
          }
        }
      } else {
        if (!context.mounted) return;
        Navigator.of(context).pop(); // Close loading dialog
        _showErrorDialog(context, 'Failed to create checkout session.');
      }
    } catch (e) {
      // ignore: avoid_print
      print('[Go Pro] Error: $e');
      if (context.mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        _showErrorDialog(context, 'Error: ${e.toString()}');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showErrorDialog(BuildContext context, String msg) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Something went wrong'),
        content: Text(msg),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // ── Footer links ──────────────────────────────────────────────────────────

  Widget _footerLinks(BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _fLink('Privacy Policy'),
          Text('  ·  ',
              style: AppTextStyles.bodySmall(color: const Color(0xFFBDC3C7))),
          _fLink('Terms of Use'),
          Text('  ·  ',
              style: AppTextStyles.bodySmall(color: const Color(0xFFBDC3C7))),
          _fLink('Manage Plan', onTap: () => _openPortal(context)),
        ],
      );

  Widget _fLink(String label, {VoidCallback? onTap}) => GestureDetector(
        onTap: onTap,
        child: Text(label,
            style: AppTextStyles.bodySmall(color: AppColorPalette.fieldFreshMid)
                .copyWith(decoration: TextDecoration.underline)),
      );

  Future<void> _openPortal(BuildContext context) async {
    try {
      final url = await BillingService.createPortalSession();
      if (url != null) {
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      }
    } catch (_) {
      if (context.mounted) {
        _showErrorDialog(context, 'No active subscription found.');
      }
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  _PlanCard
// ─────────────────────────────────────────────────────────────────────────────

class _PlanCard extends StatelessWidget {
  final _Plan plan;
  final bool selected;
  final bool annual;
  final VoidCallback onTap;

  const _PlanCard({
    required this.plan,
    required this.selected,
    required this.annual,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cardW = ((MediaQuery.of(context).size.width - 40 - 30) / 3.4)
        .clamp(90.0, 130.0);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        width: cardW,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: selected ? AppColorPalette.fieldFreshGradient : null,
          color:    selected ? null : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? Colors.transparent : const Color(0xFFEEEAE2),
            width: 1.5,
          ),
          boxShadow: selected
              ? [BoxShadow(
                  color: AppColorPalette.fieldFreshStart.withValues(alpha: 0.30),
                  blurRadius: 14, offset: const Offset(0, 5))]
              : [BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Badge or spacer
            if (plan.badge != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: selected
                      ? Colors.white.withValues(alpha: 0.25)
                      : AppColorPalette.fieldFreshStart.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(plan.badge!,
                    style: AppTextStyles.overline(
                      color: selected
                          ? Colors.white
                          : AppColorPalette.fieldFreshMid,
                    ).copyWith(fontWeight: FontWeight.w700)),
              )
            else
              const SizedBox(height: 16),

            // Price
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(plan.displayPrice(annual),
                    style: AppTextStyles.h3(
                      color: selected ? Colors.white : const Color(0xFF1F2933),
                    ).copyWith(fontWeight: FontWeight.w800)),
                if (plan.id != PlanId.enterprise)
                  Text('/ mo',
                      style: AppTextStyles.bodySmall(
                        color: selected
                            ? Colors.white.withValues(alpha: 0.8)
                            : const Color(0xFF9AA0A6),
                      )),
              ],
            ),

            // Plan name
            Text(plan.name,
                style: AppTextStyles.bodySmall(
                  color: selected
                      ? Colors.white.withValues(alpha: 0.9)
                      : const Color(0xFF9AA0A6),
                ).copyWith(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  _RobotRow  –  one robot tier with quantity stepper
// ─────────────────────────────────────────────────────────────────────────────

class _RobotRow extends StatelessWidget {
  final _RobotOption option;
  final int quantity;
  final ValueChanged<int> onChanged;

  const _RobotRow({
    required this.option,
    required this.quantity,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final price = _robotPrices[option.tier] ?? 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          // Color dot
          Container(
            width: 10, height: 10,
            decoration: BoxDecoration(
              color: option.color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          // Label + description
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(option.tier.label,
                        style: AppTextStyles.bodyMedium(
                            color: const Color(0xFF1F2933),
                            fontWeight: FontWeight.w600)),
                    const SizedBox(width: 6),
                    Text('\$$price / mo',
                        style: AppTextStyles.bodySmall(
                            color: option.color)
                            .copyWith(fontWeight: FontWeight.w700)),
                  ],
                ),
                Text(option.description,
                    style: AppTextStyles.bodySmall(
                        color: const Color(0xFF9AA0A6))),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Quantity stepper
          Row(
            children: [
              _StepBtn(
                icon: Icons.remove_rounded,
                color: option.color,
                enabled: quantity > 0,
                onTap: () => onChanged(quantity - 1),
              ),
              SizedBox(
                width: 28,
                child: Center(
                  child: Text('$quantity',
                      style: AppTextStyles.bodyMedium(
                          color: const Color(0xFF1F2933),
                          fontWeight: FontWeight.w700)),
                ),
              ),
              _StepBtn(
                icon: Icons.add_rounded,
                color: option.color,
                enabled: true,
                onTap: () => onChanged(quantity + 1),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StepBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final bool enabled;
  final VoidCallback onTap;

  const _StepBtn({
    required this.icon,
    required this.color,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 28, height: 28,
        decoration: BoxDecoration(
          color: enabled
              ? color.withValues(alpha: 0.12)
              : const Color(0xFFEEEAE2),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: enabled
                ? color.withValues(alpha: 0.3)
                : const Color(0xFFDDD9D0),
          ),
        ),
        child: Icon(icon,
            size: 16,
            color: enabled ? color : const Color(0xFFBDC3C7)),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  _SummaryRow
// ─────────────────────────────────────────────────────────────────────────────

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: AppTextStyles.bodyMedium(
                    color: const Color(0xFF1F2933))),
            Text(value,
                style: AppTextStyles.bodyMedium(
                    color: AppColorPalette.fieldFreshMid,
                    fontWeight: FontWeight.w700)),
          ],
        ),
      );
}

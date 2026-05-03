import 'package:flutter/material.dart';
import '../theme/color_palette.dart';
import '../theme/text_styles.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  GoProScreen  –  Fieldly subscription / upgrade modal
//  Design: inspired by the "Upgrade to Pro" card UI (image reference)
//  Colors: strictly from AppColorPalette (fieldFreshGradient, charcoalGreen…)
// ─────────────────────────────────────────────────────────────────────────────

/// Entry point – show as a bottom-sheet modal from the drawer.
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

enum _PlanId { essential, growth, operationsPro, enterprise }

class _Plan {
  final _PlanId id;
  final String name;
  final String price;
  final String period;
  final String? annualNote;
  final String? badge;
  final bool highlighted;

  const _Plan({
    required this.id,
    required this.name,
    required this.price,
    required this.period,
    this.annualNote,
    this.badge,
    this.highlighted = false,
  });
}

const _plans = [
  _Plan(
    id: _PlanId.essential,
    name: 'Essential',
    price: r'$29',
    period: '/ mo',
    annualNote: r'$290 / yr',
  ),
  _Plan(
    id: _PlanId.growth,
    name: 'Growth',
    price: r'$89',
    period: '/ mo',
    annualNote: r'$876 / yr',
    badge: 'Most popular',
    highlighted: false,
  ),
  _Plan(
    id: _PlanId.operationsPro,
    name: 'Ops Pro',
    price: r'$199',
    period: '/ mo',
    annualNote: r'$1,960 / yr',
    badge: 'Best value',
    highlighted: true,
  ),
  _Plan(
    id: _PlanId.enterprise,
    name: 'Enterprise',
    price: r'Custom',
    period: '',
    badge: 'Contact us',
  ),
];

// ─── Feature rows per plan ───────────────────────────────────────────────────

const _featuresByPlan = {
  _PlanId.essential: [
    'Core dashboard & parcels (up to 10)',
    'Animal tracking (up to 30)',
    'Weather data integration',
    'Community access',
    '200 AI credits / month',
    '5 GB storage · 2 users',
  ],
  _PlanId.growth: [
    'Everything in Essential',
    'AI Agronomist 🤖 & Plant Doctor 🌿',
    'Irrigation scheduler 💧',
    'Milk analytics & vaccination planning',
    'Mission / task management',
    '1,500 AI credits · 50 GB · 6 users',
  ],
  _PlanId.operationsPro: [
    'Everything in Growth',
    'Advanced analytics & dashboards 📊',
    'Security incident monitoring 🚨',
    'Live feed + whitelist access control',
    'Export PDF / CSV · Priority support',
    '5,000 AI credits · 200 GB · 15 users',
  ],
  _PlanId.enterprise: [
    'Everything in Ops Pro',
    'Multi-site management',
    'API access & SSO',
    'Custom integrations & SLA',
    'Dedicated onboarding & support',
    'Unlimited credits · storage · users',
  ],
};

// ─── State ───────────────────────────────────────────────────────────────────

class _GoProScreenState extends State<GoProScreen>
    with SingleTickerProviderStateMixin {
  _PlanId _selected = _PlanId.operationsPro;
  bool _annual = true;

  late final AnimationController _ac;
  late final Animation<double> _fadeSlide;

  @override
  void initState() {
    super.initState();
    _ac = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    )..forward();
    _fadeSlide = CurvedAnimation(parent: _ac, curve: Curves.easeOutCubic);
  }

  @override
  void dispose() {
    _ac.dispose();
    super.dispose();
  }

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final sheetH = mq.size.height * 0.92;

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
            _buildHandle(),
            _buildHeader(context),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 4),
                    _buildBillingToggle(),
                    const SizedBox(height: 20),
                    _buildPlanCards(),
                    const SizedBox(height: 24),
                    _buildFeatureList(),
                    const SizedBox(height: 28),
                    _buildRobotAddOn(),
                    const SizedBox(height: 28),
                    _buildTrialBanner(),
                    const SizedBox(height: 28),
                    _buildCTA(context),
                    const SizedBox(height: 12),
                    _buildFooterLinks(context),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Handle ────────────────────────────────────────────────────────────────

  Widget _buildHandle() {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 4),
      child: Center(
        child: Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: const Color(0xFFDDD9D0),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }

  // ─── Header ────────────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context) {
    return Container(
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    gradient: AppColorPalette.fieldFreshGradient,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.bolt_rounded,
                          color: Colors.white, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        'Pro',
                        style: AppTextStyles.buttonSmall(color: Colors.white),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Upgrade to Pro',
                  style: AppTextStyles.h2(
                    color: const Color(0xFF1F2933),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Unlock the full power of your farm',
                  style: AppTextStyles.bodyMedium(
                    color: const Color(0xFF9AA0A6),
                  ),
                ),
              ],
            ),
          ),
          // Close button
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close_rounded, color: Color(0xFF9AA0A6)),
          ),
        ],
      ),
    );
  }

  // ─── Billing toggle ────────────────────────────────────────────────────────

  Widget _buildBillingToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFEEEAE2),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Row(
        children: [
          _toggleOption('Monthly', !_annual),
          _toggleOption('Annual  –18%', _annual),
        ],
      ),
    );
  }

  Widget _toggleOption(String label, bool active) {
    return Expanded(
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
                ? [
                    BoxShadow(
                      color: AppColorPalette.fieldFreshStart.withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    )
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              label,
              style: AppTextStyles.bodyMedium(
                color: active ? Colors.white : const Color(0xFF9AA0A6),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─── Plan cards ────────────────────────────────────────────────────────────

  Widget _buildPlanCards() {
    return SizedBox(
      height: 130,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _plans.length,
        separatorBuilder: (context, index) => const SizedBox(width: 10),
        itemBuilder: (_, i) => _PlanCard(
          plan: _plans[i],
          selected: _plans[i].id == _selected,
          annual: _annual,
          onTap: () => setState(() => _selected = _plans[i].id),
        ),
      ),
    );
  }

  // ─── Feature list ──────────────────────────────────────────────────────────

  Widget _buildFeatureList() {
    final features = _featuresByPlan[_selected] ?? [];
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: Column(
        key: ValueKey(_selected),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'What\'s included',
            style: AppTextStyles.h4(color: const Color(0xFF1F2933)),
          ),
          const SizedBox(height: 12),
          ...features.map(
            (f) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      gradient: AppColorPalette.fieldFreshGradient,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check_rounded,
                        color: Colors.white, size: 14),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      f,
                      style: AppTextStyles.bodyMedium(
                        color: const Color(0xFF1F2933),
                      ),
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

  // ─── Robot add-on ──────────────────────────────────────────────────────────

  Widget _buildRobotAddOn() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEEEAE2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                    Text(
                      'Robot Add-On',
                      style: AppTextStyles.bodyLarge(
                        color: const Color(0xFF1F2933),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Per robot · independent from plan',
                      style: AppTextStyles.bodySmall(
                        color: const Color(0xFF9AA0A6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _RobotTierChip(
                label: 'Connect',
                price: r'$49',
                color: AppColorPalette.fieldFreshStart,
              ),
              const SizedBox(width: 8),
              _RobotTierChip(
                label: 'Autonomy',
                price: r'$99',
                color: AppColorPalette.fieldFreshMid,
              ),
              const SizedBox(width: 8),
              _RobotTierChip(
                label: 'Fleet',
                price: r'$299',
                color: AppColorPalette.fieldFreshEnd,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Trial banner ──────────────────────────────────────────────────────────

  Widget _buildTrialBanner() {
    return Container(
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
          const Text('🎁', style: TextStyle(fontSize: 28)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Free full access for 14 days',
                  style: AppTextStyles.bodyLarge(
                    color: const Color(0xFF1F2933),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'No credit card required · cancel anytime',
                  style: AppTextStyles.bodySmall(
                    color: const Color(0xFF9AA0A6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── CTA button ────────────────────────────────────────────────────────────

  Widget _buildCTA(BuildContext context) {
    final label = _selected == _PlanId.enterprise
        ? 'Contact Sales'
        : 'Start free trial';

    return GestureDetector(
      onTap: () {
        // TODO: wire to payment / contact flow
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _selected == _PlanId.enterprise
                  ? 'Our team will reach out shortly!'
                  : '14-day free trial started 🎉',
            ),
            backgroundColor: AppColorPalette.fieldFreshMid,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      },
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          gradient: AppColorPalette.fieldFreshGradient,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: AppColorPalette.fieldFreshStart.withValues(alpha: 0.35),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Center(
          child: Text(
            label,
            style: AppTextStyles.buttonLarge(color: Colors.white),
          ),
        ),
      ),
    );
  }

  // ─── Footer links ──────────────────────────────────────────────────────────

  Widget _buildFooterLinks(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _footerLink('Privacy Policy'),
        Text(
          '  ·  ',
          style: AppTextStyles.bodySmall(color: const Color(0xFFBDC3C7)),
        ),
        _footerLink('Terms of Use'),
        Text(
          '  ·  ',
          style: AppTextStyles.bodySmall(color: const Color(0xFFBDC3C7)),
        ),
        _footerLink('Restore'),
      ],
    );
  }

  Widget _footerLink(String label) {
    return GestureDetector(
      onTap: () {},
      child: Text(
        label,
        style: AppTextStyles.bodySmall(
          color: AppColorPalette.fieldFreshMid,
        ).copyWith(decoration: TextDecoration.underline),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Plan card widget
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

  String get _displayPrice {
    if (plan.price == r'Custom') return r'Custom';
    // Strip $ and parse
    final raw = double.tryParse(plan.price.replaceAll(r'$', '')) ?? 0;
    final monthly = annual ? (raw * 0.82).round() : raw.round();
    return '\$$monthly';
  }

  @override
  Widget build(BuildContext context) {
    final cardW = (MediaQuery.of(context).size.width - 40 - 30) / 3.4;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        width: cardW.clamp(90.0, 130.0),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: selected ? AppColorPalette.fieldFreshGradient : null,
          color: selected ? null : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? Colors.transparent
                : const Color(0xFFEEEAE2),
            width: 1.5,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppColorPalette.fieldFreshStart.withValues(alpha: 0.3),
                    blurRadius: 14,
                    offset: const Offset(0, 5),
                  )
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Badge
            if (plan.badge != null)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: selected
                      ? Colors.white.withValues(alpha: 0.25)
                      : AppColorPalette.fieldFreshStart.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  plan.badge!,
                  style: AppTextStyles.overline(
                    color: selected
                        ? Colors.white
                        : AppColorPalette.fieldFreshMid,
                  ).copyWith(fontWeight: FontWeight.w700),
                ),
              )
            else
              const SizedBox(height: 16),

            // Price
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _displayPrice,
                  style: AppTextStyles.h3(
                    color: selected ? Colors.white : const Color(0xFF1F2933),
                  ).copyWith(fontWeight: FontWeight.w800),
                ),
                if (plan.period.isNotEmpty)
                  Text(
                    plan.period,
                    style: AppTextStyles.bodySmall(
                      color: selected
                          ? Colors.white.withValues(alpha: 0.8)
                          : const Color(0xFF9AA0A6),
                    ),
                  ),
              ],
            ),

            // Plan name
            Text(
              plan.name,
              style: AppTextStyles.bodySmall(
                color: selected
                    ? Colors.white.withValues(alpha: 0.9)
                    : const Color(0xFF9AA0A6),
              ).copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Robot tier chip
// ─────────────────────────────────────────────────────────────────────────────

class _RobotTierChip extends StatelessWidget {
  final String label;
  final String price;
  final Color color;

  const _RobotTierChip({
    required this.label,
    required this.price,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(
          children: [
            Text(
              price,
              style: AppTextStyles.bodyLarge(
                color: color,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              label,
              style: AppTextStyles.bodySmall(color: color)
                  .copyWith(fontWeight: FontWeight.w600),
            ),
            Text(
              '/ robot / mo',
              style: AppTextStyles.overline(color: color.withValues(alpha: 0.7)),
            ),
          ],
        ),
      ),
    );
  }
}

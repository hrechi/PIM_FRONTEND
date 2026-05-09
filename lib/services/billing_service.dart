import 'api_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  BillingService  –  wraps /api/billing/* endpoints
// ─────────────────────────────────────────────────────────────────────────────

enum PlanId { essential, growth, operationsPro, enterprise }

enum RobotTierId { robotConnect, robotAutonomy, robotFleet }

extension PlanIdExt on PlanId {
  String get apiValue => switch (this) {
        PlanId.essential      => 'essential',
        PlanId.growth         => 'growth',
        PlanId.operationsPro  => 'operations_pro',
        PlanId.enterprise     => 'enterprise',
      };
}

extension RobotTierExt on RobotTierId {
  String get apiValue => switch (this) {
        RobotTierId.robotConnect   => 'robot_connect',
        RobotTierId.robotAutonomy  => 'robot_autonomy',
        RobotTierId.robotFleet     => 'robot_fleet',
      };
  String get label => switch (this) {
        RobotTierId.robotConnect   => 'Robot Connect',
        RobotTierId.robotAutonomy  => 'Robot Autonomy',
        RobotTierId.robotFleet     => 'Robot Fleet',
      };
  String get price => switch (this) {
        RobotTierId.robotConnect   => r'$49',
        RobotTierId.robotAutonomy  => r'$99',
        RobotTierId.robotFleet     => r'$299',
      };
}

class RobotAddon {
  final RobotTierId tier;
  final int quantity;
  const RobotAddon({required this.tier, this.quantity = 1});

  Map<String, dynamic> toJson() => {
        'tier':     tier.apiValue,
        'quantity': quantity,
      };
}

class SubscriptionInfo {
  final String plan;
  final String status;
  final String billingInterval;
  final DateTime? trialEndsAt;
  final DateTime? currentPeriodEnd;
  final bool cancelAtPeriodEnd;
  final List<dynamic> robotAddOns;

  const SubscriptionInfo({
    required this.plan,
    required this.status,
    required this.billingInterval,
    this.trialEndsAt,
    this.currentPeriodEnd,
    required this.cancelAtPeriodEnd,
    required this.robotAddOns,
  });

  bool get isActive => status == 'ACTIVE' || status == 'TRIALING';
  bool get isFree   => plan == 'FREE';

  factory SubscriptionInfo.fromJson(Map<String, dynamic> j) => SubscriptionInfo(
        plan:              j['plan']             as String? ?? 'FREE',
        status:            j['status']           as String? ?? 'TRIALING',
        billingInterval:   j['billingInterval']  as String? ?? 'MONTHLY',
        trialEndsAt:       j['trialEndsAt']  != null
                             ? DateTime.tryParse(j['trialEndsAt'] as String)
                             : null,
        currentPeriodEnd:  j['currentPeriodEnd'] != null
                             ? DateTime.tryParse(j['currentPeriodEnd'] as String)
                             : null,
        cancelAtPeriodEnd: j['cancelAtPeriodEnd'] as bool? ?? false,
        robotAddOns:       j['robotAddOns']      as List<dynamic>? ?? [],
      );

  factory SubscriptionInfo.free() => const SubscriptionInfo(
        plan:             'FREE',
        status:           'TRIALING',
        billingInterval:  'MONTHLY',
        cancelAtPeriodEnd: false,
        robotAddOns:      [],
      );
}

class BillingService {
  // ── Create Stripe Checkout session ───────────────────────────────────────

  static Future<String?> createCheckoutSession({
    required PlanId plan,
    required bool annual,
    List<RobotAddon> robots = const [],
  }) async {
    final body = <String, dynamic>{
      'plan':   plan.apiValue,
      'annual': annual,
      if (robots.isNotEmpty) 'robots': robots.map((r) => r.toJson()).toList(),
    };

    final data = await ApiService.post(
      '/billing/checkout',
      body,
      withAuth: true,
    );

    return data['url'] as String?;
  }

  // ── Open Customer Portal ─────────────────────────────────────────────────

  static Future<String?> createPortalSession() async {
    final data = await ApiService.post(
      '/billing/portal',
      {},
      withAuth: true,
    );
    return data['url'] as String?;
  }

  // ── Get current subscription ─────────────────────────────────────────────

  static Future<SubscriptionInfo> getSubscription() async {
    try {
      final data = await ApiService.get('/billing/subscription', withAuth: true);
      return SubscriptionInfo.fromJson(data as Map<String, dynamic>);
    } catch (_) {
      return SubscriptionInfo.free();
    }
  }
}

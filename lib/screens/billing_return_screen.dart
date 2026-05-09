import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';

class BillingReturnScreen extends StatefulWidget {
  final String? sessionId;

  const BillingReturnScreen({super.key, this.sessionId});

  @override
  State<BillingReturnScreen> createState() => _BillingReturnScreenState();
}

class _BillingReturnScreenState extends State<BillingReturnScreen> {
  bool _loading = true;
  String? _message;

  @override
  void initState() {
    super.initState();
    _finishReturn();
  }

  Future<void> _finishReturn() async {
    final auth = context.read<AuthProvider>();

    try {
      await auth.initialize();
    } catch (_) {}

    if (!mounted) return;

    if (auth.isAuthenticated) {
      try {
        await ApiService.get('/billing/subscription', withAuth: true);
      } catch (_) {}

      if (!mounted) return;

      final role = auth.user?.role.toUpperCase();
      final route = role == 'WORKER'
          ? '/worker_home'
          : role == 'OWNER'
              ? '/farmer_home'
              : '/owner_dashboard';

      Navigator.of(context).pushNamedAndRemoveUntil(route, (route) => false);
      return;
    }

    setState(() {
      _loading = false;
      _message = 'Payment completed, but the session is not connected. Please sign in again.';
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Payment completed')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle_outline, size: 72, color: Colors.green),
              const SizedBox(height: 16),
              Text(
                _message ?? 'Payment completed.',
                textAlign: TextAlign.center,
              ),
              if (widget.sessionId != null) ...[
                const SizedBox(height: 12),
                Text('Session: ${widget.sessionId}'),
              ],
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil('/owner_dashboard', (route) => false),
                child: const Text('Back to Home'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

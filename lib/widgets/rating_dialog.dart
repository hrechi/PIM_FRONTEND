import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/rating_provider.dart';
import '../utils/responsive.dart';

/// Shows the "Rate Fieldly" dialog.
///
/// On web/desktop it appears as a centred card (max 400 px wide).
/// On mobile it slides up as a bottom sheet so it never clips the keyboard.
class RatingDialog extends StatefulWidget {
  const RatingDialog({super.key});

  static Future<void> show(BuildContext context) {
    if (Responsive.isMobile(context)) {
      return showModalBottomSheet(
        context: context,
        isScrollControlled: true, // lets it resize when keyboard appears
        backgroundColor: Colors.transparent,
        builder: (_) => const _RatingSheet(),
      );
    }
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => const _RatingDialogWeb(),
    );
  }

  @override
  State<RatingDialog> createState() => _RatingDialogState();
}

// Thin shell so the widget tree stays valid (never actually rendered directly).
class _RatingDialogState extends State<RatingDialog> {
  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

// ─────────────────────────────────────────────────────────────────────────────
// Web / tablet — centred dialog
// ─────────────────────────────────────────────────────────────────────────────

class _RatingDialogWeb extends StatelessWidget {
  const _RatingDialogWeb();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(30),
                blurRadius: 32,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: const _RatingForm(isSheet: false),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Mobile — bottom sheet
// ─────────────────────────────────────────────────────────────────────────────

class _RatingSheet extends StatelessWidget {
  const _RatingSheet();

  @override
  Widget build(BuildContext context) {
    // Pad above the keyboard when it appears.
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(bottom: bottomInset),
      child: const _RatingForm(isSheet: true),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared form — used by both surfaces
// ─────────────────────────────────────────────────────────────────────────────

class _RatingForm extends StatefulWidget {
  final bool isSheet;
  const _RatingForm({required this.isSheet});

  @override
  State<_RatingForm> createState() => _RatingFormState();
}

class _RatingFormState extends State<_RatingForm> {
  int _stars = 0;
  final _messageController = TextEditingController();
  bool _submitted = false;

  static const _green = Color(0xFF309448);

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _submit(BuildContext context) {
    if (_stars == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a star rating first.')),
      );
      return;
    }

    final user = context.read<AuthProvider>().user;
    final name = user?.name.isNotEmpty == true ? user!.name : 'Anonymous';

    // Fire-and-forget — provider handles loading state internally.
    context.read<RatingProvider>().submitRating(
          stars: _stars,
          message: _messageController.text.trim().isEmpty
              ? null
              : _messageController.text.trim(),
          userName: name,
          avatarUrl: user?.profilePicture,
        );

    setState(() => _submitted = true);

    final navigator = Navigator.of(context);
    Future.delayed(const Duration(milliseconds: 1400), () {
      if (mounted) navigator.pop();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final hPad = isMobile ? 20.0 : 24.0;
    final vPad = isMobile ? 24.0 : 28.0;

    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.fromLTRB(hPad, vPad, hPad, hPad),
        child: _submitted ? _buildThankYou(isMobile) : _buildForm(context, isMobile),
      ),
    );
  }

  // ── Thank-you ─────────────────────────────────────────────────────────────

  Widget _buildThankYou(bool isMobile) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.isSheet) _sheetHandle(),
        const SizedBox(height: 16),
        Container(
          width: 68,
          height: 68,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF2ECC71), Color(0xFF309448)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF309448).withAlpha(60),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Icon(Icons.check_rounded, color: Colors.white, size: 34),
        ),
        const SizedBox(height: 18),
        Text(
          'Thank you! 🌿',
          style: TextStyle(
            fontSize: isMobile ? 18 : 20,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF1A1A1A),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Your feedback helps us grow Fieldly.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: isMobile ? 13 : 14, color: Colors.grey[600]),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  // ── Form ──────────────────────────────────────────────────────────────────

  Widget _buildForm(BuildContext context, bool isMobile) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Sheet drag handle
        if (widget.isSheet) ...[_sheetHandle(), const SizedBox(height: 16)],

        // Title row
        Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2ECC71), Color(0xFF309448)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(11),
              ),
              child: const Icon(Icons.eco_rounded, color: Colors.white, size: 19),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Rate Fieldly',
                style: TextStyle(
                  fontSize: isMobile ? 18 : 20,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1A1A1A),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close_rounded, color: Color(0xFF9E9E9E)),
              onPressed: () => Navigator.of(context).pop(),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),

        const SizedBox(height: 6),
        Text(
          'How would you rate your experience?',
          style: TextStyle(fontSize: isMobile ? 12 : 13, color: Colors.grey[600]),
        ),

        SizedBox(height: isMobile ? 16 : 20),

        // Stars
        Center(child: _buildStarRow(isMobile)),
        const SizedBox(height: 6),
        Center(
          child: Text(
            _starLabel(_stars),
            style: TextStyle(
              fontSize: isMobile ? 12 : 13,
              fontWeight: FontWeight.w600,
              color: _stars > 0 ? _green : Colors.grey[400],
            ),
          ),
        ),

        SizedBox(height: isMobile ? 16 : 20),

        // Message field
        TextField(
          controller: _messageController,
          maxLines: isMobile ? 3 : 3,
          maxLength: 280,
          keyboardType: TextInputType.multiline,
          textInputAction: TextInputAction.newline,
          decoration: InputDecoration(
            hintText: 'Leave a message or feedback (optional)',
            hintStyle: TextStyle(color: Colors.grey[400], fontSize: isMobile ? 12 : 13),
            filled: true,
            fillColor: const Color(0xFFF8F8F8),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: _green, width: 1.5),
            ),
            counterStyle: TextStyle(color: Colors.grey[400], fontSize: 11),
          ),
        ),

        SizedBox(height: isMobile ? 16 : 20),

        // Buttons — stack vertically on very small screens
        isMobile
            ? _buildButtonsVertical(context)
            : _buildButtonsHorizontal(context),

        // Extra bottom breathing room on mobile (safe area)
        if (widget.isSheet) const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildButtonsHorizontal(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _cancelBtn(context)),
        const SizedBox(width: 12),
        Expanded(child: _submitBtn(context)),
      ],
    );
  }

  Widget _buildButtonsVertical(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _submitBtn(context),
        const SizedBox(height: 10),
        _cancelBtn(context),
      ],
    );
  }

  Widget _cancelBtn(BuildContext context) {
    return OutlinedButton(
      onPressed: () => Navigator.of(context).pop(),
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF757575),
        side: BorderSide(color: Colors.grey.shade300),
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      ),
      child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w600)),
    );
  }

  Widget _submitBtn(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: _stars > 0
            ? const LinearGradient(
                colors: [Color(0xFF2ECC71), Color(0xFF309448)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              )
            : LinearGradient(colors: [Colors.grey.shade300, Colors.grey.shade300]),
        borderRadius: BorderRadius.circular(28),
      ),
      child: ElevatedButton(
        onPressed: _stars > 0 ? () => _submit(context) : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          foregroundColor: Colors.white,
          disabledForegroundColor: Colors.white60,
          disabledBackgroundColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          elevation: 0,
        ),
        child: const Text('Submit', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
    );
  }

  Widget _buildStarRow(bool isMobile) {
    final starSize = isMobile ? 36.0 : 40.0;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final filled = i < _stars;
        return GestureDetector(
          onTap: () => setState(() => _stars = i + 1),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: EdgeInsets.symmetric(horizontal: isMobile ? 3 : 4),
            child: Icon(
              filled ? Icons.star_rounded : Icons.star_outline_rounded,
              size: starSize,
              color: filled ? const Color(0xFFFFC107) : Colors.grey.shade300,
            ),
          ),
        );
      }),
    );
  }

  Widget _sheetHandle() {
    return Center(
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  String _starLabel(int stars) {
    switch (stars) {
      case 1: return 'Poor';
      case 2: return 'Fair';
      case 3: return 'Good';
      case 4: return 'Great';
      case 5: return 'Excellent! ⭐';
      default: return 'Tap a star to rate';
    }
  }
}

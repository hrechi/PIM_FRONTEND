import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../theme/color_palette.dart';
import '../theme/text_styles.dart';
import 'add_staff_screen.dart';

/// Screen that displays all whitelisted staff members with their photos.
/// Allows deletion of staff members from the whitelist.
class StaffListScreen extends StatefulWidget {
  const StaffListScreen({super.key});

  @override
  State<StaffListScreen> createState() => _StaffListScreenState();
}

class _StaffListScreenState extends State<StaffListScreen> {
  List<Map<String, dynamic>> _staff = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadStaff();
  }

  // ── Load staff from backend ─────────────────────────────────

  Future<void> _loadStaff() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await ApiService.get('/staff', withAuth: true);
      
      setState(() {
        if (response is List) {
          _staff = List<Map<String, dynamic>>.from(response);
        } else {
          _staff = [];
        }
        _isLoading = false;
      });
    } on ApiException catch (e) {
      setState(() {
        _error = e.message;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load staff: $e';
        _isLoading = false;
      });
    }
  }

  // ── Delete staff member ─────────────────────────────────────

  Future<void> _deleteStaff(String staffId, String staffName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Remove Staff', style: AppTextStyles.h3()),
        content: Text(
          'Remove "$staffName" from the security whitelist?',
          style: AppTextStyles.bodyLarge(),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: GoogleFonts.inter()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(
              foregroundColor: AppColorPalette.alertError,
            ),
            child: Text('Remove', style: GoogleFonts.inter()),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await ApiService.delete('/staff/$staffId', withAuth: true);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Staff member removed', style: GoogleFonts.inter()),
          backgroundColor: AppColorPalette.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );

      _loadStaff(); // Refresh list
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message, style: GoogleFonts.inter()),
          backgroundColor: AppColorPalette.alertError,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  // ── Build ───────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColorPalette.wheatWarmClay,
      appBar: AppBar(
        backgroundColor: AppColorPalette.wheatWarmClay,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded,
              color: AppColorPalette.charcoalGreen),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Security Whitelist',
          style: AppTextStyles.h3(color: AppColorPalette.charcoalGreen),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded,
                color: AppColorPalette.charcoalGreen),
            onPressed: () async {
              final result = await Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AddStaffScreen()),
              );
              if (result == true) {
                _loadStaff(); // Refresh if staff was added
              }
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorView()
              : _staff.isEmpty
                  ? _buildEmptyView()
                  : _buildStaffList(),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 64,
              color: AppColorPalette.alertError.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load staff',
              style: AppTextStyles.h3(color: AppColorPalette.charcoalGreen),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? 'Unknown error',
              style: AppTextStyles.bodyMedium(color: AppColorPalette.softSlate),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadStaff,
              icon: const Icon(Icons.refresh_rounded),
              label: Text('Retry', style: GoogleFonts.inter()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: AppColorPalette.fieldFreshStart.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.shield_outlined,
                size: 64,
                color: AppColorPalette.fieldFreshStart.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Staff Added Yet',
              style: AppTextStyles.h2(color: AppColorPalette.charcoalGreen),
            ),
            const SizedBox(height: 8),
            Text(
              'Add authorized staff members to the security whitelist',
              style: AppTextStyles.bodyMedium(color: AppColorPalette.softSlate),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () async {
                final result = await Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AddStaffScreen()),
                );
                if (result == true) {
                  _loadStaff();
                }
              },
              icon: const Icon(Icons.add_rounded),
              label: Text('Add First Staff', style: GoogleFonts.inter()),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStaffList() {
    return RefreshIndicator(
      onRefresh: _loadStaff,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _staff.length,
        itemBuilder: (context, index) {
          final staff = _staff[index];
          final imageUrl = '${ApiService.baseUrl.replaceAll('/api', '')}${staff['imagePath']}';

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              leading: CircleAvatar(
                radius: 30,
                backgroundColor: AppColorPalette.fieldFreshStart.withValues(alpha: 0.1),
                backgroundImage: NetworkImage(imageUrl),
                onBackgroundImageError: (_, __) {},
                child: const Icon(
                  Icons.person_rounded,
                  color: AppColorPalette.fieldFreshStart,
                ),
              ),
              title: Text(
                staff['name'] ?? 'Unknown',
                style: AppTextStyles.h3(color: AppColorPalette.charcoalGreen),
              ),
              subtitle: Text(
                'Added ${_formatDate(staff['createdAt'])}',
                style: AppTextStyles.bodySmall(color: AppColorPalette.softSlate),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline_rounded),
                color: AppColorPalette.alertError,
                onPressed: () => _deleteStaff(staff['id'], staff['name']),
              ),
            ),
          );
        },
      ),
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'Unknown date';
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final diff = now.difference(date);

      if (diff.inDays == 0) return 'Today';
      if (diff.inDays == 1) return 'Yesterday';
      if (diff.inDays < 7) return '${diff.inDays} days ago';
      return '${date.day}/${date.month}/${date.year}';
    } catch (_) {
      return 'Unknown date';
    }
  }
}

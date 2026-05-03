import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/catalogue_provider.dart';
import '../../models/catalogue_models.dart';
import 'catalogue_wizard_screen.dart';
import 'catalogue_preview_screen.dart';
import 'catalogue_export_screen.dart';

const _kGreen = Color(0xFF309448);
const _kGreenLight = Color(0xFFE8F5E9);
const _kBg = Color(0xFFF5F7F5);

class CatalogueListScreen extends StatefulWidget {
  const CatalogueListScreen({super.key});

  @override
  State<CatalogueListScreen> createState() => _CatalogueListScreenState();
}

class _CatalogueListScreenState extends State<CatalogueListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CatalogueProvider>().loadCatalogues();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),
            Expanded(
              child: Consumer<CatalogueProvider>(
                builder: (context, provider, _) {
                  if (provider.isLoading && provider.catalogues.isEmpty) {
                    return const Center(child: CircularProgressIndicator(color: _kGreen));
                  }
                  if (provider.error != null) {
                    return _buildError(provider);
                  }
                  if (provider.catalogues.isEmpty) {
                    return _buildEmpty();
                  }
                  return RefreshIndicator(
                    color: _kGreen,
                    onRefresh: () => provider.loadCatalogues(),
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                      itemCount: provider.catalogues.length,
                      itemBuilder: (context, index) =>
                          _buildCard(context, provider.catalogues[index]),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _goToWizard(context),
        backgroundColor: _kGreen,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('New Catalogue', style: TextStyle(fontWeight: FontWeight.w600)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      ),
    );
  }

  // ── AppBar ────────────────────────────────────────────────────────────────

  Widget _buildAppBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: _kGreenLight, borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.menu_book_rounded, color: _kGreen, size: 22),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Sales Catalogues',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF1A1A1A))),
                Text('Manage your livestock catalogues',
                    style: TextStyle(fontSize: 12, color: Color(0xFF9E9E9E))),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: _kGreen, size: 26),
            onPressed: () => _goToWizard(context),
          ),
        ],
      ),
    );
  }

  // ── Empty ─────────────────────────────────────────────────────────────────

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100, height: 100,
              decoration: BoxDecoration(color: _kGreenLight, shape: BoxShape.circle),
              child: const Center(child: Text('📋', style: TextStyle(fontSize: 44))),
            ),
            const SizedBox(height: 20),
            const Text('No catalogues yet',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A))),
            const SizedBox(height: 8),
            const Text('Create your first sales catalogue to showcase your livestock to buyers.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Color(0xFF9E9E9E), height: 1.5)),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: () => _goToWizard(context),
              icon: const Icon(Icons.add),
              label: const Text('Create Catalogue'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _kGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError(CatalogueProvider provider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 48),
          const SizedBox(height: 12),
          Text(provider.error ?? 'Error', style: const TextStyle(color: Colors.red)),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: () => provider.loadCatalogues(), child: const Text('Retry')),
        ],
      ),
    );
  }

  // ── Catalogue card ────────────────────────────────────────────────────────

  Widget _buildCard(BuildContext context, SaleCatalogue catalogue) {
    final statusInfo = _statusInfo(catalogue.status);
    final animalCount = catalogue.animals.length;
    final df = DateFormat('MMM dd, yyyy');

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _showActions(context, catalogue),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Colored top strip ──
              Container(
                height: 6,
                decoration: BoxDecoration(
                  color: statusInfo.color,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title + status
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            catalogue.title,
                            style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusInfo.bg,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: statusInfo.border),
                          ),
                          child: Text(statusInfo.label,
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: statusInfo.color)),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    // Meta info
                    Wrap(
                      spacing: 16,
                      runSpacing: 6,
                      children: [
                        if (catalogue.location != null)
                          _metaItem(Icons.location_on_outlined, catalogue.location!),
                        if (catalogue.saleDate != null)
                          _metaItem(Icons.calendar_today_outlined, df.format(catalogue.saleDate!)),
                        _metaItem(Icons.pets_outlined,
                            '$animalCount animal${animalCount != 1 ? 's' : ''}'),
                        if (catalogue.shareToken != null)
                          _metaItem(Icons.share_outlined, 'Shared', color: _kGreen),
                      ],
                    ),

                    const SizedBox(height: 12),
                    const Divider(height: 1, color: Color(0xFFF0F0F0)),
                    const SizedBox(height: 10),

                    // Footer
                    Row(
                      children: [
                        Text(
                          'Created ${DateFormat('MMM dd').format(catalogue.createdAt)}',
                          style: const TextStyle(fontSize: 11, color: Color(0xFFBDBDBD)),
                        ),
                        const Spacer(),
                        // Quick action buttons
                        _quickBtn(Icons.visibility_outlined, 'Preview',
                            () => _openPreview(context, catalogue)),
                        const SizedBox(width: 8),
                        _quickBtn(Icons.edit_outlined, 'Edit', () {
                          Navigator.push(context, MaterialPageRoute(
                            builder: (_) => CatalogueWizardScreen(catalogue: catalogue)));
                        }),
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

  Widget _metaItem(IconData icon, String text, {Color? color}) {
    final c = color ?? const Color(0xFF9E9E9E);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: c),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(fontSize: 12, color: c, fontWeight: color != null ? FontWeight.w600 : FontWeight.normal)),
      ],
    );
  }

  Widget _quickBtn(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: _kGreenLight,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: _kGreen),
            const SizedBox(width: 4),
            Text(label, style: const TextStyle(fontSize: 11, color: _kGreen, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  // ── Status info ───────────────────────────────────────────────────────────

  _StatusInfo _statusInfo(String status) {
    switch (status.toUpperCase()) {
      case 'PUBLISHED':
        return _StatusInfo('Published', _kGreen, _kGreenLight, const Color(0xFFA5D6A7));
      case 'CLOSED':
        return _StatusInfo('Closed', const Color(0xFFC62828), const Color(0xFFFFEBEE), const Color(0xFFEF9A9A));
      case 'ARCHIVED':
        return _StatusInfo('Archived', const Color(0xFF37474F), const Color(0xFFECEFF1), const Color(0xFFB0BEC5));
      default:
        return _StatusInfo('Draft', const Color(0xFF757575), const Color(0xFFF5F5F5), const Color(0xFFBDBDBD));
    }
  }

  // ── Actions ───────────────────────────────────────────────────────────────

  void _showActions(BuildContext context, SaleCatalogue catalogue) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(width: 40, height: 4,
                decoration: BoxDecoration(color: const Color(0xFFE0E0E0), borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(catalogue.title,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A))),
            ),
            const Divider(height: 1),
            _actionTile(Icons.visibility_outlined, 'Preview', const Color(0xFF1565C0),
                () { Navigator.pop(context); _openPreview(context, catalogue); }),
            _actionTile(Icons.edit_outlined, 'Edit', const Color(0xFF757575), () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(
                  builder: (_) => CatalogueWizardScreen(catalogue: catalogue)));
            }),
            _actionTile(Icons.ios_share_outlined, 'Export & Share', const Color(0xFF757575), () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(
                  builder: (_) => CatalogueExportScreen(catalogue: catalogue)));
            }),
            if (catalogue.status.toLowerCase() == 'draft') ...[
              const Divider(height: 1),
              _actionTile(Icons.publish_outlined, 'Publish', _kGreen, () {
                Navigator.pop(context);
                _publish(context, catalogue);
              }),
            ],
            const Divider(height: 1),
            _actionTile(Icons.delete_outline, 'Delete',
                catalogue.status.toLowerCase() == 'draft' ? Colors.red : const Color(0xFFBDBDBD),
                () {
              Navigator.pop(context);
              _confirmDelete(context, catalogue);
            }),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _actionTile(IconData icon, String label, Color color, VoidCallback onTap) {
    return ListTile(
      leading: Container(
        width: 36, height: 36,
        decoration: BoxDecoration(color: color.withAlpha(20), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: color, size: 18),
      ),
      title: Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: color)),
      onTap: onTap,
    );
  }

  // ── Navigation helpers ────────────────────────────────────────────────────

  void _goToWizard(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const CatalogueWizardScreen()));
  }

  Future<void> _openPreview(BuildContext context, SaleCatalogue catalogue) async {
    final provider = context.read<CatalogueProvider>();
    showDialog(context: context, barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator(color: _kGreen)));
    await provider.loadCatalogue(catalogue.id);
    if (!context.mounted) return;
    Navigator.pop(context);
    final full = provider.currentCatalogue ?? catalogue;
    Navigator.push(context, MaterialPageRoute(builder: (_) => CataloguePreviewScreen(catalogue: full)));
  }

  void _publish(BuildContext context, SaleCatalogue catalogue) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Publish Catalogue'),
        content: const Text('Publishing will make this catalogue visible to buyers. Continue?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<CatalogueProvider>().updateCatalogue(catalogue.id, status: 'PUBLISHED');
            },
            style: ElevatedButton.styleFrom(backgroundColor: _kGreen, foregroundColor: Colors.white),
            child: const Text('Publish'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, SaleCatalogue catalogue) {
    // Guard: backend only allows deleting DRAFT catalogues
    if (catalogue.status.toLowerCase() != 'draft') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Cannot delete a ${catalogue.status.toLowerCase()} catalogue. '
            'Only draft catalogues can be deleted.',
          ),
          backgroundColor: Colors.orange[700],
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Catalogue'),
        content: Text('Delete "${catalogue.title}"? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<CatalogueProvider>().deleteCatalogue(catalogue.id);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _StatusInfo {
  final String label;
  final Color color, bg, border;
  const _StatusInfo(this.label, this.color, this.bg, this.border);
}

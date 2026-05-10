import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/catalogue_provider.dart';
import '../../models/catalogue_models.dart';

import '../../l10n/l10n_extensions.dart';

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
        label: Text(context.l10n.newCatalogue, style: const TextStyle(fontWeight: FontWeight.w600)),
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(context.l10n.salesCatalogues,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF1A1A1A))),
                Text(context.l10n.manageLivestockCatalogues,
                    style: const TextStyle(fontSize: 12, color: Color(0xFF9E9E9E))),
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
            Text(context.l10n.createFirstCatalogue,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: Color(0xFF9E9E9E), height: 1.5)),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: () => _goToWizard(context),
              icon: const Icon(Icons.add),
              label: Text(context.l10n.createCatalogue),
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
                        _quickBtn(Icons.visibility_outlined, context.l10n.preview,
                            () => _openPreview(context, catalogue)),
                        const SizedBox(width: 8),
                        _quickBtn(Icons.edit_outlined, context.l10n.edit, () {
                          Navigator.push<bool>(context, MaterialPageRoute(
                            builder: (_) => CatalogueWizardScreen(catalogue: catalogue),
                          )).then((_) {
                            if (mounted) context.read<CatalogueProvider>().loadCatalogues();
                          });
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
        return _StatusInfo(context.l10n.published, _kGreen, _kGreenLight, const Color(0xFFA5D6A7));
      case 'CLOSED':
        return _StatusInfo(context.l10n.closed, const Color(0xFFC62828), const Color(0xFFFFEBEE), const Color(0xFFEF9A9A));
      case 'ARCHIVED':
        return _StatusInfo(context.l10n.archived, const Color(0xFF37474F), const Color(0xFFECEFF1), const Color(0xFFB0BEC5));
      default:
        return _StatusInfo(context.l10n.draft, const Color(0xFF757575), const Color(0xFFF5F5F5), const Color(0xFFBDBDBD));
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
            _actionTile(Icons.visibility_outlined, context.l10n.preview, const Color(0xFF1565C0),
                () { Navigator.pop(context); _openPreview(context, catalogue); }),
            _actionTile(Icons.edit_outlined, context.l10n.edit, const Color(0xFF757575), () {
              Navigator.pop(context);
              Navigator.push<bool>(context, MaterialPageRoute(
                  builder: (_) => CatalogueWizardScreen(catalogue: catalogue),
              )).then((_) {
                if (mounted) context.read<CatalogueProvider>().loadCatalogues();
              });
            }),
            _actionTile(Icons.ios_share_outlined, context.l10n.exportShare, const Color(0xFF757575), () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(
                  builder: (_) => CatalogueExportScreen(catalogue: catalogue)));
            }),
            if (catalogue.status.toLowerCase() == 'draft') ...[
              const Divider(height: 1),
              _actionTile(Icons.publish_outlined, context.l10n.publish, _kGreen, () {
                Navigator.pop(context);
                _publish(context, catalogue);
              }),
            ],
            // Fix #5 — Permettre de repasser en brouillon depuis PUBLISHED ou CLOSED
            if (['published', 'closed'].contains(catalogue.status.toLowerCase())) ...[
              const Divider(height: 1),
              _actionTile(Icons.unpublished_outlined, 'Repasser en brouillon', const Color(0xFF757575), () {
                Navigator.pop(context);
                context.read<CatalogueProvider>().updateCatalogue(catalogue.id, status: 'DRAFT');
              }),
            ],
            const Divider(height: 1),
            _actionTile(Icons.delete_outline, context.l10n.delete,
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
    Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const CatalogueWizardScreen()),
    ).then((created) {
      // Reload the list after wizard closes so animal counts are up to date
      if (mounted) {
        context.read<CatalogueProvider>().loadCatalogues();
      }
    });
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
        title: Text(context.l10n.publishCatalogue),
        content: Text(context.l10n.publishConfirmBody),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(context.l10n.cancel)),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<CatalogueProvider>().updateCatalogue(catalogue.id, status: 'PUBLISHED');
            },
            style: ElevatedButton.styleFrom(backgroundColor: _kGreen, foregroundColor: Colors.white),
            child: Text(context.l10n.publish),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, SaleCatalogue catalogue) {
    if (catalogue.status.toLowerCase() != 'draft') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.cannotDeletePublished(catalogue.status.toLowerCase())),
          backgroundColor: Colors.orange[700],
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(context.l10n.deleteCatalogue),
        content: Text(context.l10n.deleteConfirmTitle(catalogue.title)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(context.l10n.cancel)),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<CatalogueProvider>().deleteCatalogue(catalogue.id);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: Text(context.l10n.delete),
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

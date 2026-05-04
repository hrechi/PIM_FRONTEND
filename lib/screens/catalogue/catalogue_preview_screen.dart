import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/catalogue_models.dart';
import '../../providers/catalogue_provider.dart';
import '../../widgets/animal_catalogue_card.dart';
import 'catalogue_export_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Palette
// ─────────────────────────────────────────────────────────────────────────────
const _kGreen = Color(0xFF309448);
const _kGreenLight = Color(0xFFE8F5E9);
const _kBg = Color(0xFFFAF7F2);

class CataloguePreviewScreen extends StatefulWidget {
  final SaleCatalogue catalogue;
  final bool isPreview;
  final VoidCallback? onBack;
  final VoidCallback? onNext;

  const CataloguePreviewScreen({
    super.key,
    required this.catalogue,
    this.isPreview = false,
    this.onBack,
    this.onNext,
  });

  @override
  State<CataloguePreviewScreen> createState() => _CataloguePreviewScreenState();
}

class _CataloguePreviewScreenState extends State<CataloguePreviewScreen> {
  late List<CatalogueAnimal> _animals;

  @override
  void initState() {
    super.initState();
    _animals = List.from(widget.catalogue.animals);
    _animals.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  }

  @override
  Widget build(BuildContext context) {
    // Embedded inside wizard — no Scaffold
    if (widget.isPreview) {
      return Column(
        children: [
          _header(),
          Expanded(child: _animals.isEmpty ? _empty() : _list()),
        ],
      );
    }

    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: Color(0xFF1A1A1A)),
          onPressed: widget.onBack ?? () => Navigator.pop(context),
        ),
        title: Text(
          widget.catalogue.title,
          style: const TextStyle(color: Color(0xFF1A1A1A), fontWeight: FontWeight.w700, fontSize: 17),
        ),
        actions: [
          if (widget.onNext != null)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: ElevatedButton.icon(
                onPressed: widget.onNext,
                icon: const Icon(Icons.arrow_forward, size: 16),
                label: const Text('Export'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          // Export button always visible when not in wizard
          if (widget.onNext == null)
            IconButton(
              icon: const Icon(Icons.ios_share_outlined, color: _kGreen),
              tooltip: 'Export & Share',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CatalogueExportScreen(catalogue: widget.catalogue),
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          _header(),
          Expanded(child: _animals.isEmpty ? _empty() : _list()),
        ],
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────

  Widget _header() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE))),
      ),
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
                  widget.catalogue.title,
                  style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A)),
                ),
              ),
              const SizedBox(width: 8),
              _statusBadge(widget.catalogue.status),
            ],
          ),

          if (widget.catalogue.location != null) ...[
            const SizedBox(height: 5),
            _metaRow(Icons.location_on_outlined, widget.catalogue.location!),
          ],
          if (widget.catalogue.saleDate != null) ...[
            const SizedBox(height: 3),
            _metaRow(Icons.calendar_today_outlined,
                'Sale: ${DateFormat('MMM dd, yyyy').format(widget.catalogue.saleDate!)}'),
          ],

          const SizedBox(height: 10),

          // Chips
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _chip(Icons.pets, '${_animals.length} animal${_animals.length != 1 ? 's' : ''}',
                  _kGreen, _kGreenLight, const Color(0xFFA5D6A7)),
              if (widget.catalogue.showPrices)
                _chip(Icons.sell_rounded, 'Prices in ${widget.catalogue.currency}',
                    const Color(0xFFE65100), const Color(0xFFFFF3E0), const Color(0xFFFFCC80)),
              if (widget.isPreview)
                _chip(Icons.preview_outlined, 'Preview',
                    const Color(0xFF1565C0), const Color(0xFFE3F2FD), const Color(0xFF90CAF9)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metaRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 13, color: const Color(0xFF9E9E9E)),
        const SizedBox(width: 5),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 12, color: Color(0xFF757575)))),
      ],
    );
  }

  Widget _chip(IconData icon, String label, Color text, Color bg, Color border) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: text),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 11, color: text, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _statusBadge(String status) {
    Color text, bg, border;
    String label;
    switch (status.toUpperCase()) {
      case 'PUBLISHED':
        text = const Color(0xFF2E7D32); bg = const Color(0xFFE8F5E9); border = const Color(0xFFA5D6A7); label = 'Published'; break;
      case 'CLOSED':
        text = const Color(0xFFC62828); bg = const Color(0xFFFFEBEE); border = const Color(0xFFEF9A9A); label = 'Closed'; break;
      case 'ARCHIVED':
        text = const Color(0xFF37474F); bg = const Color(0xFFECEFF1); border = const Color(0xFFB0BEC5); label = 'Archived'; break;
      default:
        text = const Color(0xFF757575); bg = const Color(0xFFF5F5F5); border = const Color(0xFFBDBDBD); label = 'Draft';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10), border: Border.all(color: border)),
      child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: text)),
    );
  }

  // ── Empty ─────────────────────────────────────────────────────────────────

  Widget _empty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(color: _kGreenLight, shape: BoxShape.circle),
            child: const Center(child: Text('🐾', style: TextStyle(fontSize: 36))),
          ),
          const SizedBox(height: 16),
          const Text('No animals yet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF616161))),
          const SizedBox(height: 6),
          Text(
            widget.isPreview ? 'Add animals in the previous step' : 'Add animals to see the preview',
            style: const TextStyle(fontSize: 13, color: Color(0xFF9E9E9E)),
          ),
        ],
      ),
    );
  }

  // ── List ──────────────────────────────────────────────────────────────────

  Widget _list() {
    final settings = widget.catalogue.settings;
    return ReorderableListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      itemCount: _animals.length,
      onReorder: _onReorder,
      itemBuilder: (context, index) => _card(_animals[index], index, settings),
    );
  }

  Widget _card(CatalogueAnimal ca, int index, CatalogueSettings settings) {
    final name = ca.animal?.name.isNotEmpty == true
        ? ca.animal!.name
        : (ca.animal?.tagNumber != null ? 'Tag: ${ca.animal!.tagNumber}' : 'Animal #${index + 1}');

    return Container(
      key: ValueKey(ca.animalId),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(12), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Top bar ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: const BoxDecoration(
              color: Color(0xFFF1F8F1),
              borderRadius: BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Container(
                  width: 26, height: 26,
                  decoration: const BoxDecoration(color: _kGreen, shape: BoxShape.circle),
                  child: Center(
                    child: Text('${index + 1}',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(name,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF1A1A1A))),
                ),
                ReorderableDragStartListener(
                  index: index,
                  child: const Icon(Icons.drag_handle, color: Color(0xFFBDBDBD), size: 20),
                ),
              ],
            ),
          ),

          // ── Body ──
          if (ca.animal != null)
            AnimalCatalogueCard(
              animal: ca.animal!,
              showDetails: settings.showDetails,
              showPhotos: settings.showPhotos,
              showHealth: settings.showHealth,
              showVaccinations: settings.showVaccinations,
              showProduction: settings.showProduction,
              showGenetics: settings.showGenetics,
              showPrices: widget.catalogue.showPrices,
              currency: widget.catalogue.currency,
              priceOverride: ca.priceOverride,
              notes: ca.notes,
              compactMode: settings.compactMode,
            )
          else
            _missingAnimal(ca),
        ],
      ),
    );
  }

  Widget _missingAnimal(CatalogueAnimal ca) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Color(0xFFFF8F00), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Animal data not available',
                    style: TextStyle(color: Color(0xFFE65100), fontWeight: FontWeight.w500, fontSize: 13)),
                Text('ID: ${ca.animalId}',
                    style: const TextStyle(color: Color(0xFF9E9E9E), fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      if (oldIndex < newIndex) newIndex -= 1;
      final item = _animals.removeAt(oldIndex);
      _animals.insert(newIndex, item);
      for (int i = 0; i < _animals.length; i++) {
        _animals[i] = _animals[i].copyWith(sortOrder: i);
      }
    });

    // Persist new sort order to backend — fire & forget, non-blocking
    // Only persist when viewing a real catalogue (not wizard preview)
    if (!widget.isPreview) {
      final provider = context.read<CatalogueProvider>();
      for (int i = 0; i < _animals.length; i++) {
        provider.updateCatalogueAnimal(
          widget.catalogue.id,
          _animals[i].animalId,
          sortOrder: i,
        );
      }
    }
  }
}

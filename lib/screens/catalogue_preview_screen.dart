import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/catalogue_models.dart';
import '../widgets/animal_catalogue_card.dart';

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
    if (widget.isPreview) {
      return Column(
        children: [
          _buildHeader(),
          Expanded(child: _animals.isEmpty ? _buildEmpty() : _buildList()),
        ],
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: Text(
          widget.catalogue.title,
          style: const TextStyle(
            color: Color(0xFF212121),
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF212121)),
        leading: widget.onBack != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: widget.onBack,
              )
            : null,
        actions: [
          if (widget.onNext != null)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ElevatedButton.icon(
                onPressed: widget.onNext,
                icon: const Icon(Icons.arrow_forward, size: 16),
                label: const Text('Export'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF309448),
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  textStyle: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(child: _animals.isEmpty ? _buildEmpty() : _buildList()),
        ],
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  widget.catalogue.title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A1A), // always dark
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _statusBadge(widget.catalogue.status),
            ],
          ),

          // Location
          if (widget.catalogue.location != null) ...[
            const SizedBox(height: 6),
            _headerRow(
              Icons.location_on_outlined,
              widget.catalogue.location!,
            ),
          ],

          // Sale date
          if (widget.catalogue.saleDate != null) ...[
            const SizedBox(height: 4),
            _headerRow(
              Icons.calendar_today_outlined,
              'Sale date: ${DateFormat('MMM dd, yyyy').format(widget.catalogue.saleDate!)}',
            ),
          ],

          const SizedBox(height: 10),

          // Chips row
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _chip(
                Icons.pets,
                '${_animals.length} animal${_animals.length != 1 ? 's' : ''}',
                const Color(0xFF2E7D32),
                const Color(0xFFE8F5E9),
                const Color(0xFFA5D6A7),
              ),
              if (widget.catalogue.showPrices)
                _chip(
                  Icons.sell_rounded,
                  'Prices in ${widget.catalogue.currency}',
                  const Color(0xFFE65100),
                  const Color(0xFFFFF3E0),
                  const Color(0xFFFFCC80),
                ),
              if (widget.isPreview)
                _chip(
                  Icons.preview,
                  'Preview mode',
                  const Color(0xFF1565C0),
                  const Color(0xFFE3F2FD),
                  const Color(0xFF90CAF9),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _headerRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: const Color(0xFF757575)),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 13, color: Color(0xFF616161)),
          ),
        ),
      ],
    );
  }

  Widget _chip(
    IconData icon,
    String label,
    Color textColor,
    Color bgColor,
    Color borderColor,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: textColor),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: textColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(String status) {
    Color textColor;
    Color bgColor;
    Color borderColor;
    String label;

    switch (status.toUpperCase()) {
      case 'PUBLISHED':
        textColor = const Color(0xFF2E7D32);
        bgColor = const Color(0xFFE8F5E9);
        borderColor = const Color(0xFFA5D6A7);
        label = 'Published';
        break;
      case 'CLOSED':
        textColor = const Color(0xFFC62828);
        bgColor = const Color(0xFFFFEBEE);
        borderColor = const Color(0xFFEF9A9A);
        label = 'Closed';
        break;
      case 'ARCHIVED':
        textColor = const Color(0xFF37474F);
        bgColor = const Color(0xFFECEFF1);
        borderColor = const Color(0xFFB0BEC5);
        label = 'Archived';
        break;
      default:
        textColor = const Color(0xFF616161);
        bgColor = const Color(0xFFF5F5F5);
        borderColor = const Color(0xFFBDBDBD);
        label = 'Draft';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
      ),
    );
  }

  // ── Empty state ────────────────────────────────────────────

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.pets, size: 64, color: Color(0xFFBDBDBD)),
          const SizedBox(height: 16),
          const Text(
            'No animals in this catalogue',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Color(0xFF9E9E9E),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.isPreview
                ? 'Add animals in the previous step'
                : 'Add animals to see the preview',
            style: const TextStyle(fontSize: 13, color: Color(0xFFBDBDBD)),
          ),
        ],
      ),
    );
  }

  // ── Animal list ────────────────────────────────────────────

  Widget _buildList() {
    final settings = widget.catalogue.settings;
    return ReorderableListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _animals.length,
      onReorder: _onReorder,
      itemBuilder: (context, index) {
        return _buildCard(_animals[index], index, settings);
      },
    );
  }

  Widget _buildCard(
    CatalogueAnimal ca,
    int index,
    CatalogueSettings settings,
  ) {
    final animalName = ca.animal?.name.isNotEmpty == true
        ? ca.animal!.name
        : (ca.animal?.tagNumber != null ? 'Tag: ${ca.animal!.tagNumber}' : 'Animal #${index + 1}');

    return Card(
      key: ValueKey(ca.animalId),
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 2,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Card top bar ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: const BoxDecoration(
              color: Color(0xFFF1F8F5), // very light green tint — NOT the primary green
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                // Index circle
                Container(
                  width: 28,
                  height: 28,
                  decoration: const BoxDecoration(
                    color: Color(0xFF309448),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // Animal name — dark text on light background
                Expanded(
                  child: Text(
                    animalName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: Color(0xFF1A1A1A), // always readable
                    ),
                  ),
                ),
                // Drag handle
                ReorderableDragStartListener(
                  index: index,
                  child: const Icon(
                    Icons.drag_handle,
                    color: Color(0xFF9E9E9E),
                  ),
                ),
              ],
            ),
          ),

          // ── Animal card body ──
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
            _buildMissingAnimal(ca),
        ],
      ),
    );
  }

  Widget _buildMissingAnimal(CatalogueAnimal ca) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Color(0xFFFF8F00)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Animal data not available',
                  style: TextStyle(
                    color: Color(0xFFE65100),
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
                Text(
                  'ID: ${ca.animalId}',
                  style: const TextStyle(
                    color: Color(0xFF9E9E9E),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Reorder ────────────────────────────────────────────────

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      if (oldIndex < newIndex) newIndex -= 1;
      final item = _animals.removeAt(oldIndex);
      _animals.insert(newIndex, item);
      for (int i = 0; i < _animals.length; i++) {
        _animals[i] = _animals[i].copyWith(sortOrder: i);
      }
    });
  }
}

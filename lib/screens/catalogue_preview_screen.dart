import 'package:flutter/material.dart';
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
    _sortAnimals();
  }

  void _sortAnimals() {
    _animals.sort((a, b) => (a.sortOrder ?? 0).compareTo(b.sortOrder ?? 0));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isPreview ? 'Preview Catalogue' : 'Catalogue Preview'),
        leading: widget.onBack != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: widget.onBack,
              )
            : null,
        actions: [
          if (widget.onNext != null)
            ElevatedButton.icon(
              onPressed: widget.onNext,
              icon: const Icon(Icons.arrow_forward),
              label: const Text('Export'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          _buildCatalogueHeader(),
          Expanded(
            child: _animals.isEmpty
                ? _buildEmptyState()
                : _buildAnimalList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCatalogueHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withAlpha(26),
        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.catalogue.title,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          if (widget.catalogue.location != null) ...[
            Row(
              children: [
                const Icon(Icons.location_on, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  widget.catalogue.location!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
          ],
          if (widget.catalogue.saleDate != null) ...[
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  'Sale Date: ${_formatDate(widget.catalogue.saleDate!)}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
          ],
          Row(
            children: [
              Text(
                '${_animals.length} animals',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
              if (widget.catalogue.showPrices) ...[
                const SizedBox(width: 16),
                const Icon(Icons.attach_money, size: 16, color: Colors.green),
                const SizedBox(width: 4),
                Text(
                  'Prices shown in ${widget.catalogue.currency}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.green,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No animals in catalogue',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Add animals to see the preview',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimalList() {
    return ReorderableListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _animals.length,
      onReorder: _onReorder,
      itemBuilder: (context, index) {
        final catalogueAnimal = _animals[index];
        return _buildReorderableAnimalCard(catalogueAnimal, index);
      },
    );
  }

  Widget _buildReorderableAnimalCard(CatalogueAnimal catalogueAnimal, int index) {
    return ReorderableDelayedDragStartListener(
      key: ValueKey(catalogueAnimal.animalId),
      index: index,
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: Column(
          children: [
            // Drag handle
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  Text(
                    '${index + 1}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Icon(Icons.drag_handle, color: Colors.grey),
                  const Spacer(),
                  if (widget.isPreview)
                    Text(
                      'Preview Mode',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                ],
              ),
            ),
            // Animal card content
            if (catalogueAnimal.animal != null)
              AnimalCatalogueCard(
                animal: catalogueAnimal.animal!,
                showDetails: widget.catalogue.settings?.showDetails ?? true,
                showPhotos: widget.catalogue.settings?.showPhotos ?? true,
                showHealth: widget.catalogue.settings?.showHealth ?? false,
                showVaccinations: widget.catalogue.settings?.showVaccinations ?? false,
                showProduction: widget.catalogue.settings?.showProduction ?? false,
                showGenetics: widget.catalogue.settings?.showGenetics ?? false,
                showPrices: widget.catalogue.showPrices,
                currency: widget.catalogue.currency,
                priceOverride: catalogueAnimal.priceOverride,
                notes: catalogueAnimal.notes,
                compactMode: widget.catalogue.settings?.compactMode ?? false,
              )
            else
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Animal data unavailable',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      if (oldIndex < newIndex) {
        newIndex -= 1;
      }
      final item = _animals.removeAt(oldIndex);
      _animals.insert(newIndex, item);

      // Update sort orders
      for (int i = 0; i < _animals.length; i++) {
        _animals[i] = _animals[i].copyWith(sortOrder: i);
      }
    });
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
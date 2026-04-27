import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/catalogue_provider.dart';
import '../models/catalogue_models.dart';
import '../theme/app_theme.dart';
import 'catalogue_wizard_screen.dart';
import 'catalogue_preview_screen.dart';
import 'catalogue_export_screen.dart';

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
      appBar: AppBar(
        title: const Text('Sales Catalogues'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _navigateToWizard(context),
          ),
        ],
      ),
      body: Consumer<CatalogueProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.catalogues.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Error: ${provider.error}',
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => provider.loadCatalogues(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (provider.catalogues.isEmpty) {
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
                    'No catalogues yet',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Create your first sales catalogue',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[500],
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => _navigateToWizard(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Create Catalogue'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => provider.loadCatalogues(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: provider.catalogues.length,
              itemBuilder: (context, index) {
                final catalogue = provider.catalogues[index];
                return _buildCatalogueCard(context, catalogue);
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToWizard(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildCatalogueCard(BuildContext context, SaleCatalogue catalogue) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () => _showCatalogueActions(context, catalogue),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      catalogue.title,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  _buildStatusBadge(catalogue.status),
                ],
              ),
              if (catalogue.location != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      catalogue.location!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
              if (catalogue.saleDate != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      DateFormat('MMM dd, yyyy').format(catalogue.saleDate!),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(
                    '${catalogue.animals.length} animals',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  if (catalogue.shareToken != null) ...[
                    const SizedBox(width: 16),
                    const Icon(Icons.share, size: 16, color: Colors.green),
                    const SizedBox(width: 4),
                    Text(
                      'Shared',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.green,
                      ),
                    ),
                  ],
                  const Spacer(),
                  Text(
                    DateFormat('MMM dd').format(catalogue.createdAt),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String label;

    switch (status.toLowerCase()) {
      case 'draft':
        color = Colors.grey;
        label = 'Draft';
        break;
      case 'published':
        color = Colors.green;
        label = 'Published';
        break;
      case 'archived':
        color = Colors.blue;
        label = 'Archived';
        break;
      default:
        color = Colors.grey;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  void _navigateToWizard(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CatalogueWizardScreen(),
      ),
    );
  }

  void _showCatalogueActions(BuildContext context, SaleCatalogue catalogue) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.visibility),
              title: const Text('Preview'),
              onTap: () {
                Navigator.pop(context);
                _openPreview(context, catalogue);
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CatalogueWizardScreen(catalogue: catalogue),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('Export & Share'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CatalogueExportScreen(catalogue: catalogue),
                  ),
                );
              },
            ),
            if (catalogue.status.toLowerCase() == 'draft') ...[
              const Divider(),
              ListTile(
                leading: const Icon(Icons.publish, color: Colors.green),
                title: const Text('Publish'),
                onTap: () {
                  Navigator.pop(context);
                  _publishCatalogue(context, catalogue);
                },
              ),
            ],
            const Divider(),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _confirmDelete(context, catalogue);
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Load the full catalogue (with animal details) then open preview.
  Future<void> _openPreview(BuildContext context, SaleCatalogue catalogue) async {
    final provider = context.read<CatalogueProvider>();

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    await provider.loadCatalogue(catalogue.id);

    if (!context.mounted) return;
    Navigator.pop(context); // close loading

    final full = provider.currentCatalogue ?? catalogue;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CataloguePreviewScreen(catalogue: full),
      ),
    );
  }

  void _publishCatalogue(BuildContext context, SaleCatalogue catalogue) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Publish Catalogue'),
        content: const Text(
          'Publishing will make this catalogue visible to buyers. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<CatalogueProvider>().updateCatalogue(
                catalogue.id,
                status: 'PUBLISHED',
              );
            },
            child: const Text('Publish'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, SaleCatalogue catalogue) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Catalogue'),
        content: Text(
          'Delete "${catalogue.title}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(context);
              context.read<CatalogueProvider>().deleteCatalogue(catalogue.id);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
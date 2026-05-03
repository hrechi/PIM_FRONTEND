import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../providers/catalogue_provider.dart';
import '../models/catalogue_models.dart';
import '../theme/app_theme.dart';
import '../utils/constants.dart';
import '../catalogue/catalogue_book_screen.dart';

const _kGreen = Color(0xFF309448);
const _kGreenLight = Color(0xFFE8F5E9);

class CatalogueExportScreen extends StatefulWidget {
  final SaleCatalogue catalogue;
  final bool isPreview;

  const CatalogueExportScreen({
    super.key,
    required this.catalogue,
    this.isPreview = false,
  });

  @override
  State<CatalogueExportScreen> createState() => _CatalogueExportScreenState();
}

class _CatalogueExportScreenState extends State<CatalogueExportScreen> {
  bool _isGeneratingPdf = false;
  bool _isSharing = false;
  String? _pdfUrl;
  String? _shareLink;

  @override
  void initState() {
    super.initState();
    // Restore share link from existing token without an API call,
    // but only if the token is not expired.
    if (widget.catalogue.shareToken != null) {
      final isExpired = widget.catalogue.shareExpiresAt != null &&
          widget.catalogue.shareExpiresAt!.isBefore(DateTime.now());
      if (!isExpired) {
        _shareLink = AppConfig.publicCatalogueUrl(widget.catalogue.shareToken!);
      }
      // If expired, _shareLink stays null — user must generate a new one.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Export Catalogue'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCatalogueSummary(),
            const SizedBox(height: 24),
            _buildExportOptions(),
            const SizedBox(height: 24),
            _buildShareOptions(),
            if (widget.isPreview) ...[
              const SizedBox(height: 24),
              _buildPreviewNotice(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCatalogueSummary() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Catalogue Summary',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            _buildSummaryRow('Title', widget.catalogue.title),
            if (widget.catalogue.location != null)
              _buildSummaryRow('Location', widget.catalogue.location!),
            if (widget.catalogue.saleDate != null)
              _buildSummaryRow('Sale Date', _formatDate(widget.catalogue.saleDate!)),
            _buildSummaryRow('Animals', '${widget.catalogue.animals.length}'),
            _buildSummaryRow('Status', widget.catalogue.status.toUpperCase()),
            if (widget.catalogue.showPrices)
              _buildSummaryRow('Currency', widget.catalogue.currency),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExportOptions() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Export Options',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            _buildExportButton(
              icon: Icons.auto_stories,
              title: 'View as Book',
              subtitle: 'Browse catalogue page by page — cover, animals, back cover',
              onPressed: _generatePdf,
              isLoading: _isGeneratingPdf,
            ),
            const SizedBox(height: 12),
            _buildExportButton(
              icon: Icons.print,
              title: 'Print Catalogue',
              subtitle: 'Send to printer for physical copies',
              onPressed: _printCatalogue,
            ),
            const SizedBox(height: 12),
            _buildExportButton(
              icon: Icons.email,
              title: 'Email Catalogue',
              subtitle: 'Send PDF via email to buyers',
              onPressed: _emailCatalogue,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExportButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onPressed,
    bool isLoading = false,
  }) {
    return InkWell(
      onTap: isLoading ? null : onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 24,
              color: isLoading ? Colors.grey : Theme.of(context).primaryColor,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: isLoading ? Colors.grey : null,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            if (isLoading)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildShareOptions() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Share Options',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            if (_shareLink != null) ...[
              _buildShareLinkSection(),
              const SizedBox(height: 16),
            ],
            _buildShareButton(
              icon: Icons.link,
              title: 'Generate Share Link',
              subtitle: 'Create a public link for buyers to view',
              onPressed: _generateShareLink,
              isLoading: _isSharing,
            ),
            const SizedBox(height: 12),
            _buildShareButton(
              icon: Icons.share,
              title: 'Share Catalogue',
              subtitle: 'Share via social media or messaging',
              onPressed: _shareCatalogue,
            ),
            const SizedBox(height: 12),
            _buildShareButton(
              icon: Icons.qr_code,
              title: 'QR Code',
              subtitle: 'Generate QR code for easy access',
              onPressed: _generateQrCode,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShareLinkSection() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.link, color: Colors.green),
              const SizedBox(width: 8),
              Text(
                'Share Link Generated',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Colors.green[800],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _shareLink!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.green[700],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _copyShareLink,
                  icon: const Icon(Icons.copy, size: 16),
                  label: const Text('Copy'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.green[700],
                    side: BorderSide(color: Colors.green[300]!),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _revokeShareLink,
                  icon: const Icon(Icons.delete, size: 16),
                  label: const Text('Revoke'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red[700],
                    side: BorderSide(color: Colors.red[300]!),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildShareButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onPressed,
    bool isLoading = false,
  }) {
    return InkWell(
      onTap: isLoading ? null : onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 24,
              color: isLoading ? Colors.grey : Theme.of(context).primaryColor,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: isLoading ? Colors.grey : null,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            if (isLoading)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewNotice() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Row(
        children: [
          const Icon(Icons.info, color: Colors.blue),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'This is a preview. Save the catalogue to enable PDF generation and sharing.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.blue[800],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _generatePdf() async {
    if (widget.isPreview) {
      _showPreviewNotice();
      return;
    }

    // Open the book-style PDF viewer
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CatalogueBookScreen(catalogue: widget.catalogue),
        ),
      );
    }
  }

  Future<void> _printCatalogue() async {
    if (widget.isPreview) {
      _showPreviewNotice();
      return;
    }

    // TODO: Implement print functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Print functionality coming soon')),
    );
  }

  Future<void> _emailCatalogue() async {
    if (widget.isPreview) {
      _showPreviewNotice();
      return;
    }

    // TODO: Implement email functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Email functionality coming soon')),
    );
  }

  Future<void> _generateShareLink() async {
    if (widget.isPreview) {
      _showPreviewNotice();
      return;
    }

    setState(() => _isSharing = true);

    try {
      final provider = context.read<CatalogueProvider>();
      final updatedCatalogue = await provider.generateShareLink(widget.catalogue.id);

      if (updatedCatalogue != null && mounted) {
        setState(() {
          _shareLink = AppConfig.publicCatalogueUrl(updatedCatalogue.shareToken!);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to generate share link: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSharing = false);
      }
    }
  }

  Future<void> _shareCatalogue() async {
    if (_shareLink == null) {
      await _generateShareLink();
      if (_shareLink == null) return;
    }

    final text = 'Check out our animal sale catalogue: ${_shareLink!}';
    await Share.share(text);
  }

  Future<void> _generateQrCode() async {
    if (_shareLink == null) {
      await _generateShareLink();
      if (_shareLink == null) return;
    }

    // TODO: Implement QR code generation
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('QR code functionality coming soon')),
    );
  }

  Future<void> _copyShareLink() async {
    if (_shareLink != null) {
      await Clipboard.setData(ClipboardData(text: _shareLink!));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Share link copied to clipboard')),
        );
      }
    }
  }

  Future<void> _revokeShareLink() async {
    setState(() => _isSharing = true);

    try {
      final provider = context.read<CatalogueProvider>();
      await provider.revokeShareLink(widget.catalogue.id);

      if (mounted) {
        setState(() => _shareLink = null);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Share link revoked')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to revoke share link: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSharing = false);
      }
    }
  }

  void _showPdfSuccess(String pdfUrl) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('PDF Generated'),
        content: const Text('Your catalogue PDF has been generated successfully.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Open PDF viewer or download
            },
            child: const Text('View PDF'),
          ),
        ],
      ),
    );
  }

  void _showPreviewNotice() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Please save the catalogue first to enable export features'),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
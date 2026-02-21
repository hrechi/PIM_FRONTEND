import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/parcel.dart';
import '../providers/parcel_provider.dart';
import '../theme/app_theme.dart';
import '../utils/constants.dart';
import 'add_parcel_screen.dart';

class ParcelDetailScreen extends StatefulWidget {
  final Parcel parcel;

  const ParcelDetailScreen({super.key, required this.parcel});

  @override
  State<ParcelDetailScreen> createState() => _ParcelDetailScreenState();
}

class _ParcelDetailScreenState extends State<ParcelDetailScreen> {
  void _deleteParcel() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Parcel'),
        content: const Text('Are you sure you want to delete this parcel? This will delete all its crops and history.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    if (!mounted) return;
    try {
      await Provider.of<ParcelProvider>(context, listen: false).deleteParcel(widget.parcel.id);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Parcel deleted')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  // Dialogs for Nested Entities
  Future<void> _showAddCropDialog() async {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController();
    final varietyCtrl = TextEditingController();
    DateTime? plantingDate;
    DateTime? harvestDate;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateSB) {
          return AlertDialog(
            title: const Text('Add Crop'),
            content: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(labelText: 'Crop Name *'),
                      validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                    ),
                    TextFormField(
                      controller: varietyCtrl,
                      decoration: const InputDecoration(labelText: 'Variety *'),
                      validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                    ),
                    ListTile(
                      title: Text(plantingDate == null ? 'Planting Date *' : DateFormat.yMd().format(plantingDate!)),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final d = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2000), lastDate: DateTime(2100));
                        if(d != null) setStateSB(() => plantingDate = d);
                      },
                    ),
                    ListTile(
                      title: Text(harvestDate == null ? 'Expected Harvest *' : DateFormat.yMd().format(harvestDate!)),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final d = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2000), lastDate: DateTime(2100));
                        if(d != null) setStateSB(() => harvestDate = d);
                      },
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () async {
                  if (formKey.currentState!.validate() && plantingDate != null && harvestDate != null) {
                    Navigator.pop(context);
                    await Provider.of<ParcelProvider>(this.context, listen: false).addCropToParcel(widget.parcel.id, {
                      'cropName': nameCtrl.text,
                      'variety': varietyCtrl.text,
                      'plantingDate': plantingDate!.toIso8601String(),
                      'expectedHarvestDate': harvestDate!.toIso8601String(),
                    });
                  }
                },
                child: const Text('Add'),
              ),
            ],
          );
        }
      ),
    );
  }

  Future<void> _showAddFertilizationDialog() async {
    final formKey = GlobalKey<FormState>();
    final typeCtrl = TextEditingController();
    final qtyCtrl = TextEditingController();
    DateTime? appDate;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateSB) {
          return AlertDialog(
            title: const Text('Add Fertilization'),
            content: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: typeCtrl,
                      decoration: const InputDecoration(labelText: 'Fertilizer Type *'),
                      validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                    ),
                    TextFormField(
                      controller: qtyCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Quantity Used (units) *'),
                      validator: (val) => val == null || double.tryParse(val) == null ? 'Valid number required' : null,
                    ),
                    ListTile(
                      title: Text(appDate == null ? 'Application Date *' : DateFormat.yMd().format(appDate!)),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final d = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2000), lastDate: DateTime(2100));
                        if(d != null) setStateSB(() => appDate = d);
                      },
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () async {
                  if (formKey.currentState!.validate() && appDate != null) {
                    Navigator.pop(context);
                    await Provider.of<ParcelProvider>(this.context, listen: false).addFertilizationToParcel(widget.parcel.id, {
                      'fertilizerType': typeCtrl.text,
                      'quantityUsed': double.parse(qtyCtrl.text),
                      'applicationDate': appDate!.toIso8601String(),
                    });
                  }
                },
                child: const Text('Add'),
              ),
            ],
          );
        }
      ),
    );
  }
  
  Future<void> _showAddPestDialog() async {
    final formKey = GlobalKey<FormState>();
    final issueCtrl = TextEditingController();
    final treatmentCtrl = TextEditingController();
    DateTime? treatDate;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateSB) {
          return AlertDialog(
            title: const Text('Add Pest/Disease Record'),
            content: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: issueCtrl,
                      decoration: const InputDecoration(labelText: 'Issue Type (Optional)'),
                    ),
                    TextFormField(
                      controller: treatmentCtrl,
                      decoration: const InputDecoration(labelText: 'Treatment Used (Optional)'),
                    ),
                    ListTile(
                      title: Text(treatDate == null ? 'Treatment Date (Optional)' : DateFormat.yMd().format(treatDate!)),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final d = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2000), lastDate: DateTime(2100));
                        if(d != null) setStateSB(() => treatDate = d);
                      },
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () async {
                  if (formKey.currentState!.validate()) {
                    Navigator.pop(context);
                    await Provider.of<ParcelProvider>(this.context, listen: false).addPestToParcel(widget.parcel.id, {
                      if (issueCtrl.text.isNotEmpty) 'issueType': issueCtrl.text,
                      if (treatmentCtrl.text.isNotEmpty) 'treatmentUsed': treatmentCtrl.text,
                      if (treatDate != null) 'treatmentDate': treatDate!.toIso8601String(),
                    });
                  }
                },
                child: const Text('Add'),
              ),
            ],
          );
        }
      ),
    );
  }
  
  Future<void> _showAddHarvestDialog() async {
    final formKey = GlobalKey<FormState>();
    final totalCtrl = TextEditingController();
    final yieldCtrl = TextEditingController();
    DateTime? harvestDate;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateSB) {
          return AlertDialog(
            title: const Text('Record Harvest'),
            content: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: totalCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Total Yield (Optional)'),
                    ),
                    TextFormField(
                      controller: yieldCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Yield Per Hectare (Optional)'),
                    ),
                    ListTile(
                      title: Text(harvestDate == null ? 'Harvest Date (Optional)' : DateFormat.yMd().format(harvestDate!)),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final d = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2000), lastDate: DateTime(2100));
                        if(d != null) setStateSB(() => harvestDate = d);
                      },
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () async {
                  if (formKey.currentState!.validate()) {
                    Navigator.pop(context);
                    await Provider.of<ParcelProvider>(this.context, listen: false).addHarvestToParcel(widget.parcel.id, {
                      if (totalCtrl.text.isNotEmpty) 'totalYield': double.parse(totalCtrl.text),
                      if (yieldCtrl.text.isNotEmpty) 'yieldPerHectare': double.parse(yieldCtrl.text),
                      if (harvestDate != null) 'harvestDate': harvestDate!.toIso8601String(),
                    });
                  }
                },
                child: const Text('Add'),
              ),
            ],
          );
        }
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ParcelProvider>(context);
    if (provider.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    
    final currentParcel = provider.parcels.firstWhere(
      (p) => p.id == widget.parcel.id,
      orElse: () => widget.parcel,
    );

    return Scaffold(
      backgroundColor: AppColors.wheatWarmClay,
      appBar: AppBar(
        title: const Text('Parcel Details', style: TextStyle(color: AppColors.primaryText, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.emeraldGreen),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: AppColors.emeraldGreen),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => AddParcelScreen(existingParcel: currentParcel)),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.redAccent),
            onPressed: _deleteParcel,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // General Info Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(currentParcel.location, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primaryText)),
                    const SizedBox(height: 8),
                    _buildInfoRow(Icons.square_foot, 'Area:', '${currentParcel.areaSize} ha/m²'),
                    _buildInfoRow(Icons.map, 'Boundaries:', currentParcel.boundariesDescription),
                    const Divider(height: 24),
                    const Text('Soil & Irrigation', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    _buildInfoRow(Icons.grass, 'Type:', currentParcel.soilType),
                    _buildInfoRow(Icons.science, 'pH / N-P-K:', '${currentParcel.soilPh ?? "N/A"} / ${currentParcel.nitrogenLevel ?? "-"}-${currentParcel.phosphorusLevel ?? "-"}-${currentParcel.potassiumLevel ?? "-"}'),
                    _buildInfoRow(Icons.water_drop, 'Water:', currentParcel.waterSource),
                    _buildInfoRow(Icons.shower, 'Method:', '${currentParcel.irrigationMethod} (${currentParcel.irrigationFrequency})'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Nested sections
            _buildSection(
              title: 'Crops',
              icon: Icons.eco,
              items: currentParcel.crops,
              onAdd: _showAddCropDialog,
              itemBuilder: (crop) => ListTile(
                title: Text('${crop.cropName} (${crop.variety})', style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('Planted: ${DateFormat.yMd().format(crop.plantingDate)} | Harvest: ${DateFormat.yMd().format(crop.expectedHarvestDate)}'),
              ),
            ),
            
            _buildSection(
              title: 'Fertilization',
              icon: Icons.sanitizer,
              items: currentParcel.fertilizations,
              onAdd: _showAddFertilizationDialog,
              itemBuilder: (f) => ListTile(
                title: Text(f.fertilizerType, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('Qty: ${f.quantityUsed} | Date: ${DateFormat.yMd().format(f.applicationDate)}'),
              ),
            ),

            _buildSection(
              title: 'Pests & Diseases',
              icon: Icons.bug_report,
              items: currentParcel.pests,
              onAdd: _showAddPestDialog,
              itemBuilder: (p) => ListTile(
                title: Text(p.issueType ?? 'Unknown Issue', style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('Treatment: ${p.treatmentUsed ?? "None"} | Date: ${p.treatmentDate != null ? DateFormat.yMd().format(p.treatmentDate!) : "Unknown"}'),
              ),
            ),

            _buildSection(
              title: 'Harvests',
              icon: Icons.agriculture,
              items: currentParcel.harvests,
              onAdd: _showAddHarvestDialog,
              itemBuilder: (h) => ListTile(
                title: Text('Yield: ${h.totalYield ?? "?"} | Per Ha: ${h.yieldPerHectare ?? "?"}', style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('Date: ${h.harvestDate != null ? DateFormat.yMd().format(h.harvestDate!) : "Unknown"}'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.emeraldGreen),
          const SizedBox(width: 8),
          Text('$label ', style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.secondaryText)),
          Expanded(child: Text(value, style: const TextStyle(color: Colors.black87))),
        ],
      ),
    );
  }

  Widget _buildSection<T>({
    required String title,
    required IconData icon,
    required List<T> items,
    required VoidCallback onAdd,
    required Widget Function(T) itemBuilder,
  }) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ExpansionTile(
        initiallyExpanded: items.isNotEmpty,
        leading: Icon(icon, color: AppColors.emeraldGreen),
        title: Text('$title (${items.length})', style: const TextStyle(fontWeight: FontWeight.bold)),
        children: [
          ...items.map(itemBuilder),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: Text('Add $title'),
              style: TextButton.styleFrom(foregroundColor: AppColors.emeraldGreen),
            ),
          ),
        ],
      ),
    );
  }
}

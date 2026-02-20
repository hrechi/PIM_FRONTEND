import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/parcel.dart';
import '../providers/parcel_provider.dart';
import '../theme/app_theme.dart';
import '../utils/constants.dart';
import 'add_parcel_screen.dart';
import 'parcel_detail_screen.dart';

class ParcelListScreen extends StatefulWidget {
  const ParcelListScreen({super.key});

  @override
  State<ParcelListScreen> createState() => _ParcelListScreenState();
}

class _ParcelListScreenState extends State<ParcelListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ParcelProvider>(context, listen: false).fetchParcels();
    });
  }

  @override
  Widget build(BuildContext context) {
    final parcelProvider = Provider.of<ParcelProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.wheatWarmClay,
      appBar: AppBar(
        title: const Text('My Parcels', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryText)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.emeraldGreen),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: AppColors.emeraldGreen),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddParcelScreen()),
              );
            },
          )
        ],
      ),
      body: parcelProvider.isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.emeraldGreen))
          : parcelProvider.error != null
              ? Center(
                  child: Text(
                    'Failed to load parcels:\n${parcelProvider.error}',
                    textAlign: TextAlign.center,
                  ),
                )
              : parcelProvider.parcels.isEmpty
                  ? const Center(child: Text('No parcels added yet. Add your first parcel!'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: parcelProvider.parcels.length,
                      itemBuilder: (context, index) {
                        final Parcel parcel = parcelProvider.parcels[index];
                        return _buildParcelCard(context, parcel);
                      },
                    ),
    );
  }

  Widget _buildParcelCard(BuildContext context, Parcel parcel) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ParcelDetailScreen(parcel: parcel),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppColors.emeraldGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.map, color: AppColors.emeraldGreen, size: 30),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      parcel.location,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Size: ${parcel.areaSize} ha/m²',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Crops: ${parcel.crops.length} | Soil: ${parcel.soilType}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.secondaryText,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/vaccine_provider.dart';
import '../../utils/constants.dart';

class VaccineHistoryScreen extends StatefulWidget {
  final String animalId;
  final String animalName;

  const VaccineHistoryScreen({super.key, required this.animalId, required this.animalName});

  @override
  State<VaccineHistoryScreen> createState() => _VaccineHistoryScreenState();
}

class _VaccineHistoryScreenState extends State<VaccineHistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<VaccineProvider>().loadForAnimal(widget.animalId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd MMM yyyy', 'en_US');

    return Scaffold(
      backgroundColor: AppColors.wheatWarmClay,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF1E293B)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Health Record', style: TextStyle(color: Color(0xFF1E293B), fontSize: 16, fontWeight: FontWeight.w800)),
            Text(widget.animalName, style: const TextStyle(color: Color(0xFF64748B), fontSize: 12)),
          ],
        ),
      ),
      body: Consumer<VaccineProvider>(
        builder: (_, prov, _) {
          if (prov.isLoading) return const Center(child: CircularProgressIndicator(color: AppColors.mistBlue));

          final records = prov.records;
          if (records.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.history_edu_outlined, size: 64, color: Color(0xFFCBD5E1)),
                  const SizedBox(height: 16),
                  const Text('No vaccinations recorded', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: records.length,
            itemBuilder: (_, i) {
              final record = records[i];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: AppColors.mistBlue.withValues(alpha: 0.1), shape: BoxShape.circle),
                          child: const Icon(Icons.vaccines_rounded, color: AppColors.mistBlue, size: 18),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            (record.vaccine?.code == 'OTHER' ? record.notes : record.vaccine?.nameEn) ?? record.notes ?? 'Vaccine',
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: Color(0xFF1E293B)),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: const Color(0xFFF0FDF4), borderRadius: BorderRadius.circular(12)),
                          child: const Text('DONE', style: TextStyle(color: Color(0xFF16A34A), fontSize: 10, fontWeight: FontWeight.w700)),
                        ),
                      ]),
                      const SizedBox(height: 12),
                      _info(Icons.calendar_today_rounded, fmt.format(record.administeredAt)),
                      _info(Icons.person_outline_rounded, 'Dr. ${record.administeredBy}'),
                      _info(Icons.water_drop_outlined, '${record.doseGiven} ${record.doseUnit}'),
                      if (record.lotNumber != null) _info(Icons.tag_rounded, 'Lot: ${record.lotNumber}'),
                      if (record.nextDueDate != null) ...[
                        const Divider(height: 20),
                        Row(children: [
                          const Icon(Icons.update_rounded, size: 14, color: Color(0xFF64748B)),
                          const SizedBox(width: 6),
                          Text('Next booster: ${fmt.format(record.nextDueDate!)}',
                              style: const TextStyle(color: Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.w500)),
                        ]),
                      ],
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _info(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(children: [
        Icon(icon, size: 14, color: const Color(0xFF64748B)),
        const SizedBox(width: 8),
        Text(text, style: const TextStyle(color: Color(0xFF475569), fontSize: 13)),
      ]),
    );
  }
}

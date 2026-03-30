import 'package:flutter/material.dart';
import '../models/crop_calendar_model.dart';
import '../services/parcel_crud_service.dart';
import '../theme/color_palette.dart';
import '../theme/text_styles.dart';

class CropCalendarScreen extends StatefulWidget {
  final String? parcelId;
  final String? parcelName;

  const CropCalendarScreen({
    super.key,
    this.parcelId,
    this.parcelName,
  });

  @override
  State<CropCalendarScreen> createState() => _CropCalendarScreenState();
}

class _CropCalendarScreenState extends State<CropCalendarScreen> {
  final ParcelCrudService _service = ParcelCrudService();
  late Future<List<CropCalendarItem>> _calendarFuture;

  @override
  void initState() {
    super.initState();
    if (widget.parcelId != null) {
      _calendarFuture = _service.getParcelCalendar(widget.parcelId!);
    } else {
      _calendarFuture = _service.getGlobalCalendar();
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.parcelName != null 
        ? '${widget.parcelName} Calendar' 
        : 'Farm Crop Calendar';
    return Scaffold(
      backgroundColor: AppColorPalette.wheatWarmClay,
      appBar: AppBar(
        title: Text(
          title,
          style: AppTextStyles.h3(color: AppColorPalette.charcoalGreen),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColorPalette.charcoalGreen),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: FutureBuilder<List<CropCalendarItem>>(
        future: _calendarFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: AppColorPalette.fieldFreshStart,
              ),
            );
          }
          
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline_rounded, color: AppColorPalette.alertError, size: 64),
                  const SizedBox(height: 16),
                  Text(
                    'Failed to load calendar',
                    style: AppTextStyles.bodyLarge(color: AppColorPalette.charcoalGreen),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () => setState(() {
                      if (widget.parcelId != null) {
                        _calendarFuture = _service.getParcelCalendar(widget.parcelId!);
                      } else {
                        _calendarFuture = _service.getGlobalCalendar();
                      }
                    }),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColorPalette.fieldFreshStart,
                    ),
                    child: const Text('Try Again'),
                  ),
                ],
              ),
            );
          }
          
          final items = snapshot.data!;
          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.calendar_today_outlined, color: AppColorPalette.softSlate.withOpacity(0.5), size: 100),
                  const SizedBox(height: 24),
                  Text(
                    'No crops recorded',
                    style: AppTextStyles.h3(color: AppColorPalette.softSlate),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Start planting to see your timeline!',
                    style: AppTextStyles.bodyMedium(color: AppColorPalette.softSlate),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return _buildCalendarCard(item);
            },
          );
        },
      ),
    );
  }

  Widget _buildCalendarCard(CropCalendarItem item) {
    Color statusColor;
    IconData statusIcon;

    switch (item.status) {
      case 'HARVESTED':
        statusColor = AppColorPalette.softSlate;
        statusIcon = Icons.check_circle_rounded;
        break;
      case 'READY':
        statusColor = const Color(0xFFF9A825); // Golden/Amber
        statusIcon = Icons.notifications_active_rounded;
        break;
      case 'PLANTED':
        statusColor = AppColorPalette.mistyBlue;
        statusIcon = Icons.event_note_rounded;
        break;
      case 'GROWING':
      default:
        statusColor = AppColorPalette.emeraldGreen;
        statusIcon = Icons.eco_rounded;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: AppColorPalette.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.cropName,
                            style: AppTextStyles.h3(color: AppColorPalette.charcoalGreen),
                          ),
                          Text(
                            '${item.variety}${item.parcelName != null ? " • ${item.parcelName}" : ""}',
                            style: AppTextStyles.bodySmall(color: AppColorPalette.softSlate),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(statusIcon, color: statusColor, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              item.status,
                              style: AppTextStyles.caption(color: statusColor).copyWith(
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  
                  // Progress Timeline
                  Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Planting',
                            style: AppTextStyles.caption(color: AppColorPalette.softSlate),
                          ),
                          if (item.status == 'GROWING')
                            Text(
                              'Growing...',
                              style: AppTextStyles.caption(color: statusColor).copyWith(fontWeight: FontWeight.w600),
                            ),
                          Text(
                            'Harvest',
                            style: AppTextStyles.caption(color: AppColorPalette.softSlate),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Stack(
                        children: [
                          Container(
                            height: 14,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.grey.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(7),
                            ),
                          ),
                          FractionallySizedBox(
                            widthFactor: item.progress,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 800),
                              height: 14,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [statusColor.withOpacity(0.6), statusColor],
                                ),
                                borderRadius: BorderRadius.circular(7),
                                boxShadow: [
                                  BoxShadow(
                                    color: statusColor.withOpacity(0.3),
                                    blurRadius: 6,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        item.formattedPlantingDate,
                        style: AppTextStyles.bodySmall(color: AppColorPalette.charcoalGreen).copyWith(fontWeight: FontWeight.w600),
                      ),
                      if (item.status == 'GROWING' || item.status == 'PLANTED')
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColorPalette.mistyBlue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${item.daysRemaining} days left',
                            style: AppTextStyles.caption(color: AppColorPalette.mistyBlue).copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                      Text(
                        item.formattedHarvestDate,
                        style: AppTextStyles.bodySmall(color: AppColorPalette.charcoalGreen).copyWith(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Helpful Insight Footer
            if (item.status == 'READY')
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
                color: const Color(0xFFF9A825).withOpacity(0.1),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded, color: Color(0xFFF9A825), size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'This crop has reached its expected harvest date!',
                        style: AppTextStyles.caption(color: const Color(0xFFF9A825)).copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../../providers/vaccine_provider.dart';
import '../../models/vaccine_models.dart';
import '../../utils/constants.dart';
import '../../widgets/vaccine_status_chip.dart';

class VaccineCalendarScreen extends StatefulWidget {
  const VaccineCalendarScreen({super.key});

  @override
  State<VaccineCalendarScreen> createState() => _VaccineCalendarScreenState();
}

class _VaccineCalendarScreenState extends State<VaccineCalendarScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    // Load all vaccines if not loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<VaccineProvider>().loadGlobalSchedules();
    });
  }

  bool _isSameDayLocal(DateTime? a, DateTime? b) {
    if (a == null || b == null) return false;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  List<VaccineSchedule> _getEventsForDay(DateTime day) {
    final provider = context.read<VaccineProvider>();
    return provider.allSchedules.where((s) {
      return _isSameDayLocal(s.scheduledDate, day);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF7),
      appBar: AppBar(
        title: const Text('Vaccine Calendar', 
          style: TextStyle(color: Color(0xFF1B3C35), fontWeight: FontWeight.w900)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF1B3C35)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          _buildCalendarCard(),
          const SizedBox(height: 16),
          Expanded(child: _buildEventList()),
        ],
      ),
    );
  }

  Widget _buildCalendarCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1B3C35).withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: TableCalendar<VaccineSchedule>(
        firstDay: DateTime.now().subtract(const Duration(days: 365)),
        lastDay: DateTime.now().add(const Duration(days: 365 * 2)),
        focusedDay: _focusedDay,
        calendarFormat: _calendarFormat,
        selectedDayPredicate: (day) => _isSameDayLocal(_selectedDay, day),
        eventLoader: _getEventsForDay,
        onDaySelected: (selectedDay, focusedDay) {
          setState(() {
            _selectedDay = selectedDay;
            _focusedDay = focusedDay;
          });
        },
        onFormatChanged: (format) {
          if (_calendarFormat != format) {
            setState(() => _calendarFormat = format);
          }
        },
        onPageChanged: (focusedDay) {
          _focusedDay = focusedDay;
        },
        calendarStyle: CalendarStyle(
          todayDecoration: BoxDecoration(
            color: const Color(0xFF1B3C35).withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          selectedDecoration: const BoxDecoration(
            color: Color(0xFF1B3C35),
            shape: BoxShape.circle,
          ),
        ),
        calendarBuilders: CalendarBuilders(
          markerBuilder: (context, day, events) {
            if (events.isEmpty) return null;
            return Positioned(
              bottom: 1,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: events.take(3).map((event) {
                  final e = event;
                  Color c = const Color(0xFF1B3C35);
                  if (e.isMandatory) {
                     final days = e.scheduledDate.difference(DateTime.now()).inDays;
                     if (e.isOverdue || days <= 7) {
                       c = const Color(0xFFEF4444);
                     } else {
                       c = const Color(0xFFF59E0B);
                     }
                  }
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 0.5),
                    width: 6, height: 6,
                    decoration: BoxDecoration(color: c, shape: BoxShape.circle),
                  );
                }).toList(),
              ),
            );
          },
        ),
        headerStyle: const HeaderStyle(
          formatButtonVisible: true,
          titleCentered: true,
          formatButtonShowsNext: false,
          titleTextStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1B3C35)),
        ),
      ),
    );
  }

  Widget _buildEventList() {
    final events = _getEventsForDay(_selectedDay!);

    if (events.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.event_busy_rounded, size: 64, color: Colors.grey.withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            const Text('No vaccines scheduled for this day', 
              style: TextStyle(color: Color(0xFF4A6741), fontWeight: FontWeight.w600)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: events.length,
      itemBuilder: (context, index) {
        final schedule = events[index];
        return _CalendarEventCard(schedule: schedule);
      },
    );
  }
}

class _CalendarEventCard extends StatelessWidget {
  final VaccineSchedule schedule;
  const _CalendarEventCard({required this.schedule});

  @override
  Widget build(BuildContext context) {
    final vaccine = schedule.vaccine;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF1B3C35).withValues(alpha: 0.08), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1B3C35).withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF1B3C35).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.vaccines_rounded, color: Color(0xFF1B3C35), size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  (vaccine?.code == 'OTHER' ? schedule.notes : vaccine?.nameFr) ?? 'Vaccine',
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Color(0xFF1B3C35)),
                ),
                Text(
                  'Animal ID: ${schedule.animalId}', // Could be improved if animal name is available
                  style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
                ),
              ],
            ),
          ),
          VaccineStatusChip(status: schedule.status, small: true),
        ],
      ),
    );
  }
}

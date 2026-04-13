import 'package:flutter/material.dart';

import '../screens/home_screen.dart';
import '../screens/parcel_list_screen.dart';
import '../screens/plant_doctor_screen.dart';
import '../screens/harvest_analytics_screen.dart';
import '../screens/crop_calendar_screen.dart';
import '../screens/weather_screen.dart';
import '../screens/agricultural_news_screen.dart';
import '../screens/shorts_screen.dart';
import '../screens/community_feed_screen.dart';
import '../screens/irrigation_scheduler_screen.dart';
import '../screens/soil/soil_measurements_list_screen.dart';
import '../screens/farm_quiz_screen.dart';
import '../screens/staff_list_screen.dart';
import '../screens/add_staff_screen.dart';
import '../screens/security/incident_history_screen.dart';
import '../screens/security/live_feed_screen.dart';
import '../screens/security/daily_report_screen.dart';
import '../screens/security/acoustic_monitor_screen.dart';
import '../screens/animals/animal_list_screen.dart';
import '../screens/animals/add_animal_screen.dart';
import '../screens/animals/milk_production_screen.dart';
import '../screens/animals/milk_analytics_screen.dart';
import '../screens/vaccines/vaccine_dashboard_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/fields_management_screen.dart';
import '../screens/mission_list_screen.dart';
import '../screens/chat_assistant_screen.dart';

enum VoiceCommandType {
  none,
  activateFullAccess,
  deactivateFullAccess,
  navigate,
  unknownNavigate,
}

enum VoicePage {
  home,
  myParcels,
  plantDoctor,
  harvestAnalytics,
  cropCalendar,
  weather,
  agriculturalNews,
  farmReels,
  communityFeed,
  irrigationScheduler,
  soilMeasurements,
  farmQuiz,
  securityWhitelist,
  addStaff,
  incidentHistory,
  liveFeed,
  dailyReports,
  acousticMonitor,
  animalList,
  addAnimal,
  milkProduction,
  milkAnalytics,
  vaccineDashboard,
  profile,
  fields,
  missions,
  assistant,
}

class VoiceCommandResult {
  const VoiceCommandResult({
    required this.type,
    this.page,
    this.target,
    this.suggestions = const <String>[],
  });

  final VoiceCommandType type;
  final VoicePage? page;
  final String? target;
  final List<String> suggestions;
}

class VoiceNavigationService {
  static final List<String> _activatePhrases = <String>[
    'give me full access',
    'activate full access',
    'full access mode',
    'active le mode acces complet',
    'activer acces complet',
    'donne moi un acces complet',
    'donne moi acces complet',
    'donnini full access',
    'فعل الوصول الكامل',
    'اعطني وصول كامل',
  ];

  static final List<String> _deactivatePhrases = <String>[
    'disable full access',
    'exit full access mode',
    'turn off full access',
    'desactiver acces complet',
    'desactive le mode acces complet',
    'quitter le mode acces complet',
    'وقف الوصول الكامل',
    'الغاء الوصول الكامل',
  ];

  static final List<String> _navigationPrefixes = <String>[
    'open ',
    'take me to ',
    'go to ',
    'navigate to ',
    'show ',
    'ouvre ',
    'ouvrir ',
    'va a ',
    'aller a ',
    'emmene moi a ',
    'montre ',
    'افتح ',
    'خذني الى ',
    'خذني إلى ',
    'روح الى ',
    'روح إلى ',
    'اذهب الى ',
    'اذهب إلى ',
  ];

  static final Map<VoicePage, String> _pageLabels = <VoicePage, String>{
    VoicePage.home: 'Home',
    VoicePage.myParcels: 'My Parcels',
    VoicePage.plantDoctor: 'AI Plant Doctor',
    VoicePage.harvestAnalytics: 'Harvest Analytics',
    VoicePage.cropCalendar: 'Crop Calendar',
    VoicePage.weather: 'Weather & Advice',
    VoicePage.agriculturalNews: 'Agricultural News',
    VoicePage.farmReels: 'Farm Reels',
    VoicePage.communityFeed: 'Community Feed',
    VoicePage.irrigationScheduler: 'Irrigation Scheduler',
    VoicePage.soilMeasurements: 'Soil Measurements',
    VoicePage.farmQuiz: 'Farm Quiz',
    VoicePage.securityWhitelist: 'Security Whitelist',
    VoicePage.addStaff: 'Add Staff',
    VoicePage.incidentHistory: 'Incident History',
    VoicePage.liveFeed: 'Live Feed',
    VoicePage.dailyReports: 'Daily Reports',
    VoicePage.acousticMonitor: 'Acoustic Monitor',
    VoicePage.animalList: 'Animal List',
    VoicePage.addAnimal: 'Add Animal',
    VoicePage.milkProduction: 'Milk Production',
    VoicePage.milkAnalytics: 'Milk Analytics',
    VoicePage.vaccineDashboard: 'Vaccine Dashboard',
    VoicePage.profile: 'Profile',
    VoicePage.fields: 'Fields',
    VoicePage.missions: 'Missions',
    VoicePage.assistant: 'Assistant',
  };

  static final Map<VoicePage, List<String>> _aliases =
      <VoicePage, List<String>>{
    VoicePage.home: <String>['home', 'home screen', 'dashboard', 'accueil', 'الرئيسية'],
    VoicePage.myParcels: <String>['my parcels', 'parcels', 'fields list', 'mes parcelles', 'parcelles', 'الحقول', 'قطعتي'],
    VoicePage.plantDoctor: <String>['plant doctor', 'ai plant doctor', 'doctor', 'medecin des plantes', 'طبيب النبات'],
    VoicePage.harvestAnalytics: <String>['harvest analytics', 'yield analytics', 'analyse recolte', 'تحليل الحصاد'],
    VoicePage.cropCalendar: <String>['crop calendar', 'calendar', 'calendrier des cultures', 'تقويم المحاصيل'],
    VoicePage.weather: <String>['weather', 'weather advice', 'forecast', 'meteo', 'طقس'],
    VoicePage.agriculturalNews: <String>['agricultural news', 'news', 'actualites agricoles', 'اخبار زراعية'],
    VoicePage.farmReels: <String>['farm reels', 'reels', 'videos', 'فيديوهات'],
    VoicePage.communityFeed: <String>['community feed', 'community', 'communaute', 'المجتمع'],
    VoicePage.irrigationScheduler: <String>['irrigation scheduler', 'irrigation', 'watering', 'irrigation intelligente', 'الري'],
    VoicePage.soilMeasurements: <String>['soil measurements', 'soil', 'soil health', 'mesures du sol', 'قياسات التربة'],
    VoicePage.farmQuiz: <String>['farm quiz', 'quiz', 'اختبار'],
    VoicePage.securityWhitelist: <String>['security whitelist', 'whitelist', 'authorized staff', 'liste blanche', 'القائمة البيضاء'],
    VoicePage.addStaff: <String>['add staff', 'add worker', 'ajouter staff', 'اضافة عامل'],
    VoicePage.incidentHistory: <String>['incident history', 'security logs', 'historique incidents', 'سجل الحوادث'],
    VoicePage.liveFeed: <String>['live feed', 'camera', 'live camera', 'flux direct', 'بث مباشر'],
    VoicePage.dailyReports: <String>['daily reports', 'daily report', 'rapport quotidien', 'تقارير يومية'],
    VoicePage.acousticMonitor: <String>['acoustic monitor', 'sound monitor', 'surveillance acoustique', 'مراقبة صوتية'],
    VoicePage.animalList: <String>['animal list', 'animals', 'liste animaux', 'الحيوانات'],
    VoicePage.addAnimal: <String>['add animal', 'new animal', 'ajouter animal', 'اضافة حيوان'],
    VoicePage.milkProduction: <String>['milk production', 'production lait', 'انتاج الحليب'],
    VoicePage.milkAnalytics: <String>['milk analytics', 'analyse lait', 'تحليل الحليب'],
    VoicePage.vaccineDashboard: <String>['vaccine dashboard', 'vaccines', 'vaccination', 'لوحة اللقاحات'],
    VoicePage.profile: <String>['profile', 'account', 'profil', 'الملف الشخصي'],
    VoicePage.fields: <String>['fields', 'field management', 'gestion des champs', 'ادارة الحقول'],
    VoicePage.missions: <String>['missions', 'tasks', 'taches', 'المهام'],
    VoicePage.assistant: <String>['assistant', 'chat assistant', 'assistant vocal', 'المساعد'],
  };

  static String _normalize(String text) {
    return text
        .toLowerCase()
      .replaceAll(RegExp("[\"'`]+"), ' ')
        .replaceAll(RegExp(r'[،,;:!?؟!.]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static VoiceCommandResult parse(String transcript) {
    final normalized = _normalize(transcript);
    if (normalized.isEmpty) {
      return const VoiceCommandResult(type: VoiceCommandType.none);
    }

    if (_activatePhrases.any((phrase) => normalized.contains(_normalize(phrase)))) {
      return const VoiceCommandResult(type: VoiceCommandType.activateFullAccess);
    }

    if (_deactivatePhrases.any((phrase) => normalized.contains(_normalize(phrase)))) {
      return const VoiceCommandResult(type: VoiceCommandType.deactivateFullAccess);
    }

    final target = _extractNavigationTarget(normalized);
    if (target == null) {
      return const VoiceCommandResult(type: VoiceCommandType.none);
    }

    final page = _matchPage(target);
    if (page != null) {
      return VoiceCommandResult(
        type: VoiceCommandType.navigate,
        page: page,
        target: target,
      );
    }

    return VoiceCommandResult(
      type: VoiceCommandType.unknownNavigate,
      target: target,
      suggestions: _suggestPages(target),
    );
  }

  static String? _extractNavigationTarget(String normalized) {
    for (final prefix in _navigationPrefixes) {
      final idx = normalized.indexOf(prefix);
      if (idx >= 0) {
        final target = normalized.substring(idx + prefix.length).trim();
        if (target.isNotEmpty) {
          return target;
        }
      }
    }

    return null;
  }

  static VoicePage? _matchPage(String target) {
    VoicePage? bestPage;
    int bestScore = -1;

    for (final entry in _aliases.entries) {
      for (final alias in entry.value) {
        final normalizedAlias = _normalize(alias);
        int score = -1;

        if (target == normalizedAlias) {
          score = 1000 + normalizedAlias.length;
        } else if (target.contains(normalizedAlias)) {
          score = 700 + normalizedAlias.length;
        } else if (normalizedAlias.contains(target)) {
          score = 500 + target.length;
        }

        if (score > bestScore) {
          bestScore = score;
          bestPage = entry.key;
        }
      }
    }

    return bestScore > 0 ? bestPage : null;
  }

  static List<String> _suggestPages(String target) {
    final suggestions = <String>[];

    for (final entry in _aliases.entries) {
      final hasCloseAlias = entry.value.any((alias) {
        final normalizedAlias = _normalize(alias);
        return normalizedAlias.contains(target) || target.contains(normalizedAlias);
      });

      if (hasCloseAlias) {
        final label = labelForPage(entry.key);
        if (!suggestions.contains(label)) {
          suggestions.add(label);
        }
      }

      if (suggestions.length >= 3) {
        break;
      }
    }

    return suggestions;
  }

  static String labelForPage(VoicePage page) {
    return _pageLabels[page] ?? 'that page';
  }

  static void navigateToPage(BuildContext context, VoicePage page) {
    navigateToPageWithNavigator(Navigator.of(context), page);
  }

  static void navigateToPageWithNavigator(NavigatorState navigator, VoicePage page) {
    if (page == VoicePage.home) {
      navigator.popUntil((route) => route.isFirst);
      return;
    }

    final Widget destination;
    switch (page) {
      case VoicePage.home:
        destination = const HomeScreen();
        break;
      case VoicePage.myParcels:
        destination = const ParcelListScreen();
        break;
      case VoicePage.plantDoctor:
        destination = const PlantDoctorScreen();
        break;
      case VoicePage.harvestAnalytics:
        destination = const HarvestAnalyticsScreen();
        break;
      case VoicePage.cropCalendar:
        destination = const CropCalendarScreen();
        break;
      case VoicePage.weather:
        destination = const WeatherScreen();
        break;
      case VoicePage.agriculturalNews:
        destination = AgriculturalNewsScreen();
        break;
      case VoicePage.farmReels:
        destination = const ShortsScreen();
        break;
      case VoicePage.communityFeed:
        destination = const CommunityFeedScreen();
        break;
      case VoicePage.irrigationScheduler:
        destination = const IrrigationSchedulerScreen();
        break;
      case VoicePage.soilMeasurements:
        destination = const SoilMeasurementsListScreen();
        break;
      case VoicePage.farmQuiz:
        destination = FarmQuizScreen(parcelId: null);
        break;
      case VoicePage.securityWhitelist:
        destination = const StaffListScreen();
        break;
      case VoicePage.addStaff:
        destination = const AddStaffScreen();
        break;
      case VoicePage.incidentHistory:
        destination = const IncidentHistoryScreen();
        break;
      case VoicePage.liveFeed:
        destination = const LiveFeedScreen();
        break;
      case VoicePage.dailyReports:
        destination = const DailyReportScreen();
        break;
      case VoicePage.acousticMonitor:
        destination = const AcousticMonitorScreen();
        break;
      case VoicePage.animalList:
        destination = const AnimalListScreen();
        break;
      case VoicePage.addAnimal:
        destination = const AddAnimalScreen();
        break;
      case VoicePage.milkProduction:
        destination = const MilkProductionScreen();
        break;
      case VoicePage.milkAnalytics:
        destination = const MilkAnalyticsScreen();
        break;
      case VoicePage.vaccineDashboard:
        destination = const VaccineDashboardScreen();
        break;
      case VoicePage.profile:
        destination = const ProfileScreen();
        break;
      case VoicePage.fields:
        destination = const FieldsManagementScreen();
        break;
      case VoicePage.missions:
        destination = const MissionListScreen();
        break;
      case VoicePage.assistant:
        destination = const ChatAssistantScreen();
        break;
    }

    navigator.push(
      MaterialPageRoute(builder: (_) => destination),
    );
  }
}

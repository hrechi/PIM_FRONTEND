import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Supported locales for the application.
const List<Locale> kSupportedLocales = [
  Locale('en'),
  Locale('fr'),
  Locale('ar'),
];

/// Maps locale code to display name shown in the language picker.
const Map<String, String> kLocaleDisplayNames = {
  'en': 'English',
  'fr': 'Français',
  'ar': 'العربية',
};

/// Maps locale code to its native flag emoji.
const Map<String, String> kLocaleFlags = {
  'en': '🇬🇧',
  'fr': '🇫🇷',
  'ar': '🇹🇳',
};

/// Locales that use right-to-left text direction.
const Set<String> kRtlLocales = {'ar'};

/// Main localizations class.
/// Usage: `AppLocalizations.of(context).signIn`
/// Or via extension: `context.l10n.signIn`
class AppLocalizations {
  AppLocalizations(this.locale, this._strings);

  final Locale locale;
  final Map<String, String> _strings;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  // ─── Helpers ──────────────────────────────────────────────────────────────

  String _t(String key) => _strings[key] ?? key;

  String _tp(String key, Map<String, String> params) {
    String value = _strings[key] ?? key;
    params.forEach((k, v) {
      value = value.replaceAll('{$k}', v);
    });
    return value;
  }

  bool get isRtl => kRtlLocales.contains(locale.languageCode);

  TextDirection get textDirection =>
      isRtl ? TextDirection.rtl : TextDirection.ltr;

  // ─── App ──────────────────────────────────────────────────────────────────

  String get appName => _t('appName');

  // ─── Auth ─────────────────────────────────────────────────────────────────

  String get signIn => _t('signIn');
  String get signUp => _t('signUp');
  String get signOut => _t('signOut');
  String get email => _t('email');
  String get phone => _t('phone');
  String get emailOrPhone => _t('emailOrPhone');
  String get emailOrPhoneLabel => _t('emailOrPhoneLabel');
  String get password => _t('password');
  String get confirmPassword => _t('confirmPassword');
  String get forgotPassword => _t('forgotPassword');
  String get rememberMe => _t('rememberMe');
  String get fullName => _t('fullName');
  String get farmName => _t('farmName');
  String get createAccount => _t('createAccount');
  String get welcomeBack => _t('welcomeBack');
  String get signInToContinue => _t('signInToContinue');
  String get joinFieldly => _t('joinFieldly');
  String get alreadyHaveAccount => _t('alreadyHaveAccount');
  String get dontHaveAccount => _t('dontHaveAccount');
  String get contactMethod => _t('contactMethod');
  String get enterFullName => _t('enterFullName');
  String get enterFarmName => _t('enterFarmName');
  String get enterEmail => _t('enterEmail');
  String get enterPhone => _t('enterPhone');
  String get createPassword => _t('createPassword');
  String get confirmYourPassword => _t('confirmYourPassword');
  String get enterPassword => _t('enterPassword');

  // ─── Navigation ───────────────────────────────────────────────────────────

  String get home => _t('home');
  String get dashboard => _t('dashboard');
  String get profile => _t('profile');
  String get settings => _t('settings');
  String get notifications => _t('notifications');
  String get language => _t('language');
  String get selectLanguage => _t('selectLanguage');

  // ─── Fields & Parcels ─────────────────────────────────────────────────────

  String get fields => _t('fields');
  String get parcels => _t('parcels');
  String get missions => _t('missions');
  String get crops => _t('crops');
  String get addField => _t('addField');
  String get addParcel => _t('addParcel');
  String get createMission => _t('createMission');
  String get fieldManagement => _t('fieldManagement');
  String get parcelList => _t('parcelList');
  String get missionList => _t('missionList');
  String get selectField => _t('selectField');

  // ─── Animals ──────────────────────────────────────────────────────────────

  String get animals => _t('animals');
  String get addAnimal => _t('addAnimal');
  String get animalList => _t('animalList');
  String get animalDetails => _t('animalDetails');
  String get animalType => _t('animalType');
  String get breed => _t('breed');
  String get age => _t('age');
  String get weight => _t('weight');
  String get healthStatus => _t('healthStatus');
  String get vaccination => _t('vaccination');
  String get milkProduction => _t('milkProduction');
  String get genealogy => _t('genealogy');
  String get plannedSales => _t('plannedSales');
  String get cow => _t('cow');
  String get horse => _t('horse');
  String get sheep => _t('sheep');
  String get dog => _t('dog');
  String get male => _t('male');
  String get female => _t('female');
  String get active => _t('active');
  String get sold => _t('sold');
  String get deceased => _t('deceased');

  // ─── Vaccines ─────────────────────────────────────────────────────────────

  String get vaccines => _t('vaccines');
  String get vaccineDashboard => _t('vaccineDashboard');
  String get vaccineSchedule => _t('vaccineSchedule');
  String get vaccineRecord => _t('vaccineRecord');
  String get vaccinesDue => _t('vaccinesDue');
  String get addVaccine => _t('addVaccine');

  // ─── Soil ─────────────────────────────────────────────────────────────────

  String get soil => _t('soil');
  String get soilMeasurements => _t('soilMeasurements');
  String get soilAlerts => _t('soilAlerts');
  String get soilIntelligence => _t('soilIntelligence');
  String get ph => _t('ph');
  String get moisture => _t('moisture');
  String get temperature => _t('temperature');
  String get nutrients => _t('nutrients');

  // ─── Weather & Irrigation ─────────────────────────────────────────────────

  String get weather => _t('weather');
  String get irrigation => _t('irrigation');
  String get irrigationScheduler => _t('irrigationScheduler');

  // ─── Assets ───────────────────────────────────────────────────────────────

  String get assets => _t('assets');
  String get assetList => _t('assetList');
  String get addAsset => _t('addAsset');
  String get assetDetails => _t('assetDetails');
  String get available => _t('available');
  String get inUse => _t('inUse');
  String get maintenance => _t('maintenance');
  String get startUsing => _t('startUsing');
  String get finishUsing => _t('finishUsing');
  String get markAvailable => _t('markAvailable');
  String get markInUse => _t('markInUse');

  // ─── Finance ──────────────────────────────────────────────────────────────

  String get finance => _t('finance');
  String get expenses => _t('expenses');
  String get financeDetails => _t('financeDetails');
  String get addExpense => _t('addExpense');
  String get monthlySpend => _t('monthlySpend');

  // ─── Catalogues ───────────────────────────────────────────────────────────

  String get catalogues => _t('catalogues');
  String get salesCatalogues => _t('salesCatalogues');
  String get newCatalogue => _t('newCatalogue');
  String get createCatalogue => _t('createCatalogue');
  String get publishCatalogue => _t('publishCatalogue');
  String get deleteCatalogue => _t('deleteCatalogue');
  String get noCataloguesYet => _t('noCataloguesYet');
  String get createFirstCatalogue => _t('createFirstCatalogue');
  String get draft => _t('draft');
  String get published => _t('published');
  String get closed => _t('closed');
  String get archived => _t('archived');
  String get preview => _t('preview');
  String get edit => _t('edit');
  String get delete => _t('delete');
  String get publish => _t('publish');
  String get exportShare => _t('exportShare');
  String get cancel => _t('cancel');
  String get confirm => _t('confirm');
  String get save => _t('save');
  String get retry => _t('retry');
  String get close => _t('close');

  // ─── Community ────────────────────────────────────────────────────────────

  String get community => _t('community');
  String get communityFeed => _t('communityFeed');
  String get createPost => _t('createPost');
  String get newPost => _t('newPost');
  String get shareUpdate => _t('shareUpdate');
  String get post => _t('post');
  String get like => _t('like');
  String get dislike => _t('dislike');
  String get comments => _t('comments');
  String get vote => _t('vote');
  String get deletePost => _t('deletePost');
  String get deletePostConfirm => _t('deletePostConfirm');

  // ─── Security ─────────────────────────────────────────────────────────────

  String get security => _t('security');
  String get incidents => _t('incidents');
  String get incidentHistory => _t('incidentHistory');
  String get liveFeed => _t('liveFeed');
  String get dailyReport => _t('dailyReport');
  String get acousticMonitor => _t('acousticMonitor');

  // ─── AI ───────────────────────────────────────────────────────────────────

  String get ai => _t('ai');
  String get chatAssistant => _t('chatAssistant');
  String get plantDoctor => _t('plantDoctor');
  String get aiAgronomist => _t('aiAgronomist');
  String get mechanicChat => _t('mechanicChat');
  String get voiceAssistant => _t('voiceAssistant');

  // ─── Robots ───────────────────────────────────────────────────────────────

  String get controlRoom => _t('controlRoom');
  String get robots => _t('robots');
  String get telemetry => _t('telemetry');

  // ─── Learning ─────────────────────────────────────────────────────────────

  String get skillCertification => _t('skillCertification');
  String get farmQuiz => _t('farmQuiz');
  String get shorts => _t('shorts');
  String get news => _t('news');

  // ─── Staff ────────────────────────────────────────────────────────────────

  String get staff => _t('staff');
  String get addStaff => _t('addStaff');
  String get staffList => _t('staffList');
  String get worker => _t('worker');
  String get owner => _t('owner');

  // ─── Common ───────────────────────────────────────────────────────────────

  String get loading => _t('loading');
  String get error => _t('error');
  String get noData => _t('noData');
  String get refresh => _t('refresh');
  String get search => _t('search');
  String get filter => _t('filter');
  String get sort => _t('sort');
  String get back => _t('back');
  String get next => _t('next');
  String get done => _t('done');
  String get yes => _t('yes');
  String get no => _t('no');
  String get ok => _t('ok');

  // ─── Greetings ────────────────────────────────────────────────────────────

  String get goodMorning => _t('goodMorning');
  String get goodAfternoon => _t('goodAfternoon');
  String get goodEvening => _t('goodEvening');
  String get goodNight => _t('goodNight');
  String get hi => _t('hi');

  /// Returns the appropriate greeting based on current hour.
  String get timeBasedGreeting {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) return goodMorning;
    if (hour >= 12 && hour < 17) return goodAfternoon;
    if (hour >= 17 && hour < 21) return goodEvening;
    return goodNight;
  }

  // ─── Dashboard stats ──────────────────────────────────────────────────────

  String get totalAnimals => _t('totalAnimals');
  String get healthAlerts => _t('healthAlerts');
  String get totalCrops => _t('totalCrops');
  String get farmScore => _t('farmScore');

  // ─── Worker screen ────────────────────────────────────────────────────────

  String get myMaterials => _t('myMaterials');
  String get noMaterialsAssigned => _t('noMaterialsAssigned');
  String get currentlyInUse => _t('currentlyInUse');
  String get startUsingMaterial => _t('startUsingMaterial');
  String get selectMaterial => _t('selectMaterial');
  String get start => _t('start');
  String get finish => _t('finish');
  String get distanceKm => _t('distanceKm');
  String get issues => _t('issues');
  String get issuesOptional => _t('issuesOptional');
  String get maintenanceNote => _t('maintenanceNote');
  String get condition => _t('condition');
  String get good => _t('good');
  String get warning => _t('warning');
  String get critical => _t('critical');
  String get manageYourMaterials => _t('manageYourMaterials');
  String get welcome => _t('welcome');

  // ─── Alerts ───────────────────────────────────────────────────────────────

  String get soilAlert => _t('soilAlert');
  String get newSoilAlertReceived => _t('newSoilAlertReceived');

  // ─── Parameterized strings ────────────────────────────────────────────────

  String cannotDeletePublished(String status) =>
      _tp('cannotDeletePublished', {'status': status});

  String deleteConfirmTitle(String title) =>
      _tp('deleteConfirmTitle', {'title': title});

  String get deleteConfirmBody => _t('deleteConfirmBody');
  String get publishConfirmBody => _t('publishConfirmBody');

  String animalsCount(int count) =>
      _tp('animalsCount', {'count': count.toString()});

  String createdOn(String date) => _tp('createdOn', {'date': date});

  String get manageLivestockCatalogues => _t('manageLivestockCatalogues');
  String get enterDistanceTraveled => _t('enterDistanceTraveled');
  String get describeIssues => _t('describeIssues');
  String get recommendedMaintenance => _t('recommendedMaintenance');
  String get maintenanceRequired => _t('maintenanceRequired');
  String get machineRequiresMaintenance => _t('machineRequiresMaintenance');
  String get currentlyUsedByYou => _t('currentlyUsedByYou');
  String currentlyUsedBy(String name) =>
      _tp('currentlyUsedBy', {'name': name});

  String get assetNotFound => _t('assetNotFound');
  String get assetFound => _t('assetFound');
  String get workerAccount => _t('workerAccount');
  String get noFieldAssigned => _t('noFieldAssigned');
  String get failedToLoad => _t('failedToLoad');
  String get signOutConfirm => _t('signOutConfirm');
  String get enterValidNumber => _t('enterValidNumber');
  String get distanceRequired => _t('distanceRequired');
  String get distanceNegative => _t('distanceNegative');
  String get serialNumber => _t('serialNumber');
  String get category => _t('category');
  String get brand => _t('brand');
  String get model => _t('model');
  String get mileage => _t('mileage');
  String get operatingHours => _t('operatingHours');
  String get unknown => _t('unknown');

  // ─── Animals ──────────────────────────────────────────────────────────────
  String get addLivestock => _t('addLivestock');
  String get livestock => _t('livestock');
  String get searchByNameOrId => _t('searchByNameOrId');
  String get all => _t('all');
  String get viewDetails => _t('viewDetails');
  String get cancelSale => _t('cancelSale');
  String get fattening => _t('fattening');
  String get deleteAnimal => _t('deleteAnimal');
  String deleteAnimalConfirm(String name) => _tp('deleteAnimalConfirm', {'name': name});
  String get animalDeleted => _t('animalDeleted');
  String get markAsFattening => _t('markAsFattening');
  String get markedAsFattening => _t('markedAsFattening');
  String get startDate => _t('startDate');
  String get targetSaleDate => _t('targetSaleDate');
  String get sellAnimal => _t('sellAnimal');
  String get salePrice => _t('salePrice');
  String get saleDate => _t('saleDate');
  String get buyerName => _t('buyerName');
  String get saleWeightKg => _t('saleWeightKg');
  String get notes => _t('notes');
  String get confirmSale => _t('confirmSale');
  String get animalSoldSuccess => _t('animalSoldSuccess');
  String get cancelSaleConfirmTitle => _t('cancelSaleConfirmTitle');
  String cancelSaleConfirmBody(String name) => _tp('cancelSaleConfirmBody', {'name': name});
  String saleCancelled(String name) => _tp('saleCancelled', {'name': name});

  String get sex => _t('sex');
  String get origin => _t('origin');
  String get aiHealthRisk => _t('aiHealthRisk');
  String get highRisk => _t('highRisk');
  String get moderateRisk => _t('moderateRisk');
  String get lowRisk => _t('lowRisk');
  String get healthAndVitals => _t('healthAndVitals');
  String get vitalityScore => _t('vitalityScore');
  String get activityLevel => _t('activityLevel');
  String get lastVetCheck => _t('lastVetCheck');
  String get vaccinatedUpToDate => _t('vaccinatedUpToDate');
  String get notVaccinated => _t('notVaccinated');
  String get dairyAndReproduction => _t('dairyAndReproduction');
  String get pregnant => _t('pregnant');
  String get birthCount => _t('birthCount');
  String get avgMilkPerDay => _t('avgMilkPerDay');
  String get lactationNumber => _t('lactationNumber');
  String get performance => _t('performance');
  String get bestTime => _t('bestTime');
  String get trainingLevel => _t('trainingLevel');
  String get lastShearing => _t('lastShearing');
  String get meatGrade => _t('meatGrade');
  String get role => _t('role');
  String get fatteningProgress => _t('fatteningProgress');
  String get started => _t('started');
  String get daysInFattening => _t('daysInFattening');
  String get daysRemaining => _t('daysRemaining');
  String get readyForSale => _t('readyForSale');
  String get mother => _t('mother');
  String get father => _t('father');
  String get purchasePrice => _t('purchasePrice');
  String get purchaseDate => _t('purchaseDate');
  String get birthCost => _t('birthCost');
  String get birthWeight => _t('birthWeight');
  String get estimatedValue => _t('estimatedValue');
  String get medicalHistory => _t('medicalHistory');
  String get vaccinations => _t('vaccinations');
  String get medicalEvents => _t('medicalEvents');
  String get noVaccinationsRecorded => _t('noVaccinationsRecorded');
  String get species => _t('species');
  String get selectSpecies => _t('selectSpecies');
  String get addPhoto => _t('addPhoto');
  String get cameraOrGallery => _t('cameraOrGallery');
  String get takePhoto => _t('takePhoto');
  String get chooseFromGallery => _t('chooseFromGallery');
  String get removePhoto => _t('removePhoto');
  String get editAnimal => _t('editAnimal');

  // ─── Milk ──────────────────────────────────────────────────────────────────
  String get milkAnalytics => _t('milkAnalytics');
  String get thisWeek => _t('thisWeek');
  String get thisMonth => _t('thisMonth');
  String get thisYear => _t('thisYear');
  String get totalYield => _t('totalYield');
  String get topProducer => _t('topProducer');
  String get productionHistory => _t('productionHistory');
  String get addEntry => _t('addEntry');
  String get noRecordsYet => _t('noRecordsYet');
  String get newMilkRecord => _t('newMilkRecord');
  String get editMilkRecord => _t('editMilkRecord');
  String get selectCow => _t('selectCow');
  String get morningL => _t('morningL');
  String get eveningL => _t('eveningL');
  String get saveRecord => _t('saveRecord');
  String get updateRecord => _t('updateRecord');
  String get deleteRecord => _t('deleteRecord');
  String get deleteRecordConfirm => _t('deleteRecordConfirm');
  String get allTime => _t('allTime');
  String get recordMilk => _t('recordMilk');

  // ─── Catalogue wizard & export ────────────────────────────────────────────
  String get catalogueTitle => _t('catalogueTitle');
  String get catalogueTitleHint => _t('catalogueTitleHint');
  String get titleRequired => _t('titleRequired');
  String get location => _t('location');
  String get locationHint => _t('locationHint');
  String get selectDate => _t('selectDate');
  String get currency => _t('currency');
  String get showPrices => _t('showPrices');
  String get selectedAnimals => _t('selectedAnimals');
  String get addAnimals => _t('addAnimals');
  String get noAnimalsSelected => _t('noAnimalsSelected');
  String get addAnimalsToInclude => _t('addAnimalsToInclude');
  String get selectAnimals => _t('selectAnimals');
  String get catalogueSettingsTitle => _t('catalogueSettings');
  String get sectionsToInclude => _t('sectionsToInclude');
  String get animalPhotos => _t('animalPhotos');
  String get animalDetailsSection => _t('animalDetailsSection');
  String get healthRecords => _t('healthRecords');
  String get vaccinationHistory => _t('vaccinationHistory');
  String get productionRecords => _t('productionRecords');
  String get geneticInformation => _t('geneticInformation');
  String get layoutOptions => _t('layoutOptions');
  String get twoColumnLayout => _t('twoColumnLayout');
  String get showQrCodes => _t('showQrCodes');
  String get includeContactInfo => _t('includeContactInfo');
  String get exitWizard => _t('exitWizard');
  String get exitWizardConfirm => _t('exitWizardConfirm');
  String get exit => _t('exit');
  String get basicInformation => _t('basicInformation');
  String get info => _t('info');
  String get step => _t('step');
  String get catalogueSummary => _t('catalogueSummary');
  String get exportOptions => _t('exportOptions');
  String get viewAsBook => _t('viewAsBook');
  String get viewAsBookSubtitle => _t('viewAsBookSubtitle');
  String get printCatalogue => _t('printCatalogue');
  String get printCatalogueSubtitle => _t('printCatalogueSubtitle');
  String get emailCatalogue => _t('emailCatalogue');
  String get emailCatalogueSubtitle => _t('emailCatalogueSubtitle');
  String get shareOptions => _t('shareOptions');
  String get generateShareLink => _t('generateShareLink');
  String get generateShareLinkSubtitle => _t('generateShareLinkSubtitle');
  String get shareCatalogue => _t('shareCatalogue');
  String get shareCatalogueSubtitle => _t('shareCatalogueSubtitle');
  String get qrCode => _t('qrCode');
  String get qrCodeSubtitle => _t('qrCodeSubtitle');
  String get copy => _t('copy');
  String get revoke => _t('revoke');
  String get shareLinkCopied => _t('shareLinkCopied');
  String get shareLinkRevoked => _t('shareLinkRevoked');
  String get pdfGenerated => _t('pdfGenerated');
  String get pdfGeneratedSuccess => _t('pdfGeneratedSuccess');
  String get viewPdf => _t('viewPdf');
  String get previewNotice => _t('previewNotice');

  // ─── Soil ─────────────────────────────────────────────────────────────────
  String get soilAlertNotifications => _t('soilAlertNotifications');
  String get markRead => _t('markRead');
  String get addMeasurement => _t('addMeasurement');
  String get deleteMeasurement => _t('deleteMeasurement');
  String get deleteMeasurementConfirm => _t('deleteMeasurementConfirm');
  String get measurementDeleted => _t('measurementDeleted');
  String get selectLocation => _t('selectLocation');
  String get camera => _t('camera');
  String get gallery => _t('gallery');
  String get allFields => _t('allFields');
  String get selectFieldTitle => _t('selectFieldTitle');
  String get mapLegend => _t('mapLegend');
  String get clear => _t('clear');

  // ─── Vaccines ─────────────────────────────────────────────────────────────
  String get vaccinePlanning => _t('vaccinePlanning');
  String get confirmAdministration => _t('confirmAdministration');
  String get noVaccinesScheduled => _t('noVaccinesScheduled');
  String get bulkVaccination => _t('bulkVaccination');
  String get confirmVaccination => _t('confirmVaccination');
  String get nextBooster => _t('nextBooster');
  String get healthRecord => _t('healthRecord');

  // ─── Security ─────────────────────────────────────────────────────────────
  String get deleteIncident => _t('deleteIncident');
  String get deleteIncidentConfirm => _t('deleteIncidentConfirm');
  String get incidentDeleted => _t('incidentDeleted');
  String get incidentResolved => _t('incidentResolved');
  String get sirenActivated => _t('sirenActivated');
  String get sirenDeactivated => _t('sirenDeactivated');
  String get goBack => _t('goBack');
  String get previousReports => _t('previousReports');
  String get changeIp => _t('changeIp');

  // ─── Finance ──────────────────────────────────────────────────────────────
  String get financeDashboard => _t('financeDashboard');
  String get netBalance => _t('netBalance');
  String get revenues => _t('revenues');
  String get expensesByCategory => _t('expensesByCategory');
  String get topCostlyAnimals => _t('topCostlyAnimals');
  String get latestExpenses => _t('latestExpenses');
  String get noFieldFound => _t('noFieldFound');
  String get selectAField => _t('selectAField');
  String get overview => _t('overview');

  // ─── Plant Doctor ─────────────────────────────────────────────────────────
  String get plantDoctorResult => _t('plantDoctorResult');
  String get deleteDiagnosis => _t('deleteDiagnosis');
  String get deleteDiagnosisConfirm => _t('deleteDiagnosisConfirm');
  String get clearHistory => _t('clearHistory');
  String get clearHistoryConfirm => _t('clearHistoryConfirm');

  // ─── Catalogue book ───────────────────────────────────────────────────────
  String get smartFarmManagement => _t('smartFarmManagement');
  String get livestockSalesCatalogue => _t('livestockSalesCatalogue');
  String get thankYouInterest => _t('thankYouInterest');
  String get forInquiries => _t('forInquiries');
  String get previous => _t('previous');
  String get cover => _t('cover');
  String get backCover => _t('backCover');

  // ─── Misc ─────────────────────────────────────────────────────────────────
  String get searchByName => _t('searchByName');
  String get noAnimalsFound => _t('noAnimalsFound');
  String get animalDataNotAvailable => _t('animalDataNotAvailable');
  String get addAnimalToPreview => _t('addAnimalToPreview');
  String get resetToDefaults => _t('resetToDefaults');
  String get applySettings => _t('applySettings');
  String get advancedOptions => _t('advancedOptions');
  String get includeNotes => _t('includeNotes');
  String get compactMode => _t('compactMode');
  String get goToSignIn => _t('goToSignIn');
  String get connectionTimeout => _t('connectionTimeout');
  String get sessionExpired => _t('sessionExpired');
  String get couldNotLoadProfile => _t('couldNotLoadProfile');
  String get editProfile => _t('editProfile');
  String get deleteAccount => _t('deleteAccount');
  String get deleteAccountConfirm => _t('deleteAccountConfirm');
  String get memberSince => _t('memberSince');
  String get username => _t('username');
  String get goPro => _t('goPro');
  String get rateApp => _t('rateApp');

  // ─── Seasonal Sales ───────────────────────────────────────────────────────
  String get seasonalSales => _t('seasonalSales');
  String get allParcels => _t('allParcels');
  String animalSoldSuccessName(String name) => _tp('animalSoldSuccessName', {'name': name});
  String errorPrefix(String message) => _tp('errorPrefix', {'message': message});
  String get noFatteningAnimals => _t('noFatteningAnimals');
  String fatteningDays(int days) => _tp('fatteningDays', {'days': days.toString()});
  String get targetSaleDateLabel => _t('targetSaleDateLabel');
  String get notDefined => _t('notDefined');
  String get ready => _t('ready');
  String get details => _t('details');
  String get sell => _t('sell');
  String get sellAnimalTitle => _t('sellAnimalTitle');
  String sellAnimalConfirm(String name) => _tp('sellAnimalConfirm', {'name': name});

  // ─── Finance ──────────────────────────────────────────────────────────────
  String financeTitle(String name) => _tp('financeTitle', {'name': name});
  String get birthCostLabel => _t('birthCostLabel');
  String get purchasePriceLabel => _t('purchasePriceLabel');
  String get totalCost => _t('totalCost');
  String get realizedMargin => _t('realizedMargin');
  String get currentCostVsValue => _t('currentCostVsValue');
  String soldFor(String price) => _tp('soldFor', {'price': price});
  String get duration => _t('duration');
  String durationDays(int days) => _tp('durationDays', {'days': days.toString()});
  String get costPerDay => _t('costPerDay');
  String get expensesBreakdown => _t('expensesBreakdown');
  String get feedAndNutrition => _t('feedAndNutrition');
  String get veterinary => _t('veterinary');
  String get medicationAndVaccines => _t('medicationAndVaccines');
  String get equipmentAndServices => _t('equipmentAndServices');
  String get labor => _t('labor');
  String get other => _t('other');
  String get missingBirthCost => _t('missingBirthCost');
  String get missingPurchasePrice => _t('missingPurchasePrice');
  String get noExpensesTracked => _t('noExpensesTracked');

  // ─── Medical Events ───────────────────────────────────────────────────────
  String get medicalEventTypeVisit => _t('medicalEventTypeVisit');
  String get medicalEventTypeDisease => _t('medicalEventTypeDisease');
  String get medicalEventTypeSurgery => _t('medicalEventTypeSurgery');
  String get medicalEventTypeTreatment => _t('medicalEventTypeTreatment');
  String get medicalEventTypeCheckup => _t('medicalEventTypeCheckup');
  String get medicalEventTypeOther => _t('medicalEventTypeOther');
  String get editEvent => _t('editEvent');
  String get newMedicalEvent => _t('newMedicalEvent');
  String get eventType => _t('eventType');
  String get eventDate => _t('eventDate');
  String get diagnosisLabel => _t('diagnosisLabel');
  String get diagnosisHint => _t('diagnosisHint');
  String get treatmentLabel => _t('treatmentLabel');
  String get treatmentHint => _t('treatmentHint');
  String get veterinarianLabel => _t('veterinarianLabel');
  String get veterinarianHint => _t('veterinarianHint');
  String get costTnd => _t('costTnd');
  String get costHint => _t('costHint');
  String get invalidNumber => _t('invalidNumber');
  String get additionalNotes => _t('additionalNotes');
  String get eventUpdated => _t('eventUpdated');
  String get eventAdded => _t('eventAdded');

  // ─── AI Diagnosis ─────────────────────────────────────────────────────────
  String get aiDiagnosis => _t('aiDiagnosis');
  String get alertLevelCritical => _t('alertLevelCritical');
  String get alertLevelModerate => _t('alertLevelModerate');
  String get alertLevelHealthy => _t('alertLevelHealthy');
  String get diagnosisSummary => _t('diagnosisSummary');
  String get sensorReadings1h => _t('sensorReadings1h');
  String get sensorTemperature => _t('sensorTemperature');
  String get sensorHeartRate => _t('sensorHeartRate');
  String get sensorActivityScore => _t('sensorActivityScore');
  String get sensorLyingTime => _t('sensorLyingTime');
  String get sensorGaitAsymmetry => _t('sensorGaitAsymmetry');
  String get anomalyTriggers => _t('anomalyTriggers');
  String get triggersSubtitle => _t('triggersSubtitle');
  String get diseaseProbabilities => _t('diseaseProbabilities');
  String get probabilitiesSubtitle => _t('probabilitiesSubtitle');
  String clinicalSigns(String disease) => _tp('clinicalSigns', {'disease': disease});
  String get urgentActionRequired => _t('urgentActionRequired');
  String get recommendation => _t('recommendation');
  String get staticFallbackWarning => _t('staticFallbackWarning');
  String get nonBovineNote => _t('nonBovineNote');
  String confidenceAndAnomaly(int conf, int anomaly) => _tp('confidenceAndAnomaly', {'conf': conf.toString(), 'anomaly': anomaly.toString()});

  // ─── Weight Tracking ──────────────────────────────────────────────────────
  String get weightTracking => _t('weightTracking');
  String get addMeasurementTooltip => _t('addMeasurementTooltip');
  String get addWeightRecord => _t('addWeightRecord');
  String get weightKgLabel => _t('weightKgLabel');
  String get measuredByLabel => _t('measuredByLabel');
  String get pleaseEnterValidWeight => _t('pleaseEnterValidWeight');
  String get weightRecordAdded => _t('weightRecordAdded');
  String get deleteWeightRecord => _t('deleteWeightRecord');
  String get deleteWeightRecordConfirm => _t('deleteWeightRecordConfirm');
  String get weightMeasurements => _t('weightMeasurements');
  String get noMeasurementsYet => _t('noMeasurementsYet');
  String get weightEvolution => _t('weightEvolution');
  String get noDataForPeriod => _t('noDataForPeriod');
  String get current => _t('current');
  String get min => _t('min');
  String get max => _t('max');
  String get trend => _t('trend');
  String kgPerWeek(String value) => _tp('kgPerWeek', {'value': value});

  // ─── Sensor Graph ─────────────────────────────────────────────────────────
  String get sensorPeriod => _t('sensorPeriod');
  String get period6h => _t('period6h');
  String get period24h => _t('period24h');
  String get period7d => _t('period7d');
  String get sensorTemperatureLabel => _t('sensorTemperatureLabel');
  String get sensorHeartRateLabel => _t('sensorHeartRateLabel');
  String get sensorActivityLabel => _t('sensorActivityLabel');
  String get noSensorData => _t('noSensorData');
  String get noSensorDataAvailable => _t('noSensorDataAvailable');
  String get sensorTempChart => _t('sensorTempChart');
  String get sensorHrChart => _t('sensorHrChart');
  String get sensorActivityChart => _t('sensorActivityChart');
  String normalRange(String range) => _tp('normalRange', {'range': range});
  String get alertsDetected => _t('alertsDetected');
  String get anomalyDetected => _t('anomalyDetected');
  String confidence(String value) => _tp('confidence', {'value': value});
  String get refreshTooltip => _t('refreshTooltip');
  String sensorsTitle(String name) => _tp('sensorsTitle', {'name': name});

  // ─── Animal Details ───────────────────────────────────────────────────────
  String get markAsDeceased => _t('markAsDeceased');
  String markAsDeceasedConfirm(String name) => _tp('markAsDeceasedConfirm', {'name': name});
  String get causeNotesOptional => _t('causeNotesOptional');
  String markedAsDeceased(String name) => _tp('markedAsDeceased', {'name': name});
  String get runAiDiagnostic => _t('runAiDiagnostic');
  String get analysing => _t('analysing');
  String get simulateSensorData => _t('simulateSensorData');
  String get seeFullExplanation => _t('seeFullExplanation');
  String get aiServiceOffline => _t('aiServiceOffline');
  String get sensorSimulator => _t('sensorSimulator');
  String get sensorSimulatorSubtitle => _t('sensorSimulatorSubtitle');
  String get scenario => _t('scenario');

  // ─── Dashboard ────────────────────────────────────────────────────────────
  String get dashboardTotalAnimals => _t('dashboardTotalAnimals');
  String get dashboardActive => _t('dashboardActive');
  String get dashboardHealthAlerts => _t('dashboardHealthAlerts');
  String get dashboardHighRisk => _t('dashboardHighRisk');
  String get dashboardVaccinesDue => _t('dashboardVaccinesDue');
  String get dashboardSchedulingPending => _t('dashboardSchedulingPending');
  String get dashboardMonthlySpend => _t('dashboardMonthlySpend');
  String get dashboardRequireAttention => _t('dashboardRequireAttention');
  String get noLivestockData => _t('noLivestockData');
  String get animalsNeedingAttention => _t('animalsNeedingAttention');
  String get viewAll => _t('viewAll');
  String get alertBadge => _t('alertBadge');
  String get healthScoreLabel => _t('healthScoreLabel');
  String get todaysMilk => _t('todaysMilk');
  String vsYesterdayLiters(String liters) => _tp('vsYesterdayLiters', {'liters': liters});
  String get todaysReminders => _t('todaysReminders');

  // ─── Milk Analytics ───────────────────────────────────────────────────────
  String get milkAnalyticsTitle => _t('milkAnalyticsTitle');
  String get selectYear => _t('selectYear');
  String get selectMonth => _t('selectMonth');
  String totalLitersIn(String period) => _tp('totalLitersIn', {'period': period});
  String get liters => _t('liters');
  String vsLastPeriod(String period) => _tp('vsLastPeriod', {'period': period});
  String get weeklyProduction => _t('weeklyProduction');
  String get monToSunAverage => _t('monToSunAverage');
  String get lPerDay => _t('lPerDay');
  String get dayMon => _t('dayMon');
  String get dayTue => _t('dayTue');
  String get dayWed => _t('dayWed');
  String get dayThu => _t('dayThu');
  String get dayFri => _t('dayFri');
  String get daySat => _t('daySat');
  String get daySun => _t('daySun');
  String get productionTrendYearly => _t('productionTrendYearly');
  String get productionTrendMonthly => _t('productionTrendMonthly');
  String get yearlyPerformance => _t('yearlyPerformance');
  String get avgDailyYield => _t('avgDailyYield');
  String get activeCattle => _t('activeCattle');
  String get head => _t('head');
  String get weeklyHerdBreakdown => _t('weeklyHerdBreakdown');
  String get topProducingCows => _t('topProducingCows');
  String get tagIdPrefix => _t('tagIdPrefix');
  String get totalPerWeek => _t('totalPerWeek');
  String get totalPerYear => _t('totalPerYear');

  // ─── Revenues (manual) ────────────────────────────────────────────────────
  String get addRevenue => _t('addRevenue');
  String get revenueAddedSuccess => _t('revenueAddedSuccess');
  String get noRevenuesFound => _t('noRevenuesFound');
  String get revenueSourceManual => _t('revenueSourceManual');
  String get revenueSourceAnimalSale => _t('revenueSourceAnimalSale');
  String get revenueCategoryMilk => _t('revenueCategoryMilk');
  String get revenueCategoryCrops => _t('revenueCategoryCrops');
  String get revenueCategoryServices => _t('revenueCategoryServices');
  String get revenueCategorySubsidies => _t('revenueCategorySubsidies');
  String get revenueDescription => _t('revenueDescription');
  String get revenueDescriptionHint => _t('revenueDescriptionHint');
  String get revenueSearchHint => _t('revenueSearchHint');
  String get amount => _t('amount');
  String get amountRequired => _t('amountRequired');
  String get date => _t('date');
  String get period => _t('period');
  String get periodMonth => _t('periodMonth');
  String get periodQuarter => _t('periodQuarter');
  String get periodYear => _t('periodYear');
}

// ─── Delegate ─────────────────────────────────────────────────────────────────

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      kSupportedLocales.map((l) => l.languageCode).contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    final code = locale.languageCode;
    final jsonString = await rootBundle.loadString('lib/l10n/app_$code.arb');
    final Map<String, dynamic> raw = json.decode(jsonString);
    final strings = raw.map(
      (key, value) => MapEntry(key, value.toString()),
    )..removeWhere((key, _) => key.startsWith('@'));
    return AppLocalizations(locale, strings);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
    Locale('fr')
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Fieldly'**
  String get appName;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signIn;

  /// No description provided for @signUp.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signUp;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get signOut;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @phone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phone;

  /// No description provided for @emailOrPhone.
  ///
  /// In en, this message translates to:
  /// **'Email or phone number'**
  String get emailOrPhone;

  /// No description provided for @emailOrPhoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Email or Phone'**
  String get emailOrPhoneLabel;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPassword;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgotPassword;

  /// No description provided for @rememberMe.
  ///
  /// In en, this message translates to:
  /// **'Remember me'**
  String get rememberMe;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullName;

  /// No description provided for @farmName.
  ///
  /// In en, this message translates to:
  /// **'Farm Name'**
  String get farmName;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get createAccount;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome Back'**
  String get welcomeBack;

  /// No description provided for @signInToContinue.
  ///
  /// In en, this message translates to:
  /// **'Sign in to continue to Fieldly'**
  String get signInToContinue;

  /// No description provided for @joinFieldly.
  ///
  /// In en, this message translates to:
  /// **'Join Fieldly to manage your farm'**
  String get joinFieldly;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? '**
  String get alreadyHaveAccount;

  /// No description provided for @dontHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? '**
  String get dontHaveAccount;

  /// No description provided for @contactMethod.
  ///
  /// In en, this message translates to:
  /// **'Contact Method'**
  String get contactMethod;

  /// No description provided for @enterFullName.
  ///
  /// In en, this message translates to:
  /// **'Enter your full name'**
  String get enterFullName;

  /// No description provided for @enterFarmName.
  ///
  /// In en, this message translates to:
  /// **'Enter your farm name'**
  String get enterFarmName;

  /// No description provided for @enterEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter your email'**
  String get enterEmail;

  /// No description provided for @enterPhone.
  ///
  /// In en, this message translates to:
  /// **'Enter your phone number'**
  String get enterPhone;

  /// No description provided for @createPassword.
  ///
  /// In en, this message translates to:
  /// **'Create a password'**
  String get createPassword;

  /// No description provided for @confirmYourPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm your password'**
  String get confirmYourPassword;

  /// No description provided for @enterPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get enterPassword;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @dashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboard;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @selectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get selectLanguage;

  /// No description provided for @fields.
  ///
  /// In en, this message translates to:
  /// **'Fields'**
  String get fields;

  /// No description provided for @parcels.
  ///
  /// In en, this message translates to:
  /// **'Parcels'**
  String get parcels;

  /// No description provided for @missions.
  ///
  /// In en, this message translates to:
  /// **'Missions'**
  String get missions;

  /// No description provided for @crops.
  ///
  /// In en, this message translates to:
  /// **'Crops'**
  String get crops;

  /// No description provided for @addField.
  ///
  /// In en, this message translates to:
  /// **'Add Field'**
  String get addField;

  /// No description provided for @addParcel.
  ///
  /// In en, this message translates to:
  /// **'Add Parcel'**
  String get addParcel;

  /// No description provided for @createMission.
  ///
  /// In en, this message translates to:
  /// **'Create Mission'**
  String get createMission;

  /// No description provided for @fieldManagement.
  ///
  /// In en, this message translates to:
  /// **'Field Management'**
  String get fieldManagement;

  /// No description provided for @parcelList.
  ///
  /// In en, this message translates to:
  /// **'Parcel List'**
  String get parcelList;

  /// No description provided for @missionList.
  ///
  /// In en, this message translates to:
  /// **'Mission List'**
  String get missionList;

  /// No description provided for @selectField.
  ///
  /// In en, this message translates to:
  /// **'Select a field'**
  String get selectField;

  /// No description provided for @animals.
  ///
  /// In en, this message translates to:
  /// **'Animals'**
  String get animals;

  /// No description provided for @addAnimal.
  ///
  /// In en, this message translates to:
  /// **'Add Animal'**
  String get addAnimal;

  /// No description provided for @animalList.
  ///
  /// In en, this message translates to:
  /// **'Animal List'**
  String get animalList;

  /// No description provided for @animalDetails.
  ///
  /// In en, this message translates to:
  /// **'Animal Details'**
  String get animalDetails;

  /// No description provided for @animalType.
  ///
  /// In en, this message translates to:
  /// **'Animal Type'**
  String get animalType;

  /// No description provided for @breed.
  ///
  /// In en, this message translates to:
  /// **'Breed'**
  String get breed;

  /// No description provided for @age.
  ///
  /// In en, this message translates to:
  /// **'Age'**
  String get age;

  /// No description provided for @weight.
  ///
  /// In en, this message translates to:
  /// **'Weight'**
  String get weight;

  /// No description provided for @healthStatus.
  ///
  /// In en, this message translates to:
  /// **'Health Status'**
  String get healthStatus;

  /// No description provided for @vaccination.
  ///
  /// In en, this message translates to:
  /// **'Vaccination'**
  String get vaccination;

  /// No description provided for @milkProduction.
  ///
  /// In en, this message translates to:
  /// **'Milk Production'**
  String get milkProduction;

  /// No description provided for @genealogy.
  ///
  /// In en, this message translates to:
  /// **'Genealogy'**
  String get genealogy;

  /// No description provided for @plannedSales.
  ///
  /// In en, this message translates to:
  /// **'Planned Sales'**
  String get plannedSales;

  /// No description provided for @cow.
  ///
  /// In en, this message translates to:
  /// **'Cow'**
  String get cow;

  /// No description provided for @horse.
  ///
  /// In en, this message translates to:
  /// **'Horse'**
  String get horse;

  /// No description provided for @sheep.
  ///
  /// In en, this message translates to:
  /// **'Sheep'**
  String get sheep;

  /// No description provided for @dog.
  ///
  /// In en, this message translates to:
  /// **'Dog'**
  String get dog;

  /// No description provided for @male.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get male;

  /// No description provided for @female.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get female;

  /// No description provided for @active.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get active;

  /// No description provided for @sold.
  ///
  /// In en, this message translates to:
  /// **'Sold'**
  String get sold;

  /// No description provided for @deceased.
  ///
  /// In en, this message translates to:
  /// **'Deceased'**
  String get deceased;

  /// No description provided for @vaccines.
  ///
  /// In en, this message translates to:
  /// **'Vaccines'**
  String get vaccines;

  /// No description provided for @vaccineDashboard.
  ///
  /// In en, this message translates to:
  /// **'Vaccine Management'**
  String get vaccineDashboard;

  /// No description provided for @vaccineSchedule.
  ///
  /// In en, this message translates to:
  /// **'Vaccine Schedule'**
  String get vaccineSchedule;

  /// No description provided for @vaccineRecord.
  ///
  /// In en, this message translates to:
  /// **'Vaccine Record'**
  String get vaccineRecord;

  /// No description provided for @vaccinesDue.
  ///
  /// In en, this message translates to:
  /// **'Vaccines Due'**
  String get vaccinesDue;

  /// No description provided for @addVaccine.
  ///
  /// In en, this message translates to:
  /// **'Add Vaccine'**
  String get addVaccine;

  /// No description provided for @soil.
  ///
  /// In en, this message translates to:
  /// **'Soil'**
  String get soil;

  /// No description provided for @soilMeasurements.
  ///
  /// In en, this message translates to:
  /// **'Soil Measurements'**
  String get soilMeasurements;

  /// No description provided for @soilAlerts.
  ///
  /// In en, this message translates to:
  /// **'Soil Alerts'**
  String get soilAlerts;

  /// No description provided for @soilIntelligence.
  ///
  /// In en, this message translates to:
  /// **'Soil Intelligence'**
  String get soilIntelligence;

  /// No description provided for @ph.
  ///
  /// In en, this message translates to:
  /// **'pH'**
  String get ph;

  /// No description provided for @moisture.
  ///
  /// In en, this message translates to:
  /// **'Moisture'**
  String get moisture;

  /// No description provided for @temperature.
  ///
  /// In en, this message translates to:
  /// **'Temperature'**
  String get temperature;

  /// No description provided for @nutrients.
  ///
  /// In en, this message translates to:
  /// **'Nutrients'**
  String get nutrients;

  /// No description provided for @weather.
  ///
  /// In en, this message translates to:
  /// **'Weather'**
  String get weather;

  /// No description provided for @irrigation.
  ///
  /// In en, this message translates to:
  /// **'Irrigation'**
  String get irrigation;

  /// No description provided for @irrigationScheduler.
  ///
  /// In en, this message translates to:
  /// **'Irrigation Scheduler'**
  String get irrigationScheduler;

  /// No description provided for @assets.
  ///
  /// In en, this message translates to:
  /// **'Assets'**
  String get assets;

  /// No description provided for @assetList.
  ///
  /// In en, this message translates to:
  /// **'Asset List'**
  String get assetList;

  /// No description provided for @addAsset.
  ///
  /// In en, this message translates to:
  /// **'Add Asset'**
  String get addAsset;

  /// No description provided for @assetDetails.
  ///
  /// In en, this message translates to:
  /// **'Asset Details'**
  String get assetDetails;

  /// No description provided for @available.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get available;

  /// No description provided for @inUse.
  ///
  /// In en, this message translates to:
  /// **'In Use'**
  String get inUse;

  /// No description provided for @maintenance.
  ///
  /// In en, this message translates to:
  /// **'Maintenance'**
  String get maintenance;

  /// No description provided for @startUsing.
  ///
  /// In en, this message translates to:
  /// **'Start Using'**
  String get startUsing;

  /// No description provided for @finishUsing.
  ///
  /// In en, this message translates to:
  /// **'Finish Using'**
  String get finishUsing;

  /// No description provided for @markAvailable.
  ///
  /// In en, this message translates to:
  /// **'Mark Available'**
  String get markAvailable;

  /// No description provided for @markInUse.
  ///
  /// In en, this message translates to:
  /// **'Mark In Use'**
  String get markInUse;

  /// No description provided for @finance.
  ///
  /// In en, this message translates to:
  /// **'Finance'**
  String get finance;

  /// No description provided for @expenses.
  ///
  /// In en, this message translates to:
  /// **'Expenses'**
  String get expenses;

  /// No description provided for @financeDetails.
  ///
  /// In en, this message translates to:
  /// **'Finance Details'**
  String get financeDetails;

  /// No description provided for @addExpense.
  ///
  /// In en, this message translates to:
  /// **'Add Expense'**
  String get addExpense;

  /// No description provided for @monthlySpend.
  ///
  /// In en, this message translates to:
  /// **'Monthly Spend'**
  String get monthlySpend;

  /// No description provided for @catalogues.
  ///
  /// In en, this message translates to:
  /// **'Catalogues'**
  String get catalogues;

  /// No description provided for @salesCatalogues.
  ///
  /// In en, this message translates to:
  /// **'Sales Catalogues'**
  String get salesCatalogues;

  /// No description provided for @newCatalogue.
  ///
  /// In en, this message translates to:
  /// **'New Catalogue'**
  String get newCatalogue;

  /// No description provided for @createCatalogue.
  ///
  /// In en, this message translates to:
  /// **'Create Catalogue'**
  String get createCatalogue;

  /// No description provided for @editCatalogue.
  ///
  /// In en, this message translates to:
  /// **'Edit Catalogue'**
  String get editCatalogue;

  /// No description provided for @publishCatalogue.
  ///
  /// In en, this message translates to:
  /// **'Publish Catalogue'**
  String get publishCatalogue;

  /// No description provided for @deleteCatalogue.
  ///
  /// In en, this message translates to:
  /// **'Delete Catalogue'**
  String get deleteCatalogue;

  /// No description provided for @noCataloguesYet.
  ///
  /// In en, this message translates to:
  /// **'No catalogues yet'**
  String get noCataloguesYet;

  /// No description provided for @createFirstCatalogue.
  ///
  /// In en, this message translates to:
  /// **'Create your first sales catalogue to showcase your livestock to buyers.'**
  String get createFirstCatalogue;

  /// No description provided for @draft.
  ///
  /// In en, this message translates to:
  /// **'Draft'**
  String get draft;

  /// No description provided for @published.
  ///
  /// In en, this message translates to:
  /// **'Published'**
  String get published;

  /// No description provided for @closed.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get closed;

  /// No description provided for @archived.
  ///
  /// In en, this message translates to:
  /// **'Archived'**
  String get archived;

  /// No description provided for @preview.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get preview;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @publish.
  ///
  /// In en, this message translates to:
  /// **'Publish'**
  String get publish;

  /// No description provided for @exportShare.
  ///
  /// In en, this message translates to:
  /// **'Export & Share'**
  String get exportShare;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @community.
  ///
  /// In en, this message translates to:
  /// **'Community'**
  String get community;

  /// No description provided for @communityFeed.
  ///
  /// In en, this message translates to:
  /// **'Community Feed'**
  String get communityFeed;

  /// No description provided for @createPost.
  ///
  /// In en, this message translates to:
  /// **'Create Post'**
  String get createPost;

  /// No description provided for @newPost.
  ///
  /// In en, this message translates to:
  /// **'New Post'**
  String get newPost;

  /// No description provided for @shareUpdate.
  ///
  /// In en, this message translates to:
  /// **'Share an update or start a vote with farmers'**
  String get shareUpdate;

  /// No description provided for @post.
  ///
  /// In en, this message translates to:
  /// **'Post'**
  String get post;

  /// No description provided for @like.
  ///
  /// In en, this message translates to:
  /// **'Like'**
  String get like;

  /// No description provided for @dislike.
  ///
  /// In en, this message translates to:
  /// **'Dislike'**
  String get dislike;

  /// No description provided for @comments.
  ///
  /// In en, this message translates to:
  /// **'Comments'**
  String get comments;

  /// No description provided for @vote.
  ///
  /// In en, this message translates to:
  /// **'Vote'**
  String get vote;

  /// No description provided for @deletePost.
  ///
  /// In en, this message translates to:
  /// **'Delete Post?'**
  String get deletePost;

  /// No description provided for @deletePostConfirm.
  ///
  /// In en, this message translates to:
  /// **'This action cannot be undone.'**
  String get deletePostConfirm;

  /// No description provided for @security.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get security;

  /// No description provided for @incidents.
  ///
  /// In en, this message translates to:
  /// **'Incidents'**
  String get incidents;

  /// No description provided for @incidentHistory.
  ///
  /// In en, this message translates to:
  /// **'Incident History'**
  String get incidentHistory;

  /// No description provided for @liveFeed.
  ///
  /// In en, this message translates to:
  /// **'Live Feed'**
  String get liveFeed;

  /// No description provided for @dailyReport.
  ///
  /// In en, this message translates to:
  /// **'Daily Report'**
  String get dailyReport;

  /// No description provided for @acousticMonitor.
  ///
  /// In en, this message translates to:
  /// **'Acoustic Monitor'**
  String get acousticMonitor;

  /// No description provided for @ai.
  ///
  /// In en, this message translates to:
  /// **'AI Assistant'**
  String get ai;

  /// No description provided for @chatAssistant.
  ///
  /// In en, this message translates to:
  /// **'Chat Assistant'**
  String get chatAssistant;

  /// No description provided for @plantDoctor.
  ///
  /// In en, this message translates to:
  /// **'Plant Doctor'**
  String get plantDoctor;

  /// No description provided for @aiAgronomist.
  ///
  /// In en, this message translates to:
  /// **'AI Agronomist'**
  String get aiAgronomist;

  /// No description provided for @mechanicChat.
  ///
  /// In en, this message translates to:
  /// **'Mechanic Chat'**
  String get mechanicChat;

  /// No description provided for @voiceAssistant.
  ///
  /// In en, this message translates to:
  /// **'Voice Assistant'**
  String get voiceAssistant;

  /// No description provided for @controlRoom.
  ///
  /// In en, this message translates to:
  /// **'Control Room'**
  String get controlRoom;

  /// No description provided for @robots.
  ///
  /// In en, this message translates to:
  /// **'Robots'**
  String get robots;

  /// No description provided for @telemetry.
  ///
  /// In en, this message translates to:
  /// **'Telemetry'**
  String get telemetry;

  /// No description provided for @skillCertification.
  ///
  /// In en, this message translates to:
  /// **'Skill Certification'**
  String get skillCertification;

  /// No description provided for @farmQuiz.
  ///
  /// In en, this message translates to:
  /// **'Farm Quiz'**
  String get farmQuiz;

  /// No description provided for @shorts.
  ///
  /// In en, this message translates to:
  /// **'Shorts'**
  String get shorts;

  /// No description provided for @news.
  ///
  /// In en, this message translates to:
  /// **'Agricultural News'**
  String get news;

  /// No description provided for @staff.
  ///
  /// In en, this message translates to:
  /// **'Staff'**
  String get staff;

  /// No description provided for @addStaff.
  ///
  /// In en, this message translates to:
  /// **'Add Staff'**
  String get addStaff;

  /// No description provided for @staffList.
  ///
  /// In en, this message translates to:
  /// **'Staff List'**
  String get staffList;

  /// No description provided for @worker.
  ///
  /// In en, this message translates to:
  /// **'Worker'**
  String get worker;

  /// No description provided for @owner.
  ///
  /// In en, this message translates to:
  /// **'Owner'**
  String get owner;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @noData.
  ///
  /// In en, this message translates to:
  /// **'No data available'**
  String get noData;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @filter.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get filter;

  /// No description provided for @sort.
  ///
  /// In en, this message translates to:
  /// **'Sort'**
  String get sort;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @goodMorning.
  ///
  /// In en, this message translates to:
  /// **'Good Morning'**
  String get goodMorning;

  /// No description provided for @goodAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good Afternoon'**
  String get goodAfternoon;

  /// No description provided for @goodEvening.
  ///
  /// In en, this message translates to:
  /// **'Good Evening'**
  String get goodEvening;

  /// No description provided for @goodNight.
  ///
  /// In en, this message translates to:
  /// **'Good Night'**
  String get goodNight;

  /// No description provided for @hi.
  ///
  /// In en, this message translates to:
  /// **'Hi'**
  String get hi;

  /// No description provided for @totalAnimals.
  ///
  /// In en, this message translates to:
  /// **'Total Animals'**
  String get totalAnimals;

  /// No description provided for @healthAlerts.
  ///
  /// In en, this message translates to:
  /// **'Health Alerts'**
  String get healthAlerts;

  /// No description provided for @totalCrops.
  ///
  /// In en, this message translates to:
  /// **'Total Crops'**
  String get totalCrops;

  /// No description provided for @farmScore.
  ///
  /// In en, this message translates to:
  /// **'Farm Score'**
  String get farmScore;

  /// No description provided for @myMaterials.
  ///
  /// In en, this message translates to:
  /// **'My Materials & Equipment'**
  String get myMaterials;

  /// No description provided for @noMaterialsAssigned.
  ///
  /// In en, this message translates to:
  /// **'No materials assigned yet'**
  String get noMaterialsAssigned;

  /// No description provided for @currentlyInUse.
  ///
  /// In en, this message translates to:
  /// **'Currently in Use'**
  String get currentlyInUse;

  /// No description provided for @startUsingMaterial.
  ///
  /// In en, this message translates to:
  /// **'Start Using Material'**
  String get startUsingMaterial;

  /// No description provided for @selectMaterial.
  ///
  /// In en, this message translates to:
  /// **'Select material...'**
  String get selectMaterial;

  /// No description provided for @start.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get start;

  /// No description provided for @finish.
  ///
  /// In en, this message translates to:
  /// **'Finish & Save'**
  String get finish;

  /// No description provided for @distanceKm.
  ///
  /// In en, this message translates to:
  /// **'Distance (km)'**
  String get distanceKm;

  /// No description provided for @issues.
  ///
  /// In en, this message translates to:
  /// **'Issues'**
  String get issues;

  /// No description provided for @issuesOptional.
  ///
  /// In en, this message translates to:
  /// **'Issues (Optional)'**
  String get issuesOptional;

  /// No description provided for @maintenanceNote.
  ///
  /// In en, this message translates to:
  /// **'Maintenance Note (Optional)'**
  String get maintenanceNote;

  /// No description provided for @condition.
  ///
  /// In en, this message translates to:
  /// **'Condition'**
  String get condition;

  /// No description provided for @good.
  ///
  /// In en, this message translates to:
  /// **'Good'**
  String get good;

  /// No description provided for @warning.
  ///
  /// In en, this message translates to:
  /// **'Warning'**
  String get warning;

  /// No description provided for @critical.
  ///
  /// In en, this message translates to:
  /// **'Critical'**
  String get critical;

  /// No description provided for @manageYourMaterials.
  ///
  /// In en, this message translates to:
  /// **'Manage your materials and equipment for today\'s work'**
  String get manageYourMaterials;

  /// No description provided for @welcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome'**
  String get welcome;

  /// No description provided for @soilAlert.
  ///
  /// In en, this message translates to:
  /// **'Soil Alert'**
  String get soilAlert;

  /// No description provided for @newSoilAlertReceived.
  ///
  /// In en, this message translates to:
  /// **'New soil alert received'**
  String get newSoilAlertReceived;

  /// No description provided for @cannotDeletePublished.
  ///
  /// In en, this message translates to:
  /// **'Cannot delete a {status} catalogue. Only draft catalogues can be deleted.'**
  String cannotDeletePublished(String status);

  /// No description provided for @deleteConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete \"{title}\"?'**
  String deleteConfirmTitle(String title);

  /// No description provided for @deleteConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'This cannot be undone.'**
  String get deleteConfirmBody;

  /// No description provided for @publishConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'Publishing will make this catalogue visible to buyers. Continue?'**
  String get publishConfirmBody;

  /// No description provided for @animalsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} animal{count, plural, =1{} other{s}}'**
  String animalsCount(int count);

  /// No description provided for @createdOn.
  ///
  /// In en, this message translates to:
  /// **'Created {date}'**
  String createdOn(String date);

  /// No description provided for @manageLivestockCatalogues.
  ///
  /// In en, this message translates to:
  /// **'Manage your livestock catalogues'**
  String get manageLivestockCatalogues;

  /// No description provided for @enterDistanceTraveled.
  ///
  /// In en, this message translates to:
  /// **'Enter distance traveled'**
  String get enterDistanceTraveled;

  /// No description provided for @describeIssues.
  ///
  /// In en, this message translates to:
  /// **'Describe issues encountered'**
  String get describeIssues;

  /// No description provided for @recommendedMaintenance.
  ///
  /// In en, this message translates to:
  /// **'Recommended maintenance actions'**
  String get recommendedMaintenance;

  /// No description provided for @maintenanceRequired.
  ///
  /// In en, this message translates to:
  /// **'Maintenance Required'**
  String get maintenanceRequired;

  /// No description provided for @machineRequiresMaintenance.
  ///
  /// In en, this message translates to:
  /// **'⚠ Machine requires maintenance before use'**
  String get machineRequiresMaintenance;

  /// No description provided for @currentlyUsedByYou.
  ///
  /// In en, this message translates to:
  /// **'Currently used by you'**
  String get currentlyUsedByYou;

  /// No description provided for @currentlyUsedBy.
  ///
  /// In en, this message translates to:
  /// **'Currently used by {name}'**
  String currentlyUsedBy(String name);

  /// No description provided for @assetNotFound.
  ///
  /// In en, this message translates to:
  /// **'Asset not found for this QR code.'**
  String get assetNotFound;

  /// No description provided for @assetFound.
  ///
  /// In en, this message translates to:
  /// **'Asset Found'**
  String get assetFound;

  /// No description provided for @workerAccount.
  ///
  /// In en, this message translates to:
  /// **'Worker Account'**
  String get workerAccount;

  /// No description provided for @noFieldAssigned.
  ///
  /// In en, this message translates to:
  /// **'No field is assigned to this worker account yet.'**
  String get noFieldAssigned;

  /// No description provided for @failedToLoad.
  ///
  /// In en, this message translates to:
  /// **'Failed to load dashboard'**
  String get failedToLoad;

  /// No description provided for @signOutConfirm.
  ///
  /// In en, this message translates to:
  /// **'Do you want to sign out of this worker account?'**
  String get signOutConfirm;

  /// No description provided for @enterValidNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid number'**
  String get enterValidNumber;

  /// No description provided for @distanceRequired.
  ///
  /// In en, this message translates to:
  /// **'Distance is required'**
  String get distanceRequired;

  /// No description provided for @distanceNegative.
  ///
  /// In en, this message translates to:
  /// **'Distance cannot be negative'**
  String get distanceNegative;

  /// No description provided for @serialNumber.
  ///
  /// In en, this message translates to:
  /// **'Serial'**
  String get serialNumber;

  /// No description provided for @category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// No description provided for @brand.
  ///
  /// In en, this message translates to:
  /// **'Brand'**
  String get brand;

  /// No description provided for @model.
  ///
  /// In en, this message translates to:
  /// **'Model'**
  String get model;

  /// No description provided for @mileage.
  ///
  /// In en, this message translates to:
  /// **'Mileage'**
  String get mileage;

  /// No description provided for @operatingHours.
  ///
  /// In en, this message translates to:
  /// **'Hours'**
  String get operatingHours;

  /// No description provided for @unknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknown;

  /// No description provided for @addLivestock.
  ///
  /// In en, this message translates to:
  /// **'Add Livestock'**
  String get addLivestock;

  /// No description provided for @livestock.
  ///
  /// In en, this message translates to:
  /// **'Livestock'**
  String get livestock;

  /// No description provided for @searchByNameOrId.
  ///
  /// In en, this message translates to:
  /// **'Search by name or tag...'**
  String get searchByNameOrId;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @viewDetails.
  ///
  /// In en, this message translates to:
  /// **'View Details'**
  String get viewDetails;

  /// No description provided for @cancelSale.
  ///
  /// In en, this message translates to:
  /// **'Cancel Sale'**
  String get cancelSale;

  /// No description provided for @fattening.
  ///
  /// In en, this message translates to:
  /// **'Fattening'**
  String get fattening;

  /// No description provided for @deleteAnimal.
  ///
  /// In en, this message translates to:
  /// **'Delete Animal'**
  String get deleteAnimal;

  /// No description provided for @deleteAnimalConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete {name}? This cannot be undone.'**
  String deleteAnimalConfirm(String name);

  /// No description provided for @animalDeleted.
  ///
  /// In en, this message translates to:
  /// **'Animal deleted'**
  String get animalDeleted;

  /// No description provided for @markAsFattening.
  ///
  /// In en, this message translates to:
  /// **'Mark as Fattening'**
  String get markAsFattening;

  /// No description provided for @markedAsFattening.
  ///
  /// In en, this message translates to:
  /// **'Marked as fattening'**
  String get markedAsFattening;

  /// No description provided for @startDate.
  ///
  /// In en, this message translates to:
  /// **'Start date'**
  String get startDate;

  /// No description provided for @targetSaleDate.
  ///
  /// In en, this message translates to:
  /// **'Target sale date (optional)'**
  String get targetSaleDate;

  /// No description provided for @sellAnimal.
  ///
  /// In en, this message translates to:
  /// **'Sell'**
  String get sellAnimal;

  /// No description provided for @salePrice.
  ///
  /// In en, this message translates to:
  /// **'Sale Price'**
  String get salePrice;

  /// No description provided for @saleDate.
  ///
  /// In en, this message translates to:
  /// **'Sale Date'**
  String get saleDate;

  /// No description provided for @buyerName.
  ///
  /// In en, this message translates to:
  /// **'Buyer Name (Optional)'**
  String get buyerName;

  /// No description provided for @saleWeightKg.
  ///
  /// In en, this message translates to:
  /// **'Sale Weight Kg (Optional)'**
  String get saleWeightKg;

  /// No description provided for @notes.
  ///
  /// In en, this message translates to:
  /// **'Notes (Optional)'**
  String get notes;

  /// No description provided for @confirmSale.
  ///
  /// In en, this message translates to:
  /// **'CONFIRM SALE'**
  String get confirmSale;

  /// No description provided for @animalSoldSuccess.
  ///
  /// In en, this message translates to:
  /// **'Animal sold successfully!'**
  String get animalSoldSuccess;

  /// No description provided for @cancelSaleConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Cancel Sale'**
  String get cancelSaleConfirmTitle;

  /// No description provided for @cancelSaleConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to cancel the sale of {name}? The animal will be marked as active.'**
  String cancelSaleConfirmBody(String name);

  /// No description provided for @saleCancelled.
  ///
  /// In en, this message translates to:
  /// **'Sale of {name} has been cancelled'**
  String saleCancelled(String name);

  /// No description provided for @sex.
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get sex;

  /// No description provided for @origin.
  ///
  /// In en, this message translates to:
  /// **'Origin'**
  String get origin;

  /// No description provided for @aiHealthRisk.
  ///
  /// In en, this message translates to:
  /// **'AI Health Risk'**
  String get aiHealthRisk;

  /// No description provided for @highRisk.
  ///
  /// In en, this message translates to:
  /// **'High Risk'**
  String get highRisk;

  /// No description provided for @moderateRisk.
  ///
  /// In en, this message translates to:
  /// **'Moderate Risk'**
  String get moderateRisk;

  /// No description provided for @lowRisk.
  ///
  /// In en, this message translates to:
  /// **'Low Risk'**
  String get lowRisk;

  /// No description provided for @healthAndVitals.
  ///
  /// In en, this message translates to:
  /// **'Health & Vitals'**
  String get healthAndVitals;

  /// No description provided for @vitalityScore.
  ///
  /// In en, this message translates to:
  /// **'Vitality Score'**
  String get vitalityScore;

  /// No description provided for @activityLevel.
  ///
  /// In en, this message translates to:
  /// **'Activity'**
  String get activityLevel;

  /// No description provided for @lastVetCheck.
  ///
  /// In en, this message translates to:
  /// **'Last vet check'**
  String get lastVetCheck;

  /// No description provided for @vaccinatedUpToDate.
  ///
  /// In en, this message translates to:
  /// **'✓ Up to date'**
  String get vaccinatedUpToDate;

  /// No description provided for @notVaccinated.
  ///
  /// In en, this message translates to:
  /// **'✗ Not vaccinated'**
  String get notVaccinated;

  /// No description provided for @dairyAndReproduction.
  ///
  /// In en, this message translates to:
  /// **'Dairy & Reproduction'**
  String get dairyAndReproduction;

  /// No description provided for @pregnant.
  ///
  /// In en, this message translates to:
  /// **'Pregnant'**
  String get pregnant;

  /// No description provided for @birthCount.
  ///
  /// In en, this message translates to:
  /// **'Birth count'**
  String get birthCount;

  /// No description provided for @avgMilkPerDay.
  ///
  /// In en, this message translates to:
  /// **'Avg milk/day'**
  String get avgMilkPerDay;

  /// No description provided for @lactationNumber.
  ///
  /// In en, this message translates to:
  /// **'Lactation #'**
  String get lactationNumber;

  /// No description provided for @performance.
  ///
  /// In en, this message translates to:
  /// **'Performance'**
  String get performance;

  /// No description provided for @bestTime.
  ///
  /// In en, this message translates to:
  /// **'Best time'**
  String get bestTime;

  /// No description provided for @trainingLevel.
  ///
  /// In en, this message translates to:
  /// **'Training level'**
  String get trainingLevel;

  /// No description provided for @lastShearing.
  ///
  /// In en, this message translates to:
  /// **'Last shearing'**
  String get lastShearing;

  /// No description provided for @meatGrade.
  ///
  /// In en, this message translates to:
  /// **'Meat grade'**
  String get meatGrade;

  /// No description provided for @role.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get role;

  /// No description provided for @fatteningProgress.
  ///
  /// In en, this message translates to:
  /// **'Fattening Progress'**
  String get fatteningProgress;

  /// No description provided for @started.
  ///
  /// In en, this message translates to:
  /// **'Started'**
  String get started;

  /// No description provided for @daysInFattening.
  ///
  /// In en, this message translates to:
  /// **'Days in fattening'**
  String get daysInFattening;

  /// No description provided for @daysRemaining.
  ///
  /// In en, this message translates to:
  /// **'Days remaining'**
  String get daysRemaining;

  /// No description provided for @readyForSale.
  ///
  /// In en, this message translates to:
  /// **'Ready for sale'**
  String get readyForSale;

  /// No description provided for @mother.
  ///
  /// In en, this message translates to:
  /// **'Mother'**
  String get mother;

  /// No description provided for @father.
  ///
  /// In en, this message translates to:
  /// **'Father'**
  String get father;

  /// No description provided for @purchasePrice.
  ///
  /// In en, this message translates to:
  /// **'Purchase price'**
  String get purchasePrice;

  /// No description provided for @purchaseDate.
  ///
  /// In en, this message translates to:
  /// **'Purchase date'**
  String get purchaseDate;

  /// No description provided for @birthCost.
  ///
  /// In en, this message translates to:
  /// **'Birth cost'**
  String get birthCost;

  /// No description provided for @birthWeight.
  ///
  /// In en, this message translates to:
  /// **'Birth weight'**
  String get birthWeight;

  /// No description provided for @estimatedValue.
  ///
  /// In en, this message translates to:
  /// **'Estimated value'**
  String get estimatedValue;

  /// No description provided for @medicalHistory.
  ///
  /// In en, this message translates to:
  /// **'Medical History'**
  String get medicalHistory;

  /// No description provided for @vaccinations.
  ///
  /// In en, this message translates to:
  /// **'Vaccinations'**
  String get vaccinations;

  /// No description provided for @medicalEvents.
  ///
  /// In en, this message translates to:
  /// **'Medical Events'**
  String get medicalEvents;

  /// No description provided for @noVaccinationsRecorded.
  ///
  /// In en, this message translates to:
  /// **'No vaccinations recorded'**
  String get noVaccinationsRecorded;

  /// No description provided for @species.
  ///
  /// In en, this message translates to:
  /// **'Species'**
  String get species;

  /// No description provided for @selectSpecies.
  ///
  /// In en, this message translates to:
  /// **'Select Species'**
  String get selectSpecies;

  /// No description provided for @addPhoto.
  ///
  /// In en, this message translates to:
  /// **'Add a photo'**
  String get addPhoto;

  /// No description provided for @cameraOrGallery.
  ///
  /// In en, this message translates to:
  /// **'Camera or gallery'**
  String get cameraOrGallery;

  /// No description provided for @takePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take a photo'**
  String get takePhoto;

  /// No description provided for @chooseFromGallery.
  ///
  /// In en, this message translates to:
  /// **'Choose from gallery'**
  String get chooseFromGallery;

  /// No description provided for @removePhoto.
  ///
  /// In en, this message translates to:
  /// **'Remove photo'**
  String get removePhoto;

  /// No description provided for @editAnimal.
  ///
  /// In en, this message translates to:
  /// **'Edit Animal'**
  String get editAnimal;

  /// No description provided for @milkAnalytics.
  ///
  /// In en, this message translates to:
  /// **'Milk Analytics'**
  String get milkAnalytics;

  /// No description provided for @thisWeek.
  ///
  /// In en, this message translates to:
  /// **'This Week'**
  String get thisWeek;

  /// No description provided for @thisMonth.
  ///
  /// In en, this message translates to:
  /// **'This Month'**
  String get thisMonth;

  /// No description provided for @thisYear.
  ///
  /// In en, this message translates to:
  /// **'This Year'**
  String get thisYear;

  /// No description provided for @totalYield.
  ///
  /// In en, this message translates to:
  /// **'Total Yield'**
  String get totalYield;

  /// No description provided for @topProducer.
  ///
  /// In en, this message translates to:
  /// **'Top Producer'**
  String get topProducer;

  /// No description provided for @productionHistory.
  ///
  /// In en, this message translates to:
  /// **'Production History'**
  String get productionHistory;

  /// No description provided for @addEntry.
  ///
  /// In en, this message translates to:
  /// **'Add Entry'**
  String get addEntry;

  /// No description provided for @noRecordsYet.
  ///
  /// In en, this message translates to:
  /// **'No records yet'**
  String get noRecordsYet;

  /// No description provided for @newMilkRecord.
  ///
  /// In en, this message translates to:
  /// **'New Milk Record'**
  String get newMilkRecord;

  /// No description provided for @editMilkRecord.
  ///
  /// In en, this message translates to:
  /// **'Edit Milk Record'**
  String get editMilkRecord;

  /// No description provided for @selectCow.
  ///
  /// In en, this message translates to:
  /// **'Select Cow'**
  String get selectCow;

  /// No description provided for @morningL.
  ///
  /// In en, this message translates to:
  /// **'Morning (L)'**
  String get morningL;

  /// No description provided for @eveningL.
  ///
  /// In en, this message translates to:
  /// **'Evening (L)'**
  String get eveningL;

  /// No description provided for @saveRecord.
  ///
  /// In en, this message translates to:
  /// **'Save Record'**
  String get saveRecord;

  /// No description provided for @updateRecord.
  ///
  /// In en, this message translates to:
  /// **'Update Record'**
  String get updateRecord;

  /// No description provided for @deleteRecord.
  ///
  /// In en, this message translates to:
  /// **'Delete Record'**
  String get deleteRecord;

  /// No description provided for @deleteRecordConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this milk production record?'**
  String get deleteRecordConfirm;

  /// No description provided for @allTime.
  ///
  /// In en, this message translates to:
  /// **'All time'**
  String get allTime;

  /// No description provided for @recordMilk.
  ///
  /// In en, this message translates to:
  /// **'Record Milk'**
  String get recordMilk;

  /// No description provided for @catalogueTitle.
  ///
  /// In en, this message translates to:
  /// **'Catalogue Title'**
  String get catalogueTitle;

  /// No description provided for @catalogueTitleHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., Spring 2024 Dairy Cattle Sale'**
  String get catalogueTitleHint;

  /// No description provided for @titleRequired.
  ///
  /// In en, this message translates to:
  /// **'Title is required'**
  String get titleRequired;

  /// No description provided for @location.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get location;

  /// No description provided for @locationHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., Farm Location, City'**
  String get locationHint;

  /// No description provided for @selectDate.
  ///
  /// In en, this message translates to:
  /// **'Select date'**
  String get selectDate;

  /// No description provided for @currency.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get currency;

  /// No description provided for @showPrices.
  ///
  /// In en, this message translates to:
  /// **'Show Prices'**
  String get showPrices;

  /// No description provided for @selectedAnimals.
  ///
  /// In en, this message translates to:
  /// **'Selected Animals'**
  String get selectedAnimals;

  /// No description provided for @addAnimals.
  ///
  /// In en, this message translates to:
  /// **'Add Animals'**
  String get addAnimals;

  /// No description provided for @noAnimalsSelected.
  ///
  /// In en, this message translates to:
  /// **'No animals selected'**
  String get noAnimalsSelected;

  /// No description provided for @addAnimalsToInclude.
  ///
  /// In en, this message translates to:
  /// **'Add animals to include in your catalogue'**
  String get addAnimalsToInclude;

  /// No description provided for @selectAnimals.
  ///
  /// In en, this message translates to:
  /// **'Select Animals'**
  String get selectAnimals;

  /// No description provided for @catalogueSettings.
  ///
  /// In en, this message translates to:
  /// **'Catalogue Settings'**
  String get catalogueSettings;

  /// No description provided for @sectionsToInclude.
  ///
  /// In en, this message translates to:
  /// **'Sections to Include'**
  String get sectionsToInclude;

  /// No description provided for @animalPhotos.
  ///
  /// In en, this message translates to:
  /// **'Animal Photos'**
  String get animalPhotos;

  /// No description provided for @animalDetailsSection.
  ///
  /// In en, this message translates to:
  /// **'Animal Details'**
  String get animalDetailsSection;

  /// No description provided for @healthRecords.
  ///
  /// In en, this message translates to:
  /// **'Health Records'**
  String get healthRecords;

  /// No description provided for @vaccinationHistory.
  ///
  /// In en, this message translates to:
  /// **'Vaccination History'**
  String get vaccinationHistory;

  /// No description provided for @productionRecords.
  ///
  /// In en, this message translates to:
  /// **'Production Records'**
  String get productionRecords;

  /// No description provided for @geneticInformation.
  ///
  /// In en, this message translates to:
  /// **'Genetic Information'**
  String get geneticInformation;

  /// No description provided for @layoutOptions.
  ///
  /// In en, this message translates to:
  /// **'Layout Options'**
  String get layoutOptions;

  /// No description provided for @twoColumnLayout.
  ///
  /// In en, this message translates to:
  /// **'Two Column Layout'**
  String get twoColumnLayout;

  /// No description provided for @showQrCodes.
  ///
  /// In en, this message translates to:
  /// **'Show QR Codes'**
  String get showQrCodes;

  /// No description provided for @includeContactInfo.
  ///
  /// In en, this message translates to:
  /// **'Include Contact Info'**
  String get includeContactInfo;

  /// No description provided for @exitWizard.
  ///
  /// In en, this message translates to:
  /// **'Exit Wizard'**
  String get exitWizard;

  /// No description provided for @exitWizardConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to exit? Any unsaved changes will be lost.'**
  String get exitWizardConfirm;

  /// No description provided for @exit.
  ///
  /// In en, this message translates to:
  /// **'Exit'**
  String get exit;

  /// No description provided for @basicInformation.
  ///
  /// In en, this message translates to:
  /// **'Basic Information'**
  String get basicInformation;

  /// No description provided for @info.
  ///
  /// In en, this message translates to:
  /// **'Info'**
  String get info;

  /// No description provided for @step.
  ///
  /// In en, this message translates to:
  /// **'Step'**
  String get step;

  /// No description provided for @catalogueSummary.
  ///
  /// In en, this message translates to:
  /// **'Catalogue Summary'**
  String get catalogueSummary;

  /// No description provided for @exportOptions.
  ///
  /// In en, this message translates to:
  /// **'Export Options'**
  String get exportOptions;

  /// No description provided for @viewAsBook.
  ///
  /// In en, this message translates to:
  /// **'View as Book'**
  String get viewAsBook;

  /// No description provided for @viewAsBookSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Browse catalogue page by page — cover, animals, back cover'**
  String get viewAsBookSubtitle;

  /// No description provided for @printCatalogue.
  ///
  /// In en, this message translates to:
  /// **'Print Catalogue'**
  String get printCatalogue;

  /// No description provided for @printCatalogueSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Send to printer for physical copies'**
  String get printCatalogueSubtitle;

  /// No description provided for @emailCatalogue.
  ///
  /// In en, this message translates to:
  /// **'Email Catalogue'**
  String get emailCatalogue;

  /// No description provided for @emailCatalogueSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Send PDF via email to buyers'**
  String get emailCatalogueSubtitle;

  /// No description provided for @shareOptions.
  ///
  /// In en, this message translates to:
  /// **'Share Options'**
  String get shareOptions;

  /// No description provided for @generateShareLink.
  ///
  /// In en, this message translates to:
  /// **'Generate Share Link'**
  String get generateShareLink;

  /// No description provided for @generateShareLinkSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create a public link for buyers to view'**
  String get generateShareLinkSubtitle;

  /// No description provided for @shareCatalogue.
  ///
  /// In en, this message translates to:
  /// **'Share Catalogue'**
  String get shareCatalogue;

  /// No description provided for @shareCatalogueSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Share via social media or messaging'**
  String get shareCatalogueSubtitle;

  /// No description provided for @qrCode.
  ///
  /// In en, this message translates to:
  /// **'QR Code'**
  String get qrCode;

  /// No description provided for @qrCodeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Generate QR code for easy access'**
  String get qrCodeSubtitle;

  /// No description provided for @copy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copy;

  /// No description provided for @revoke.
  ///
  /// In en, this message translates to:
  /// **'Revoke'**
  String get revoke;

  /// No description provided for @shareLinkCopied.
  ///
  /// In en, this message translates to:
  /// **'Share link copied to clipboard'**
  String get shareLinkCopied;

  /// No description provided for @shareLinkRevoked.
  ///
  /// In en, this message translates to:
  /// **'Share link revoked'**
  String get shareLinkRevoked;

  /// No description provided for @pdfGenerated.
  ///
  /// In en, this message translates to:
  /// **'PDF Generated'**
  String get pdfGenerated;

  /// No description provided for @pdfGeneratedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Your catalogue PDF has been generated successfully.'**
  String get pdfGeneratedSuccess;

  /// No description provided for @viewPdf.
  ///
  /// In en, this message translates to:
  /// **'View PDF'**
  String get viewPdf;

  /// No description provided for @previewNotice.
  ///
  /// In en, this message translates to:
  /// **'This is a preview. Save the catalogue to enable PDF generation and sharing.'**
  String get previewNotice;

  /// No description provided for @soilAlertNotifications.
  ///
  /// In en, this message translates to:
  /// **'Soil Alert Notifications'**
  String get soilAlertNotifications;

  /// No description provided for @markRead.
  ///
  /// In en, this message translates to:
  /// **'Mark read'**
  String get markRead;

  /// No description provided for @addMeasurement.
  ///
  /// In en, this message translates to:
  /// **'Add Measurement'**
  String get addMeasurement;

  /// No description provided for @deleteMeasurement.
  ///
  /// In en, this message translates to:
  /// **'Delete Measurement'**
  String get deleteMeasurement;

  /// No description provided for @deleteMeasurementConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this measurement? This action cannot be undone.'**
  String get deleteMeasurementConfirm;

  /// No description provided for @measurementDeleted.
  ///
  /// In en, this message translates to:
  /// **'Measurement deleted successfully'**
  String get measurementDeleted;

  /// No description provided for @selectLocation.
  ///
  /// In en, this message translates to:
  /// **'Please select a location on the map'**
  String get selectLocation;

  /// No description provided for @camera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get camera;

  /// No description provided for @gallery.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get gallery;

  /// No description provided for @allFields.
  ///
  /// In en, this message translates to:
  /// **'All Fields'**
  String get allFields;

  /// No description provided for @selectFieldTitle.
  ///
  /// In en, this message translates to:
  /// **'Select Field'**
  String get selectFieldTitle;

  /// No description provided for @mapLegend.
  ///
  /// In en, this message translates to:
  /// **'Map Legend'**
  String get mapLegend;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @vaccinePlanning.
  ///
  /// In en, this message translates to:
  /// **'Vaccine Planning'**
  String get vaccinePlanning;

  /// No description provided for @confirmAdministration.
  ///
  /// In en, this message translates to:
  /// **'Confirm administration'**
  String get confirmAdministration;

  /// No description provided for @noVaccinesScheduled.
  ///
  /// In en, this message translates to:
  /// **'No vaccines scheduled'**
  String get noVaccinesScheduled;

  /// No description provided for @bulkVaccination.
  ///
  /// In en, this message translates to:
  /// **'Bulk vaccination'**
  String get bulkVaccination;

  /// No description provided for @confirmVaccination.
  ///
  /// In en, this message translates to:
  /// **'Confirm vaccination'**
  String get confirmVaccination;

  /// No description provided for @nextBooster.
  ///
  /// In en, this message translates to:
  /// **'Next booster'**
  String get nextBooster;

  /// No description provided for @healthRecord.
  ///
  /// In en, this message translates to:
  /// **'Health Record'**
  String get healthRecord;

  /// No description provided for @deleteIncident.
  ///
  /// In en, this message translates to:
  /// **'Delete Incident'**
  String get deleteIncident;

  /// No description provided for @deleteIncidentConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this incident?'**
  String get deleteIncidentConfirm;

  /// No description provided for @incidentDeleted.
  ///
  /// In en, this message translates to:
  /// **'Incident deleted'**
  String get incidentDeleted;

  /// No description provided for @incidentResolved.
  ///
  /// In en, this message translates to:
  /// **'Incident marked as resolved'**
  String get incidentResolved;

  /// No description provided for @sirenActivated.
  ///
  /// In en, this message translates to:
  /// **'🚨 Siren activated!'**
  String get sirenActivated;

  /// No description provided for @sirenDeactivated.
  ///
  /// In en, this message translates to:
  /// **'Siren deactivated'**
  String get sirenDeactivated;

  /// No description provided for @goBack.
  ///
  /// In en, this message translates to:
  /// **'Go Back'**
  String get goBack;

  /// No description provided for @previousReports.
  ///
  /// In en, this message translates to:
  /// **'Previous Reports'**
  String get previousReports;

  /// No description provided for @changeIp.
  ///
  /// In en, this message translates to:
  /// **'Change IP'**
  String get changeIp;

  /// No description provided for @financeDashboard.
  ///
  /// In en, this message translates to:
  /// **'Finance Dashboard'**
  String get financeDashboard;

  /// No description provided for @netBalance.
  ///
  /// In en, this message translates to:
  /// **'Net Balance'**
  String get netBalance;

  /// No description provided for @revenues.
  ///
  /// In en, this message translates to:
  /// **'Revenues'**
  String get revenues;

  /// No description provided for @expensesByCategory.
  ///
  /// In en, this message translates to:
  /// **'Expenses by Category'**
  String get expensesByCategory;

  /// No description provided for @topCostlyAnimals.
  ///
  /// In en, this message translates to:
  /// **'Top costly animals'**
  String get topCostlyAnimals;

  /// No description provided for @latestExpenses.
  ///
  /// In en, this message translates to:
  /// **'Latest Expenses'**
  String get latestExpenses;

  /// No description provided for @noFieldFound.
  ///
  /// In en, this message translates to:
  /// **'No field found'**
  String get noFieldFound;

  /// No description provided for @selectAField.
  ///
  /// In en, this message translates to:
  /// **'Select a field'**
  String get selectAField;

  /// No description provided for @overview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get overview;

  /// No description provided for @plantDoctorResult.
  ///
  /// In en, this message translates to:
  /// **'Diagnosis Result'**
  String get plantDoctorResult;

  /// No description provided for @deleteDiagnosis.
  ///
  /// In en, this message translates to:
  /// **'Delete diagnosis?'**
  String get deleteDiagnosis;

  /// No description provided for @deleteDiagnosisConfirm.
  ///
  /// In en, this message translates to:
  /// **'This will remove the saved capture and AI report from your history.'**
  String get deleteDiagnosisConfirm;

  /// No description provided for @clearHistory.
  ///
  /// In en, this message translates to:
  /// **'Clear all history?'**
  String get clearHistory;

  /// No description provided for @clearHistoryConfirm.
  ///
  /// In en, this message translates to:
  /// **'All saved plant doctor diagnoses will be permanently removed.'**
  String get clearHistoryConfirm;

  /// No description provided for @smartFarmManagement.
  ///
  /// In en, this message translates to:
  /// **'Smart Farm Management'**
  String get smartFarmManagement;

  /// No description provided for @livestockSalesCatalogue.
  ///
  /// In en, this message translates to:
  /// **'LIVESTOCK SALES CATALOGUE'**
  String get livestockSalesCatalogue;

  /// No description provided for @thankYouInterest.
  ///
  /// In en, this message translates to:
  /// **'Thank you for your interest in our livestock.'**
  String get thankYouInterest;

  /// No description provided for @forInquiries.
  ///
  /// In en, this message translates to:
  /// **'For inquiries, please contact us.'**
  String get forInquiries;

  /// No description provided for @previous.
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get previous;

  /// No description provided for @cover.
  ///
  /// In en, this message translates to:
  /// **'Cover'**
  String get cover;

  /// No description provided for @backCover.
  ///
  /// In en, this message translates to:
  /// **'Back cover'**
  String get backCover;

  /// No description provided for @searchByName.
  ///
  /// In en, this message translates to:
  /// **'Search by name...'**
  String get searchByName;

  /// No description provided for @noAnimalsFound.
  ///
  /// In en, this message translates to:
  /// **'No animals found'**
  String get noAnimalsFound;

  /// No description provided for @animalDataNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Animal data not available'**
  String get animalDataNotAvailable;

  /// No description provided for @addAnimalToPreview.
  ///
  /// In en, this message translates to:
  /// **'Add animals to see the preview'**
  String get addAnimalToPreview;

  /// No description provided for @resetToDefaults.
  ///
  /// In en, this message translates to:
  /// **'Reset to Defaults'**
  String get resetToDefaults;

  /// No description provided for @applySettings.
  ///
  /// In en, this message translates to:
  /// **'Apply Settings'**
  String get applySettings;

  /// No description provided for @advancedOptions.
  ///
  /// In en, this message translates to:
  /// **'Advanced Options'**
  String get advancedOptions;

  /// No description provided for @includeNotes.
  ///
  /// In en, this message translates to:
  /// **'Include Notes'**
  String get includeNotes;

  /// No description provided for @compactMode.
  ///
  /// In en, this message translates to:
  /// **'Compact Mode'**
  String get compactMode;

  /// No description provided for @goToSignIn.
  ///
  /// In en, this message translates to:
  /// **'Go to Sign In'**
  String get goToSignIn;

  /// No description provided for @connectionTimeout.
  ///
  /// In en, this message translates to:
  /// **'Connection Timeout'**
  String get connectionTimeout;

  /// No description provided for @sessionExpired.
  ///
  /// In en, this message translates to:
  /// **'Session Expired'**
  String get sessionExpired;

  /// No description provided for @couldNotLoadProfile.
  ///
  /// In en, this message translates to:
  /// **'Could not load profile. Please sign in again.'**
  String get couldNotLoadProfile;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfile;

  /// No description provided for @deleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get deleteAccount;

  /// No description provided for @deleteAccountConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete your account? This action cannot be undone.'**
  String get deleteAccountConfirm;

  /// No description provided for @memberSince.
  ///
  /// In en, this message translates to:
  /// **'Member Since'**
  String get memberSince;

  /// No description provided for @username.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get username;

  /// No description provided for @goPro.
  ///
  /// In en, this message translates to:
  /// **'Go Pro'**
  String get goPro;

  /// No description provided for @rateApp.
  ///
  /// In en, this message translates to:
  /// **'Rate App'**
  String get rateApp;

  /// No description provided for @seasonalSales.
  ///
  /// In en, this message translates to:
  /// **'Seasonal Sales'**
  String get seasonalSales;

  /// No description provided for @allParcels.
  ///
  /// In en, this message translates to:
  /// **'All Parcels'**
  String get allParcels;

  /// No description provided for @animalSoldSuccessName.
  ///
  /// In en, this message translates to:
  /// **'{name} has been sold successfully'**
  String animalSoldSuccessName(String name);

  /// No description provided for @errorPrefix.
  ///
  /// In en, this message translates to:
  /// **'Error: {message}'**
  String errorPrefix(String message);

  /// No description provided for @noFatteningAnimals.
  ///
  /// In en, this message translates to:
  /// **'No animals in fattening'**
  String get noFatteningAnimals;

  /// No description provided for @fatteningDays.
  ///
  /// In en, this message translates to:
  /// **'In fattening for {days} days'**
  String fatteningDays(int days);

  /// No description provided for @targetSaleDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Target sale date'**
  String get targetSaleDateLabel;

  /// No description provided for @notDefined.
  ///
  /// In en, this message translates to:
  /// **'Not defined'**
  String get notDefined;

  /// No description provided for @ready.
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get ready;

  /// No description provided for @details.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get details;

  /// No description provided for @sell.
  ///
  /// In en, this message translates to:
  /// **'Sell'**
  String get sell;

  /// No description provided for @sellAnimalTitle.
  ///
  /// In en, this message translates to:
  /// **'Sell Animal'**
  String get sellAnimalTitle;

  /// No description provided for @sellAnimalConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to sell {name}?'**
  String sellAnimalConfirm(String name);

  /// No description provided for @financeTitle.
  ///
  /// In en, this message translates to:
  /// **'Finance: {name}'**
  String financeTitle(String name);

  /// No description provided for @birthCostLabel.
  ///
  /// In en, this message translates to:
  /// **'Birth Cost'**
  String get birthCostLabel;

  /// No description provided for @purchasePriceLabel.
  ///
  /// In en, this message translates to:
  /// **'Purchase Price'**
  String get purchasePriceLabel;

  /// No description provided for @totalCost.
  ///
  /// In en, this message translates to:
  /// **'Total Cost'**
  String get totalCost;

  /// No description provided for @realizedMargin.
  ///
  /// In en, this message translates to:
  /// **'REALIZED MARGIN'**
  String get realizedMargin;

  /// No description provided for @currentCostVsValue.
  ///
  /// In en, this message translates to:
  /// **'CURRENT COST VS VALUE'**
  String get currentCostVsValue;

  /// No description provided for @soldFor.
  ///
  /// In en, this message translates to:
  /// **'Sold for {price}'**
  String soldFor(String price);

  /// No description provided for @duration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get duration;

  /// No description provided for @durationDays.
  ///
  /// In en, this message translates to:
  /// **'{days} days'**
  String durationDays(int days);

  /// No description provided for @costPerDay.
  ///
  /// In en, this message translates to:
  /// **'Cost / Day'**
  String get costPerDay;

  /// No description provided for @expensesBreakdown.
  ///
  /// In en, this message translates to:
  /// **'EXPENSES BREAKDOWN'**
  String get expensesBreakdown;

  /// No description provided for @feedAndNutrition.
  ///
  /// In en, this message translates to:
  /// **'Feed & Nutrition'**
  String get feedAndNutrition;

  /// No description provided for @veterinary.
  ///
  /// In en, this message translates to:
  /// **'Veterinary'**
  String get veterinary;

  /// No description provided for @medicationAndVaccines.
  ///
  /// In en, this message translates to:
  /// **'Medication & Vaccines'**
  String get medicationAndVaccines;

  /// No description provided for @equipmentAndServices.
  ///
  /// In en, this message translates to:
  /// **'Equipment & Services'**
  String get equipmentAndServices;

  /// No description provided for @labor.
  ///
  /// In en, this message translates to:
  /// **'Labor'**
  String get labor;

  /// No description provided for @other.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get other;

  /// No description provided for @missingBirthCost.
  ///
  /// In en, this message translates to:
  /// **'Birth cost is missing. Margin calculation is incomplete.'**
  String get missingBirthCost;

  /// No description provided for @missingPurchasePrice.
  ///
  /// In en, this message translates to:
  /// **'Purchase price is missing. Margin calculation is incomplete.'**
  String get missingPurchasePrice;

  /// No description provided for @noExpensesTracked.
  ///
  /// In en, this message translates to:
  /// **'No expenses tracked yet for this animal.'**
  String get noExpensesTracked;

  /// No description provided for @medicalEventTypeVisit.
  ///
  /// In en, this message translates to:
  /// **'Vet Visit'**
  String get medicalEventTypeVisit;

  /// No description provided for @medicalEventTypeDisease.
  ///
  /// In en, this message translates to:
  /// **'Disease'**
  String get medicalEventTypeDisease;

  /// No description provided for @medicalEventTypeSurgery.
  ///
  /// In en, this message translates to:
  /// **'Surgery'**
  String get medicalEventTypeSurgery;

  /// No description provided for @medicalEventTypeTreatment.
  ///
  /// In en, this message translates to:
  /// **'Treatment'**
  String get medicalEventTypeTreatment;

  /// No description provided for @medicalEventTypeCheckup.
  ///
  /// In en, this message translates to:
  /// **'Checkup'**
  String get medicalEventTypeCheckup;

  /// No description provided for @medicalEventTypeOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get medicalEventTypeOther;

  /// No description provided for @editEvent.
  ///
  /// In en, this message translates to:
  /// **'Edit Event'**
  String get editEvent;

  /// No description provided for @newMedicalEvent.
  ///
  /// In en, this message translates to:
  /// **'New Medical Event'**
  String get newMedicalEvent;

  /// No description provided for @eventType.
  ///
  /// In en, this message translates to:
  /// **'Event Type'**
  String get eventType;

  /// No description provided for @eventDate.
  ///
  /// In en, this message translates to:
  /// **'Event Date'**
  String get eventDate;

  /// No description provided for @diagnosisLabel.
  ///
  /// In en, this message translates to:
  /// **'Diagnosis'**
  String get diagnosisLabel;

  /// No description provided for @diagnosisHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Acute mastitis, right quarter'**
  String get diagnosisHint;

  /// No description provided for @treatmentLabel.
  ///
  /// In en, this message translates to:
  /// **'Treatment'**
  String get treatmentLabel;

  /// No description provided for @treatmentHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Antibiotics 5 days + anti-inflammatory'**
  String get treatmentHint;

  /// No description provided for @veterinarianLabel.
  ///
  /// In en, this message translates to:
  /// **'Veterinarian'**
  String get veterinarianLabel;

  /// No description provided for @veterinarianHint.
  ///
  /// In en, this message translates to:
  /// **'Dr. Benali'**
  String get veterinarianHint;

  /// No description provided for @costTnd.
  ///
  /// In en, this message translates to:
  /// **'Cost (TND)'**
  String get costTnd;

  /// No description provided for @costHint.
  ///
  /// In en, this message translates to:
  /// **'150'**
  String get costHint;

  /// No description provided for @invalidNumber.
  ///
  /// In en, this message translates to:
  /// **'Invalid number'**
  String get invalidNumber;

  /// No description provided for @additionalNotes.
  ///
  /// In en, this message translates to:
  /// **'Additional observations...'**
  String get additionalNotes;

  /// No description provided for @eventUpdated.
  ///
  /// In en, this message translates to:
  /// **'Event updated'**
  String get eventUpdated;

  /// No description provided for @eventAdded.
  ///
  /// In en, this message translates to:
  /// **'Event added'**
  String get eventAdded;

  /// No description provided for @aiDiagnosis.
  ///
  /// In en, this message translates to:
  /// **'AI Diagnosis'**
  String get aiDiagnosis;

  /// No description provided for @alertLevelCritical.
  ///
  /// In en, this message translates to:
  /// **'CRITICAL'**
  String get alertLevelCritical;

  /// No description provided for @alertLevelModerate.
  ///
  /// In en, this message translates to:
  /// **'MODERATE'**
  String get alertLevelModerate;

  /// No description provided for @alertLevelHealthy.
  ///
  /// In en, this message translates to:
  /// **'HEALTHY'**
  String get alertLevelHealthy;

  /// No description provided for @diagnosisSummary.
  ///
  /// In en, this message translates to:
  /// **'Diagnosis Summary'**
  String get diagnosisSummary;

  /// No description provided for @sensorReadings1h.
  ///
  /// In en, this message translates to:
  /// **'Sensor Readings (1h average)'**
  String get sensorReadings1h;

  /// No description provided for @sensorTemperature.
  ///
  /// In en, this message translates to:
  /// **'🌡️ Temperature'**
  String get sensorTemperature;

  /// No description provided for @sensorHeartRate.
  ///
  /// In en, this message translates to:
  /// **'❤️ Heart Rate'**
  String get sensorHeartRate;

  /// No description provided for @sensorActivityScore.
  ///
  /// In en, this message translates to:
  /// **'🏃 Activity Score'**
  String get sensorActivityScore;

  /// No description provided for @sensorLyingTime.
  ///
  /// In en, this message translates to:
  /// **'🛏️ Lying Time (6h)'**
  String get sensorLyingTime;

  /// No description provided for @sensorGaitAsymmetry.
  ///
  /// In en, this message translates to:
  /// **'📐 Gait Asymmetry'**
  String get sensorGaitAsymmetry;

  /// No description provided for @anomalyTriggers.
  ///
  /// In en, this message translates to:
  /// **'Anomaly Triggers'**
  String get anomalyTriggers;

  /// No description provided for @triggersSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Parameters that triggered the alert'**
  String get triggersSubtitle;

  /// No description provided for @diseaseProbabilities.
  ///
  /// In en, this message translates to:
  /// **'Disease Probabilities'**
  String get diseaseProbabilities;

  /// No description provided for @probabilitiesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'XGBoost classification output (bovine model)'**
  String get probabilitiesSubtitle;

  /// No description provided for @clinicalSigns.
  ///
  /// In en, this message translates to:
  /// **'{disease} — Clinical Signs'**
  String clinicalSigns(String disease);

  /// No description provided for @urgentActionRequired.
  ///
  /// In en, this message translates to:
  /// **'URGENT ACTION REQUIRED'**
  String get urgentActionRequired;

  /// No description provided for @recommendation.
  ///
  /// In en, this message translates to:
  /// **'RECOMMENDATION'**
  String get recommendation;

  /// No description provided for @staticFallbackWarning.
  ///
  /// In en, this message translates to:
  /// **'⚠ Based on static fields — add IoT sensors for precision'**
  String get staticFallbackWarning;

  /// No description provided for @nonBovineNote.
  ///
  /// In en, this message translates to:
  /// **'The PastureAI model (bovine pathologies) does not apply to this species. The score shown is heuristic surveillance based on species physiological references.'**
  String get nonBovineNote;

  /// No description provided for @confidenceAndAnomaly.
  ///
  /// In en, this message translates to:
  /// **'Confidence: {conf}%  •  Anomaly: {anomaly}%'**
  String confidenceAndAnomaly(int conf, int anomaly);

  /// No description provided for @weightTracking.
  ///
  /// In en, this message translates to:
  /// **'Weight Tracking'**
  String get weightTracking;

  /// No description provided for @addMeasurementTooltip.
  ///
  /// In en, this message translates to:
  /// **'Add measurement'**
  String get addMeasurementTooltip;

  /// No description provided for @addWeightRecord.
  ///
  /// In en, this message translates to:
  /// **'Add Weight Record'**
  String get addWeightRecord;

  /// No description provided for @weightKgLabel.
  ///
  /// In en, this message translates to:
  /// **'Weight (kg)'**
  String get weightKgLabel;

  /// No description provided for @measuredByLabel.
  ///
  /// In en, this message translates to:
  /// **'Measured by (optional)'**
  String get measuredByLabel;

  /// No description provided for @pleaseEnterValidWeight.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid weight'**
  String get pleaseEnterValidWeight;

  /// No description provided for @weightRecordAdded.
  ///
  /// In en, this message translates to:
  /// **'Weight record added'**
  String get weightRecordAdded;

  /// No description provided for @deleteWeightRecord.
  ///
  /// In en, this message translates to:
  /// **'Delete Record'**
  String get deleteWeightRecord;

  /// No description provided for @deleteWeightRecordConfirm.
  ///
  /// In en, this message translates to:
  /// **'Remove this weight measurement?'**
  String get deleteWeightRecordConfirm;

  /// No description provided for @weightMeasurements.
  ///
  /// In en, this message translates to:
  /// **'Measurements'**
  String get weightMeasurements;

  /// No description provided for @noMeasurementsYet.
  ///
  /// In en, this message translates to:
  /// **'No measurements yet. Tap + to add one.'**
  String get noMeasurementsYet;

  /// No description provided for @weightEvolution.
  ///
  /// In en, this message translates to:
  /// **'Weight Evolution'**
  String get weightEvolution;

  /// No description provided for @noDataForPeriod.
  ///
  /// In en, this message translates to:
  /// **'No data for this period'**
  String get noDataForPeriod;

  /// No description provided for @current.
  ///
  /// In en, this message translates to:
  /// **'Current'**
  String get current;

  /// No description provided for @min.
  ///
  /// In en, this message translates to:
  /// **'Min'**
  String get min;

  /// No description provided for @max.
  ///
  /// In en, this message translates to:
  /// **'Max'**
  String get max;

  /// No description provided for @trend.
  ///
  /// In en, this message translates to:
  /// **'Trend'**
  String get trend;

  /// No description provided for @kgPerWeek.
  ///
  /// In en, this message translates to:
  /// **'{value} kg/w'**
  String kgPerWeek(String value);

  /// No description provided for @sensorPeriod.
  ///
  /// In en, this message translates to:
  /// **'Period:'**
  String get sensorPeriod;

  /// No description provided for @period6h.
  ///
  /// In en, this message translates to:
  /// **'6h'**
  String get period6h;

  /// No description provided for @period24h.
  ///
  /// In en, this message translates to:
  /// **'24h'**
  String get period24h;

  /// No description provided for @period7d.
  ///
  /// In en, this message translates to:
  /// **'7d'**
  String get period7d;

  /// No description provided for @sensorTemperatureLabel.
  ///
  /// In en, this message translates to:
  /// **'Temperature'**
  String get sensorTemperatureLabel;

  /// No description provided for @sensorHeartRateLabel.
  ///
  /// In en, this message translates to:
  /// **'Heart Rate'**
  String get sensorHeartRateLabel;

  /// No description provided for @sensorActivityLabel.
  ///
  /// In en, this message translates to:
  /// **'Activity'**
  String get sensorActivityLabel;

  /// No description provided for @noSensorData.
  ///
  /// In en, this message translates to:
  /// **'No data'**
  String get noSensorData;

  /// No description provided for @noSensorDataAvailable.
  ///
  /// In en, this message translates to:
  /// **'No data available'**
  String get noSensorDataAvailable;

  /// No description provided for @sensorTempChart.
  ///
  /// In en, this message translates to:
  /// **'🌡️ Temperature (°C)'**
  String get sensorTempChart;

  /// No description provided for @sensorHrChart.
  ///
  /// In en, this message translates to:
  /// **'❤️ Heart Rate (bpm)'**
  String get sensorHrChart;

  /// No description provided for @sensorActivityChart.
  ///
  /// In en, this message translates to:
  /// **'🏃 Activity Score'**
  String get sensorActivityChart;

  /// No description provided for @normalRange.
  ///
  /// In en, this message translates to:
  /// **'Normal range: {range}'**
  String normalRange(String range);

  /// No description provided for @alertsDetected.
  ///
  /// In en, this message translates to:
  /// **'🚨 Alerts Detected'**
  String get alertsDetected;

  /// No description provided for @anomalyDetected.
  ///
  /// In en, this message translates to:
  /// **'Anomaly detected'**
  String get anomalyDetected;

  /// No description provided for @confidence.
  ///
  /// In en, this message translates to:
  /// **'Confidence: {value}%'**
  String confidence(String value);

  /// No description provided for @refreshTooltip.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refreshTooltip;

  /// No description provided for @sensorsTitle.
  ///
  /// In en, this message translates to:
  /// **'Sensors — {name}'**
  String sensorsTitle(String name);

  /// No description provided for @markAsDeceased.
  ///
  /// In en, this message translates to:
  /// **'Mark as Deceased'**
  String get markAsDeceased;

  /// No description provided for @markAsDeceasedConfirm.
  ///
  /// In en, this message translates to:
  /// **'Mark {name} as deceased? This cannot be undone easily.'**
  String markAsDeceasedConfirm(String name);

  /// No description provided for @causeNotesOptional.
  ///
  /// In en, this message translates to:
  /// **'Cause / notes (optional)'**
  String get causeNotesOptional;

  /// No description provided for @markedAsDeceased.
  ///
  /// In en, this message translates to:
  /// **'{name} marked as deceased'**
  String markedAsDeceased(String name);

  /// No description provided for @runAiDiagnostic.
  ///
  /// In en, this message translates to:
  /// **'Run AI Diagnostic'**
  String get runAiDiagnostic;

  /// No description provided for @analysing.
  ///
  /// In en, this message translates to:
  /// **'Analysing...'**
  String get analysing;

  /// No description provided for @simulateSensorData.
  ///
  /// In en, this message translates to:
  /// **'Simulate Sensor Data'**
  String get simulateSensorData;

  /// No description provided for @seeFullExplanation.
  ///
  /// In en, this message translates to:
  /// **'See full explanation'**
  String get seeFullExplanation;

  /// No description provided for @aiServiceOffline.
  ///
  /// In en, this message translates to:
  /// **'AI service offline — start pastureai-ai server'**
  String get aiServiceOffline;

  /// No description provided for @sensorSimulator.
  ///
  /// In en, this message translates to:
  /// **'Sensor Simulator'**
  String get sensorSimulator;

  /// No description provided for @sensorSimulatorSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Inject synthetic sensor data & run AI diagnostic'**
  String get sensorSimulatorSubtitle;

  /// No description provided for @scenario.
  ///
  /// In en, this message translates to:
  /// **'SCENARIO'**
  String get scenario;

  /// No description provided for @dashboardTotalAnimals.
  ///
  /// In en, this message translates to:
  /// **'TOTAL ANIMALS'**
  String get dashboardTotalAnimals;

  /// No description provided for @dashboardActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get dashboardActive;

  /// No description provided for @dashboardHealthAlerts.
  ///
  /// In en, this message translates to:
  /// **'HEALTH ALERTS'**
  String get dashboardHealthAlerts;

  /// No description provided for @dashboardHighRisk.
  ///
  /// In en, this message translates to:
  /// **'High Risk'**
  String get dashboardHighRisk;

  /// No description provided for @dashboardVaccinesDue.
  ///
  /// In en, this message translates to:
  /// **'VACCINES DUE'**
  String get dashboardVaccinesDue;

  /// No description provided for @dashboardSchedulingPending.
  ///
  /// In en, this message translates to:
  /// **'Scheduling pending today'**
  String get dashboardSchedulingPending;

  /// No description provided for @dashboardMonthlySpend.
  ///
  /// In en, this message translates to:
  /// **'MONTHLY SPEND'**
  String get dashboardMonthlySpend;

  /// No description provided for @dashboardRequireAttention.
  ///
  /// In en, this message translates to:
  /// **'Require immediate attention'**
  String get dashboardRequireAttention;

  /// No description provided for @noLivestockData.
  ///
  /// In en, this message translates to:
  /// **'No livestock data'**
  String get noLivestockData;

  /// No description provided for @animalsNeedingAttention.
  ///
  /// In en, this message translates to:
  /// **'Animals needing attention'**
  String get animalsNeedingAttention;

  /// No description provided for @viewAll.
  ///
  /// In en, this message translates to:
  /// **'View All'**
  String get viewAll;

  /// No description provided for @alertBadge.
  ///
  /// In en, this message translates to:
  /// **'ALERT'**
  String get alertBadge;

  /// No description provided for @healthScoreLabel.
  ///
  /// In en, this message translates to:
  /// **'HEALTH SCORE'**
  String get healthScoreLabel;

  /// No description provided for @todaysMilk.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Milk'**
  String get todaysMilk;

  /// No description provided for @vsYesterdayLiters.
  ///
  /// In en, this message translates to:
  /// **'vs {liters}L yesterday'**
  String vsYesterdayLiters(String liters);

  /// No description provided for @analytics.
  ///
  /// In en, this message translates to:
  /// **'Analytics'**
  String get analytics;

  /// No description provided for @todaysReminders.
  ///
  /// In en, this message translates to:
  /// **'Today\'s reminders'**
  String get todaysReminders;

  /// No description provided for @milkAnalyticsTitle.
  ///
  /// In en, this message translates to:
  /// **'Milk Analytics'**
  String get milkAnalyticsTitle;

  /// No description provided for @selectYear.
  ///
  /// In en, this message translates to:
  /// **'Select Year'**
  String get selectYear;

  /// No description provided for @selectMonth.
  ///
  /// In en, this message translates to:
  /// **'Select Month'**
  String get selectMonth;

  /// No description provided for @totalLitersIn.
  ///
  /// In en, this message translates to:
  /// **'Total Liters in {period}'**
  String totalLitersIn(String period);

  /// No description provided for @liters.
  ///
  /// In en, this message translates to:
  /// **'Liters'**
  String get liters;

  /// No description provided for @vsLastPeriod.
  ///
  /// In en, this message translates to:
  /// **'vs last {period}'**
  String vsLastPeriod(String period);

  /// No description provided for @weeklyProduction.
  ///
  /// In en, this message translates to:
  /// **'Weekly Production'**
  String get weeklyProduction;

  /// No description provided for @monToSunAverage.
  ///
  /// In en, this message translates to:
  /// **'Mon - Sun Average'**
  String get monToSunAverage;

  /// No description provided for @lPerDay.
  ///
  /// In en, this message translates to:
  /// **'L/day'**
  String get lPerDay;

  /// No description provided for @dayMon.
  ///
  /// In en, this message translates to:
  /// **'MON'**
  String get dayMon;

  /// No description provided for @dayTue.
  ///
  /// In en, this message translates to:
  /// **'TUE'**
  String get dayTue;

  /// No description provided for @dayWed.
  ///
  /// In en, this message translates to:
  /// **'WED'**
  String get dayWed;

  /// No description provided for @dayThu.
  ///
  /// In en, this message translates to:
  /// **'THU'**
  String get dayThu;

  /// No description provided for @dayFri.
  ///
  /// In en, this message translates to:
  /// **'FRI'**
  String get dayFri;

  /// No description provided for @daySat.
  ///
  /// In en, this message translates to:
  /// **'SAT'**
  String get daySat;

  /// No description provided for @daySun.
  ///
  /// In en, this message translates to:
  /// **'SUN'**
  String get daySun;

  /// No description provided for @productionTrendYearly.
  ///
  /// In en, this message translates to:
  /// **'Production Trend (Yearly)'**
  String get productionTrendYearly;

  /// No description provided for @productionTrendMonthly.
  ///
  /// In en, this message translates to:
  /// **'Production Trend (Monthly)'**
  String get productionTrendMonthly;

  /// No description provided for @yearlyPerformance.
  ///
  /// In en, this message translates to:
  /// **'Yearly Performance'**
  String get yearlyPerformance;

  /// No description provided for @avgDailyYield.
  ///
  /// In en, this message translates to:
  /// **'Avg Daily Yield'**
  String get avgDailyYield;

  /// No description provided for @activeCattle.
  ///
  /// In en, this message translates to:
  /// **'Active Cattle'**
  String get activeCattle;

  /// No description provided for @head.
  ///
  /// In en, this message translates to:
  /// **'Head'**
  String get head;

  /// No description provided for @weeklyHerdBreakdown.
  ///
  /// In en, this message translates to:
  /// **'Weekly Herd Breakdown'**
  String get weeklyHerdBreakdown;

  /// No description provided for @topProducingCows.
  ///
  /// In en, this message translates to:
  /// **'Top Producing Cows'**
  String get topProducingCows;

  /// No description provided for @tagIdPrefix.
  ///
  /// In en, this message translates to:
  /// **'Tag ID: #'**
  String get tagIdPrefix;

  /// No description provided for @totalPerWeek.
  ///
  /// In en, this message translates to:
  /// **'TOTAL / WK'**
  String get totalPerWeek;

  /// No description provided for @totalPerYear.
  ///
  /// In en, this message translates to:
  /// **'TOTAL / YR'**
  String get totalPerYear;

  /// No description provided for @addRevenue.
  ///
  /// In en, this message translates to:
  /// **'Add Revenue'**
  String get addRevenue;

  /// No description provided for @revenueAddedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Revenue added successfully'**
  String get revenueAddedSuccess;

  /// No description provided for @noRevenuesFound.
  ///
  /// In en, this message translates to:
  /// **'No revenues found'**
  String get noRevenuesFound;

  /// No description provided for @revenueSourceManual.
  ///
  /// In en, this message translates to:
  /// **'Manual Revenue'**
  String get revenueSourceManual;

  /// No description provided for @revenueSourceAnimalSale.
  ///
  /// In en, this message translates to:
  /// **'Animal Sale'**
  String get revenueSourceAnimalSale;

  /// No description provided for @revenueCategoryMilk.
  ///
  /// In en, this message translates to:
  /// **'Milk'**
  String get revenueCategoryMilk;

  /// No description provided for @revenueCategoryCrops.
  ///
  /// In en, this message translates to:
  /// **'Crops'**
  String get revenueCategoryCrops;

  /// No description provided for @revenueCategoryServices.
  ///
  /// In en, this message translates to:
  /// **'Services'**
  String get revenueCategoryServices;

  /// No description provided for @revenueCategorySubsidies.
  ///
  /// In en, this message translates to:
  /// **'Subsidies'**
  String get revenueCategorySubsidies;

  /// No description provided for @revenueDescription.
  ///
  /// In en, this message translates to:
  /// **'Description (optional)'**
  String get revenueDescription;

  /// No description provided for @revenueDescriptionHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Milk sale to cooperative, wheat harvest...'**
  String get revenueDescriptionHint;

  /// No description provided for @revenueSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search by type, description...'**
  String get revenueSearchHint;

  /// No description provided for @amount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amount;

  /// No description provided for @amountRequired.
  ///
  /// In en, this message translates to:
  /// **'Amount is required'**
  String get amountRequired;

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// No description provided for @period.
  ///
  /// In en, this message translates to:
  /// **'Period'**
  String get period;

  /// No description provided for @periodMonth.
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get periodMonth;

  /// No description provided for @periodQuarter.
  ///
  /// In en, this message translates to:
  /// **'Quarter'**
  String get periodQuarter;

  /// No description provided for @periodYear.
  ///
  /// In en, this message translates to:
  /// **'Year'**
  String get periodYear;

  /// No description provided for @newConversation.
  ///
  /// In en, this message translates to:
  /// **'New Conversation'**
  String get newConversation;

  /// No description provided for @deleteConversation.
  ///
  /// In en, this message translates to:
  /// **'Delete Conversation'**
  String get deleteConversation;

  /// No description provided for @deleteConversationConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this conversation?'**
  String get deleteConversationConfirm;

  /// No description provided for @newChat.
  ///
  /// In en, this message translates to:
  /// **'New Chat'**
  String get newChat;

  /// No description provided for @create.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// No description provided for @generatingPlan.
  ///
  /// In en, this message translates to:
  /// **'Generating your plan…'**
  String get generatingPlan;

  /// No description provided for @weeklyOverview.
  ///
  /// In en, this message translates to:
  /// **'Weekly Overview'**
  String get weeklyOverview;

  /// No description provided for @noFieldsFound.
  ///
  /// In en, this message translates to:
  /// **'No fields found'**
  String get noFieldsFound;

  /// No description provided for @addFieldFirstIrrigation.
  ///
  /// In en, this message translates to:
  /// **'Add a field first to generate an irrigation schedule.'**
  String get addFieldFirstIrrigation;

  /// No description provided for @readyToPlan.
  ///
  /// In en, this message translates to:
  /// **'Ready to plan'**
  String get readyToPlan;

  /// No description provided for @fetchingWeather.
  ///
  /// In en, this message translates to:
  /// **'Fetching weather...'**
  String get fetchingWeather;

  /// No description provided for @agriNews.
  ///
  /// In en, this message translates to:
  /// **'Agri News'**
  String get agriNews;

  /// No description provided for @offlineCachedNews.
  ///
  /// In en, this message translates to:
  /// **'Offline Mode - Showing Cached News'**
  String get offlineCachedNews;

  /// No description provided for @noArticlesAvailable.
  ///
  /// In en, this message translates to:
  /// **'No articles available.'**
  String get noArticlesAvailable;

  /// No description provided for @savedArticles.
  ///
  /// In en, this message translates to:
  /// **'Saved Articles'**
  String get savedArticles;

  /// No description provided for @loginToViewSaved.
  ///
  /// In en, this message translates to:
  /// **'Please log in to view saved articles.'**
  String get loginToViewSaved;

  /// No description provided for @catalogueSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Catalogue Settings'**
  String get catalogueSettingsTitle;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['ar', 'en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar': return AppLocalizationsAr();
    case 'en': return AppLocalizationsEn();
    case 'fr': return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';

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
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

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
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('en')];

  /// Application name
  ///
  /// In en, this message translates to:
  /// **'PeakLog'**
  String get appName;

  /// Back navigation label
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// Back label that points to home screen
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get homeLabel;

  /// Back label that points to settings screen
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsLabel;

  /// Screen title for adding a new exercise
  ///
  /// In en, this message translates to:
  /// **'Add Exercise'**
  String get addExerciseTitle;

  /// Screen title for editing an exercise
  ///
  /// In en, this message translates to:
  /// **'Edit Exercise'**
  String get editExerciseTitle;

  /// Screen title for adding a new record
  ///
  /// In en, this message translates to:
  /// **'Add Record'**
  String get addRecordTitle;

  /// Screen title for editing a record
  ///
  /// In en, this message translates to:
  /// **'Edit Record'**
  String get editRecordTitle;

  /// Screen title for record detail view
  ///
  /// In en, this message translates to:
  /// **'Record Detail'**
  String get recordDetailTitle;

  /// Screen title for categories management
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get categoriesTitle;

  /// Screen title for profile screen
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileTitle;

  /// Screen title for quick share screen
  ///
  /// In en, this message translates to:
  /// **'Quick Share'**
  String get quickShareTitle;

  /// Button label to save changes when editing
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get saveChanges;

  /// Button label to add a new exercise
  ///
  /// In en, this message translates to:
  /// **'Add Exercise'**
  String get addExerciseButton;

  /// Button label to save a record
  ///
  /// In en, this message translates to:
  /// **'Save Record'**
  String get saveRecord;

  /// Cancel button label
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Delete button label
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// Save button label
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// Done button label (e.g. date picker)
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// Button label to add a new category
  ///
  /// In en, this message translates to:
  /// **'Add Category'**
  String get addCategoryButton;

  /// Manage link label (e.g. public records)
  ///
  /// In en, this message translates to:
  /// **'Manage'**
  String get manage;

  /// Share action label
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// Button to add a new record on exercise detail
  ///
  /// In en, this message translates to:
  /// **'Add Record'**
  String get addRecordButton;

  /// Link to view 1RM percentage table
  ///
  /// In en, this message translates to:
  /// **'View Table'**
  String get viewTable;

  /// Button on 404 error page
  ///
  /// In en, this message translates to:
  /// **'Go Home'**
  String get goHome;

  /// Label above exercise name input
  ///
  /// In en, this message translates to:
  /// **'EXERCISE NAME'**
  String get exerciseNameLabel;

  /// Placeholder text for exercise name field
  ///
  /// In en, this message translates to:
  /// **'e.g. Back Squat'**
  String get exerciseNameHint;

  /// Category selector label
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get categoryLabel;

  /// Descriptive text below PB/PR segmented control
  ///
  /// In en, this message translates to:
  /// **'Personal Best (PB)  ·  Personal Record (PR)'**
  String get pbPrDescription;

  /// Descriptive text below weight unit segmented control
  ///
  /// In en, this message translates to:
  /// **'Default weight unit for this exercise'**
  String get defaultWeightUnit;

  /// Weight input field label
  ///
  /// In en, this message translates to:
  /// **'WEIGHT'**
  String get weightLabel;

  /// Reps input field label
  ///
  /// In en, this message translates to:
  /// **'REPS'**
  String get repsLabel;

  /// Value input field label (ETC record type)
  ///
  /// In en, this message translates to:
  /// **'VALUE'**
  String get valueLabel;

  /// Unit input field label for ETC records
  ///
  /// In en, this message translates to:
  /// **'UNIT (optional)'**
  String get unitOptionalLabel;

  /// Placeholder text for ETC unit field
  ///
  /// In en, this message translates to:
  /// **'e.g. reps, kg, km'**
  String get unitHint;

  /// Time input field label (For Time record type)
  ///
  /// In en, this message translates to:
  /// **'TIME'**
  String get timeLabel;

  /// Time cap input field label for AMRAP records
  ///
  /// In en, this message translates to:
  /// **'TIME CAP (min)'**
  String get timeCapLabel;

  /// Rounds input field label for AMRAP records
  ///
  /// In en, this message translates to:
  /// **'ROUNDS'**
  String get roundsLabel;

  /// Date selector label on record form
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get dateLabel;

  /// Prompt for record type picker on first record
  ///
  /// In en, this message translates to:
  /// **'How do you track this exercise?'**
  String get howToTrackQuestion;

  /// Record type chip: weight lifting
  ///
  /// In en, this message translates to:
  /// **'Weight'**
  String get recordTypeWeight;

  /// Record type chip: As Many Rounds As Possible
  ///
  /// In en, this message translates to:
  /// **'AMRAP'**
  String get recordTypeAmrap;

  /// Record type chip: timed workout
  ///
  /// In en, this message translates to:
  /// **'For Time'**
  String get recordTypeForTime;

  /// Record type chip: custom / other metric
  ///
  /// In en, this message translates to:
  /// **'ETC'**
  String get recordTypeEtc;

  /// Section label for personal best card
  ///
  /// In en, this message translates to:
  /// **'PERSONAL BEST'**
  String get sectionPersonalBest;

  /// Section label for record action rows
  ///
  /// In en, this message translates to:
  /// **'ACTIONS'**
  String get sectionActions;

  /// Section label for exercise history list
  ///
  /// In en, this message translates to:
  /// **'HISTORY'**
  String get sectionHistory;

  /// Card label for AMRAP time cap on exercise detail
  ///
  /// In en, this message translates to:
  /// **'TIME CAP'**
  String get sectionTimeCap;

  /// Section label for 1RM calculator card
  ///
  /// In en, this message translates to:
  /// **'1RM CALCULATOR'**
  String get section1rmCalculator;

  /// Settings section: general
  ///
  /// In en, this message translates to:
  /// **'GENERAL'**
  String get sectionGeneral;

  /// Settings section: about
  ///
  /// In en, this message translates to:
  /// **'ABOUT'**
  String get sectionAbout;

  /// Profile section: public records
  ///
  /// In en, this message translates to:
  /// **'PUBLIC RECORDS'**
  String get sectionPublicRecords;

  /// Empty state message for exercise list
  ///
  /// In en, this message translates to:
  /// **'No exercises'**
  String get noExercises;

  /// Empty state message for categories list
  ///
  /// In en, this message translates to:
  /// **'No categories'**
  String get noCategories;

  /// Error message when a record cannot be loaded
  ///
  /// In en, this message translates to:
  /// **'Record not found'**
  String get recordNotFound;

  /// 404 error page message
  ///
  /// In en, this message translates to:
  /// **'Page not found'**
  String get pageNotFound;

  /// Label for app version in about section
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// Default username placeholder
  ///
  /// In en, this message translates to:
  /// **'PeakLog User'**
  String get peaklogUser;

  /// Action row label to edit a record
  ///
  /// In en, this message translates to:
  /// **'Edit Record'**
  String get editRecord;

  /// Action row label / dialog title to delete a record
  ///
  /// In en, this message translates to:
  /// **'Delete Record'**
  String get deleteRecord;

  /// Confirmation dialog body for record deletion
  ///
  /// In en, this message translates to:
  /// **'This record will be permanently deleted.'**
  String get deleteRecordContent;

  /// Confirmation dialog title for exercise deletion
  ///
  /// In en, this message translates to:
  /// **'Delete Exercise'**
  String get deleteExerciseTitle;

  /// Confirmation dialog body for exercise deletion
  ///
  /// In en, this message translates to:
  /// **'\"{name}\" and all its records will be deleted.'**
  String deleteExerciseContent(String name);

  /// Confirmation dialog title for category deletion
  ///
  /// In en, this message translates to:
  /// **'Delete Category?'**
  String get deleteCategoryTitle;

  /// Confirmation dialog body for category deletion
  ///
  /// In en, this message translates to:
  /// **'Exercises in this category will be moved to Uncategorized.'**
  String get deleteCategoryContent;

  /// Validation snackbar: no weight unit selected
  ///
  /// In en, this message translates to:
  /// **'Please select a unit (kg or lb).'**
  String get validationSelectUnit;

  /// Validation snackbar: missing weight value
  ///
  /// In en, this message translates to:
  /// **'Enter a weight to save.'**
  String get validationEnterWeight;

  /// Validation snackbar: missing ETC value
  ///
  /// In en, this message translates to:
  /// **'Enter a value to save.'**
  String get validationEnterValue;

  /// Validation snackbar: missing time value
  ///
  /// In en, this message translates to:
  /// **'Enter a time to save.'**
  String get validationEnterTime;

  /// Validation snackbar: missing AMRAP rounds
  ///
  /// In en, this message translates to:
  /// **'Enter rounds completed.'**
  String get validationEnterRounds;

  /// Snackbar when a save operation throws an exception
  ///
  /// In en, this message translates to:
  /// **'Save failed: {error}'**
  String saveFailed(Object error);

  /// Checkbox label on first PR record
  ///
  /// In en, this message translates to:
  /// **'This is my {label}!'**
  String thisIsMyLabel(String label);

  /// One-time hint text for swipeable rows
  ///
  /// In en, this message translates to:
  /// **'Swipe left on records for Share and Delete actions.'**
  String get swipeHint;

  /// Snackbar after user copies profile URL
  ///
  /// In en, this message translates to:
  /// **'Profile URL copied'**
  String get profileUrlCopied;

  /// Empty state for public records grid on profile screen
  ///
  /// In en, this message translates to:
  /// **'No public exercises selected.'**
  String get noPublicExercises;

  /// Quick share placeholder main text
  ///
  /// In en, this message translates to:
  /// **'Create beautiful workout cards.'**
  String get quickShareTagline;

  /// Quick share placeholder beta notice
  ///
  /// In en, this message translates to:
  /// **'Available after the beta.'**
  String get quickShareBeta;

  /// Placeholder text for category name field
  ///
  /// In en, this message translates to:
  /// **'Category name'**
  String get categoryNameHint;

  /// Color picker label in category edit bottom sheet
  ///
  /// In en, this message translates to:
  /// **'Color'**
  String get colorLabel;

  /// Placeholder text for exercise search bar
  ///
  /// In en, this message translates to:
  /// **'Search exercises...'**
  String get searchExercises;

  /// Category filter chip: show all categories
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filterAll;

  /// Time cap line on record detail (e.g. 'Time Cap 15:00')
  ///
  /// In en, this message translates to:
  /// **'Time Cap {time}'**
  String timeCap(String time);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}

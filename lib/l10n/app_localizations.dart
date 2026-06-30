import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ko.dart';

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
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ko'),
  ];

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
  /// **'Enter exercise name'**
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
  /// **'Custom'**
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

  /// Default profile name when no nickname is set
  ///
  /// In en, this message translates to:
  /// **'Your Profile'**
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
  /// **'Share your workout beautifully.'**
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
  /// **'Search'**
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

  /// Empty state on 1RM table screen when no PB exists
  ///
  /// In en, this message translates to:
  /// **'No 1RM record'**
  String get no1RmRecord;

  /// Hint text below the title in public-records management sheet
  ///
  /// In en, this message translates to:
  /// **'Select up to 8 exercises to show on your profile.'**
  String get publicExercisesHint;

  /// Selection counter in public-records management sheet (e.g. '3 / 8 selected')
  ///
  /// In en, this message translates to:
  /// **'{count} / 8 selected'**
  String publicExercisesSelected(int count);

  /// Empty state inside public-records management sheet when no exercises exist
  ///
  /// In en, this message translates to:
  /// **'No exercises yet.'**
  String get noExercisesYet;

  /// Warning shown at the bottom of public-records sheet when limit of 8 is reached
  ///
  /// In en, this message translates to:
  /// **'You can select up to 8 public exercises.'**
  String get publicExercisesMaxHint;

  /// Badge label on export share frames (clean_frame, frame_painter). Mixed-case; sectionPersonalBest is the all-caps section heading.
  ///
  /// In en, this message translates to:
  /// **'Personal Best'**
  String get personalBestLabel;

  /// Days-since-last-PR label on export share card (Korean: '+N일 만에')
  ///
  /// In en, this message translates to:
  /// **'+{days} days'**
  String daysSince(int days);

  /// AlertDialog title when Health permission is denied in quick_share_screen
  ///
  /// In en, this message translates to:
  /// **'Apple Health Permission Required'**
  String get healthPermissionTitle;

  /// AlertDialog body when Health permission is denied in quick_share_screen
  ///
  /// In en, this message translates to:
  /// **'Please allow Health access in Settings.'**
  String get healthPermissionContent;

  /// Button to open system Settings when Health permission is denied
  ///
  /// In en, this message translates to:
  /// **'Allow in Settings'**
  String get healthPermissionOpenSettings;

  /// Empty state for the record picker sheet in quick_share_screen
  ///
  /// In en, this message translates to:
  /// **'No records'**
  String get noRecords;

  /// Label for the built-in uncategorized category
  ///
  /// In en, this message translates to:
  /// **'Uncategorized'**
  String get categoryUncategorized;

  /// Section label above the kg/lb unit picker when selecting Weight record type for the first time
  ///
  /// In en, this message translates to:
  /// **'UNIT'**
  String get unitSelectorLabel;

  /// Input card label for weight field in Edit Record, with the current unit in parentheses
  ///
  /// In en, this message translates to:
  /// **'WEIGHT ({unit})'**
  String weightWithUnit(String unit);

  /// Error state on the Edit Record screen when the exercise has no record type set
  ///
  /// In en, this message translates to:
  /// **'No record type is configured for this exercise.'**
  String get noRecordTypeConfigured;

  /// Title of the Apple Health activity picker bottom sheet
  ///
  /// In en, this message translates to:
  /// **'Import Activity'**
  String get importActivityTitle;

  /// Subtitle below the title in the activity picker sheet
  ///
  /// In en, this message translates to:
  /// **'Recent activities from Apple Health'**
  String get importActivitySubtitle;

  /// Error state in the activity picker sheet when the Health fetch fails
  ///
  /// In en, this message translates to:
  /// **'Could not load activities.'**
  String get importActivityError;

  /// Empty state in the activity picker sheet when no workouts exist
  ///
  /// In en, this message translates to:
  /// **'No activities found in the last 90 days.'**
  String get importActivityEmpty;

  /// Date label for a workout that happened today
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// Date label for a workout that happened yesterday
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get yesterday;

  /// Activity type label: running
  ///
  /// In en, this message translates to:
  /// **'Running'**
  String get activityRunning;

  /// Activity type label: cycling
  ///
  /// In en, this message translates to:
  /// **'Cycling'**
  String get activityCycling;

  /// Activity type label: swimming
  ///
  /// In en, this message translates to:
  /// **'Swimming'**
  String get activitySwimming;

  /// Activity type label: generic workout
  ///
  /// In en, this message translates to:
  /// **'Workout'**
  String get activityOther;

  /// Hour unit label in the time input field
  ///
  /// In en, this message translates to:
  /// **'h'**
  String get timeHourLabel;

  /// Minute unit label in the time input field
  ///
  /// In en, this message translates to:
  /// **'min'**
  String get timeMinuteLabel;

  /// Second unit label in the time input field
  ///
  /// In en, this message translates to:
  /// **'sec'**
  String get timeSecondLabel;

  /// Section header label for the public exercises grid on the profile screen
  ///
  /// In en, this message translates to:
  /// **'PUBLIC EXERCISES'**
  String get sectionPublicExercises;

  /// Pill button on profile hero to open the nickname editor sheet
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfile;

  /// Sheet title for the nickname editor bottom sheet
  ///
  /// In en, this message translates to:
  /// **'Set Nickname'**
  String get setNickname;

  /// Placeholder text for the nickname input field
  ///
  /// In en, this message translates to:
  /// **'Enter your nickname'**
  String get nicknameHint;

  /// Title of the public exercises management bottom sheet
  ///
  /// In en, this message translates to:
  /// **'Public Exercises'**
  String get publicExercisesTitle;

  /// Suffix after the count fraction in the manage sheet — EN: '3 / 8 selected', KO: '3 / 8 선택'
  ///
  /// In en, this message translates to:
  /// **'selected'**
  String get selectedLabel;

  /// Settings section header for feedback row
  ///
  /// In en, this message translates to:
  /// **'FEEDBACK'**
  String get sectionFeedback;

  /// Settings menu row label to open the feedback form
  ///
  /// In en, this message translates to:
  /// **'Send Feedback'**
  String get sendFeedback;

  /// Snackbar shown when the feedback URL placeholder has not been replaced
  ///
  /// In en, this message translates to:
  /// **'Feedback form is not available yet.'**
  String get feedbackNotAvailable;

  /// Share option card title for PeakLog records
  ///
  /// In en, this message translates to:
  /// **'PeakLog Record'**
  String get shareOptionRecordTitle;

  /// Share option card subtitle for PeakLog records
  ///
  /// In en, this message translates to:
  /// **'Share your tracked records'**
  String get shareOptionRecordSubtitle;

  /// Share option card title for Apple Health activities
  ///
  /// In en, this message translates to:
  /// **'Health Activity'**
  String get shareOptionActivityTitle;

  /// Share option card subtitle for Apple Health activities
  ///
  /// In en, this message translates to:
  /// **'Share a workout from Apple Health'**
  String get shareOptionActivitySubtitle;

  /// Control label for aspect ratio selector on export screen
  ///
  /// In en, this message translates to:
  /// **'Ratio'**
  String get exportLabelRatio;

  /// Control label for frame style selector on export screen
  ///
  /// In en, this message translates to:
  /// **'Frame'**
  String get exportLabelFrame;

  /// Control label for background media picker on export screen
  ///
  /// In en, this message translates to:
  /// **'Background'**
  String get exportLabelBackground;

  /// Control label for overlay sticker toggles on export screen
  ///
  /// In en, this message translates to:
  /// **'Sticker'**
  String get exportLabelSticker;

  /// Frame style option: clean minimal design
  ///
  /// In en, this message translates to:
  /// **'Clean'**
  String get frameStyleClean;

  /// Frame style option: rough bold design
  ///
  /// In en, this message translates to:
  /// **'Rough'**
  String get frameStyleRough;

  /// Sticker toggle label: show exercise name overlay
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get stickerName;

  /// Sticker toggle label: show record value overlay
  ///
  /// In en, this message translates to:
  /// **'Value'**
  String get stickerValue;

  /// Sticker toggle label: show days-since-PR overlay
  ///
  /// In en, this message translates to:
  /// **'Days'**
  String get stickerDays;

  /// Media picker chip label for photo
  ///
  /// In en, this message translates to:
  /// **'Photo'**
  String get exportPhoto;

  /// Media picker chip label for video
  ///
  /// In en, this message translates to:
  /// **'Video'**
  String get exportVideo;

  /// Button to save export card as image to Photos
  ///
  /// In en, this message translates to:
  /// **'Save Image'**
  String get saveImage;

  /// Button to save export card composited over video to Photos
  ///
  /// In en, this message translates to:
  /// **'Save Video'**
  String get saveVideo;

  /// Progress label while saving an image to Photos
  ///
  /// In en, this message translates to:
  /// **'Saving image…'**
  String get exportSavingImage;

  /// Progress label while saving a video to Photos
  ///
  /// In en, this message translates to:
  /// **'Saving video…'**
  String get exportSavingVideo;

  /// Progress label while preparing a share export
  ///
  /// In en, this message translates to:
  /// **'Preparing…'**
  String get exportPreparing;

  /// Snackbar after successfully saving image or video to Photos
  ///
  /// In en, this message translates to:
  /// **'Saved to Photos'**
  String get savedToPhotos;

  /// Snackbar when video compositing or save fails
  ///
  /// In en, this message translates to:
  /// **'Video save failed'**
  String get videoSaveFailed;

  /// Share sheet subject line when sharing a record PR/PB
  ///
  /// In en, this message translates to:
  /// **'PeakLog — {name} New {badge}!'**
  String shareSubjectRecord(String name, String badge);

  /// Share sheet subject line when sharing an Apple Health activity
  ///
  /// In en, this message translates to:
  /// **'PeakLog — {name}'**
  String shareSubjectActivity(String name);

  /// Screen title for 1RM percentage table when no exercise context
  ///
  /// In en, this message translates to:
  /// **'1RM Table'**
  String get oneRmTableTitle;

  /// Screen title for 1RM percentage table when an exercise is provided
  ///
  /// In en, this message translates to:
  /// **'{name} — 1RM Table'**
  String exerciseOneRmTableTitle(String name);

  /// Label in the 100% row of the 1RM table
  ///
  /// In en, this message translates to:
  /// **'Current 1RM'**
  String get current1rm;

  /// Bottom sheet title when editing an existing category
  ///
  /// In en, this message translates to:
  /// **'Edit Category'**
  String get editCategoryTitle;

  /// Calculator hub screen title and back label from child calculator screens
  ///
  /// In en, this message translates to:
  /// **'Calculators'**
  String get calculatorsTitle;

  /// Screen title for the pace calculator
  ///
  /// In en, this message translates to:
  /// **'Pace Calculator'**
  String get paceCalculatorTitle;

  /// Screen title for the plate calculator
  ///
  /// In en, this message translates to:
  /// **'Plate Calculator'**
  String get plateCalculatorTitle;

  /// Hub card description for the 1RM calculator
  ///
  /// In en, this message translates to:
  /// **'Estimate your one-rep max and training percentages.'**
  String get oneRmCalculatorDescription;

  /// Hub card description for the pace calculator
  ///
  /// In en, this message translates to:
  /// **'Calculate pace, finish time, and race splits.'**
  String get paceCalculatorDescription;

  /// Hub card description for the plate calculator
  ///
  /// In en, this message translates to:
  /// **'Calculate barbell loading and total weight.'**
  String get plateCalculatorDescription;

  /// Section label for the weight input card on the 1RM calculator screen
  ///
  /// In en, this message translates to:
  /// **'1RM WEIGHT'**
  String get oneRmWeightLabel;

  /// Input card label for the pace field on the pace calculator screen
  ///
  /// In en, this message translates to:
  /// **'PACE'**
  String get paceLabel;

  /// Section label for the total weight input on the plate calculator screen
  ///
  /// In en, this message translates to:
  /// **'TOTAL WEIGHT'**
  String get totalWeightLabel;

  /// Section label for the bar weight selector on the plate calculator screen
  ///
  /// In en, this message translates to:
  /// **'BAR'**
  String get barLabel;

  /// Button to reset plate counts on the plate calculator screen
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get resetLabel;

  /// Section label for the plate rows on the plate calculator screen
  ///
  /// In en, this message translates to:
  /// **'PLATES'**
  String get platesLabel;

  /// Button to expand the split table on the pace calculator screen
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get moreLabel;

  /// Button to collapse the split table on the pace calculator screen
  ///
  /// In en, this message translates to:
  /// **'Hide'**
  String get hideLabel;

  /// Aspect ratio chip label for 'Original' ratio on export screen
  ///
  /// In en, this message translates to:
  /// **'Original'**
  String get aspectRatioOriginal;

  /// Hub card title and screen header title for the 1RM calculator
  ///
  /// In en, this message translates to:
  /// **'1RM Calculator'**
  String get oneRmCalculatorTitle;
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
      <String>['en', 'ko'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ko':
      return AppLocalizationsKo();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}

// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'PeakLog';

  @override
  String get back => 'Back';

  @override
  String get homeLabel => 'Home';

  @override
  String get settingsLabel => 'Settings';

  @override
  String get addExerciseTitle => 'Add Exercise';

  @override
  String get editExerciseTitle => 'Edit Exercise';

  @override
  String get addRecordTitle => 'Add Record';

  @override
  String get editRecordTitle => 'Edit Record';

  @override
  String get recordDetailTitle => 'Record Detail';

  @override
  String get completionDetailTitle => 'Completion Detail';

  @override
  String get completeExerciseButton => 'Complete Exercise';

  @override
  String get completedTodayButton => 'Completed Today ✓';

  @override
  String get completionSheetSubtitle =>
      'Choose when you completed this exercise.';

  @override
  String get completionActionToday => 'Today';

  @override
  String get completionActionAnotherDate => 'Another Date...';

  @override
  String get categoriesTitle => 'Categories';

  @override
  String get profileTitle => 'Profile';

  @override
  String get shareTitle => 'Share';

  @override
  String get saveChanges => 'Save Changes';

  @override
  String get addExerciseButton => 'Add Exercise';

  @override
  String get saveRecord => 'Save Record';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get save => 'Save';

  @override
  String get done => 'Done';

  @override
  String get addCategoryButton => 'Add Category';

  @override
  String get manage => 'Manage';

  @override
  String get share => 'Share';

  @override
  String get addRecordButton => 'Add Record';

  @override
  String get viewTable => 'View Table';

  @override
  String get goHome => 'Go Home';

  @override
  String get exerciseNameLabel => 'EXERCISE NAME';

  @override
  String get exerciseNameHint => 'Enter exercise name';

  @override
  String get categoryLabel => 'Category';

  @override
  String get pbPrDescription => 'Personal Best (PB)  ·  Personal Record (PR)';

  @override
  String get defaultWeightUnit => 'Default weight unit for this exercise';

  @override
  String get weightLabel => 'WEIGHT';

  @override
  String get repsLabel => 'REPS';

  @override
  String get valueLabel => 'VALUE';

  @override
  String get unitOptionalLabel => 'UNIT (optional)';

  @override
  String get unitHint => 'Unit name';

  @override
  String get timeLabel => 'TIME';

  @override
  String get timeCapLabel => 'TIME CAP (min)';

  @override
  String get roundsLabel => 'ROUNDS';

  @override
  String get dateLabel => 'Date';

  @override
  String get howToTrackQuestion => 'Choose a tracking format';

  @override
  String get exerciseTypeHint => 'Tracking Type';

  @override
  String get exerciseTypePerformance => 'Performance';

  @override
  String get exerciseTypeChecklist => 'Checklist';

  @override
  String get exerciseTypePerformanceDesc =>
      'Track weight, reps, time, distance, and other measurable results.';

  @override
  String get exerciseTypeChecklistDesc =>
      'Simply mark the exercise as completed.';

  @override
  String get recordTypeWeight => 'Weight';

  @override
  String get recordTypeAmrap => 'AMRAP';

  @override
  String get recordTypeForTime => 'For Time';

  @override
  String get recordTypeEtc => 'Custom';

  @override
  String get sectionPersonalBest => 'PERSONAL BEST';

  @override
  String get sectionActions => 'ACTIONS';

  @override
  String get sectionHistory => 'HISTORY';

  @override
  String get sectionTimeCap => 'TIME CAP';

  @override
  String get section1rmCalculator => '1RM CALCULATOR';

  @override
  String get sectionGeneral => 'GENERAL';

  @override
  String get sectionAbout => 'ABOUT';

  @override
  String get noExercises => 'No exercises';

  @override
  String get noCategories => 'No categories';

  @override
  String get recordNotFound => 'Record not found';

  @override
  String get pageNotFound => 'Page not found';

  @override
  String get version => 'Version';

  @override
  String get versionCopied => 'Version copied.';

  @override
  String get peaklogUser => 'Your Profile';

  @override
  String get editRecord => 'Edit Record';

  @override
  String get deleteRecord => 'Delete Record';

  @override
  String get deleteRecordContent => 'This record will be permanently deleted.';

  @override
  String get deleteExerciseTitle => 'Delete Exercise';

  @override
  String get deleteExerciseDialogTitle => 'Delete Exercise?';

  @override
  String get deleteExerciseContent =>
      'This will permanently delete this exercise and all associated records.\nThis action cannot be undone.';

  @override
  String get deleteCategoryTitle => 'Delete Category?';

  @override
  String get deleteCategoryContent =>
      'Exercises in this category will be moved to Uncategorized.';

  @override
  String get validationSelectUnit => 'Please select a unit (kg or lb).';

  @override
  String get validationEnterWeight => 'Please enter a weight.';

  @override
  String get validationEnterValue => 'Enter a value to save.';

  @override
  String get validationEnterTime => 'Enter a time to save.';

  @override
  String get validationEnterRounds => 'Enter rounds completed.';

  @override
  String saveFailed(Object error) {
    return 'Save failed: $error';
  }

  @override
  String thisIsMyLabel(String label) {
    return 'This is my $label!';
  }

  @override
  String get swipeHint => 'Swipe left on records for Share and Delete actions.';

  @override
  String get profileUrlCopied => 'Profile URL copied';

  @override
  String get noPublicExercises => 'No public exercises selected.';

  @override
  String get shareTagline => 'Share your workout beautifully.';

  @override
  String get shareBeta => 'Available after the beta.';

  @override
  String get categoryNameHint => 'Category name';

  @override
  String get colorLabel => 'Color';

  @override
  String get searchExercises => 'Search';

  @override
  String get filterAll => 'All';

  @override
  String timeCap(String time) {
    return 'Time Cap $time';
  }

  @override
  String get no1RmRecord => 'No 1RM record';

  @override
  String get publicExercisesHint =>
      'Select up to 8 exercises to show on your profile.';

  @override
  String publicExercisesSelected(int count) {
    return '$count / 8 selected';
  }

  @override
  String get noExercisesYet => 'No exercises yet.';

  @override
  String get publicExercisesMaxHint =>
      'You can select up to 8 public exercises.';

  @override
  String get personalBestLabel => 'Personal Best';

  @override
  String daysSince(int days) {
    return '+$days days';
  }

  @override
  String get healthPermissionTitle => 'Apple Health Permission Required';

  @override
  String get healthPermissionContent =>
      'Please allow Health access in Settings.';

  @override
  String get healthPermissionOpenSettings => 'Allow in Settings';

  @override
  String get noRecords => 'No records';

  @override
  String get categoryUncategorized => 'Uncategorized';

  @override
  String get unitSelectorLabel => 'UNIT';

  @override
  String weightWithUnit(String unit) {
    return 'WEIGHT ($unit)';
  }

  @override
  String get noRecordTypeConfigured =>
      'No record type is configured for this exercise.';

  @override
  String get importActivityTitle => 'Import Activity';

  @override
  String get importActivitySubtitle => 'Recent activities from Apple Health';

  @override
  String get importActivityError => 'Could not load activities.';

  @override
  String get importActivityEmpty => 'No activities found in the last 90 days.';

  @override
  String get today => 'Today';

  @override
  String get yesterday => 'Yesterday';

  @override
  String get activityRunning => 'Running';

  @override
  String get activityCycling => 'Cycling';

  @override
  String get activitySwimming => 'Swimming';

  @override
  String get activityOther => 'Workout';

  @override
  String get timeHourLabel => 'h';

  @override
  String get timeMinuteLabel => 'min';

  @override
  String get timeSecondLabel => 'sec';

  @override
  String get sectionPublicExercises => 'PUBLIC EXERCISES';

  @override
  String get editProfile => 'Edit Profile';

  @override
  String get setNickname => 'Set Nickname';

  @override
  String get nicknameHint => 'Enter your nickname';

  @override
  String get publicExercisesTitle => 'Public Exercises';

  @override
  String get selectedLabel => 'selected';

  @override
  String get sectionFeedback => 'FEEDBACK';

  @override
  String get sendFeedback => 'Send Feedback';

  @override
  String get feedbackNotAvailable => 'Feedback form is not available yet.';

  @override
  String get shareOptionRecordTitle => 'PeakLog Record';

  @override
  String get shareOptionRecordSubtitle => 'Share your tracked records';

  @override
  String get shareOptionActivityTitle => 'Health Activity';

  @override
  String get shareOptionActivitySubtitle => 'Share a workout from Apple Health';

  @override
  String get exportLabelRatio => 'Ratio';

  @override
  String get exportLabelFrame => 'Frame';

  @override
  String get exportLabelBackground => 'Background';

  @override
  String get exportLabelSticker => 'Sticker';

  @override
  String get frameStyleClean => 'Clean';

  @override
  String get frameStyleRough => 'Rough';

  @override
  String get stickerName => 'Name';

  @override
  String get stickerValue => 'Value';

  @override
  String get stickerDays => 'Days';

  @override
  String get exportPhoto => 'Photo';

  @override
  String get exportVideo => 'Video';

  @override
  String get saveImage => 'Save Image';

  @override
  String get saveVideo => 'Save Video';

  @override
  String get exportSavingImage => 'Saving image…';

  @override
  String get exportSavingVideo => 'Saving video…';

  @override
  String get exportPreparing => 'Preparing…';

  @override
  String get savedToPhotos => 'Saved to Photos';

  @override
  String get videoSaveFailed => 'Video save failed';

  @override
  String shareSubjectRecord(String name, String badge) {
    return 'PeakLog — $name New $badge!';
  }

  @override
  String shareSubjectActivity(String name) {
    return 'PeakLog — $name';
  }

  @override
  String get oneRmTableTitle => '1RM Table';

  @override
  String exerciseOneRmTableTitle(String name) {
    return '$name — 1RM Table';
  }

  @override
  String get current1rm => 'Current 1RM';

  @override
  String get editCategoryTitle => 'Edit Category';

  @override
  String get calculatorsTitle => 'Calculators';

  @override
  String get paceCalculatorTitle => 'Pace Calculator';

  @override
  String get plateCalculatorTitle => 'Plate Calculator';

  @override
  String get oneRmCalculatorDescription =>
      'Estimate your one-rep max and training percentages.';

  @override
  String get paceCalculatorDescription =>
      'Calculate pace, finish time, and race splits.';

  @override
  String get plateCalculatorDescription =>
      'Calculate barbell loading and total weight.';

  @override
  String get oneRmWeightLabel => '1RM WEIGHT';

  @override
  String get paceLabel => 'PACE';

  @override
  String get totalWeightLabel => 'TOTAL WEIGHT';

  @override
  String get barLabel => 'BAR';

  @override
  String get resetLabel => 'Reset';

  @override
  String get platesLabel => 'PLATES';

  @override
  String get moreLabel => 'More';

  @override
  String get hideLabel => 'Hide';

  @override
  String get aspectRatioOriginal => 'Original';

  @override
  String get oneRmCalculatorTitle => '1RM Calculator';

  @override
  String get calendarLabel => 'Calendar';

  @override
  String get calendarCardSwipeHint => 'Swipe to Calendar';

  @override
  String calendarSummary(int workoutDays, int prCount) {
    return '$workoutDays workouts · $prCount PR';
  }

  @override
  String get calendarNoRecords => 'No workouts this month';

  @override
  String get calendarRecordsLabel => 'RECORDS';

  @override
  String get calendarNotesLabel => 'NOTES';

  @override
  String get calendarAddNoteAffordance => '+ Add Note';

  @override
  String get calendarAddNoteTitle => 'New Note';

  @override
  String get calendarEditNoteTitle => 'Edit Note';

  @override
  String get calendarNoteHintTitle => 'Title (optional)';

  @override
  String get calendarNoteHintBody => 'Write a note for this day…';

  @override
  String get calendarDeleteNote => 'Delete Note';

  @override
  String get calendarReturnToMonth => 'Month';

  @override
  String get calendarHintText => 'Tap a date to see records and notes.';

  @override
  String get calendarSwipeHint => '← Swipe to Calendar';

  @override
  String get calendarLegendPersonalBest => 'Personal Best';

  @override
  String get weekdaySun => 'S';

  @override
  String get weekdayMon => 'M';

  @override
  String get weekdayTue => 'T';

  @override
  String get weekdayWed => 'W';

  @override
  String get weekdayThu => 'T';

  @override
  String get weekdayFri => 'F';

  @override
  String get weekdaySat => 'S';

  @override
  String get etcDefaultUnitLabel => 'Default Unit';

  @override
  String get etcDefaultUnitHint => 'e.g. km, min/km';

  @override
  String get pbDirectionLabel => 'PB Direction';

  @override
  String get pbDirectionHigher => 'Higher ↑';

  @override
  String get pbDirectionLower => 'Lower ↓';

  @override
  String get betaNote => 'Thank you for helping test PeakLog.\nAs a thank you, we plan to provide a lifetime license when the official version launches.\nYour feedback will help us make PeakLog even better.';
}

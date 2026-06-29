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
  String get categoriesTitle => 'Categories';

  @override
  String get profileTitle => 'Profile';

  @override
  String get quickShareTitle => 'Quick Share';

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
  String get exerciseNameHint => 'e.g. Back Squat';

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
  String get unitHint => 'e.g. reps, kg, km';

  @override
  String get timeLabel => 'TIME';

  @override
  String get timeCapLabel => 'TIME CAP (min)';

  @override
  String get roundsLabel => 'ROUNDS';

  @override
  String get dateLabel => 'Date';

  @override
  String get howToTrackQuestion => 'How do you track this exercise?';

  @override
  String get recordTypeWeight => 'Weight';

  @override
  String get recordTypeAmrap => 'AMRAP';

  @override
  String get recordTypeForTime => 'For Time';

  @override
  String get recordTypeEtc => 'ETC';

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
  String get sectionPublicRecords => 'PUBLIC RECORDS';

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
  String get peaklogUser => 'PeakLog User';

  @override
  String get editRecord => 'Edit Record';

  @override
  String get deleteRecord => 'Delete Record';

  @override
  String get deleteRecordContent => 'This record will be permanently deleted.';

  @override
  String get deleteExerciseTitle => 'Delete Exercise';

  @override
  String deleteExerciseContent(String name) {
    return '\"$name\" and all its records will be deleted.';
  }

  @override
  String get deleteCategoryTitle => 'Delete Category?';

  @override
  String get deleteCategoryContent =>
      'Exercises in this category will be moved to Uncategorized.';

  @override
  String get validationSelectUnit => 'Please select a unit (kg or lb).';

  @override
  String get validationEnterWeight => 'Enter a weight to save.';

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
  String get quickShareTagline => 'Create beautiful workout cards.';

  @override
  String get quickShareBeta => 'Available after the beta.';

  @override
  String get categoryNameHint => 'Category name';

  @override
  String get colorLabel => 'Color';

  @override
  String get searchExercises => 'Search exercises...';

  @override
  String get filterAll => 'All';

  @override
  String timeCap(String time) {
    return 'Time Cap $time';
  }

  @override
  String get no1RmRecord => 'No 1RM record';

  @override
  String get managePublicExercises => 'Manage Public Exercises';

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
}

// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get appName => 'PeakLog';

  @override
  String get back => '뒤로';

  @override
  String get homeLabel => '홈';

  @override
  String get settingsLabel => '설정';

  @override
  String get addExerciseTitle => '운동 추가';

  @override
  String get editExerciseTitle => '운동 편집';

  @override
  String get addRecordTitle => '기록 추가';

  @override
  String get editRecordTitle => '기록 편집';

  @override
  String get recordDetailTitle => '기록 상세';

  @override
  String get completionDetailTitle => '완료 상세';

  @override
  String get completeExerciseButton => '운동 완료';

  @override
  String get completedTodayButton => '오늘 완료 ✓';

  @override
  String get completionSheetSubtitle => '운동 완료 날짜를 선택하세요.';

  @override
  String get completionActionToday => '오늘';

  @override
  String get completionActionAnotherDate => '다른 날짜...';

  @override
  String get categoriesTitle => '카테고리';

  @override
  String get profileTitle => '프로필';

  @override
  String get shareTitle => '공유';

  @override
  String get saveChanges => '변경 저장';

  @override
  String get addExerciseButton => '운동 추가';

  @override
  String get saveRecord => '기록 저장';

  @override
  String get cancel => '취소';

  @override
  String get delete => '삭제';

  @override
  String get save => '저장';

  @override
  String get done => '완료';

  @override
  String get addCategoryButton => '카테고리 추가';

  @override
  String get manage => '관리';

  @override
  String get share => '공유';

  @override
  String get addRecordButton => '기록 추가';

  @override
  String get viewTable => '표 보기';

  @override
  String get goHome => '홈으로';

  @override
  String get exerciseNameLabel => '운동 이름';

  @override
  String get exerciseNameHint => '운동 이름 입력';

  @override
  String get categoryLabel => '카테고리';

  @override
  String get pbPrDescription => '개인 최고 기록 (PB)  ·  개인 기록 (PR)';

  @override
  String get defaultWeightUnit => '이 운동의 기본 무게 단위';

  @override
  String get weightLabel => '무게';

  @override
  String get repsLabel => '횟수';

  @override
  String get setsLabel => '세트';

  @override
  String get setsHint => '선택 사항';

  @override
  String setsDisplay(int count) {
    return '$count세트';
  }

  @override
  String get valueLabel => '값';

  @override
  String get unitOptionalLabel => '단위 (선택)';

  @override
  String get unitHint => '단위 이름';

  @override
  String get timeLabel => '시간';

  @override
  String get timeCapLabel => '타임캡 (분)';

  @override
  String get roundsLabel => '라운드';

  @override
  String get dateLabel => '날짜';

  @override
  String get howToTrackQuestion => '이 운동은 어떤 형식으로 기록할까요?';

  @override
  String get exerciseTypeHint => '입력 유형';

  @override
  String get exerciseTypePerformance => '기록';

  @override
  String get exerciseTypeChecklist => '체크';

  @override
  String get exerciseTypePerformanceDesc => '무게, 횟수, 시간 등을 입력합니다.';

  @override
  String get exerciseTypeChecklistDesc => '운동을 완료했는지만 간단하게 체크합니다.';

  @override
  String get recordTypeWeight => 'Weight';

  @override
  String get recordTypeAmrap => 'AMRAP';

  @override
  String get recordTypeForTime => 'For Time';

  @override
  String get recordTypeEtc => 'Custom';

  @override
  String get sectionPersonalBest => '개인 최고 기록';

  @override
  String get sectionActions => '작업';

  @override
  String get sectionHistory => '기록 내역';

  @override
  String get sectionTimeCap => '타임캡';

  @override
  String get section1rmCalculator => '1RM 계산기';

  @override
  String get sectionGeneral => '일반';

  @override
  String get sectionAbout => '정보';

  @override
  String get noExercises => '운동이 없습니다.';

  @override
  String get noCategories => '카테고리가 없습니다.';

  @override
  String get recordNotFound => '기록을 찾을 수 없습니다.';

  @override
  String get pageNotFound => '페이지를 찾을 수 없습니다.';

  @override
  String get version => '버전';

  @override
  String get versionCopied => '버전이 복사되었습니다.';

  @override
  String get peaklogUser => '내 프로필';

  @override
  String get editRecord => '기록 편집';

  @override
  String get deleteRecord => '기록 삭제';

  @override
  String get deleteRecordContent => '이 기록이 영구 삭제됩니다.';

  @override
  String get deleteExerciseTitle => '운동 삭제';

  @override
  String get deleteExerciseDialogTitle => '운동을 삭제할까요?';

  @override
  String get deleteExerciseContent =>
      '이 운동과 관련된 모든 기록이 함께 삭제됩니다.\n삭제된 데이터는 복구할 수 없습니다.';

  @override
  String get deleteCategoryTitle => '카테고리 삭제';

  @override
  String get deleteCategoryContent => '이 카테고리의 운동들이 미지정으로 이동됩니다.';

  @override
  String get validationSelectUnit => '단위를 선택해 주세요 (kg 또는 lb).';

  @override
  String get validationEnterWeight => '무게를 입력해 주세요.';

  @override
  String get validationEnterValue => '저장할 값을 입력해 주세요.';

  @override
  String get validationEnterTime => '저장할 시간을 입력해 주세요.';

  @override
  String get validationEnterRounds => '완료한 라운드 수를 입력해 주세요.';

  @override
  String get validationEnterSets => '세트 수를 올바르게 입력하거나 비워 두세요.';

  @override
  String saveFailed(Object error) {
    return '저장 실패: $error';
  }

  @override
  String thisIsMyLabel(String label) {
    return '나의 $label입니다!';
  }

  @override
  String get swipeHint => '기록을 왼쪽으로 밀면 공유 및 삭제할 수 있습니다.';

  @override
  String get profileUrlCopied => '프로필 URL이 복사되었습니다';

  @override
  String get noPublicExercises => '공개된 운동이 없습니다.';

  @override
  String get shareTagline => '운동을 멋지게 공유하세요.';

  @override
  String get shareBeta => '베타 이후 사용 가능합니다.';

  @override
  String get categoryNameHint => '카테고리 이름';

  @override
  String get colorLabel => '색상';

  @override
  String get searchExercises => '검색';

  @override
  String get filterAll => '전체';

  @override
  String timeCap(String time) {
    return '타임캡 $time';
  }

  @override
  String get no1RmRecord => '1RM 기록이 없습니다.';

  @override
  String get publicExercisesHint => '프로필에 표시할 운동을 최대 8개까지 선택하세요.';

  @override
  String publicExercisesSelected(int count) {
    return '$count / 8 선택됨';
  }

  @override
  String get noExercisesYet => '아직 운동이 없습니다.';

  @override
  String get publicExercisesMaxHint => '최대 8개의 공개 운동을 선택할 수 있습니다.';

  @override
  String get personalBestLabel => '개인 최고 기록';

  @override
  String daysSince(int days) {
    return '+${days}d';
  }

  @override
  String get categoryUncategorized => '미지정';

  @override
  String get unitSelectorLabel => '단위';

  @override
  String weightWithUnit(String unit) {
    return '중량 ($unit)';
  }

  @override
  String get noRecordTypeConfigured => '이 운동에 기록 방식이 설정되지 않았습니다.';

  @override
  String get importActivityTitle => '활동 가져오기';

  @override
  String get importActivitySubtitle => 'Apple Health의 최근 운동 기록';

  @override
  String get importActivityError => '활동을 불러올 수 없습니다.';

  @override
  String get importActivityEmpty => '최근 90일간의 활동이 없습니다.';

  @override
  String get today => '오늘';

  @override
  String get yesterday => '어제';

  @override
  String get activityRunning => '달리기';

  @override
  String get activityCycling => '사이클링';

  @override
  String get activitySwimming => '수영';

  @override
  String get activityOther => '운동';

  @override
  String get timeHourLabel => '시';

  @override
  String get timeMinuteLabel => '분';

  @override
  String get timeSecondLabel => '초';

  @override
  String get sectionPublicExercises => '공개 운동';

  @override
  String get editProfile => '프로필 수정';

  @override
  String get setNickname => '닉네임 설정';

  @override
  String get nicknameHint => '닉네임을 입력하세요';

  @override
  String get publicExercisesTitle => '공개 운동';

  @override
  String get selectedLabel => '선택';

  @override
  String get sectionFeedback => '피드백';

  @override
  String get sendFeedback => '피드백 보내기';

  @override
  String get feedbackNotAvailable => '피드백 양식을 아직 사용할 수 없습니다.';

  @override
  String get categorySettingsLabel => '카테고리 설정';

  @override
  String get launchScreenSettingsLabel => '시작 화면 설정';

  @override
  String get launchScreenLabel => '시작 화면';

  @override
  String get launchScreenDescription => '앱을 실행할 때 열릴 화면을 선택하세요.';

  @override
  String get preferredWeightUnitLabel => '선호 무게 단위';

  @override
  String get preferredWeightUnitDescription => '새로운 무게 입력과 계산기의 시작 단위로 사용됩니다.';

  @override
  String get defaultBestTypeSettingsLabel => '선호 Best Type';

  @override
  String get defaultBestTypeDescription => '새 운동을 추가할 때 기본으로 선택될 항목을 선택하세요.';

  @override
  String get defaultBestTypePr => 'PR';

  @override
  String get defaultBestTypePb => 'PB';

  @override
  String get exportLabelRatio => '비율';

  @override
  String get exportLabelFrame => '프레임';

  @override
  String get exportLabelBackground => '배경';

  @override
  String get exportLabelSticker => '스티커';

  @override
  String get frameStyleClean => '클린';

  @override
  String get frameStyleRough => '러프';

  @override
  String get stickerName => '이름';

  @override
  String get stickerValue => '값';

  @override
  String get stickerDays => '기간';

  @override
  String get exportPhoto => '사진';

  @override
  String get exportVideo => '동영상';

  @override
  String get saveImage => '이미지 저장';

  @override
  String get saveVideo => '동영상 저장';

  @override
  String get exportSavingImage => '이미지 저장 중…';

  @override
  String get exportSavingVideo => '동영상 저장 중…';

  @override
  String get exportPreparing => '준비 중…';

  @override
  String get savedToPhotos => '사진 앱에 저장됨';

  @override
  String get videoSaveFailed => '동영상 저장에 실패했습니다.';

  @override
  String shareSubjectRecord(String name, String badge) {
    return 'PeakLog — $name 신규 $badge!';
  }

  @override
  String shareSubjectActivity(String name) {
    return 'PeakLog — $name';
  }

  @override
  String get oneRmTableTitle => '1RM 테이블';

  @override
  String exerciseOneRmTableTitle(String name) {
    return '$name 1RM 테이블';
  }

  @override
  String get current1rm => '현재 1RM';

  @override
  String get editCategoryTitle => '카테고리 편집';

  @override
  String get calculatorsTitle => '계산기';

  @override
  String get paceCalculatorTitle => '페이스 계산기';

  @override
  String get plateCalculatorTitle => '플레이트 계산기';

  @override
  String get oneRmCalculatorDescription => '1RM과 훈련 퍼센테이지를 계산하세요.';

  @override
  String get paceCalculatorDescription => '페이스, 완주 시간, 구간 기록을 계산하세요.';

  @override
  String get plateCalculatorDescription => '바벨 구성과 총 중량을 계산하세요.';

  @override
  String get oneRmWeightLabel => '1RM 무게';

  @override
  String get paceLabel => '페이스';

  @override
  String get totalWeightLabel => '총 중량';

  @override
  String get barLabel => '바';

  @override
  String get resetLabel => '초기화';

  @override
  String get platesLabel => '플레이트';

  @override
  String get moreLabel => '더 보기';

  @override
  String get hideLabel => '접기';

  @override
  String get aspectRatioOriginal => '원본';

  @override
  String get oneRmCalculatorTitle => '1RM 계산기';

  @override
  String get calendarLabel => '캘린더';

  @override
  String get calendarCardSwipeHint => '밀어서 캘린더 보기';

  @override
  String calendarSummary(int workoutDays, int prCount) {
    return '$workoutDays일 운동 · $prCount PR';
  }

  @override
  String get calendarNoRecords => '이번 달 운동 기록이 없습니다';

  @override
  String get calendarRecordsLabel => '운동 기록';

  @override
  String get calendarNotesLabel => '메모';

  @override
  String get calendarAddNoteAffordance => '+ 메모 추가';

  @override
  String get calendarAddNoteTitle => '새 메모';

  @override
  String get calendarEditNoteTitle => '메모 편집';

  @override
  String get calendarNoteHintTitle => '제목 (선택)';

  @override
  String get calendarNoteHintBody => '이 날의 메모를 작성하세요…';

  @override
  String get calendarDeleteNote => '메모 삭제';

  @override
  String get calendarReturnToMonth => '월';

  @override
  String get calendarHintText => '날짜를 탭하면 기록과 메모를 확인할 수 있습니다.';

  @override
  String get calendarSwipeHint => '← 밀어서 캘린더 보기';

  @override
  String get calendarLegendPersonalBest => '개인 기록';

  @override
  String get weekdaySun => '일';

  @override
  String get weekdayMon => '월';

  @override
  String get weekdayTue => '화';

  @override
  String get weekdayWed => '수';

  @override
  String get weekdayThu => '목';

  @override
  String get weekdayFri => '금';

  @override
  String get weekdaySat => '토';

  @override
  String get etcDefaultUnitLabel => '기본 단위';

  @override
  String get etcDefaultUnitHint => '예: km, min/km';

  @override
  String get pbDirectionLabel => '최고 기록 방향';

  @override
  String get pbDirectionHigher => '높음 ↑';

  @override
  String get pbDirectionLower => '낮음 ↓';

  @override
  String get betaNote =>
      '베타 테스트에 참여해주셔서 감사합니다.\n감사의 의미로 정식 버전 출시 시\n평생 이용 라이선스를 제공할 예정입니다.\n더 나은 PeakLog를 만들기 위해 많은 피드백 부탁드립니다.';
}

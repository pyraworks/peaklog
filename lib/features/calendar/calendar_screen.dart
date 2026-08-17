import 'dart:async';
import 'dart:ui' show PlatformDispatcher;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' as intl;
import '../../core/design/app_colors.dart';
import '../../core/design/app_icons.dart';
import '../../core/design/app_typography.dart';
import '../../core/models/exercise.dart';
import '../../core/models/note.dart';
import '../../core/models/record.dart';
import '../../core/utils/unit_converter.dart';
import '../../domain/models/category.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/analytics_provider.dart';
import '../../providers/calendar_month_provider.dart';
import '../../providers/categories_provider.dart';
import '../../providers/notes_provider.dart';
import '../../providers/personal_best_provider.dart';
import '../../widgets/destructive_action_button.dart';
import '../../widgets/exercise_record_row.dart';
import 'share/day_capture_sheet.dart';
import 'share/day_share_builder.dart';
import 'share/day_share_models.dart';
import 'share/day_share_painter.dart';
import 'share/month_share_builder.dart';
import 'share/month_share_models.dart';
import 'share/month_share_painter.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  // Static cache: future is resolved once per process; int? lets initState
  // read the settled value synchronously on all subsequent state creations.
  static Future<int?>? _nativeWeekStartFuture;
  static int? _cachedNativeWeekStart;

  static Future<int?> _fetchNativeWeekStart() {
    return _nativeWeekStartFuture ??= () async {
      try {
        final native = await const MethodChannel('peaklog/calendar')
            .invokeMethod<int>('getFirstDayOfWeek');
        if (native == null) return null;
        // Native: 1=Sun, 2=Mon, ..., 7=Sat → Dart: 1=Mon, ..., 7=Sun
        final dartWeekday = native == 1 ? DateTime.sunday : native - 1;
        _cachedNativeWeekStart = dartWeekday;
        return dartWeekday;
      } catch (_) {
        return null;
      }
    }();
  }

  // Locale-based fallback — no context needed (uses PlatformDispatcher).
  static int _localeWeekStart() {
    final locale = PlatformDispatcher.instance.locale;
    for (final candidate in [locale.toString(), locale.languageCode]) {
      try {
        final fow = intl.DateFormat('', candidate).dateSymbols.FIRSTDAYOFWEEK;
        // intl FIRSTDAYOFWEEK: 0=Mon..6=Sun → Dart: 1=Mon..7=Sun
        return fow + 1;
      } catch (_) {
        continue;
      }
    }
    return DateTime.monday;
  }

  late int _year;
  late int _month;
  int? _selectedDay; // null = month view, non-null = day-detail (week) view
  int _weekStart = DateTime.monday; // Dart weekday: 1=Mon..7=Sun
  bool _weekStartReady = false;
  bool _capturingImage = false;
  // Month View capture only — not persisted, resets on app restart. See
  // _captureMonthImage/_renderMonthShareBytes.
  bool _showEmptyCategoriesInCapture = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _year = now.year;
    _month = now.month;

    if (_cachedNativeWeekStart != null) {
      // Fast path: value already known — no async work needed.
      _weekStart = _cachedNativeWeekStart!;
      _weekStartReady = true;
    } else {
      // Slow path: ask the platform. A 200 ms timeout guards against a
      // non-responsive channel; locale-based value is used as fallback.
      _fetchNativeWeekStart()
          .timeout(
            const Duration(milliseconds: 200),
            onTimeout: () => null,
          )
          .then((native) {
        if (!mounted) return;
        setState(() {
          _weekStart = native ?? _localeWeekStart();
          _weekStartReady = true;
        });
      });
    }
  }

  bool get _isWeekView => _selectedDay != null;

  int get _firstWeekdayOffset {
    final wd = DateTime(_year, _month, 1).weekday; // 1=Mon..7=Sun
    return (wd - _weekStart + 7) % 7;
  }

  int get _daysInMonth => DateTime(_year, _month + 1, 0).day;

  int get _rowCount =>
      ((_firstWeekdayOffset + _daysInMonth + 6) ~/ 7).clamp(4, 6);

  int? get _selectedRow {
    if (_selectedDay == null) return null;
    final cellIndex = _firstWeekdayOffset + _selectedDay! - 1;
    return cellIndex ~/ 7;
  }

  void _prevMonth() => setState(() {
        _selectedDay = null;
        if (_month == 1) {
          _year -= 1;
          _month = 12;
        } else {
          _month -= 1;
        }
      });

  void _nextMonth() => setState(() {
        _selectedDay = null;
        if (_month == 12) {
          _year += 1;
          _month = 1;
        } else {
          _month += 1;
        }
      });

  String _monthTitle(AppLocalizations l10n) {
    if (l10n.localeName == 'ko') return '$_year년 $_month월';
    return intl.DateFormat.yMMMM(l10n.localeName)
        .format(DateTime(_year, _month));
  }

  String _selectedDayTitle(AppLocalizations l10n) {
    final day = _selectedDay!;
    final dt = DateTime(_year, _month, day);
    final weekdays = [
      l10n.weekdayMon,
      l10n.weekdayTue,
      l10n.weekdayWed,
      l10n.weekdayThu,
      l10n.weekdayFri,
      l10n.weekdaySat,
      l10n.weekdaySun,
    ];
    final wdName = weekdays[dt.weekday - 1]; // weekday: 1=Mon..7=Sun
    if (l10n.localeName == 'ko') return '$_month월 $day일 ($wdName)';
    final monthStr = intl.DateFormat.MMM(l10n.localeName).format(dt);
    return '$monthStr $day ($wdName)';
  }

  // Intrinsic height of the weekday-row padding (top:20 + bottom:14) plus
  // the minimum four-row grid (4 × 66 px). Used to reserve card space while
  // the native first-weekday call is in flight.
  static const _calendarCardMinHeight = 34.0 + 4 * 66.0;

  Widget _buildCalendarCard(AppLocalizations l10n,
      AsyncValue<CalendarMonthData> dataAsync) {
    return Container(
      margin: const EdgeInsets.fromLTRB(8, 4, 8, 0),
      decoration: BoxDecoration(
        color: AppColors.card,
        border: Border.all(color: AppColors.separator, width: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        children: [
          if (_weekStartReady) ...[
            Padding(
              padding: const EdgeInsets.only(top: 20, bottom: 14),
              child: _buildWeekdayRow(l10n),
            ),
            ClipRect(child: _buildGrid(dataAsync)),
          ] else
            // Reserve space while waiting for the native first-weekday value.
            // The card chrome (border, background, rounded corners) is already
            // visible; only the grid interior is deferred. The placeholder
            // height matches the minimum 4-row calendar so nothing shifts.
            const SizedBox(height: _calendarCardMinHeight),
          const SizedBox(height: 14),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final l10n = AppLocalizations.of(context)!;
    final dataAsync =
        ref.watch(calendarMonthProvider((year: _year, month: _month)));
    final categories = ref.watch(categoriesProvider).valueOrNull ?? [];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 20, 0),
              child: Text(
                l10n.calendarLabel,
                style: AppTypography.appTitle.copyWith(color: AppColors.label1),
              ),
            ),
            _buildHeader(l10n, dataAsync),
            _buildCalendarCard(l10n, dataAsync),
            if (_isWeekView)
              Expanded(
                child: _buildDayDetail(l10n, dataAsync.valueOrNull),
              )
            else ...[
              _buildLegend(l10n, categories),
              Padding(
                padding: const EdgeInsets.fromLTRB(26, 10, 26, 0),
                child: Text(
                  l10n.calendarHintText,
                  style: AppTypography.footnote
                      .copyWith(color: AppColors.label5),
                ),
              ),
            ],
          ],
        ),
      ),
      floatingActionButton: dataAsync.hasValue
          ? _CaptureFab(
              capturing: _capturingImage,
              onTap: () => _captureCalendarImage(dataAsync.requireValue, categories),
            )
          : null,
    );
  }

  // ── Header ──────────────────────────────────────────────────────────────────

  Widget _buildHeader(
      AppLocalizations l10n, AsyncValue<CalendarMonthData> dataAsync) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 6, 20, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: _isWeekView
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedDayTitle(l10n),
                        style: const TextStyle(
                          fontFamily: 'Pretendard',
                          fontSize: 21,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.4,
                          color: AppColors.label1,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        _monthTitle(l10n),
                        style: AppTypography.footnote
                            .copyWith(color: AppColors.label2),
                      ),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _monthTitle(l10n),
                        style: const TextStyle(
                          fontFamily: 'Pretendard',
                          fontSize: 21,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.4,
                          color: AppColors.label1,
                        ),
                      ),
                      const SizedBox(height: 2),
                      dataAsync.when(
                        data: (d) => d.workoutDays == 0
                            ? Text(
                                l10n.calendarNoRecords,
                                style: AppTypography.footnote
                                    .copyWith(color: AppColors.label2),
                              )
                            : Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    l10n.calendarSummaryWorkoutDays(d.workoutDays),
                                    style: AppTypography.footnote
                                        .copyWith(color: AppColors.label2),
                                  ),
                                  const SizedBox(width: 6),
                                  Icon(AppIcons.trophy, size: 13, color: AppColors.pbGold),
                                  const SizedBox(width: 4),
                                  Text(
                                    l10n.calendarSummaryPrCount(d.prCount),
                                    style: AppTypography.footnote
                                        .copyWith(color: AppColors.label2),
                                  ),
                                ],
                              ),
                        loading: () => const SizedBox(height: 16),
                        error: (_, __) => const SizedBox.shrink(),
                      ),
                    ],
                  ),
          ),
          const SizedBox(width: 8),
          if (_isWeekView)
            _ReturnToMonthButton(
              label: l10n.calendarReturnToMonth,
              onTap: () => setState(() => _selectedDay = null),
            )
          else ...[
            _NavButton(icon: AppIcons.back, onTap: _prevMonth),
            const SizedBox(width: 6),
            _NavButton(icon: AppIcons.forward, onTap: _nextMonth),
          ],
        ],
      ),
    );
  }

  // ── Weekday labels ──────────────────────────────────────────────────────────

  Widget _buildWeekdayRow(AppLocalizations l10n) {
    // All 7 labels indexed 0..6 where index = _weekStart's Sunday-anchored position.
    // _weekStart % 7 maps Dart weekday 7 (Sun) → 0, 1 (Mon) → 1, ..., 6 (Sat) → 6.
    final allLabels = <String Function(AppLocalizations)>[
      (l) => l.weekdaySun, // index 0
      (l) => l.weekdayMon, // index 1
      (l) => l.weekdayTue, // index 2
      (l) => l.weekdayWed, // index 3
      (l) => l.weekdayThu, // index 4
      (l) => l.weekdayFri, // index 5
      (l) => l.weekdaySat, // index 6
    ];
    final startIndex = _weekStart % 7;
    final labels = List.generate(7, (i) => allLabels[(startIndex + i) % 7](l10n));
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: labels
            .map(
              (label) => Expanded(
                child: Center(
                  child: Text(
                    label,
                    style: AppTypography.footnote.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.label4,
                    ),
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  // ── Grid ────────────────────────────────────────────────────────────────────

  Widget _buildGrid(AsyncValue<CalendarMonthData> dataAsync) {
    final data = dataAsync.valueOrNull;
    final today = DateTime.now();
    final isCurrentMonth =
        today.year == _year && today.month == _month;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        children: List.generate(_rowCount, (row) {
          final visible = !_isWeekView || row == _selectedRow;
          return ClipRect(
            // AnimatedAlign's heightFactor shrinks/grows the *visible* box
            // while always laying the row out at its natural (full) height —
            // unlike AnimatedContainer's height, which forces the row's
            // actual constraint down as it collapses. That's what let cell
            // content (day number + category dots) get squeezed below the
            // height it needs mid-transition and overflow. Here, the row is
            // always given the room it needs; ClipRect only hides the part
            // of it that falls outside the currently-animated box, so the
            // content itself never shrinks or scales.
            child: AnimatedAlign(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              alignment: Alignment.topCenter,
              heightFactor: visible ? 1.0 : 0.0,
              child: AnimatedOpacity(
                opacity: visible ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: Row(
                  children: List.generate(7, (col) {
                    final (day, isOut) = _cellInfo(row, col);
                    final isToday =
                        isCurrentMonth && !isOut && today.day == day;
                    final isSelected =
                        _isWeekView && !isOut && day == _selectedDay;
                    final dayData = isOut ? null : data?.days[day];
                    return Expanded(
                      child: _CalendarCell(
                        day: day,
                        isOutOfMonth: isOut,
                        isToday: isToday,
                        isSelected: isSelected,
                        categoryColorKeys:
                            dayData?.categoryColorKeys ?? [],
                        hasPr: dayData?.hasPr ?? false,
                        hasNote: dayData?.hasNote ?? false,
                        onTap: isOut
                            ? null
                            : () =>
                                setState(() => _selectedDay = day),
                      ),
                    );
                  }),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  (int, bool) _cellInfo(int row, int col) {
    final cellIndex = row * 7 + col;
    final dayIndex = cellIndex - _firstWeekdayOffset;
    if (dayIndex < 0) {
      final prevDays = DateTime(_year, _month, 0).day;
      return (prevDays + dayIndex + 1, true);
    } else if (dayIndex >= _daysInMonth) {
      return (dayIndex - _daysInMonth + 1, true);
    } else {
      return (dayIndex + 1, false);
    }
  }

  // ── Legend ──────────────────────────────────────────────────────────────────

  Widget _buildLegend(AppLocalizations l10n, List<Category> categories) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Wrap(
        spacing: 16,
        runSpacing: 10,
        children: buildCalendarLegendItems(
          categories: categories,
          noteLegendLabel: l10n.calendarNoteLegendLabel,
        ),
      ),
    );
  }

  // ── Day detail ──────────────────────────────────────────────────────────────

  Widget _buildDayDetail(
      AppLocalizations l10n, CalendarMonthData? data) {
    final performedOn =
        DateTime(_year, _month, _selectedDay!).millisecondsSinceEpoch;
    return ListView(
      padding: const EdgeInsets.only(bottom: 40),
      children: [
        _buildDayRecordsSection(l10n, data),
        _buildDayNotesSection(l10n, performedOn),
      ],
    );
  }

  Widget _buildDayRecordsSection(
      AppLocalizations l10n, CalendarMonthData? data) {
    if (data == null) return const SizedBox.shrink();
    final today = _selectedDay!;
    final dayRecords = data.records
        .where((r) =>
            DateTime.fromMillisecondsSinceEpoch(r.performedAt).day ==
            today)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(label: l10n.calendarRecordsLabel),
        if (dayRecords.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22),
            child: Text(
              l10n.calendarNoRecords,
              style: AppTypography.footnote
                  .copyWith(color: AppColors.label3),
            ),
          )
        else
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: AppColors.separator, width: 0.5),
            ),
            clipBehavior: Clip.hardEdge,
            child: Column(
              children: dayRecords.asMap().entries.map((entry) {
                final i = entry.key;
                final record = entry.value;
                final exercise = data.exerciseMap[record.exerciseId];
                if (exercise == null) return const SizedBox.shrink();
                final pb = ref.watch(personalBestProvider(exercise.id));
                final isThisPr = exercise.exerciseType == ExerciseType.complete
                    ? false
                    : pb?.sourceRecordId == record.id;
                final colorKey =
                    data.exerciseColorKeys[exercise.id] ?? 'gray';
                final color = CategoryColor.toColor(colorKey);
                final value = _formatRecordValue(record, exercise);
                return Column(
                  children: [
                    if (i > 0)
                      const Divider(
                        height: 1,
                        thickness: 0.5,
                        color: AppColors.separator,
                      ),
                    GestureDetector(
                      onTap: () => context.push(
                        exercise.exerciseType == ExerciseType.complete
                            ? '/exercise/${exercise.id}'
                            : '/exercise/${exercise.id}/record/${record.id}',
                      ),
                      child: ExerciseRecordRow(
                        name: exercise.displayName,
                        value: value,
                        categoryColor: color,
                        hasPr: isThisPr,
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildDayNotesSection(AppLocalizations l10n, int performedOn) {
    final notesAsync = ref.watch(notesProvider(performedOn));
    final notes = notesAsync.valueOrNull ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(label: l10n.calendarNotesLabel),
        if (notes.isEmpty)
          GestureDetector(
            onTap: () => _showNoteEditSheet(performedOn: performedOn),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.label1.withValues(alpha: 0.13),
                  width: 1.5,
                ),
              ),
              child: Center(
                child: Text(
                  l10n.calendarAddNoteAffordance,
                  style: AppTypography.footnote.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.label3,
                  ),
                ),
              ),
            ),
          )
        else ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: notes
                  .map((note) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _NoteCard(
                          note: note,
                          onTap: () => _showNoteEditSheet(
                            performedOn: performedOn,
                            note: note,
                          ),
                        ),
                      ))
                  .toList(),
            ),
          ),
          GestureDetector(
            onTap: () => _showNoteEditSheet(performedOn: performedOn),
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 0),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border:
                    Border.all(color: AppColors.separator, width: 0.5),
              ),
              child: Center(
                child: Text(
                  l10n.calendarAddNoteAffordance,
                  style: AppTypography.footnote.copyWith(
                    fontWeight: FontWeight.w500,
                    color: AppColors.label3,
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  /// Single capture entry point for the whole screen. No day selected →
  /// captures the displayed month (the exact same [CalendarMonthData]
  /// already loaded for the grid). A day selected → captures that day's
  /// records/notes. Never saves anything itself — only generates a PNG and
  /// hands it to [DayCaptureSheet] for the user to confirm. "Capturing"
  /// only covers generation, not the review sheet: the FAB returns to
  /// normal as soon as the image is ready, matching how a camera app's
  /// shutter button isn't "busy" while you review the shot.
  Future<void> _captureCalendarImage(
      CalendarMonthData data, List<Category> categories) async {
    if (_capturingImage) return;
    final l10n = AppLocalizations.of(context)!;

    if (_selectedDay == null) {
      await _captureMonthImage(data, categories, l10n);
    } else {
      await _captureDayImage(data, l10n);
    }
  }

  Future<void> _captureMonthImage(
      CalendarMonthData data, List<Category> categories, AppLocalizations l10n) async {
    setState(() => _capturingImage = true);
    final Uint8List bytes;
    try {
      bytes = await _renderMonthShareBytes(
        data: data,
        categories: categories,
        l10n: l10n,
        includeEmptyCategories: _showEmptyCategoriesInCapture,
      );
    } catch (e) {
      if (mounted) {
        setState(() => _capturingImage = false);
        _showSnack(l10n.saveFailed(e));
      }
      return;
    }

    if (!mounted) return;
    setState(() => _capturingImage = false);
    await DayCaptureSheet.show(
      context,
      bytes,
      fileNamePrefix: 'peaklog_month_share_',
      initialShowEmptyCategories: _showEmptyCategoriesInCapture,
      // Month View capture only — regenerates the image with/without
      // categories that have no workout records this month. Never touches
      // Calendar/category data or the on-screen grid, only this capture's
      // own legend. Remembered for the rest of this Calendar session (not
      // persisted to disk) so re-opening capture keeps the last choice.
      onToggleShowEmptyCategories: (showEmpty) {
        _showEmptyCategoriesInCapture = showEmpty;
        return _renderMonthShareBytes(
          data: data,
          categories: categories,
          l10n: l10n,
          includeEmptyCategories: showEmpty,
        );
      },
    );
  }

  Future<Uint8List> _renderMonthShareBytes({
    required CalendarMonthData data,
    required List<Category> categories,
    required AppLocalizations l10n,
    required bool includeEmptyCategories,
  }) async {
    // Split so the painter can place the existing PR trophy icon between
    // the two parts, exactly like the on-screen summary — null when
    // there's no activity, matching calendarNoRecords being a separate,
    // unrelated message (not "0 workouts").
    final workoutDaysLabel = data.workoutDays == 0
        ? null
        : l10n.calendarSummaryWorkoutDays(data.workoutDays);
    final prCountLabel =
        data.workoutDays == 0 ? null : l10n.calendarSummaryPrCount(data.prCount);
    final countLabel = data.workoutDays == 0 ? l10n.calendarNoRecords : '';
    // Same weekday-label ordering _buildWeekdayRow already uses, so the
    // image matches the on-screen grid exactly.
    final allWeekdayLabels = <String Function(AppLocalizations)>[
      (l) => l.weekdaySun,
      (l) => l.weekdayMon,
      (l) => l.weekdayTue,
      (l) => l.weekdayWed,
      (l) => l.weekdayThu,
      (l) => l.weekdayFri,
      (l) => l.weekdaySat,
    ];
    final startIndex = _weekStart % 7;
    final weekdayLabels =
        List.generate(7, (i) => allWeekdayLabels[(startIndex + i) % 7](l10n));

    final shareData = MonthShareData(
      monthLabel: _monthTitle(l10n),
      countLabel: countLabel,
      workoutDaysLabel: workoutDaysLabel,
      prCountLabel: prCountLabel,
      weekdayLabels: weekdayLabels,
      cells: buildMonthShareCells(
        firstWeekdayOffset: _firstWeekdayOffset,
        daysInMonth: _daysInMonth,
        days: data.days,
      ),
      // Same records/exerciseMap already loaded for the grid, plus the
      // same categories list already watched for the on-screen legend —
      // no new category query.
      usedCategories: buildMonthShareCategories(
        records: data.records,
        exerciseMap: data.exerciseMap,
        categories: categories,
        includeEmpty: includeEmptyCategories,
      ),
      // data.days already carries hasNote per day (the same per-day flag
      // the on-screen grid's Note indicator uses) — no separate notes
      // query needed to know whether this month has any.
      noteLegendLabel: buildMonthShareShowNoteLegend(
        hasAnyNotes: data.days.values.any((d) => d.hasNote),
        includeEmpty: includeEmptyCategories,
      )
          ? l10n.calendarNoteLegendLabel
          : null,
    );
    return renderMonthShareToBytes(shareData);
  }

  Future<void> _captureDayImage(CalendarMonthData data, AppLocalizations l10n) async {
    final today = _selectedDay!;
    final dayRecords = data.records
        .where((r) => DateTime.fromMillisecondsSinceEpoch(r.performedAt).day == today)
        .toList();
    if (dayRecords.isEmpty) {
      // Day View capture is a single date, never a month — a date-neutral
      // message distinct from calendarNoRecords (which is Month View's
      // "no workouts this month" wording, shared by the normal calendar
      // header and day-detail records section).
      _showSnack(l10n.calendarDayCaptureNoRecords);
      return;
    }

    setState(() => _capturingImage = true);
    final Uint8List bytes;
    try {
      final prRecordIds = <String>{};
      for (final exerciseId in dayRecords.map((r) => r.exerciseId).toSet()) {
        final pb = ref.read(personalBestProvider(exerciseId));
        if (pb != null) prRecordIds.add(pb.sourceRecordId);
      }
      final performedOn = DateTime(_year, _month, today).millisecondsSinceEpoch;
      // Same notes Day Detail's own Notes section already loads — no
      // separate query, sorting, or filtering logic.
      final notes = ref.read(notesProvider(performedOn)).valueOrNull ?? [];

      final shareData = DayShareData(
        dateLabel: _selectedDayTitle(l10n),
        recordsSectionLabel: l10n.calendarRecordsLabel,
        records: buildDayShareRecords(
          records: dayRecords,
          exerciseMap: data.exerciseMap,
          exerciseColorKeys: data.exerciseColorKeys,
          prRecordIds: prRecordIds,
          l10n: l10n,
        ),
        notesSectionLabel: l10n.calendarNotesLabel,
        notes: buildDayShareNotes(notes),
      );

      bytes = await renderDayShareToBytes(shareData);
    } catch (e) {
      if (mounted) {
        setState(() => _capturingImage = false);
        _showSnack(l10n.saveFailed(e));
      }
      return;
    }

    if (!mounted) return;
    setState(() => _capturingImage = false);
    await DayCaptureSheet.show(context, bytes, fileNamePrefix: 'peaklog_day_share_');
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(seconds: 2)),
    );
  }

  void _showNoteEditSheet({required int performedOn, Note? note}) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => NoteEditSheet(
        initialNote: note,
        performedOn: performedOn,
      ),
    );
  }

  String _formatRecordValue(Record r, Exercise exercise) {
    if (exercise.exerciseType == ExerciseType.complete) return '✓';
    final rt = exercise.recordType;
    if (rt == null) return '—';
    switch (rt) {
      case RecordType.weight:
        final w = r.weight;
        if (w == null) return '—';
        final formatted =
            UnitConverter.formatWeight(w, exercise.baseUnit);
        return (r.reps != null && r.reps! > 1)
            ? '$formatted × ${r.reps}'
            : formatted;
      case RecordType.forTime:
        final d = r.durationSeconds;
        return d != null ? UnitConverter.secondsToDisplay(d) : '—';
      case RecordType.etc:
        final dist = r.distance;
        return dist != null
            ? UnitConverter.formatEtc(dist, r.distanceUnit)
            : '—';
      case RecordType.amrap:
        if (r.rounds == null) return '—';
        final extra =
            r.reps != null && r.reps! > 0 ? ' ${r.reps}' : '';
        return '${r.rounds}R$extra';
    }
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _NavButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _NavButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: const [
            BoxShadow(
              color: Color(0x12000000),
              blurRadius: 4,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child:
            Center(child: Icon(icon, size: 18, color: AppColors.label1)),
      ),
    );
  }
}

class _ReturnToMonthButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _ReturnToMonthButton(
      {required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.actionDark,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.grid_view, size: 13, color: Colors.white),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTypography.button
                  .copyWith(color: Colors.white, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

/// Resolves the visual style of a Month/Week View date-cell number circle
/// from its selection/today/in-month state. Pure and stateless — public
/// (unlike _CalendarCell itself) specifically so this logic is unit
/// testable without needing to render the full Calendar widget tree.
class CalendarDateCellStyle {
  final Color textColor;
  final Color? fillColor;
  final Color? borderColor;

  const CalendarDateCellStyle({
    required this.textColor,
    this.fillColor,
    this.borderColor,
  });

  factory CalendarDateCellStyle.resolve({
    required bool isSelected,
    required bool isOutOfMonth,
    required bool isToday,
  }) {
    if (isSelected) {
      return const CalendarDateCellStyle(
        textColor: Colors.white,
        fillColor: AppColors.actionDark,
      );
    }
    if (isOutOfMonth) {
      return const CalendarDateCellStyle(textColor: AppColors.label5);
    }
    if (isToday) {
      // Today, unselected: same black used for the selected fill, but as
      // an outline only — no red text treatment.
      return const CalendarDateCellStyle(
        textColor: AppColors.label1,
        borderColor: AppColors.actionDark,
      );
    }
    return const CalendarDateCellStyle(textColor: AppColors.label1);
  }
}

class _CalendarCell extends StatelessWidget {
  final int day;
  final bool isOutOfMonth;
  final bool isToday;
  final bool isSelected;
  final List<String> categoryColorKeys;
  final bool hasPr;
  final bool hasNote;
  final VoidCallback? onTap;

  const _CalendarCell({
    required this.day,
    required this.isOutOfMonth,
    required this.isToday,
    required this.isSelected,
    required this.categoryColorKeys,
    required this.hasPr,
    required this.hasNote,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final style = CalendarDateCellStyle.resolve(
      isSelected: isSelected,
      isOutOfMonth: isOutOfMonth,
      isToday: isToday,
    );
    final numColor = style.textColor;
    final numBg = style.fillColor;
    final numBorder = style.borderColor != null
        ? Border.all(color: style.borderColor!, width: 1.5)
        : null;

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        height: 66,
        child: Stack(
          children: [
            Align(
              alignment: Alignment.topCenter,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 7),
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: numBg,
                      shape: BoxShape.circle,
                      border: numBorder,
                    ),
                    child: Center(
                      child: Text(
                        '$day',
                        style: TextStyle(
                          fontFamily: 'Pretendard',
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: numColor,
                          height: 1,
                        ),
                      ),
                    ),
                  ),
                  if (!isOutOfMonth && (categoryColorKeys.isNotEmpty || hasNote))
                    CalendarCategoryDots(colorKeys: categoryColorKeys, hasNote: hasNote),
                ],
              ),
            ),
            if (hasPr && !isOutOfMonth)
              Positioned(
                top: 4,
                right: 6,
                child: Icon(
                  AppIcons.trophy,
                  size: 10,
                  color: AppColors.pbGold,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class CalendarCategoryDots extends StatelessWidget {
  final List<String> colorKeys;
  final bool hasNote;
  const CalendarCategoryDots({
    required this.colorKeys,
    required this.hasNote,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final visible = colorKeys.take(4).toList();
    final hasOverflow = colorKeys.length > 4;
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      // Wrap, not Row: at the narrowest realistic cell widths, 4 dots +
      // the "+" overflow + a note indicator can exceed the cell's width
      // (verified: a fixed-width Row overflows by 1-9px at 375/360/320pt
      // device widths). Wrap reflows the excess onto a second centered
      // line instead of overlapping or clipping — there's ~20px of
      // vertical headroom left in the 66px cell for that. When everything
      // still fits on one line (the common, unchanged case), Wrap and Row
      // render identically for the same spacing/alignment.
      child: Wrap(
        alignment: WrapAlignment.center,
        runAlignment: WrapAlignment.center,
        spacing: 3,
        runSpacing: 2,
        children: [
          ...visible.map(
            (key) => Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                color: CategoryColor.toColor(key),
                shape: BoxShape.circle,
              ),
            ),
          ),
          if (hasOverflow)
            const Text(
              '+',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w800,
                color: AppColors.label4,
                height: 1,
              ),
            ),
          // Notes are never a category — appended after every category dot
          // (and the overflow "+") so it can never overlap either, and
          // square/rounded (vs. the dots' circles) so it's never mistaken
          // for one, regardless of category color.
          if (hasNote)
            Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                color: AppColors.label1,
                borderRadius: BorderRadius.circular(1.5),
              ),
            ),
        ],
      ),
    );
  }
}

/// Builds the normal Month View legend's items: one entry per category
/// that currently exists (color dot + name, Uncategorized excluded —
/// unchanged from before), followed by a permanent Note entry.
///
/// Unlike the Month View *capture* legend (`buildMonthShareCategories`/
/// `buildMonthShareShowNoteLegend`, which conditionally include Note based
/// on whether the captured month has notes and the "Show categories
/// without workout records" toggle), this function takes no such inputs
/// at all — the Note entry it appends is unconditional. That's not an
/// oversight: the normal Month View legend is a permanent key explaining
/// what the per-date Note indicator means, so it must remain visible
/// whether or not the current month happens to have any notes, and is
/// completely unaffected by the separate capture toggle. Pure and public
/// (no BuildContext/State) so this is unit-testable without rendering the
/// full Calendar widget tree.
List<CalendarLegendItem> buildCalendarLegendItems({
  required List<Category> categories,
  required String noteLegendLabel,
}) =>
    [
      for (final cat in categories.where((c) => c.id != Category.uncategorizedId))
        CalendarLegendItem(color: CategoryColor.toColor(cat.color), label: cat.name),
      CalendarLegendItem(label: noteLegendLabel, isNote: true),
    ];

class CalendarLegendItem extends StatelessWidget {
  final Color? color;
  final String label;
  /// True for the permanent Note legend entry: draws the same rounded-
  /// square marker as the date-cell Note indicator (CalendarCategoryDots)
  /// instead of a category's colored circle. [color] is unused in that case.
  final bool isNote;
  const CalendarLegendItem({
    this.color,
    required this.label,
    this.isNote = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Same 5px marker size as the grid's own indicators
        // (CalendarCategoryDots) — one consistent indicator system.
        Container(
          width: 5,
          height: 5,
          decoration: isNote
              ? BoxDecoration(
                  color: AppColors.label1,
                  borderRadius: BorderRadius.circular(1.5),
                )
              : BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: AppTypography.footnote.copyWith(color: AppColors.label2),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 10),
      child: Text(
        label,
        style: AppTypography.footnote.copyWith(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.label2,
        ),
      ),
    );
  }
}

/// Single capture entry point for the whole Calendar screen: captures the
/// displayed month (Month view or a selected day's collapsed grid) or the
/// selected day's records/notes, depending on Calendar's own current state
/// — see `_CalendarScreenState._captureCalendarImage`.
class _CaptureFab extends StatelessWidget {
  final bool capturing;
  final VoidCallback onTap;
  const _CaptureFab({required this.capturing, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: capturing ? null : onTap,
      child: Container(
        width: 52,
        height: 52,
        decoration: const BoxDecoration(
          color: AppColors.actionDark,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Color(0x33000000),
              blurRadius: 10,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Center(
          child: capturing
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : Icon(AppIcons.gallery, size: 22, color: Colors.white),
        ),
      ),
    );
  }
}

class _NoteCard extends StatelessWidget {
  final Note note;
  final VoidCallback onTap;
  const _NoteCard({required this.note, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.separator, width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (note.title.isNotEmpty) ...[
              Text(
                note.title,
                style: AppTypography.cardTitle
                    .copyWith(color: AppColors.label1),
              ),
              const SizedBox(height: 4),
            ],
            if (note.body.isNotEmpty)
              Text(
                note.body,
                style: AppTypography.footnote.copyWith(
                  color: AppColors.label2,
                  height: 1.55,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Note Edit Sheet ───────────────────────────────────────────────────────────

/// One shared source of truth for both the Share and Save buttons'
/// enabled state in the Edit Note popup — an editing-SESSION state
/// machine, not a text-dirty comparison:
///
/// - [_Phase.initial] (popup just opened): Share enabled, Save enabled —
///   nothing has happened in this session yet.
/// - [_Phase.editing] (user focused/typed in any editable field, whether
///   or not anything actually changed): Share disabled, Save enabled.
///   [markInteracted] moves here from either other phase and is a no-op
///   if already here — further edits, deletions, or restoring the
///   original text never move it anywhere else. Only [markSaved] does.
/// - [_Phase.saved] (a successful Save just committed the fields'
///   content as the new saved Note): Share enabled, Save disabled — "the
///   currently displayed content is already saved." [markSaved] moves
///   here from [_Phase.editing].
///
/// [isAvailable] (Share) and [isSaveAvailable] (Save) are both simple
/// projections of the same [_phase], so they can never disagree with
/// each other about which phase the session is in. Pure and public (no
/// BuildContext/Riverpod) specifically so this state machine is
/// unit-testable without pumping the full Note Edit popup.
enum _Phase { initial, editing, saved }

class NoteShareAvailability {
  _Phase _phase = _Phase.initial;

  bool get isAvailable => _phase != _Phase.editing;
  bool get isSaveAvailable => _phase != _Phase.saved;

  void markInteracted() => _phase = _Phase.editing;
  void markSaved() => _phase = _Phase.saved;
}

/// The Edit Note popup's Share button — sits immediately to the left of
/// the existing Save button. Pure/stateless (no BuildContext/Riverpod) so
/// its enabled/disabled rendering and tap-gating are unit-testable
/// without pumping the full Note Edit popup. Disabled: [onTap] is never
/// invoked (same null-onTap-means-inert convention as this file's other
/// gesture-driven buttons), and the icon uses AppColors.label3 — the same
/// muted token this popup's own field hint text already uses — rather
/// than a new disabled color.
class NoteShareButton extends StatelessWidget {
  final bool enabled;
  final VoidCallback onTap;
  const NoteShareButton({required this.enabled, required this.onTap, super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 48,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.separator),
        ),
        child: Center(
          child: Icon(
            AppIcons.share,
            size: 18,
            color: enabled ? AppColors.label1 : AppColors.label3,
          ),
        ),
      ),
    );
  }
}

class NoteEditSheet extends ConsumerStatefulWidget {
  final Note? initialNote;
  final int performedOn;
  const NoteEditSheet({required this.performedOn, this.initialNote, super.key});

  @override
  ConsumerState<NoteEditSheet> createState() => _NoteEditSheetState();
}

class _NoteEditSheetState extends ConsumerState<NoteEditSheet> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _bodyCtrl;
  late final FocusNode _titleFocus;
  late final FocusNode _bodyFocus;
  final _shareAvailability = NoteShareAvailability();
  Note? _currentSavedNote;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.initialNote?.title ?? '')
      ..addListener(_onFieldInteraction);
    _bodyCtrl = TextEditingController(text: widget.initialNote?.body ?? '')
      ..addListener(_onFieldInteraction);
    _currentSavedNote = widget.initialNote;
    _titleFocus = FocusNode()..addListener(_onFieldInteraction);
    _bodyFocus = FocusNode()..addListener(_onFieldInteraction);
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    _titleFocus.dispose();
    _bodyFocus.dispose();
    super.dispose();
  }

  // Share availability is an editing-session state, not a dirty-text
  // comparison: the moment the user focuses EITHER field — even without
  // typing anything — Share must disable, and it's never re-enabled by
  // text matching the original (only a successful Save does that). The
  // FocusNode listeners alone catch "focused but never typed"; the
  // TextEditingController listeners are a second, independent trigger for
  // the same one-way latch, needed because Save does not unfocus the
  // field it was called from — a field can stay continuously focused
  // across a Save, so a later keystroke in that same field would
  // otherwise produce no focus-transition event at all. Neither listener
  // ever looks at what the text says, only that something happened.
  // New Notes (no initialNote) have no Share button at all, so this is a
  // no-op there.
  void _onFieldInteraction() {
    if (widget.initialNote == null || !_shareAvailability.isAvailable) return;
    setState(_shareAvailability.markInteracted);
  }

  // Enters the exact same visual share/customization screen and final
  // SharePlus pipeline used by workout Record/Activity sharing
  // (ExportScreen, routed via '/share/note') — this popup no longer
  // calls SharePlus or the OS share sheet directly, and no longer logs
  // logShareUsed() itself; ExportScreen's own _share() does both,
  // exactly once, the same way it already does for workout content.
  // Only the persisted _currentSavedNote is ever passed — never the live
  // _titleCtrl/_bodyCtrl contents.
  Future<void> _shareNote() async {
    final note = _currentSavedNote;
    if (note == null) return;
    await context.push('/share/note', extra: note);
  }

  Future<void> _save() async {
    if (_saving) return;
    if (widget.initialNote == null) {
      final title = _titleCtrl.text.trim();
      final body = _bodyCtrl.text.trim();
      if (title.isEmpty && body.isEmpty) {
        if (mounted) Navigator.pop(context);
        return;
      }
    }
    setState(() => _saving = true);
    final notifier =
        ref.read(notesProvider(widget.performedOn).notifier);
    if (widget.initialNote == null) {
      // Add: unchanged — a new Note always closes the sheet on success,
      // it has no Share button/state to preserve.
      await notifier.addNote(
        title: _titleCtrl.text.trim(),
        body: _bodyCtrl.text.trim(),
      );
      unawaited(ref.read(analyticsProvider).logNoteCreated());
      if (mounted) Navigator.pop(context);
      return;
    }
    final now = DateTime.now().millisecondsSinceEpoch;
    final updated = widget.initialNote!.copyWith(
      title: _titleCtrl.text.trim(),
      body: _bodyCtrl.text.trim(),
      updatedAt: now,
    );
    await notifier.updateNote(updated);
    // Edit: the sheet stays open (unlike Add) so the user can Share the
    // just-saved content immediately, without reopening. The just-saved
    // Note becomes the new Share source of truth, and the field-
    // interaction latch resets exactly like a freshly opened Edit
    // session — see NoteShareAvailability doc. _saving must be reset here
    // (unlike Add, which never revisits this state after popping) so a
    // second Save in the same still-open session isn't blocked by the
    // guard at the top of this method.
    //
    // If updateNote above throws, none of this runs: _currentSavedNote,
    // _shareAvailability, and the sheet's mounted state are all left
    // untouched, so a failed save can never re-enable Share or share
    // unsaved content.
    if (mounted) {
      setState(() {
        _currentSavedNote = updated;
        _shareAvailability.markSaved();
        _saving = false;
      });
    }
  }

  Future<void> _delete() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text(l10n.calendarDeleteNote),
        content: const SizedBox.shrink(),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await ref
        .read(notesProvider(widget.performedOn).notifier)
        .deleteNote(widget.initialNote!.id);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isEditing = widget.initialNote != null;
    // Add always stays enabled — it never reaches the "saved, still open"
    // state Edit does, since a successful Add closes the sheet
    // immediately.
    final saveEnabled = !isEditing || _shareAvailability.isSaveAvailable;
    final insets = MediaQuery.viewInsetsOf(context);

    return Padding(
      padding: EdgeInsets.only(bottom: insets.bottom),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.85,
        ),
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 6),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFD1D1D6),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 6, 8, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      isEditing
                          ? l10n.calendarEditNoteTitle
                          : l10n.calendarAddNoteTitle,
                      style: AppTypography.headline
                          .copyWith(color: AppColors.label1),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(AppIcons.close,
                        color: AppColors.label2),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 8),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildField(
                      controller: _titleCtrl,
                      focusNode: _titleFocus,
                      hint: l10n.calendarNoteHintTitle,
                      maxLines: 1,
                    ),
                    const SizedBox(height: 10),
                    _buildField(
                      controller: _bodyCtrl,
                      focusNode: _bodyFocus,
                      hint: l10n.calendarNoteHintBody,
                      minLines: 4,
                      maxLines: 8,
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Row(
                children: [
                  // Add Note has no Share button — a new Note is not
                  // shareable until it's been saved at least once.
                  if (isEditing) ...[
                    NoteShareButton(
                      enabled: _shareAvailability.isAvailable,
                      onTap: _shareNote,
                    ),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: GestureDetector(
                      onTap: saveEnabled ? _save : null,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          // Same existing disabled-button token used
                          // elsewhere for a primary CTA (e.g. Add/Edit
                          // Exercise's Save button) — not a new color.
                          color: saveEnabled
                              ? AppColors.actionDark
                              : AppColors.disabled,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            l10n.save,
                            style: AppTypography.button
                                .copyWith(color: Colors.white, fontSize: 15),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (isEditing) ...[
              DestructiveActionButton(
                label: l10n.calendarDeleteNote,
                onPressed: _delete,
              ),
            ],
            SizedBox(
              height: MediaQuery.paddingOf(context).bottom + 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    FocusNode? focusNode,
    int? minLines,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      minLines: minLines,
      maxLines: maxLines,
      style: AppTypography.body.copyWith(color: AppColors.label1),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AppTypography.body.copyWith(color: AppColors.label3),
        filled: true,
        fillColor: AppColors.card,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.separator),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.separator),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: AppColors.actionDark),
        ),
        contentPadding: const EdgeInsets.all(14),
      ),
    );
  }
}

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
              _buildLegend(categories),
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
                        data: (d) => Text(
                          d.workoutDays == 0
                              ? l10n.calendarNoRecords
                              : l10n.calendarSummary(
                                  d.workoutDays, d.prCount),
                          style: AppTypography.footnote
                              .copyWith(color: AppColors.label2),
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
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              height: visible ? 66.0 : 0.0,
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

  Widget _buildLegend(List<Category> categories) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Wrap(
        spacing: 16,
        runSpacing: 10,
        children: [
          ...categories
              .where((c) => c.id != Category.uncategorizedId)
              .map((cat) => _LegendItem(
                    color: CategoryColor.toColor(cat.color),
                    label: cat.name,
                  )),
        ],
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

  void _showNoteEditSheet({required int performedOn, Note? note}) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _NoteEditSheet(
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

class _CalendarCell extends StatelessWidget {
  final int day;
  final bool isOutOfMonth;
  final bool isToday;
  final bool isSelected;
  final List<String> categoryColorKeys;
  final bool hasPr;
  final VoidCallback? onTap;

  const _CalendarCell({
    required this.day,
    required this.isOutOfMonth,
    required this.isToday,
    required this.isSelected,
    required this.categoryColorKeys,
    required this.hasPr,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color numColor;
    final Color? numBg;

    if (isSelected) {
      numColor = Colors.white;
      numBg = AppColors.actionDark;
    } else if (isOutOfMonth) {
      numColor = AppColors.label5;
      numBg = null;
    } else if (isToday) {
      numColor = AppColors.todayAccent;
      numBg = null;
    } else {
      numColor = AppColors.label1;
      numBg = null;
    }

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
                  if (!isOutOfMonth && categoryColorKeys.isNotEmpty)
                    _CategoryDots(colorKeys: categoryColorKeys),
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

class _CategoryDots extends StatelessWidget {
  final List<String> colorKeys;
  const _CategoryDots({required this.colorKeys});

  @override
  Widget build(BuildContext context) {
    final visible = colorKeys.take(4).toList();
    final hasOverflow = colorKeys.length > 4;
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          ...visible.map(
            (key) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 1.5),
              child: Container(
                width: 5,
                height: 5,
                decoration: BoxDecoration(
                  color: CategoryColor.toColor(key),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
          if (hasOverflow) ...[
            const SizedBox(width: 1),
            const Text(
              '+',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w800,
                color: AppColors.label4,
                height: 1,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
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

class _NoteEditSheet extends ConsumerStatefulWidget {
  final Note? initialNote;
  final int performedOn;
  const _NoteEditSheet({required this.performedOn, this.initialNote});

  @override
  ConsumerState<_NoteEditSheet> createState() => _NoteEditSheetState();
}

class _NoteEditSheetState extends ConsumerState<_NoteEditSheet> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _bodyCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _titleCtrl =
        TextEditingController(text: widget.initialNote?.title ?? '');
    _bodyCtrl =
        TextEditingController(text: widget.initialNote?.body ?? '');
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
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
      await notifier.addNote(
        title: _titleCtrl.text.trim(),
        body: _bodyCtrl.text.trim(),
      );
      unawaited(ref.read(analyticsProvider).logNoteCreated());
    } else {
      final now = DateTime.now().millisecondsSinceEpoch;
      await notifier.updateNote(
        widget.initialNote!.copyWith(
          title: _titleCtrl.text.trim(),
          body: _bodyCtrl.text.trim(),
          updatedAt: now,
        ),
      );
    }
    if (mounted) Navigator.pop(context);
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
                      hint: l10n.calendarNoteHintTitle,
                      maxLines: 1,
                    ),
                    const SizedBox(height: 10),
                    _buildField(
                      controller: _bodyCtrl,
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
              child: GestureDetector(
                onTap: _save,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.actionDark,
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
    int? minLines,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
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

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/design/app_colors.dart';
import '../../core/design/app_icons.dart';
import '../../core/design/app_typography.dart';
import '../../core/models/exercise.dart';
import '../../core/models/record.dart';
import '../../core/utils/unit_converter.dart';
import '../../domain/models/category.dart';
import '../../widgets/category_color_indicator.dart';
import '../../domain/models/personal_best.dart';
import '../../providers/categories_provider.dart';
import '../../providers/exercises_provider.dart';
import '../../providers/personal_best_provider.dart';
import '../../providers/records_provider.dart';
import '../../widgets/exercise_record_row.dart';
import '../../widgets/swipeable_row.dart';
import '../../l10n/app_localizations.dart';
import 'add_exercise_sheet.dart';

class HomeScreen extends ConsumerStatefulWidget {
  final FocusNode? searchFocus;
  final Widget? swipeHint;
  final VoidCallback? onCalendarTap;
  const HomeScreen({super.key, this.searchFocus, this.swipeHint, this.onCalendarTap});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  String _search = '';
  String? _filterCategoryId; // null = All
  late final FocusNode _searchFocus;
  late final bool _ownsFocusNode;

  void _onFocusChange() => setState(() {});

  @override
  void initState() {
    super.initState();
    if (widget.searchFocus != null) {
      _searchFocus = widget.searchFocus!;
      _ownsFocusNode = false;
    } else {
      _searchFocus = FocusNode();
      _ownsFocusNode = true;
    }
    _searchFocus.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _searchFocus.removeListener(_onFocusChange);
    if (_ownsFocusNode) _searchFocus.dispose();
    super.dispose();
  }

  // See plan's "PB / PR Rendering Reference" for full type-by-type rules.
  String _bestValue(PersonalBest? pb, List<Record> records, Exercise exercise) {
    if (pb != null) {
      switch (exercise.recordType) {
        case RecordType.weight:
          if (pb.weight != null) {
            return UnitConverter.formatWeight(pb.weight!, exercise.baseUnit);
          }
        case RecordType.etc:
          if (pb.etcValue != null) {
            final src = records.where((r) => r.id == pb.sourceRecordId).firstOrNull;
            return UnitConverter.formatEtc(pb.etcValue!, src?.distanceUnit ?? '');
          }
        case RecordType.forTime:
          if (pb.durationSeconds != null) {
            return UnitConverter.secondsToDisplay(pb.durationSeconds!);
          }
        case RecordType.amrap:
          if (pb.rounds != null) {
            return UnitConverter.formatAmrap(pb.rounds!, pb.reps);
          }
        case null: break;
      }
    }
    if (records.isEmpty || exercise.recordType == null) return '—';
    final active = records.where((r) => !r.isDeleted).toList();
    if (active.isEmpty) return '—';
    switch (exercise.recordType!) {
      case RecordType.weight:
        final best = active.where((r) => r.weight != null)
            .fold<Record?>(null, (b, r) => b == null || r.weight! > b.weight! ? r : b);
        return best != null ? UnitConverter.formatWeight(best.weight!, exercise.baseUnit) : '—';
      case RecordType.etc:
        final best = active.where((r) => r.distance != null)
            .fold<Record?>(null, (b, r) => b == null || r.distance! > b.distance! ? r : b);
        return best != null ? UnitConverter.formatEtc(best.distance!, best.distanceUnit) : '—';
      case RecordType.forTime:
        final best2 = active.where((r) => r.durationSeconds != null)
            .fold<Record?>(null, (b, r) => b == null || r.durationSeconds! < b.durationSeconds! ? r : b);
        return best2 != null ? UnitConverter.secondsToDisplay(best2.durationSeconds!) : '—';
      case RecordType.amrap:
        final best = active.where((r) => r.rounds != null)
            .fold<Record?>(null, (b, r) => b == null || r.rounds! > b.rounds! ? r : b);
        return best != null ? UnitConverter.formatAmrap(best.rounds!, best.reps) : '—';
    }
  }

  Future<void> _confirmDelete(BuildContext context, Exercise exercise) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text(l10n.deleteExerciseTitle),
        content: Text(l10n.deleteExerciseContent(exercise.displayName)),
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
    if (confirmed == true) {
      await ref.read(exercisesProvider.notifier).deleteExercise(exercise.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final l10n = AppLocalizations.of(context)!;
    final exercises  = ref.watch(exercisesProvider).valueOrNull ?? [];
    final categories = ref.watch(categoriesProvider).valueOrNull ?? [];

    // id → color key lookup; avoids repeated list scans inside itemBuilder.
    final colorMap = {for (final c in categories) c.id: c.color};

    final filtered = exercises.where((e) {
      final matchesSearch = _search.isEmpty ||
          e.displayName.toLowerCase().contains(_search.toLowerCase());
      final matchesCat = _filterCategoryId == null || e.categoryId == _filterCategoryId;
      return matchesSearch && matchesCat;
    }).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  Text(
                    'PeakLog',
                    style: AppTypography.appTitle.copyWith(color: AppColors.label1),
                  ),
                  Expanded(
                    child: Center(
                      child: widget.swipeHint ?? const SizedBox.shrink(),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => context.push('/calculators'),
                    child: _IconButton(icon: AppIcons.calculator),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => context.push('/settings'),
                    child: _IconButton(icon: AppIcons.settings),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // ── Search bar ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.separator, width: 0.5),
                ),
                child: TextField(
                  focusNode: _searchFocus,
                  onChanged: (v) => setState(() => _search = v),
                  cursorColor: AppColors.textPrimaryAlt,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    color: AppColors.label1,
                  ),
                  decoration: InputDecoration(
                    hintText: _searchFocus.hasFocus ? null : l10n.searchExercises,
                    hintStyle: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                      color: AppColors.textSecondaryAlt,
                    ),
                    prefixIcon: Icon(AppIcons.search, size: 16, color: AppColors.textSecondaryAlt),
                    prefixIconConstraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    filled: false,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            // ── Category chip filter (horizontally scrollable) ───────
            // Uses ListView so chips never wrap and always accommodate
            // any number of categories without overflow.
            SizedBox(
              height: 32,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _CategoryChip(
                    label: l10n.filterAll,
                    color: null,
                    selected: _filterCategoryId == null,
                    onTap: () => setState(() => _filterCategoryId = null),
                  ),
                  ...categories.map((cat) => Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: _CategoryChip(
                      label: cat.id == Category.uncategorizedId ? l10n.categoryUncategorized : cat.name,
                      color: CategoryColor.toColor(cat.color),
                      selected: _filterCategoryId == cat.id,
                      onTap: () => setState(() => _filterCategoryId = cat.id),
                    ),
                  )),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // ── Exercise list (flat, no section headers) ─────────────
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Text(
                        l10n.noExercises,
                        style: const TextStyle(fontSize: 15, color: AppColors.label2),
                      ),
                    )
                  : Container(
                      color: Colors.white,
                      child: ListView.separated(
                        padding: EdgeInsets.zero,
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const Divider(
                          height: 1,
                          thickness: 0.5,
                          indent: 34, // aligns with exercise name start
                          color: AppColors.separator,
                        ),
                        itemBuilder: (context, index) {
                          final exercise = filtered[index];
                          final records =
                              ref.watch(recordsProvider(exercise.id)).valueOrNull ?? [];
                          final pb = ref.watch(personalBestProvider(exercise.id));
                          final bestValue = _bestValue(pb, records, exercise);
                          final catColor = exercise.categoryId != null
                              ? CategoryColor.toColor(colorMap[exercise.categoryId])
                              : AppColors.label2;

                          return SwipeableRow(
                            id: exercise.id,
                            onEdit: () => context.push('/exercise/${exercise.id}'),
                            onDelete: () => _confirmDelete(context, exercise),
                            child: ExerciseRecordRow(
                              name: exercise.displayName,
                              value: bestValue,
                              categoryColor: catColor,
                              hasPr: pb != null,
                            ),
                          );
                        },
                      ),
                    ),
            ),
            // ── Calendar entry card + Add Exercise button ────────────
            Container(
              color: AppColors.background,
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _CalendarEntryCard(onTap: widget.onCalendarTap),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () async {
                          final selectedCategoryId = await showAddExerciseSheet(
                            context,
                            initialCategoryId: _filterCategoryId,
                          );
                          if (selectedCategoryId != null && mounted) {
                            setState(() => _filterCategoryId = selectedCategoryId);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: AppColors.actionDark,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.actionDarkBorder),
                          ),
                          child: Center(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text('+',
                                    style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.white,
                                        fontWeight: FontWeight.w300)),
                                const SizedBox(width: 6),
                                Text(l10n.addExerciseButton,
                                    style: AppTypography.button.copyWith(color: Colors.white)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Private widgets ────────────────────────────────────────────────────────────

class _IconButton extends StatelessWidget {
  final IconData icon;
  const _IconButton({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.separator),
      ),
      child: Center(child: Icon(icon, size: 17, color: AppColors.textPrimaryAlt)),
    );
  }
}

/// Compact card that taps (or swipes) to the Calendar page.
class _CalendarEntryCard extends StatelessWidget {
  final VoidCallback? onTap;
  const _CalendarEntryCard({this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.separator, width: 0.5),
        ),
        child: Row(
          children: [
            Icon(AppIcons.calendar, size: 17, color: AppColors.label2),
            const SizedBox(width: 9),
            Text(
              l10n.calendarLabel,
              style: AppTypography.body.copyWith(
                fontWeight: FontWeight.w500,
                color: AppColors.label1,
              ),
            ),
            const Spacer(),
            Text(
              l10n.calendarCardSwipeHint,
              style: AppTypography.footnote.copyWith(color: AppColors.label5),
            ),
            const SizedBox(width: 2),
            Icon(AppIcons.forward, size: 18, color: AppColors.chevron),
          ],
        ),
      ),
    );
  }
}

/// Horizontal chip for the category filter bar.
/// `color: null` = the "All" chip (no dot).
class _CategoryChip extends StatelessWidget {
  final String label;
  final Color? color;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: selected ? AppColors.chipSelected : AppColors.chip,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (color != null) ...[
              CategoryColorIndicator(color: color!, size: 14),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: selected ? Colors.white : AppColors.textPrimaryAlt,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


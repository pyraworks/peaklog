import 'package:flutter/material.dart';
import '../../core/design/app_colors.dart';
import '../../core/design/app_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/design/app_spacing.dart';
import '../../core/design/app_typography.dart';
import '../../core/models/exercise.dart';
import '../../domain/models/category.dart';
import '../../widgets/category_color_indicator.dart';
import '../../providers/categories_provider.dart';
import '../../providers/exercises_provider.dart';
import '../../widgets/screen_header.dart';
import '../../l10n/app_localizations.dart';

Future<void> showAddExerciseSheet(BuildContext context) {
  return Navigator.push<void>(
    context,
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => const AddExerciseSheet(),
    ),
  );
}

Future<void> showEditExerciseSheet(BuildContext context, Exercise exercise) {
  return Navigator.push<void>(
    context,
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => AddExerciseSheet(initialExercise: exercise),
    ),
  );
}

class AddExerciseSheet extends ConsumerStatefulWidget {
  final Exercise? initialExercise;
  const AddExerciseSheet({this.initialExercise, super.key});

  @override
  ConsumerState<AddExerciseSheet> createState() => _AddExerciseSheetState();
}

class _AddExerciseSheetState extends ConsumerState<AddExerciseSheet> {
  final _nameCtrl = TextEditingController();
  String? _selectedCategoryId;
  BestType _bestType = BestType.pb;
  String _baseUnit = 'kg';
  bool _saving = false;
  bool _categoryOpen = false;

  bool get _isEditMode => widget.initialExercise != null;

  @override
  void initState() {
    super.initState();
    final ex = widget.initialExercise;
    if (ex != null) {
      _nameCtrl.text = ex.displayName;
      _selectedCategoryId = ex.categoryId;
      _bestType = ex.bestType ?? BestType.pb;
      _baseUnit = ex.baseUnit;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  String _categoryLabel(String id, List<Category> categories, String uncategorizedLabel) {
    return categories.firstWhere(
      (c) => c.id == id,
      orElse: () => categories.isNotEmpty ? categories.first : Category(id: Category.uncategorizedId, name: uncategorizedLabel, color: 'gray', sortOrder: 0, createdAt: 0, updatedAt: 0),
    ).name;
  }

  String get _effectiveCategoryId =>
      _selectedCategoryId ?? Category.uncategorizedId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final categories = ref.watch(categoriesProvider).valueOrNull ?? [];
    final nameEmpty = _nameCtrl.text.trim().isEmpty;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          ScreenHeader(
            backLabel: _isEditMode ? l10n.back : l10n.homeLabel,
            title: _isEditMode ? l10n.editExerciseTitle : l10n.addExerciseTitle,
            onBack: () => Navigator.pop(context),
          ),
          // ── Body ──────────────────────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _NameCard(
                    controller: _nameCtrl,
                    onChanged: () => setState(() {}),
                  ),
                  const SizedBox(height: AppSpacing.s12),
                  _CategoryDropdown(
                    selectedId: _selectedCategoryId,
                    categoryLabel: _selectedCategoryId != null
                        ? _categoryLabel(_selectedCategoryId!, categories, l10n.categoryUncategorized)
                        : null,
                    open: _categoryOpen,
                    categories: categories,
                    onToggle: () =>
                        setState(() => _categoryOpen = !_categoryOpen),
                    onSelect: (id) => setState(() {
                      _selectedCategoryId = id;
                      _categoryOpen = false;
                    }),
                  ),
                  if (_isEditMode) ...[
                    const SizedBox(height: AppSpacing.s12),
                    _UnitCard(
                      value: _baseUnit,
                      onChanged: (v) => setState(() => _baseUnit = v),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.s12),
                  _BestTypeCard(
                    value: _bestType,
                    onChanged: (v) => setState(() => _bestType = v),
                  ),
                  const SizedBox(height: AppSpacing.s24),
                  _AddButton(
                    loading: _saving,
                    disabled: nameEmpty,
                    isEdit: _isEditMode,
                    onPressed: nameEmpty || _saving ? null : _submit,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    setState(() => _saving = true);

    try {
      if (_isEditMode) {
        await ref.read(exercisesProvider.notifier).updateExerciseSettings(
              widget.initialExercise!.id,
              displayName: name,
              categoryId: _effectiveCategoryId,
              bestType: _bestType,
              baseUnit: _baseUnit,
            );
        if (mounted) Navigator.of(context).pop();
      } else {
        final exercise = await ref
            .read(exercisesProvider.notifier)
            .addExercise(name, _effectiveCategoryId,
                bestType: _bestType);

        if (!mounted) return;
        final id = exercise?.id;
        Navigator.of(context).pop();
        if (id != null) context.push('/exercise/$id');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.saveFailed(e)),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

// ── Widgets ───────────────────────────────────────────────────────────────────

class _NameCard extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onChanged;
  const _NameCard({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        border: Border.all(color: AppColors.separator, width: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: Text(
              l10n.exerciseNameLabel,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondaryAlt,
                letterSpacing: 0.64,
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  onChanged: (_) => onChanged(),
                  autofocus: true,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimaryAlt,
                  ),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.fromLTRB(16, 2, 8, 11),
                    hintText: l10n.exerciseNameHint,
                    hintStyle: const TextStyle(color: AppColors.label2),
                  ),
                ),
              ),
              if (controller.text.isNotEmpty)
                GestureDetector(
                  onTap: () {
                    controller.clear();
                    onChanged();
                  },
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(0, 0, 12, 0),
                    child: Icon(AppIcons.close,
                        size: 14, color: AppColors.textSecondaryAlt),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CategoryDropdown extends StatelessWidget {
  final String? selectedId;
  final String? categoryLabel;
  final bool open;
  final List<Category> categories;
  final VoidCallback onToggle;
  final ValueChanged<String> onSelect;

  const _CategoryDropdown({
    required this.selectedId,
    required this.categoryLabel,
    required this.open,
    required this.categories,
    required this.onToggle,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final selectedCat = (selectedId != null && categories.isNotEmpty)
        ? categories.firstWhere((c) => c.id == selectedId,
            orElse: () => categories.first)
        : null;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        border: Border.all(color: AppColors.separator, width: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        children: [
          GestureDetector(
            onTap: onToggle,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 12),
              child: Row(
                children: [
                  Text(
                    l10n.categoryLabel,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: AppColors.textSecondaryAlt,
                    ),
                  ),
                  if (!open && categoryLabel != null) ...[
                    const SizedBox(width: 8),
                    if (selectedCat != null) ...[
                      CategoryColorIndicator(
                        color: CategoryColor.toColor(selectedCat.color),
                        size: 10,
                      ),
                      const SizedBox(width: 5),
                    ],
                    Text(
                      categoryLabel!,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimaryAlt,
                      ),
                    ),
                  ],
                  const Spacer(),
                  Icon(
                    open ? AppIcons.caretUp : AppIcons.caretDown,
                    size: 16,
                    color: AppColors.textSecondaryAlt,
                  ),
                ],
              ),
            ),
          ),
          if (open)
            Column(
              children: categories.map((c) {
                final isSelected = c.id == selectedId;
                return GestureDetector(
                  onTap: () => onSelect(c.id),
                  child: Container(
                    decoration: const BoxDecoration(
                      border: Border(
                          top: BorderSide(color: AppColors.separatorAlt)),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    child: Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: CategoryColorIndicator(
                            color: CategoryColor.toColor(c.color),
                            size: 10,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            c.name,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: isSelected
                                  ? FontWeight.w500
                                  : FontWeight.w400,
                              color: isSelected
                                  ? AppColors.textPrimaryAlt
                                  : AppColors.textTertiary,
                            ),
                          ),
                        ),
                        if (isSelected)
                          Icon(AppIcons.check,
                              size: 14, color: AppColors.textPrimaryAlt),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}

class _BestTypeCard extends StatelessWidget {
  final BestType value;
  final ValueChanged<BestType> onChanged;
  const _BestTypeCard({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        border: Border.all(color: AppColors.separator, width: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Segmented control
          Container(
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                _Segment(
                  label: 'PB',
                  selected: value == BestType.pb,
                  onTap: () => onChanged(BestType.pb),
                  isFirst: true,
                ),
                _Segment(
                  label: 'PR',
                  selected: value == BestType.pr,
                  onTap: () => onChanged(BestType.pr),
                  isFirst: false,
                ),
              ],
            ),
          ),
          const SizedBox(height: 7),
          Text(
            l10n.pbPrDescription,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondaryAlt,
            ),
          ),
        ],
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool isFirst;

  const _Segment({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.isFirst,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: EdgeInsets.fromLTRB(
            isFirst ? 2 : 1, 2, isFirst ? 1 : 2, 2,
          ),
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight:
                    selected ? FontWeight.w600 : FontWeight.w400,
                color: selected
                    ? AppColors.label1
                    : AppColors.textSecondaryAlt,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _UnitCard extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;
  const _UnitCard({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        border: Border.all(color: AppColors.separator, width: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                _Segment(
                  label: 'kg',
                  selected: value == 'kg',
                  onTap: () => onChanged('kg'),
                  isFirst: true,
                ),
                _Segment(
                  label: 'lb',
                  selected: value == 'lbs',
                  onTap: () => onChanged('lbs'),
                  isFirst: false,
                ),
              ],
            ),
          ),
          const SizedBox(height: 7),
          Text(
            l10n.defaultWeightUnit,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondaryAlt,
            ),
          ),
        ],
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  final bool loading;
  final bool disabled;
  final bool isEdit;
  final VoidCallback? onPressed;
  const _AddButton({
    required this.loading,
    required this.disabled,
    required this.onPressed,
    this.isEdit = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final active = !disabled && !loading;
    return GestureDetector(
      onTap: onPressed,
      child: AnimatedOpacity(
        opacity: disabled ? 0.5 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 13),
          decoration: BoxDecoration(
            color: active
                ? AppColors.actionDark
                : AppColors.disabled,
            border: Border.all(
              color: active
                  ? AppColors.actionDarkBorder
                  : AppColors.disabled,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: loading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : Text(
                    isEdit ? l10n.saveChanges : l10n.addExerciseButton,
                    style: AppTypography.button.copyWith(
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

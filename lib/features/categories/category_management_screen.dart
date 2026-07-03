import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../core/design/app_colors.dart';
import '../../core/design/app_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../core/database/database_helper.dart';
import '../../domain/models/category.dart';
import '../../widgets/category_color_indicator.dart';
import '../../providers/categories_provider.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/screen_header.dart';
import '../../widgets/swipeable_row.dart';

class CategoryManagementScreen extends ConsumerStatefulWidget {
  const CategoryManagementScreen({super.key});

  @override
  ConsumerState<CategoryManagementScreen> createState() =>
      _CategoryManagementScreenState();
}

class _CategoryManagementScreenState
    extends ConsumerState<CategoryManagementScreen> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final categories = ref.watch(categoriesProvider).valueOrNull ?? [];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          ScreenHeader(
            backLabel: l10n.settingsLabel,
            title: l10n.categoriesTitle,
          ),
          Expanded(
            child: categories.isEmpty
                ? Center(
                    child: Text(
                      l10n.noCategories,
                      style: const TextStyle(color: AppColors.textTertiary, fontSize: 15),
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: AppColors.separatorAlt, width: 0.5),
                        ),
                        clipBehavior: Clip.hardEdge,
                        child: ReorderableListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          padding: EdgeInsets.zero,
                          buildDefaultDragHandles: false,
                          itemCount: categories.length,
                          onReorderItem: (oldIdx, newIdx) =>
                              _reorder(categories, oldIdx, newIdx),
                          proxyDecorator: (child, _, animation) => Material(
                            elevation: 2,
                            borderRadius: BorderRadius.circular(12),
                            child: child,
                          ),
                          itemBuilder: (context, i) {
                            final cat = categories[i];
                            return _CategoryTile(
                              key: ValueKey(cat.id),
                              index: i,
                              category: cat,
                              showDivider: i < categories.length - 1,
                              onEdit: () => _showEditSheet(context, cat),
                              onDelete: () => _confirmDelete(context, cat),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
          ),
          // ── Add Category button ────────────────────────────────────
          Container(
            color: AppColors.background,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                child: GestureDetector(
                  onTap: () => _showAddSheet(context),
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
                          Text(l10n.addCategoryButton,
                              style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }


  Future<void> _reorder(List<Category> cats, int oldIdx, int newIdx) async {
    final reordered = List<Category>.from(cats);
    final moved = reordered.removeAt(oldIdx);
    reordered.insert(newIdx, moved);

    final now = DateTime.now().millisecondsSinceEpoch;
    for (var i = 0; i < reordered.length; i++) {
      await DatabaseHelper.instance.updateCategory(
        reordered[i].copyWith(sortOrder: i, updatedAt: now),
      );
    }
    ref.invalidate(categoriesProvider);
  }

  Future<void> _showAddSheet(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final result = await _openSheet(
      context,
      title: l10n.addCategoryButton,
      initialName: '',
      initialColor: 'blue',
    );
    if (result == null) return;

    final now = DateTime.now().millisecondsSinceEpoch;
    final cats = ref.read(categoriesProvider).valueOrNull ?? [];
    final cat = Category(
      id: const Uuid().v4(),
      name: result.$1,
      color: result.$2,
      sortOrder: cats.length,
      createdAt: now,
      updatedAt: now,
    );
    await DatabaseHelper.instance.insertCategory(cat);
    ref.invalidate(categoriesProvider);
  }

  Future<void> _showEditSheet(BuildContext context, Category cat) async {
    final l10n = AppLocalizations.of(context)!;
    final result = await _openSheet(
      context,
      title: l10n.editCategoryTitle,
      initialName: cat.name,
      initialColor: cat.color,
    );
    if (result == null) return;

    await DatabaseHelper.instance.updateCategory(
      cat.copyWith(
        name: result.$1,
        color: result.$2,
        updatedAt: DateTime.now().millisecondsSinceEpoch,
      ),
    );
    ref.invalidate(categoriesProvider);
  }

  /// Opens `_CategoryEditSheet` and returns `(name, colorKey)` or null.
  Future<(String, String)?> _openSheet(
    BuildContext context, {
    required String title,
    required String initialName,
    required String initialColor,
  }) {
    return showModalBottomSheet<(String, String)>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _CategoryEditSheet(
        title: title,
        initialName: initialName,
        initialColor: initialColor,
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, Category cat) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text(l10n.deleteCategoryTitle),
        content: Text(l10n.deleteCategoryContent),
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
    if (confirmed != true) return;
    await DatabaseHelper.instance.deleteCategory(cat.id);
    ref.invalidate(categoriesProvider);
  }
}

// ── Bottom sheet (add / edit) ─────────────────────────────────────────────────

class _CategoryEditSheet extends StatefulWidget {
  final String title;
  final String initialName;
  final String initialColor;

  const _CategoryEditSheet({
    required this.title,
    required this.initialName,
    required this.initialColor,
  });

  @override
  State<_CategoryEditSheet> createState() => _CategoryEditSheetState();
}

class _CategoryEditSheetState extends State<_CategoryEditSheet> {
  late final TextEditingController _ctrl;
  late String _selectedColor;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.initialName);
    _selectedColor = widget.initialColor;
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimaryAlt,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _ctrl,
            autofocus: true,
            onChanged: (_) => setState(() {}),
            style: const TextStyle(fontSize: 15, color: AppColors.textPrimaryAlt),
            decoration: InputDecoration(
              hintText: l10n.categoryNameHint,
              hintStyle: const TextStyle(color: AppColors.textSecondaryAlt),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.separatorAlt),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.separatorAlt),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.primary),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.colorLabel,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondaryAlt,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: CategoryColor.palette.map((key) {
              final isSelected = key == _selectedColor;
              final color = CategoryColor.toColor(key);
              return GestureDetector(
                onTap: () => setState(() => _selectedColor = key),
                child: CategoryColorIndicator(
                  color: color,
                  size: 32,
                  isSelected: isSelected,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.separatorAlt),
                    ),
                    child: Center(
                      child: Text(l10n.cancel,
                          style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textPrimaryAlt)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: _ctrl.text.trim().isEmpty
                      ? null
                      : () => Navigator.pop(
                          context, (_ctrl.text.trim(), _selectedColor)),
                  child: AnimatedOpacity(
                    opacity: _ctrl.text.trim().isEmpty ? 0.5 : 1.0,
                    duration: const Duration(milliseconds: 150),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.actionDark,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(l10n.save,
                            style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: Colors.white)),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Category tile ─────────────────────────────────────────────────────────────

class _CategoryTile extends StatelessWidget {
  final int index;
  final Category category;
  final bool showDivider;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _CategoryTile({
    required this.index,
    required this.category,
    required this.showDivider,
    required this.onEdit,
    required this.onDelete,
    super.key,
  });

  Widget _colorIndicator() {
    return CategoryColorIndicator(
      color: CategoryColor.toColor(category.color),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ReorderableDelayedDragStartListener(
      index: index,
      child: SwipeableRow(
        id: category.id,
        onEdit: onEdit,
        onSwipeEdit: onEdit,
        onDelete: onDelete,
        child: ColoredBox(
          color: Colors.white,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                leading: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(AppIcons.dragHandle,
                        color: AppColors.label5, size: 16),
                    const SizedBox(width: 10),
                    _colorIndicator(),
                  ],
                ),
              title: Text(
                category.id == Category.uncategorizedId
                    ? AppLocalizations.of(context)!.categoryUncategorized
                    : category.name,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  color: AppColors.label1,
                ),
              ),
            ),
            if (showDivider)
              const Divider(
                height: 0.5,
                thickness: 0.5,
                indent: 44,
                color: AppColors.separator,
              ),
          ],
        ),
      ),
    ),
    );
  }
}

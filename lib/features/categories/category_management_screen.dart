import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../core/design/app_colors.dart';
import '../../core/design/app_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../core/database/database_helper.dart';
import '../../domain/models/category.dart';
import '../../providers/categories_provider.dart';
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
    final categories = ref.watch(categoriesProvider).valueOrNull ?? [];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          ScreenHeader(
            backLabel: 'Settings',
            title: 'Categories',
            trailing: GestureDetector(
              onTap: () => _showAddSheet(context),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.actionDark,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  '+ Add',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: categories.isEmpty
                ? const Center(
                    child: Text(
                      'No categories',
                      style: TextStyle(color: AppColors.textTertiary, fontSize: 15),
                    ),
                  )
                : ReorderableListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                    buildDefaultDragHandles: false,
                    itemCount: categories.length,
                    onReorderItem: (oldIdx, newIdx) =>
                        _reorder(categories, oldIdx, newIdx),
                    proxyDecorator: (child, _, animation) => Material(
                      elevation: 4,
                      borderRadius: BorderRadius.circular(12),
                      child: child,
                    ),
                    itemBuilder: (context, i) {
                      final cat = categories[i];
                      return _CategoryTile(
                        key: ValueKey(cat.id),
                        index: i,
                        category: cat,
                        onEdit: () => _showEditSheet(context, cat),
                        onDelete: () => _confirmDelete(context, cat),
                      );
                    },
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
    final result = await _openSheet(
      context,
      title: 'Add Category',
      initialName: '',
      initialColor: 'gray',
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
    final result = await _openSheet(
      context,
      title: 'Edit Category',
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
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Delete Category?'),
        content: const Text(
            'Exercises in this category will be moved to Uncategorized.'),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
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
              hintText: 'Category name',
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
          const Text(
            'Color',
            style: TextStyle(
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
              return GestureDetector(
                onTap: () => setState(() => _selectedColor = key),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: CategoryColor.toColor(key),
                    shape: BoxShape.circle,
                    border: isSelected
                        ? Border.all(color: AppColors.textPrimaryAlt, width: 2.5)
                        : null,
                    boxShadow: isSelected
                        ? [BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 4,
                          )]
                        : null,
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, size: 16, color: Colors.white)
                      : null,
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
                    child: const Center(
                      child: Text('Cancel',
                          style: TextStyle(
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
                      child: const Center(
                        child: Text('Save',
                            style: TextStyle(
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
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _CategoryTile({
    required this.index,
    required this.category,
    required this.onEdit,
    required this.onDelete,
    super.key,
  });

  Widget _colorDot() => Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          color: CategoryColor.toColor(category.color),
          shape: BoxShape.circle,
        ),
      );

  @override
  Widget build(BuildContext context) {
    final content = ColoredBox(
      color: Colors.white,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ReorderableDragStartListener(
              index: index,
              child: Icon(AppIcons.dragHandle, color: const Color(0xFFD1D5DA), size: 18),
            ),
            const SizedBox(width: 10),
            _colorDot(),
          ],
        ),
        title: Text(
          category.name,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: Color(0xFF1F2328),
          ),
        ),
      ),
    );

    final inner = SwipeableRow(
      id: category.id,
      onEdit: onEdit,
      onSwipeEdit: onEdit,
      onDelete: onDelete,
      child: content,
    );

    // Outer container: border radius + clip matches History card (radius 12,
    // hardEdge), so swiped action pane rendering is identical.
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.separatorAlt),
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.hardEdge,
      child: inner,
    );
  }
}

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/exercise.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/exercises_provider.dart';
import 'add_exercise_sheet.dart' show AddExerciseScreen;
import 'category_drawer.dart';
import 'exercise_card.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _editMode = false;
  final _searchController = TextEditingController();
  String _searchQuery = '';
  ExerciseCategory? _filterCategory;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final exercisesAsync = ref.watch(exercisesProvider);
    final allExercises = exercisesAsync.valueOrNull ?? [];
    final canAdd = allExercises.length < 6;

    return Scaffold(
      backgroundColor: AppTheme.background,
      drawer: CategoryDrawer(
        selected: _filterCategory,
        exercises: allExercises,
        onCategorySelected: (cat) =>
            setState(() => _filterCategory = cat),
      ),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        toolbarHeight: 60,
        leading: Builder(
          builder: (ctx) => CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () => Scaffold.of(ctx).openDrawer(),
            child: const Icon(
              CupertinoIcons.line_horizontal_3,
              color: AppTheme.textPrimary,
              size: 22,
            ),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'PBPR',
              style: TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
                color: AppTheme.textPrimary,
              ),
            ),
            if (_filterCategory != null)
              Text(
                _filterCategory!.label,
                style: const TextStyle(
                    color: AppTheme.accent,
                    fontSize: 11,
                    fontWeight: FontWeight.w600),
              ),
          ],
        ),
        actions: [
          CupertinoButton(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            onPressed: () => setState(() => _editMode = !_editMode),
            child: Text(
              _editMode ? '완료' : '편집',
              style: const TextStyle(
                color: AppTheme.accent,
                fontSize: 17,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          const Divider(
              height: 0.5, thickness: 0.5, color: AppTheme.separator),
          Expanded(
            child: exercisesAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppTheme.accent),
              ),
              error: (e, _) => Center(child: Text('오류: $e')),
              data: (exercises) {
                var filtered = exercises;
                if (_filterCategory != null) {
                  filtered = filtered
                      .where((e) => e.category == _filterCategory)
                      .toList();
                }
                if (_searchQuery.isNotEmpty) {
                  filtered = filtered
                      .where((e) => e.displayName
                          .toLowerCase()
                          .contains(_searchQuery.toLowerCase()))
                      .toList();
                }

                if (exercises.isEmpty) {
                  return const _EmptyState();
                }
                if (filtered.isEmpty) {
                  return _EmptyFilterState(
                    category: _filterCategory,
                    onClear: () =>
                        setState(() => _filterCategory = null),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                  itemCount: filtered.length,
                  itemBuilder: (_, i) {
                    final isFirst = i == 0;
                    final isLast = i == filtered.length - 1;
                    return ClipRRect(
                      borderRadius: BorderRadius.vertical(
                        top: isFirst
                            ? const Radius.circular(10)
                            : Radius.zero,
                        bottom: isLast
                            ? const Radius.circular(10)
                            : Radius.zero,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ExerciseCard(
                            exercise: filtered[i],
                            editMode: _editMode,
                          ),
                          if (!isLast)
                            const Divider(
                              height: 0.5,
                              thickness: 0.5,
                              color: AppTheme.separator,
                              indent: 16,
                            ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: _BottomToolbar(
        searchController: _searchController,
        onSearchChanged: (q) => setState(() => _searchQuery = q),
        onAdd: canAdd
            ? () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const AddExerciseScreen()),
                )
            : null,
      ),
    );
  }
}

class _BottomToolbar extends StatelessWidget {
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback? onAdd;

  const _BottomToolbar({
    required this.searchController,
    required this.onSearchChanged,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(16, 8, 16, 8 + bottomPadding),
      decoration: const BoxDecoration(
        color: AppTheme.background,
        border: Border(
          top: BorderSide(color: AppTheme.separator, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 36,
              decoration: BoxDecoration(
                color: AppTheme.card,
                borderRadius: BorderRadius.circular(10),
                border:
                    Border.all(color: AppTheme.separator, width: 0.5),
              ),
              child: TextField(
                controller: searchController,
                onChanged: onSearchChanged,
                style: const TextStyle(
                    fontSize: 14, color: AppTheme.textPrimary),
                decoration: const InputDecoration(
                  hintText: '운동 검색',
                  hintStyle: TextStyle(
                      color: AppTheme.textSecondary, fontSize: 14),
                  prefixIcon: Icon(CupertinoIcons.search,
                      color: AppTheme.textSecondary, size: 16),
                  contentPadding: EdgeInsets.symmetric(vertical: 8),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 44,
            child: onAdd != null
                ? CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: onAdd,
                    child: const Icon(CupertinoIcons.square_pencil,
                        color: AppTheme.accent, size: 26),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(CupertinoIcons.heart,
              color: AppTheme.textSecondary, size: 40),
          SizedBox(height: 12),
          Text('운동을 추가해보세요',
              style:
                  TextStyle(color: AppTheme.textSecondary, fontSize: 16)),
          SizedBox(height: 8),
          Text('하단 연필 버튼을 눌러 추가하세요',
              style: TextStyle(
                  color: AppTheme.textSecondary, fontSize: 13)),
        ],
      ),
    );
  }
}

class _EmptyFilterState extends StatelessWidget {
  final ExerciseCategory? category;
  final VoidCallback onClear;

  const _EmptyFilterState(
      {required this.category, required this.onClear});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${category?.label ?? ''} 운동 없음',
            style: const TextStyle(
                color: AppTheme.textSecondary, fontSize: 16),
          ),
          const SizedBox(height: 12),
          CupertinoButton(
            onPressed: onClear,
            child: const Text('전체 보기',
                style: TextStyle(color: AppTheme.accent)),
          ),
        ],
      ),
    );
  }
}

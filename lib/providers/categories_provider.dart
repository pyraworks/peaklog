import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/repositories/category_repository_impl.dart';
import '../domain/models/category.dart';
import '../domain/repositories/category_repository.dart';

final categoryRepositoryProvider = Provider<CategoryRepository>(
  (ref) => CategoryRepositoryImpl.instance,
);

class CategoriesNotifier extends AsyncNotifier<List<Category>> {
  @override
  Future<List<Category>> build() =>
      ref.watch(categoryRepositoryProvider).getAll();
}

final categoriesProvider =
    AsyncNotifierProvider<CategoriesNotifier, List<Category>>(
  CategoriesNotifier.new,
);

import '../../core/database/database_helper.dart';
import '../../domain/models/category.dart';
import '../../domain/repositories/category_repository.dart';

class CategoryRepositoryImpl implements CategoryRepository {
  const CategoryRepositoryImpl._();
  static const CategoryRepositoryImpl instance = CategoryRepositoryImpl._();

  @override
  Future<List<Category>> getAll() =>
      DatabaseHelper.instance.getCategories();
}

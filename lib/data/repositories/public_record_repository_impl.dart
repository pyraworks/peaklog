import '../../core/database/database_helper.dart';
import '../../domain/models/public_record.dart';
import '../../domain/repositories/public_record_repository.dart';

class PublicRecordRepositoryImpl implements PublicRecordRepository {
  const PublicRecordRepositoryImpl._();
  static const PublicRecordRepositoryImpl instance = PublicRecordRepositoryImpl._();

  @override
  Future<List<PublicRecord>> getAll() =>
      DatabaseHelper.instance.getPublicRecords();

  @override
  Future<void> insert(PublicRecord pr) =>
      DatabaseHelper.instance.insertPublicRecord(pr);

  @override
  Future<void> delete(String exerciseId) =>
      DatabaseHelper.instance.deletePublicRecord(exerciseId);

  @override
  Future<int> count() =>
      DatabaseHelper.instance.countPublicRecords();
}

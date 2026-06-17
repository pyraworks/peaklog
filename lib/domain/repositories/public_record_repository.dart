import '../models/public_record.dart';

abstract class PublicRecordRepository {
  Future<List<PublicRecord>> getAll();
  Future<void> insert(PublicRecord pr);
  Future<void> delete(String exerciseId);
  Future<int> count();
}

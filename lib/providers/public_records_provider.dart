import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/repositories/public_record_repository_impl.dart';
import '../domain/models/public_record.dart';
import '../domain/repositories/public_record_repository.dart';

final publicRecordRepositoryProvider = Provider<PublicRecordRepository>(
  (ref) => PublicRecordRepositoryImpl.instance,
);

class PublicRecordsNotifier extends AsyncNotifier<List<PublicRecord>> {
  @override
  Future<List<PublicRecord>> build() =>
      ref.watch(publicRecordRepositoryProvider).getAll();

  Future<void> add(PublicRecord pr) async {
    final repo = ref.read(publicRecordRepositoryProvider);
    await repo.insert(pr);
    final current = state.valueOrNull ?? [];
    state = AsyncData([...current, pr]
      ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder)));
  }

  Future<void> remove(String exerciseId) async {
    final repo = ref.read(publicRecordRepositoryProvider);
    await repo.delete(exerciseId);
    final current = state.valueOrNull ?? [];
    state = AsyncData(current.where((r) => r.exerciseId != exerciseId).toList());
  }
}

final publicRecordsProvider =
    AsyncNotifierProvider<PublicRecordsNotifier, List<PublicRecord>>(
  PublicRecordsNotifier.new,
);

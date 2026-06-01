import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/database/database_helper.dart';
import '../core/models/personal_best.dart';

class PersonalBestNotifier
    extends FamilyAsyncNotifier<List<PersonalBest>, String> {
  @override
  Future<List<PersonalBest>> build(String exerciseId) async =>
      DatabaseHelper.instance.getPersonalBestsForExercise(exerciseId);
}

final personalBestProvider = AsyncNotifierProvider.family<
    PersonalBestNotifier, List<PersonalBest>, String>(
  PersonalBestNotifier.new,
);

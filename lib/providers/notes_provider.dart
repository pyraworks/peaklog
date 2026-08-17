import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/models/note.dart';
import '../data/repositories/note_repository_impl.dart';

/// Bumped whenever any note is added, updated, or deleted (any date).
/// Providers that derive data from the notes table (e.g. calendar month
/// summaries) watch this to stay in sync — same pattern as
/// recordsRevisionProvider in records_provider.dart.
final notesRevisionProvider = StateProvider<int>((ref) => 0);

class NotesNotifier
    extends AutoDisposeFamilyAsyncNotifier<List<Note>, int> {
  @override
  Future<List<Note>> build(int arg) =>
      NoteRepositoryImpl.instance.getNotesByDate(arg);

  Future<void> addNote({required String title, required String body}) async {
    final note = Note.create(
      performedOn: arg,
      title: title,
      body: body,
      sortOrder: (state.valueOrNull ?? []).length,
    );
    await NoteRepositoryImpl.instance.insert(note);
    state = AsyncData([...(state.valueOrNull ?? []), note]);
    ref.read(notesRevisionProvider.notifier).state++;
  }

  Future<void> updateNote(Note note) async {
    await NoteRepositoryImpl.instance.update(note);
    final current = state.valueOrNull ?? [];
    state = AsyncData(
      current.map((n) => n.id == note.id ? note : n).toList(),
    );
    ref.read(notesRevisionProvider.notifier).state++;
  }

  Future<void> deleteNote(String id) async {
    await NoteRepositoryImpl.instance.softDelete(id);
    final current = state.valueOrNull ?? [];
    state = AsyncData(current.where((n) => n.id != id).toList());
    ref.read(notesRevisionProvider.notifier).state++;
  }
}

final notesProvider =
    AutoDisposeAsyncNotifierProvider.family<NotesNotifier, List<Note>, int>(
  NotesNotifier.new,
);

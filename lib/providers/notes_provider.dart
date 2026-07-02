import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/models/note.dart';
import '../data/repositories/note_repository_impl.dart';

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
  }

  Future<void> updateNote(Note note) async {
    await NoteRepositoryImpl.instance.update(note);
    final current = state.valueOrNull ?? [];
    state = AsyncData(
      current.map((n) => n.id == note.id ? note : n).toList(),
    );
  }

  Future<void> deleteNote(String id) async {
    await NoteRepositoryImpl.instance.softDelete(id);
    final current = state.valueOrNull ?? [];
    state = AsyncData(current.where((n) => n.id != id).toList());
  }
}

final notesProvider =
    AutoDisposeAsyncNotifierProvider.family<NotesNotifier, List<Note>, int>(
  NotesNotifier.new,
);

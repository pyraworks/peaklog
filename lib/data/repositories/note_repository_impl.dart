import '../../core/database/database_helper.dart';
import '../../core/models/note.dart';
import '../../domain/repositories/note_repository.dart';

class NoteRepositoryImpl implements NoteRepository {
  const NoteRepositoryImpl._();
  static const NoteRepositoryImpl instance = NoteRepositoryImpl._();

  @override
  Future<List<Note>> getNotesByDate(int dayEpoch) =>
      DatabaseHelper.instance.getNotesByDate(dayEpoch);

  @override
  Future<Note> insert(Note note) async {
    await DatabaseHelper.instance.insertNote(note);
    return note;
  }

  @override
  Future<void> update(Note note) => DatabaseHelper.instance.updateNote(note);

  @override
  Future<void> softDelete(String id) =>
      DatabaseHelper.instance.softDeleteNote(id);
}

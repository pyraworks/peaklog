import '../../core/models/note.dart';

abstract class NoteRepository {
  Future<List<Note>> getNotesByDate(int dayEpoch);
  Future<List<Note>> getNotesByDateRange(int startMs, int endMs);
  Future<Note> insert(Note note);
  Future<void> update(Note note);
  Future<void> softDelete(String id);
}

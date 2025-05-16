import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'package:studyflow_v2/classes/note.dart';

class NoteState extends ChangeNotifier {
  List<Note> _notes = [];
  List<Note> get notes => _notes;
  Logger logger = Logger();

  CollectionReference<Note> get notesCollection {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('User not logged in');
    }
    return FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('notes')
        .withConverter<Note>(
          fromFirestore: Note.fromFirestore,
          toFirestore: (Note note, SetOptions? options) => note.toFirestore(),
        );
  }

  NoteState() {
    fetchNotes();
  }

  Future<void> fetchNotes() async {
    try {
      final snapshot = await notesCollection.get();
      _notes = snapshot.docs.map((doc) => doc.data()).toList();
      notifyListeners();
    } catch (e) {
      logger.e('Error fetching notes: $e');
    }
  }

  Future<void> addNote(Note note) async {
    try {
      final docRef = await notesCollection.add(note);
      final newNote = Note(
          id: docRef.id,
          title: note.title,
          content: note.content,
          pinned: note.pinned);
      _notes.add(newNote);
      notifyListeners();
    } catch (e) {
      logger.e('Error adding note: $e');
    }
  }

  Future<void> updateNote(Note updatedNote) async {
    try {
      await notesCollection.doc(updatedNote.id).update({
        'title': updatedNote.title,
        'content': updatedNote.content,
        'pinned': updatedNote.pinned,
      });
      final index = _notes.indexWhere((note) => note.id == updatedNote.id);
      if (index != -1) {
        _notes[index] = updatedNote;
        notifyListeners();
      }
    } catch (e) {
      logger.e('Error updating note: $e');
    }
  }

  Future<void> deleteNote(String noteId) async {
    try {
      await notesCollection.doc(noteId).delete();
      _notes.removeWhere((note) => note.id == noteId);
      notifyListeners();
    } catch (e) {
      logger.e('Error deleting note: $e');
    }
  }

  Future<void> pinNote(String noteId, bool pinned) async {
    try {
      await notesCollection.doc(noteId).update({'pinned': pinned});
      final index = _notes.indexWhere((note) => note.id == noteId);
      if (index != -1) {
        _notes[index] = _notes[index].copyWith(pinned: pinned);
        notifyListeners();
      }
    } catch (e) {
      logger.e('Error pinning note: $e');
    }
  }
}

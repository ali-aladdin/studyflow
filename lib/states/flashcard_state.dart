import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'package:studyflow_v2/classes/flashcard.dart';

class FlashcardState extends ChangeNotifier {
  List<Flashcard> _cards = [];
  List<Flashcard> get cards => _cards;
  Logger logger = Logger();

  // Firestore collection reference
  CollectionReference<Flashcard> get flashcardsCollection {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('User not logged in'); // Or handle this appropriately
    }
    return FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('flashcards') // Changed collection name
        .withConverter<Flashcard>(
          fromFirestore: Flashcard.fromFirestore,
          toFirestore: (Flashcard flashcard, SetOptions? options) =>
              flashcard.toFirestore(),
        );
  }

  FlashcardState() {
    fetchFlashcards();
  }

  // Fetch flashcards from Firestore
  Future<void> fetchFlashcards() async {
    try {
      final snapshot = await flashcardsCollection.get();
      _cards = snapshot.docs.map((doc) => doc.data()).toList();
      notifyListeners();
    } catch (e) {
      logger.e('Error fetching flashcards: $e');
      // Handle error (e.g., show a message to the user)
    }
  }

  // Add a new flashcard to Firestore
  Future<void> addCard(Flashcard newCard) async {
    try {
      final docRef = await flashcardsCollection.add(newCard);
      final newFlashcard = Flashcard(
          id: docRef.id,
          title: newCard.title,
          content: newCard.content,
          pinned: newCard.pinned); //get ID
      _cards.add(newFlashcard);
      notifyListeners();
    } catch (e) {
      logger.e('Error adding flashcard: $e');
      // Handle error
    }
  }

  void deleteCard(Flashcard cardToDelete) async {
    try {
      await flashcardsCollection.doc(cardToDelete.id).delete();
      _cards.removeWhere((card) => card.id == cardToDelete.id);
      notifyListeners();
    } catch (e) {
      logger.e('Error deleting flashcard: $e');
    }
  }

  Future<void> editCardTitle(String id, String newTitle) async {
    try {
      await flashcardsCollection.doc(id).update({'title': newTitle});
      final index = _cards.indexWhere((card) => card.id == id);
      if (index != -1) {
        _cards[index] = _cards[index].copyWith(title: newTitle);
        notifyListeners();
      }
    } catch (e) {
      logger.e('Error updating flashcard title: $e');
    }
  }

  Future<void> editCardContent(String id, String newContent) async {
    try {
      await flashcardsCollection.doc(id).update({'content': newContent});
      final index = _cards.indexWhere((card) => card.id == id);
      if (index != -1) {
        _cards[index] = _cards[index].copyWith(content: newContent);
        notifyListeners();
      }
    } catch (e) {
      logger.e('Error updating flashcard content: $e');
    }
  }

  Future<void> pinCard(String cardId, bool pinned) async {
    try {
      await flashcardsCollection.doc(cardId).update({'pinned': pinned});
      final index = _cards.indexWhere((card) => card.id == cardId);
      if (index != -1) {
        _cards[index] = _cards[index].copyWith(pinned: pinned);
        notifyListeners();
      }
    } catch (e) {
      logger.e('Error pinning flashcard: $e');
      // Handle error.  You might want to show a message to the user.
    }
  }
}

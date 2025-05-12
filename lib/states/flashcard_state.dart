import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'package:studyflow_v2/classes/flashcard.dart';

class FlashcardState extends ChangeNotifier {
  List<Flashcard> _cards = [];
  List<Flashcard> get cards => _cards;
  Logger logger = Logger();

  // Firestore collection reference for the current user's flashcards
  CollectionReference<Flashcard> get flashcardsCollection {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('User not logged in'); // Or handle this appropriately
    }
    return FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('flashcards')
        .withConverter<Flashcard>(
          fromFirestore: Flashcard.fromFirestore,
          toFirestore: (Flashcard flashcard, SetOptions? options) =>
              flashcard.toFirestore(),
        );
  }

  // Fetch flashcards from Firestore for the current user
  Future<void> fetchFlashcards() async {
    try {
      final snapshot = await flashcardsCollection.get();
      _cards = snapshot.docs.map((doc) => doc.data()).toList();
      notifyListeners();
    } catch (e) {
      logger.e('Error fetching flashcards: $e');
      _cards = []; // Ensure an empty list in case of error
      notifyListeners();
      // Handle error (e.g., show a message to the user)
    }
  }

  // Add a new flashcard to Firestore for the current user
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

  // Update an existing flashcard in Firestore
  Future<void> updateCard(Flashcard updatedCard) async {
    try {
      await flashcardsCollection.doc(updatedCard.id).update({
        'title': updatedCard.title,
        'content': updatedCard.content,
        'pinned': updatedCard.pinned,
      });
      final index = _cards.indexWhere((card) => card.id == updatedCard.id);
      if (index != -1) {
        _cards[index] = updatedCard;
        notifyListeners();
      }
    } catch (e) {
      logger.e('Error updating flashcard: $e');
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
      // Handle error. You might want to show a message to the user.
    }
  }
}

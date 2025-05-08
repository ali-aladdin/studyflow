import 'package:cloud_firestore/cloud_firestore.dart';

class Flashcard {
  final String id;
  final String title;
  final String content;
  bool pinned;
  Flashcard({
    required this.id,
    required this.title,
    required this.content,
    this.pinned = false,
  });
  Flashcard copyWith({
    String? id,
    String? title,
    String? content,
    bool? pinned,
  }) {
    return Flashcard(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      pinned: pinned ?? this.pinned,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'content': content,
      'pinned': pinned,
    };
  }

  factory Flashcard.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? options,
  ) {
    final data = snapshot.data();
    return Flashcard(
      id: snapshot.id,
      title: data?['title'] ?? '',
      content: data?['content'] ?? '',
      pinned: data?['pinned'] ?? false,
    );
  }
}

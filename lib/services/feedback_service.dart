import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

enum FeedbackCategory { bug, idea, feature, other }

extension FeedbackCategoryX on FeedbackCategory {
  String get emoji {
    switch (this) {
      case FeedbackCategory.bug:     return '🐛';
      case FeedbackCategory.idea:    return '💡';
      case FeedbackCategory.feature: return '✨';
      case FeedbackCategory.other:   return '💬';
    }
  }

  String get storageValue => name;
}

/// Invia il feedback dell'utente su Firestore.
/// Scrittura sola andata: l'app non rilegge mai la collection `feedback`,
/// viene consultata manualmente dalla Firebase Console.
class FeedbackService {
  FeedbackService._();
  static final instance = FeedbackService._();

  final _db = FirebaseFirestore.instance;

  Future<void> submit({
    required FeedbackCategory category,
    required String text,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    await _db.collection('feedback').add({
      'category': category.storageValue,
      'text': text.trim(),
      'uid': user?.uid,
      'email': user?.email,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}

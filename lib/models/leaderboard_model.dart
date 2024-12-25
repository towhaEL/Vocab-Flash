import 'package:cloud_firestore/cloud_firestore.dart';

class Leaderboard {
  final String email;
  final int totalPoints;
  final int wordsLearned;
  final int correctAnswers;
  final int questionAttended;
  final bool owner;

  Leaderboard({
    required this.email,
    required this.totalPoints,
    required this.wordsLearned,
    required this.correctAnswers,
    required this.questionAttended,
    required this.owner,
  });

  // Factory method to create a Leaderboard from Firestore document
  factory Leaderboard.fromFirestore(DocumentSnapshot doc) {
    var data = doc.data() as Map<String, dynamic>;

    return Leaderboard(
      email: data['email'] ?? '',
      totalPoints: data['totalPoints'] ?? 0,
      wordsLearned: data['wordsLearned'] ?? 0,
      correctAnswers: data['correctAnswers'] ?? 0,
      questionAttended: data['questionAttended'] ?? 0,
      owner: data['owner'] ?? false,
    );
  }
}

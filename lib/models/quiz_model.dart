import 'package:cloud_firestore/cloud_firestore.dart';

class QuizModel {
  final double accuracy;
  final int score;
  final Timestamp dateTime;

  QuizModel({
    required this.accuracy,
    required this.score,
    required this.dateTime,
  });
}
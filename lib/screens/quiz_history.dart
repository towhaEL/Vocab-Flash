import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firestore_service.dart';

class QuizHistory extends StatefulWidget {
  @override
  _QuizHistoryState createState() => _QuizHistoryState();
}

class _QuizHistoryState extends State<QuizHistory> {
  final FirestoreService _firestoreService = FirestoreService();
  bool _isLoading = true;
  List<QueryDocumentSnapshot> _quizDocs = [];

  @override
  void initState() {
    super.initState();
    _fetchQuizHistory();
  }

  Future<void> _fetchQuizHistory() async {
    try {
      List<QueryDocumentSnapshot> quizDocs = await _firestoreService.getQuizResults();
      setState(() {
        _quizDocs = quizDocs;
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching quiz history: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildQuizCard(QueryDocumentSnapshot doc) {
    int score = doc['score'];
    int totalQuestions = doc['questions'];
    double accuracy = doc['accuracy'];
    Timestamp timestamp = doc['timestamp'];
    DateTime date = timestamp.toDate();
    // Determine the emoji based on the score
    IconData emoji;
    Color emojiColor;
    if (accuracy >= 80) {
      emoji = Icons.emoji_emotions;
      emojiColor = Colors.green; // Happy emoji color
    } else if (accuracy >= 50) {
      emoji = Icons.sentiment_neutral;
      emojiColor = Colors.orange; // Neutral emoji color
    } else {
      emoji = Icons.sentiment_dissatisfied;
      emojiColor = Colors.red; // Sad emoji color
    }

    return Card(
      elevation: 5,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Score: ${score}/${totalQuestions}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Text('Accuracy: ${accuracy.toStringAsFixed(2)}%', style: TextStyle(fontSize: 16)),
                SizedBox(height: 8),
                Text('Date: ${date.toLocal().toString().split(' ')[0]} ', style: TextStyle(fontSize: 16)),
              ],
            ),
            Icon(emoji, size: 50, color: emojiColor),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Quiz History'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _quizDocs.length,
              itemBuilder: (context, index) {
                return _buildQuizCard(_quizDocs[index]);
              },
            ),
    );
  }
}
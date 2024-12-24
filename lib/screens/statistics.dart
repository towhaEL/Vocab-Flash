import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:vocabflashcard_app/screens/quiz_history.dart';
import '../services/firestore_service.dart';

class Statistics extends StatefulWidget {
  @override
  _StatisticsState createState() => _StatisticsState();
}

class _StatisticsState extends State<Statistics> {
  final FirestoreService _firestoreService = FirestoreService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  int _totalWords = 0;
  int _memorizedWords = 0;
  int _viewedWords = 0;
  int _currentStreak = 0;
  int _longestStreak = 0;
  int _quizAttempted = 0;
  int _highScore = 0;
  int _maxQues = 0;

  double _averageScore = 0.0;

  Map<String, int> _weeklyWordCount = {
    'Mon': 0,
    'Tue': 0,
    'Wed': 0,
    'Thu': 0,
    'Fri': 0,
    'Sat': 0,
    'Sun': 0,
  };
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchStatistics();
  }

  Future<void> _fetchStatistics() async {
    User? user = _auth.currentUser;
    if (user != null) {
      int totalWords = await _firestoreService.getTotalWords();
      int memorizedWords = await _firestoreService.getLearnedWords(user.uid);
      int viewedWords = await _firestoreService.getViewedWords(user.uid);
      Map<String, dynamic> streaks = await _firestoreService.getStreaks();
      Map<String, int> weeklyWordCount = await _firestoreService.getWeeklyWordCount();
      List<QueryDocumentSnapshot> quizDocs = await _firestoreService.getQuizResults();

      int highScore = 0;
      double totalScore = 0.0;
      int quesCount = 0;
      int maxQues = 0;

      for (var doc in quizDocs) {
        int score = doc['score'];
        if (score > highScore) {
          highScore = score;
          int highQuesCount = doc['questions'];
          maxQues = highQuesCount;
        }
        totalScore += score;
        int qCount = doc['questions'];
        quesCount += qCount;
      }


      setState(() {
        _totalWords = totalWords;
        _memorizedWords = memorizedWords;
        _viewedWords = viewedWords;
        _currentStreak = streaks['current_streak'];
        _longestStreak = streaks['longest_streak'];
        _quizAttempted = quizDocs.length;
        _highScore = highScore;
        _averageScore = totalScore / quesCount;
        _maxQues = maxQues;
        _weeklyWordCount = weeklyWordCount;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(),
      );
    }

    return ListView(
      children: [
        SizedBox(height: 16),
        Container(
          color: Colors.grey.shade100,
          padding: EdgeInsets.all(5),
          margin: EdgeInsets.all(5),
          child: _buildVocabularyStatistics(context)),
        SizedBox(height: 16),
        Container(
          color: Colors.grey.shade100,
          padding: EdgeInsets.all(5),
          margin: EdgeInsets.all(5),
          child: _buildDailyStreak(context)),
        SizedBox(height: 16),
        Container(
          color: Colors.grey.shade100,
          padding: EdgeInsets.all(5),
          margin: EdgeInsets.all(5),
          child: _buildQuizPerformance(context)),
      ],
    );
  }

  Widget _buildVocabularyStatistics(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Vocabulary Statistics', style: Theme.of(context).textTheme.headlineSmall),
        SizedBox(height: 16),
        Row(
          children: [
            Column(
              children: [
                _buildStatisticCard('Total', '$_totalWords words', Colors.white),
                _buildStatisticCard('Memorized', '$_memorizedWords words', Colors.green),
                _buildStatisticCard('Viewed', '$_viewedWords words', Colors.blue),
              ],
            ),
            Expanded(child: Column(
              children: [
                _buildPieChart(),
                SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      height: 12,
                      width: 12,
                      color: Colors.red,
                    ),
                    Text('  Remaining words ${_totalWords - _memorizedWords - _viewedWords}'),
                  ],
                ),
              ],
            )),
          ],
        ),
      ],
    );
  }

  Widget _buildStatisticCard(String title, String value, [Color clr = Colors.white]) {
    return Container(
      width: 120,
      child: Card(
        color: clr,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text(value, style: TextStyle(fontSize: 16)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPieChart() {
    return SizedBox(
      height: 200,
      child: PieChart(
        PieChartData(
          sections: [
            PieChartSectionData(value: _memorizedWords.toDouble(), color: Colors.green, title: 'M'),
            PieChartSectionData(value: _viewedWords.toDouble(), color: Colors.blue, title: 'V'),
            PieChartSectionData(value: (_totalWords - _memorizedWords - _viewedWords).toDouble(), color: Colors.red, title: 'R'),
          ],
        ),
      ),
    );
  }

  Widget _buildQuizPerformance(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Quiz Performance', style: Theme.of(context).textTheme.headlineSmall),
        SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          children: [
            Card(
              elevation: 5,
              color: Colors.grey,
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => QuizHistory()),
                  );
                },
                child: _buildStatisticCard('Quizzes Attempted', '${_quizAttempted}', Colors.grey.shade200),
              ),
            ),
            _buildStatisticCard('Average Score', '${_averageScore.toStringAsFixed(2)}%'),
            _buildStatisticCard('High Score', '${_highScore}/${_maxQues}'),
            // _buildStatisticCard('Accuracy', '90%'),
          ],
        ),
        SizedBox(height: 16),
      ],
    );
  }

 
  Widget _buildDailyStreak(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Daily Streak', style: Theme.of(context).textTheme.headlineSmall),
        SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Expanded(child: _buildStatisticCard('Current Streak', '$_currentStreak days')),
            Expanded(child: _buildStatisticCard('Longest Streak', '$_longestStreak days')),
          ],
        ),
        SizedBox(height: 16),
        _buildWeeklyCalendar(),
      ],
    );
  }

  Widget _buildWeeklyCalendar() {
    return Table(
      border: TableBorder.all(color: Colors.black),
      children: [
        TableRow(
          children: _weeklyWordCount.keys.map((day) {
            return Container(
              padding: const EdgeInsets.all(8.0),
              color: _getColorForWordsLearned(_weeklyWordCount[day]!),
              child: Column(
                children: [
                  Text(day, style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Text('${_weeklyWordCount[day]} words'),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Color _getColorForWordsLearned(int wordsLearned) {
    if (wordsLearned >= 6) {
      return Colors.green[700]!;
    } else if (wordsLearned >= 4) {
      return Colors.green[500]!;
    } else if (wordsLearned >= 2) {
      return Colors.green[300]!;
    } else {
      return Colors.lightGreen[100]!;
    }
  }
}
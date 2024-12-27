import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tuple/tuple.dart';
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
  int dailyGoal = 0;

  double _averageScore = 0.0;

  Map<String, Tuple2<int, bool>> _weeklyWordCount = {
    'Mon': Tuple2(0, false),
    'Tue': Tuple2(0, false),
    'Wed': Tuple2(0, false),
    'Thu': Tuple2(0, false),
    'Fri': Tuple2(0, false),
    'Sat': Tuple2(0, false),
    'Sun': Tuple2(0, false),
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
      // int daily_goal = await _firestoreService.getDailyGoal();
      int memorizedWords = await _firestoreService.getLearnedWords(user.uid);
      int viewedWords = await _firestoreService.getViewedWords(user.uid);
      Map<String, dynamic> streaks = await _firestoreService.getStreaks();
      Map<String, Tuple2<int, bool>> weeklyWordCount = await _firestoreService.getWeeklyWordCount();
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
        // dailyGoal = daily_goal;
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

  void _dailyGoal() {
    final TextEditingController _passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Set Daily Goal'),
        content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: "Enter your daily goal for learning new words",
                    // style: TextStyle(color: Colors.black),
                  ),
                  TextSpan(
                    text: "\nYour streak will reset.",
                    style: TextStyle(color: Colors.red),
                  ),
                  // TextSpan(
                  //   text: "\n\nCurrent goal: $dailyGoal words per day",
                  // ),
                ],
              ),
            ),
          SizedBox(height: 10.0),
          TextField(
              controller: _passwordController,
              keyboardType: TextInputType.number, // Set the keyboard type to numbers only
              inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly, // Allow only numeric input
              ],
              decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Daily goal',
              ),
          ),
        ],
      ),
        actions: [
          TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Cancel'),
        ),
        TextButton(
          onPressed: () async {
            final password = _passwordController.text;
            if (password.isNotEmpty) {
              await _firestoreService.setDailyGoal(int.parse(password));
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Daily goal updated!')),
              );
               // Call delete logic
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Input is not correct!')),
              );
            }
          },
          child: Text('Submit'),
        ),
        ],
      ),
    );
  }

  Color mixColorsFromInts(Color color1, Color color2, int value1, int value2) {
  final total = (value1 + value2).toDouble();
  final factor = value1 / total; // Calculate the interpolation factor
  return Color.lerp(color1, color2, factor)!; // Interpolate between the two colors
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
        Card(
          margin: EdgeInsets.all(6),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: _buildVocabularyStatistics(context),
          )),
        SizedBox(height: 16),
        Card(
          margin: EdgeInsets.all(6),
          child: Padding(
            padding: const EdgeInsets.all(5.0),
            child: _buildDailyStreak(context),
          )),
        SizedBox(height: 16),
        Card(
          margin: EdgeInsets.all(6),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: _buildQuizPerformance(context),
          )),
      ],
    );
  }

  Widget _buildVocabularyStatistics(BuildContext context) {
    final mixedColor = mixColorsFromInts(Colors.blue, Colors.green, _memorizedWords, _viewedWords-_memorizedWords);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Vocabulary Statistics ', style: Theme.of(context).textTheme.headlineSmall),
            Icon(Icons.calendar_view_month_outlined)
          ],
        ),
        SizedBox(height: 16),
        Row(
          children: [
            Column(
              children: [
                _buildStatisticCard('Total', '$_totalWords words', Colors.grey.shade100),
                _buildStatisticCard('Memorized', '$_memorizedWords words', Colors.blue),
                _buildStatisticCard('Viewed', '${_viewedWords} words', mixedColor),
              ],
            ),
            Expanded(child: Column(
              children: [
                _buildPieChart(),
                SizedBox(height: 16),
                Row(
                  children: [
                    Spacer(),
                    Container(
                      decoration: BoxDecoration(border: Border.all()),
                      child: Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                        children: [
                          Container(
                            height: 12,
                            width: 12,
                            color: Colors.red,
                          ),
                          Text('  Remaining ${_totalWords - _viewedWords} words'),
                        ],
                                        ),
                                        Row(
                        children: [
                          Container(
                            height: 12,
                            width: 12,
                            color: Colors.blue,
                          ),
                          Text('  Memorized ${_memorizedWords} words'),
                        ],
                                        ),
                                        Row(
                                          
                        children: [
                          Container(
                            height: 12,
                            width: 12,
                            color: Colors.green,
                          ),
                          Container(
                            height: 12,
                            width: 12,
                            color: Colors.blue,
                          ),
                          Text('  Viewed ${_viewedWords} words'),
                        ],
                                        ),
                          ],
                        ),
                      ),
                    ),
                  ],
                )
              ],
            )),
          ],
        ),
      ],
    );
  }

  Widget _buildStatisticCard(String title, String value, [Color clr = Colors.deepPurpleAccent]) {
    return Container(
      width: 120,
      child: Card(
        elevation: 5,
        color: clr,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black)),
              SizedBox(height: 8),
              Text(value, style: TextStyle(fontSize: 16, color: Colors.black)),
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
            PieChartSectionData(value: _memorizedWords.toDouble(), color: Colors.blue, titleStyle: TextStyle(color: Colors.black),showTitle: true),
            PieChartSectionData(value: (_viewedWords - _memorizedWords).toDouble(), color: Colors.green, titleStyle: TextStyle(color: Colors.black),showTitle: true),
            PieChartSectionData(value: (_totalWords - _viewedWords).toDouble(), color: Colors.red, titleStyle: TextStyle(color: Colors.black),showTitle: true),
          ],
        ),
      ),
    );
  }

  Widget _buildQuizPerformance(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Quiz Performance ', style: Theme.of(context).textTheme.headlineSmall),
            Icon(Icons.trending_up),
          ],
        ),
        SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          children: [
            Card(
              elevation: 5,
              color: Colors.deepPurple,
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => QuizHistory()),
                  );
                },
                child: _buildStatisticCard('Quizzes Attempted', '${_quizAttempted}', Colors.deepPurpleAccent),
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
        Row(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text('Daily Goal ', style: Theme.of(context).textTheme.headlineSmall),
            ),
            Icon(Icons.check_circle),
            Spacer(),
            ElevatedButton(
              onPressed: () {
                _dailyGoal();
              },
              child: Text('Set Daily Goal')
              )
          ],
        ),
        SizedBox(height: 8),
        _buildWeeklyCalendar(),
        SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Expanded(child: _buildStatisticCard('Current Streak', '$_currentStreak days')),
            Expanded(child: _buildStatisticCard('Longest Streak', '$_longestStreak days')),
          ],
        ),
        SizedBox(height: 16,),
      ],
    );
  }

  Widget _buildWeeklyCalendar() {
    return Table(
      border: TableBorder.all(width: 1.5, borderRadius: BorderRadius.circular(5)),
      children: [
        TableRow(
          children: _weeklyWordCount.keys.map((day) {
            return Container(
              padding: const EdgeInsets.all(8.0),
              color: (day == DateFormat('E').format(DateTime.now()))? 
                Colors.deepPurple[500]
                : Colors.deepPurple[300],
              // color: _getColorForWordsLearned(_weeklyWordCount[day]!.item1),
              child: Column(
                children: [
                  (_weeklyWordCount[day]!.item2)? Icon(Icons.check, color: Colors.green,) : Icon(Icons.cancel_outlined, color: Colors.red,),
                  SizedBox(height: 4,),
                  Text(day, style: TextStyle(fontWeight: FontWeight.bold, )),
                  Text('${_weeklyWordCount[day]?.item1}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, ),),
                  Text('words',),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Color _getColorForWordsLearned(int wordsLearned) {
    if (wordsLearned >= 15) {
      return Colors.deepPurple[700]!;
    } else if (wordsLearned >= 10) {
      return Colors.deepPurple[500]!;
    } else if (wordsLearned >= 5) {
      return Colors.deepPurple[400]!;
    } else {
      return Colors.deepPurple[300]!;
    }
  }
}
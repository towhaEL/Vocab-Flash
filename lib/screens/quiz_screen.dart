import 'package:flutter/material.dart';
import 'dart:math';
import 'package:flutter_tts/flutter_tts.dart';
import '../services/firestore_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class QuizScreen extends StatefulWidget {
  final List<String> selectedLetters;
  final int numberOfQuestions;

  QuizScreen({required this.selectedLetters, required this.numberOfQuestions});

  @override
  _QuizScreenState createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  List<Question> _questions = [];
  List<int?> _selectedAnswers = [];
  bool _isLoading = true;
  final FlutterTts _flutterTts = FlutterTts();
  final FirestoreService _firestoreService = FirestoreService();

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    try {
      List<Question> questions = [];
      Random random = Random();
      Set<String> usedWords = Set();

      // Fetch vocabulary words from Firestore using FirestoreService
      List<QueryDocumentSnapshot> vocabDocs = await _firestoreService.getVocabulary();

      // Log the number of documents fetched
      print('Fetched ${vocabDocs.length} vocabulary documents.');

      // Log the structure of the first document to inspect field names
      if (vocabDocs.isNotEmpty) {
        print('First document data: ${vocabDocs.first.data()}');
      }

      // Filter vocabulary words based on selected letters
      List<QueryDocumentSnapshot> filteredVocabDocs = vocabDocs.where((doc) {
        String word = doc['name'];
        return widget.selectedLetters.contains(word[0].toUpperCase());
      }).toList();

      // Log the number of filtered documents
      print('Filtered to ${filteredVocabDocs.length} vocabulary documents based on selected letters.');

      if (filteredVocabDocs.isEmpty) {
        throw Exception('No vocabulary words found for the selected letters.');
      }

      // Generate questions
      for (int i = 0; i < widget.numberOfQuestions; i++) {
        // Select a random word that has not been used yet
        QueryDocumentSnapshot correctDoc;
        String correctWord;
        do {
          correctDoc = filteredVocabDocs[random.nextInt(filteredVocabDocs.length)];
          correctWord = correctDoc['name'];
        } while (usedWords.contains(correctWord));

        usedWords.add(correctWord);
        String correctDefinition = correctDoc['definition'];

        // Select three incorrect definitions
        List<String> incorrectDefinitions = [];
        while (incorrectDefinitions.length < 3) {
          QueryDocumentSnapshot incorrectDoc = vocabDocs[random.nextInt(vocabDocs.length)];
          String incorrectDefinition = incorrectDoc['definition'];
          if (incorrectDefinition != correctDefinition && !incorrectDefinitions.contains(incorrectDefinition)) {
            incorrectDefinitions.add(incorrectDefinition);
          }
        }

        // Create a question
        List<String> options = [correctDefinition, ...incorrectDefinitions];
        options.shuffle();
        int correctOptionIndex = options.indexOf(correctDefinition);

        questions.add(Question(
          word: correctWord,
          options: options,
          correctOptionIndex: correctOptionIndex,
        ));
      }

      setState(() {
        _questions = questions;
        _selectedAnswers = List<int?>.filled(_questions.length, null);
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading questions: $e');
      setState(() {
        _isLoading = false;
      });
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Error'),
          content: Text('Failed to load questions. Please try again later.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _speak(String word) async {
    try {
      await _flutterTts.setLanguage("en-US");
      await _flutterTts.setPitch(1.0);
      await _flutterTts.speak(word);
    } catch (e) {
      print("Error in TTS: $e");
    }
  }

  void _submitQuiz() async {
    int score = 0;
    for (int i = 0; i < _questions.length; i++) {
      if (_selectedAnswers[i] == _questions[i].correctOptionIndex) {
        score++;
      }
    }
    double accuracy = (score / widget.numberOfQuestions) * 100;
    int ques_num = widget.numberOfQuestions;

    // Store quiz data in Firestore using FirestoreService
    await _firestoreService.saveQuizResult(score, ques_num, accuracy,);

    _showResults(score, accuracy);
  }

  void _showResults(int score, double accuracy) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => QuizResultsScreen(score: score, totalQuestions: widget.numberOfQuestions, accuracy: accuracy),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Choose the Correct Definition'),
        ),
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Choose the Correct Definition'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            ..._questions.asMap().entries.map((entry) {
              int questionIndex = entry.key;
              Question question = entry.value;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Question ${questionIndex + 1} of ${widget.numberOfQuestions}', style: Theme.of(context).textTheme.headlineSmall),
                        SizedBox(height: 8),
                        Row(
                          children: [
                            Text(question.word, style: Theme.of(context).textTheme.headlineMedium),
                            IconButton(
                              icon: Icon(Icons.volume_up),
                              onPressed: () => _speak(question.word),
                            ), 
                          ],
                        ),
                        SizedBox(height: 4),
                        ...question.options.asMap().entries.map((optionEntry) {
                          int optionIndex = optionEntry.key;
                          String option = optionEntry.value;
                          return ListTile(
                            title: Text(option),
                            leading: Radio<int>(
                              value: optionIndex,
                              groupValue: _selectedAnswers[questionIndex],
                              onChanged: (int? value) {
                                setState(() {
                                  _selectedAnswers[questionIndex] = value;
                                });
                              },
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                ],
              );
            }).toList(),
            Center(
              child: ElevatedButton(
                onPressed: _submitQuiz,
                child: Text('Submit Quiz'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class Question {
  final String word;
  final List<String> options;
  final int correctOptionIndex;

  Question({required this.word, required this.options, required this.correctOptionIndex});
}

class QuizResultsScreen extends StatelessWidget {
  final int score;
  final int totalQuestions;
  final double accuracy;

  QuizResultsScreen({required this.score, required this.totalQuestions, required this.accuracy});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Quiz Results'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text('Quiz Completed!', style: Theme.of(context).textTheme.headlineMedium),
              SizedBox(height: 16),
              Text('Your Score: $score / $totalQuestions', style: Theme.of(context).textTheme.headlineSmall),
              SizedBox(height: 16),
              Text('You scored ${accuracy.toStringAsFixed(2)}%', style: Theme.of(context).textTheme.titleLarge),
              SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text('Back to Practice'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
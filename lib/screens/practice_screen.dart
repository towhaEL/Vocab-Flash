import 'package:flutter/material.dart';
import 'quiz_screen.dart';

class PracticeScreen extends StatefulWidget {
  @override
  _PracticeScreenState createState() => _PracticeScreenState();
}

class _PracticeScreenState extends State<PracticeScreen> {
  List<String> _letters = List.generate(26, (index) => String.fromCharCode(index + 65));
  List<bool> _selectedLetters = List.generate(26, (index) => false);
  bool _selectAll = false;
  int _numberOfQuestions = 5;
  final List<int> _questionOptions = [5, 10, 15, 20];

  void _toggleSelectAll(bool? value) {
    setState(() {
      _selectAll = value ?? false;
      for (int i = 0; i < _selectedLetters.length; i++) {
        _selectedLetters[i] = _selectAll;
      }
    });
  }

  void _toggleLetterSelection(int index, bool? value) {
    setState(() {
      _selectedLetters[index] = value ?? false;
      _selectAll = _selectedLetters.every((element) => element);
    });
  }

  void _startQuiz() {
    if (_selectedLetters.every((element) => !element)) {
      // Show a dialog or snackbar if no letters are selected
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('No Letters Selected'),
          content: Text('Please select at least one letter to start the quiz.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    // Navigate to the quiz screen with the selected letters and number of questions
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QuizScreen(
          selectedLetters: _letters.asMap().entries.where((entry) => _selectedLetters[entry.key]).map((entry) => entry.value).toList(),
          numberOfQuestions: _numberOfQuestions,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Practice Quiz', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.deepPurpleAccent,
        elevation: 5.0,
        // foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(30.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Select Letters to Practice', style: Theme.of(context).textTheme.titleLarge),
            Row(
              children: [
                Checkbox(
                  value: _selectAll,
                  onChanged: _toggleSelectAll,
                ),
                Text('Select All'),
              ],
            ),
            Expanded(
              child: GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 6),
                itemCount: _letters.length,
                itemBuilder: (context, index) {
                  return Row(
                    children: [
                      Checkbox(
                        value: _selectedLetters[index],
                        onChanged: (value) => _toggleLetterSelection(index, value),
                      ),
                      Text(_letters[index]),
                    ],
                  );
                },
              ),
            ),
            SizedBox(height: 16),
            Text('Number of Questions', style: Theme.of(context).textTheme.titleLarge),
            DropdownButton<int>(
              value: _numberOfQuestions,
              onChanged: (value) {
                setState(() {
                  _numberOfQuestions = value!;
                });
              },
              items: _questionOptions.map((int value) {
                return DropdownMenuItem<int>(
                  value: value,
                  child: Text(value.toString()),
                );
              }).toList(),
            ),
            SizedBox(height: 16),
            Center(
              child: ElevatedButton(
                onPressed: _startQuiz,
                child: Text('Start Quiz'),
              ),
            ),
            SizedBox(height: 64),
          ],
        ),
      ),
    );
  }
}
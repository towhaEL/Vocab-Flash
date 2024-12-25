import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/vocabulary_model.dart';
import '../widgets/flashcard.dart';
import '../services/firestore_service.dart';

class FlashcardScreen extends StatefulWidget {
  @override
  _FlashcardScreenState createState() => _FlashcardScreenState();
}

class _FlashcardScreenState extends State<FlashcardScreen> {
  late List<Vocabulary> _vocabularyList;
  int _currentIndex = 0;
  bool _isFlipped = false;
  double _dragStartX = 0.0;
  double _dragUpdateX = 0.0;
  String _swipeDirection = '';
  bool _isLoading = true;
  final FirestoreService _firestoreService = FirestoreService();
  bool _isUndoVisible = false;
  Vocabulary? _lastRemovedVocab;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final String letter = ModalRoute.of(context)!.settings.arguments as String;
    _fetchVocabulary(letter);
  }

  Future<void> _fetchVocabulary(String letter) async {
    final List<String> memorizedWords = await _firestoreService.fetchMemorizedVocabulary();
    final QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('vocabulary')
        .where('name', isGreaterThanOrEqualTo: letter)
        .where('name', isLessThan: letter + 'z')
        .get();

    setState(() {
      _vocabularyList = snapshot.docs.map((doc) {
        return Vocabulary(
          name: doc['name'],
          definition: doc['definition'],
          synonyms: List<String>.from(doc['synonyms']),
          example: doc['example'],
          pronunciation: doc['pronunciation'],
        );
      }).where((vocab) => !memorizedWords.contains(vocab.name)).toList();
      _isLoading = false;
    });
  }

  void _flipCard() {
    setState(() {
      _isFlipped = !_isFlipped;
      if (_isUndoVisible) {
        _hideUndo();
      }
    });
  }

  void _nextCard() {
    setState(() {
      _isFlipped = false;
      _currentIndex = (_currentIndex + 1) % _vocabularyList.length;
    });
  }

  void _removeCard() {
    setState(() {
      _isFlipped = false;
      _lastRemovedVocab = _vocabularyList.removeAt(_currentIndex);
      if (_vocabularyList.isNotEmpty) {
        _currentIndex = _currentIndex % _vocabularyList.length;
      } else {
        Navigator.pop(context);
      }
    });
  }

  void _onHorizontalDragStart(DragStartDetails details) {
    _dragStartX = details.globalPosition.dx;
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    setState(() {
      _dragUpdateX = details.globalPosition.dx - _dragStartX;
      _swipeDirection = _dragUpdateX > 0 ? 'Next' : 'Remove';
    });
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    if (_dragUpdateX > 100) {
      // Swiped right
      _memorizeWord();
    } else if (_dragUpdateX < -100) {
      // Swiped left
      // _nextCard();
      _viewWord();
    }
    setState(() {
      _dragUpdateX = 0.0;
      _swipeDirection = '';
    });
  }

  void _viewWord() {
    _firestoreService.addVocabularyToViewed(_vocabularyList[_currentIndex]);
    _nextCard();
  }

  void _memorizeWord() {
    _firestoreService.addVocabularyToMemorized(_vocabularyList[_currentIndex]);
    _firestoreService.updateDailyStreak();
    _removeCard();
    _showUndo();
  }

  void _showUndo() {
    setState(() {
      _isUndoVisible = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Word memorized'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: _undoMemorize,
        ),
        duration: Duration(microseconds: 500000),
      ),
    ).closed.then((reason) {
      if (reason != SnackBarClosedReason.action) {
        _hideUndo();
      }
    });
  }

  void _hideUndo() {
    setState(() {
      _isUndoVisible = false;
      _lastRemovedVocab = null;
    });
  }

  void _undoMemorize() {
    if (_lastRemovedVocab != null) {
      _firestoreService.removeVocabularyFromMemorized(_lastRemovedVocab!);
      setState(() {
        _vocabularyList.insert(_currentIndex, _lastRemovedVocab!);
        _lastRemovedVocab = null;
      });
    }
    _hideUndo();
  }

  Future<void> _resetMemorizedWords(String letter) async {
    await _firestoreService.clearMemorizedVocabularyForLetter(letter);
    _fetchVocabulary(letter);
  }

  void _showResetConfirmationDialog(String letter) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Reset Memorized Words'),
          content: Text('Are you sure you want to clear all memorized words for this letter?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _resetMemorizedWords(letter);
              },
              child: Text('Reset'),
            ),
          ],
        );
      },
    );
  }

  

  @override
  Widget build(BuildContext context) {
    final String letter = ModalRoute.of(context)!.settings.arguments as String;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Flashcards'),
          actions: [
            IconButton(
              icon: Icon(Icons.refresh),
              onPressed: () => _showResetConfirmationDialog(letter),
            ),
          ],
        ),
        body: GestureDetector(
          onTap: () {
            ScaffoldMessenger.of(context).clearSnackBars();
          },
          child: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    if (_vocabularyList.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Flashcards'),
          actions: [
            IconButton(
              icon: Icon(Icons.refresh),
              onPressed: () => _showResetConfirmationDialog(letter),
            ),
          ],
        ),
        body: Center(
          child: Text('No vocabulary words available for this letter.', style: TextStyle(fontSize: 18)),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Flashcards'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () => _showResetConfirmationDialog(letter),
          ),
        ],
      ),
      body: GestureDetector(
        onHorizontalDragStart: _onHorizontalDragStart,
        onHorizontalDragUpdate: _onHorizontalDragUpdate,
        onHorizontalDragEnd: _onHorizontalDragEnd,
        onTap: () {
          if (_isUndoVisible) {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            _hideUndo();
          }
        },
        child: Center(
          child: Stack(
            alignment: Alignment.center,
            children: 
            [
              Flashcard(
                  vocabulary: _vocabularyList[(_currentIndex + 1) % _vocabularyList.length], 
                  onFlip: () {}, 
                  isFlipped: false,
                  isHidden: true,
                  ),
              Transform.translate(
                offset: Offset(_dragUpdateX, 0),
                child: Transform.rotate(
                  angle: _dragUpdateX / 1000,
                  child: Flashcard(
                    key: ValueKey(_currentIndex),
                    vocabulary: _vocabularyList[_currentIndex],
                    onFlip: _flipCard,
                    isFlipped: _isFlipped,
                    isHidden: false,
                  ),
                ),
              ),
              if (_swipeDirection.isNotEmpty)
                Positioned(
                  top: 50,
                  child: Icon(
                    _swipeDirection == 'Next' ? Icons.check_circle : Icons.arrow_forward,
                    size: 48,
                    color: _swipeDirection == 'Next' ? Colors.red : Colors.green,
                  ),
                ),
            ],

          ),
        ),
      ),
    );
  }
}


// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import '../models/vocabulary_model.dart';
// import '../widgets/flashcard.dart';
// import '../services/firestore_service.dart';

// class FlashcardScreen extends StatefulWidget {
//   @override
//   _FlashcardScreenState createState() => _FlashcardScreenState();
// }

// class _FlashcardScreenState extends State<FlashcardScreen> {
//   late List<Vocabulary> _vocabularyList;
//   int _currentIndex = 0;
//   bool _isFlipped = false;
//   double _dragStartX = 0.0;
//   double _dragUpdateX = 0.0;
//   String _swipeDirection = '';
//   bool _isLoading = true;
//   final FirestoreService _firestoreService = FirestoreService();
//   bool _isUndoVisible = false;
//   Vocabulary? _lastRemovedVocab;

//   @override
//   void didChangeDependencies() {
//     super.didChangeDependencies();
//     final String letter = ModalRoute.of(context)!.settings.arguments as String;
//     _fetchVocabulary(letter);
//   }

//   Future<void> _fetchVocabulary(String letter) async {
//     final List<String> memorizedWords = await _firestoreService.fetchMemorizedVocabulary();
//     final QuerySnapshot snapshot = await FirebaseFirestore.instance
//         .collection('vocabulary')
//         .where('name', isGreaterThanOrEqualTo: letter)
//         .where('name', isLessThan: letter + 'z')
//         .get();

//     setState(() {
//       _vocabularyList = snapshot.docs.map((doc) {
//         return Vocabulary(
//           name: doc['name'],
//           definition: doc['definition'],
//           synonyms: List<String>.from(doc['synonyms']),
//           example: doc['example'],
//           pronunciation: doc['pronunciation'],
//         );
//       }).where((vocab) => !memorizedWords.contains(vocab.name)).toList();
//       _isLoading = false;
//     });
//   }

//   void _flipCard() {
//     setState(() {
//       _isFlipped = !_isFlipped;
//       if (_isUndoVisible) {
//         _hideUndo();
//       }
//     });
//   }

//   void _nextCard() {
//     setState(() {
//       _isFlipped = false;
//       _currentIndex = (_currentIndex + 1) % _vocabularyList.length;
//     });
//   }

//   void _removeCard() {
//     setState(() {
//       _isFlipped = false;
//       _lastRemovedVocab = _vocabularyList.removeAt(_currentIndex);
//       if (_vocabularyList.isNotEmpty) {
//         _currentIndex = _currentIndex % _vocabularyList.length;
//       } else {
//         Navigator.pop(context);
//       }
//     });
//   }

//   void _onHorizontalDragStart(DragStartDetails details) {
//     _dragStartX = details.globalPosition.dx;
//   }

//   void _onHorizontalDragUpdate(DragUpdateDetails details) {
//     setState(() {
//       _dragUpdateX = details.globalPosition.dx - _dragStartX;
//       _swipeDirection = _dragUpdateX > 0 ? 'Next' : 'Remove';
//     });
//   }

//   void _onHorizontalDragEnd(DragEndDetails details) {
//     if (_dragUpdateX > 100) {
//       // Swiped right
//       _memorizeWord();
//     } else if (_dragUpdateX < -100) {
//       // Swiped left
//       _viewWord();
//     }
//     setState(() {
//       _dragUpdateX = 0.0;
//       _swipeDirection = '';
//     });
//   }

//   void _viewWord() {
//     _firestoreService.addVocabularyToViewed(_vocabularyList[_currentIndex]);
//     _nextCard();
//   }

//   void _memorizeWord() {
//     _firestoreService.addVocabularyToMemorized(_vocabularyList[_currentIndex]);
//     _firestoreService.updateDailyStreak();
//     _removeCard();
//     _showUndo();
//   }

//   void _showUndo() {
//     setState(() {
//       _isUndoVisible = true;
//     });
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text('Word memorized'),
//         action: SnackBarAction(
//           label: 'Undo',
//           onPressed: _undoMemorize,
//         ),
//         duration: Duration(microseconds: 500000),
//       ),
//     ).closed.then((reason) {
//       if (reason != SnackBarClosedReason.action) {
//         _hideUndo();
//       }
//     });
//   }

//   void _hideUndo() {
//     setState(() {
//       _isUndoVisible = false;
//       _lastRemovedVocab = null;
//     });
//   }

//   void _undoMemorize() {
//     if (_lastRemovedVocab != null) {
//       _firestoreService.removeVocabularyFromMemorized(_lastRemovedVocab!);
//       setState(() {
//         _vocabularyList.insert(_currentIndex, _lastRemovedVocab!);
//         _lastRemovedVocab = null;
//       });
//     }
//     _hideUndo();
//   }

//   Future<void> _resetMemorizedWords(String letter) async {
//     await _firestoreService.clearMemorizedVocabularyForLetter(letter);
//     _fetchVocabulary(letter);
//   }

//   void _showResetConfirmationDialog(String letter) {
//     showDialog(
//       context: context,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           title: Text('Reset Memorized Words'),
//           content: Text('Are you sure you want to clear all memorized words for this letter?'),
//           actions: [
//             TextButton(
//               onPressed: () {
//                 Navigator.of(context).pop();
//               },
//               child: Text('Cancel'),
//             ),
//             TextButton(
//               onPressed: () {
//                 Navigator.of(context).pop();
//                 _resetMemorizedWords(letter);
//               },
//               child: Text('Reset'),
//             ),
//           ],
//         );
//       },
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final String letter = ModalRoute.of(context)!.settings.arguments as String;

//     if (_isLoading) {
//       return Scaffold(
//         appBar: AppBar(
//           title: Text('Flashcards'),
//           actions: [
//             IconButton(
//               icon: Icon(Icons.refresh),
//               onPressed: () => _showResetConfirmationDialog(letter),
//             ),
//           ],
//         ),
//         body: GestureDetector(
//           onTap: () {
//             ScaffoldMessenger.of(context).clearSnackBars();
//           },
//           child: Center(
//             child: CircularProgressIndicator(),
//           ),
//         ),
//       );
//     }

//     if (_vocabularyList.isEmpty) {
//       return Scaffold(
//         appBar: AppBar(
//           title: Text('Flashcards'),
//           actions: [
//             IconButton(
//               icon: Icon(Icons.refresh),
//               onPressed: () => _showResetConfirmationDialog(letter),
//             ),
//           ],
//         ),
//         body: Center(
//           child: Text('No vocabulary words available for this letter.', style: TextStyle(fontSize: 18)),
//         ),
//       );
//     }

//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Flashcards'),
//         actions: [
//           IconButton(
//             icon: Icon(Icons.refresh),
//             onPressed: () => _showResetConfirmationDialog(letter),
//           ),
//         ],
//       ),
//       body: GestureDetector(
//         onHorizontalDragStart: _onHorizontalDragStart,
//         onHorizontalDragUpdate: _onHorizontalDragUpdate,
//         onHorizontalDragEnd: _onHorizontalDragEnd,
//         onTap: () {
//           if (_isUndoVisible) {
//             ScaffoldMessenger.of(context).hideCurrentSnackBar();
//             _hideUndo();
//           }
//         },
//         child: Center(
//           child: Stack(
//             alignment: Alignment.center,
//             children: _vocabularyList.asMap().entries.map((entry) {
//               int index = entry.key;
//               Vocabulary vocabulary = entry.value;
//               return Positioned(
//                 top: 0,
//                 left: 0,
//                 right: 0,
//                 bottom: 0,
//                 child: Draggable(
//                   child: Container(
//                     width: MediaQuery.of(context).size.width * 0.8,
//                     height: MediaQuery.of(context).size.height * 0.6,
//                     child: Flashcard(
//                       key: ValueKey(index),
//                       vocabulary: vocabulary,
//                       onFlip: _flipCard,
//                       isFlipped: _isFlipped,
//                     ),
//                   ),
//                   feedback: Material(
//                     type: MaterialType.transparency,
//                     child: Container(
//                       width: MediaQuery.of(context).size.width * 0.8,
//                       height: MediaQuery.of(context).size.height * 0.6,
//                       child: Flashcard(
//                         key: ValueKey(index),
//                         vocabulary: vocabulary,
//                         onFlip: _flipCard,
//                         isFlipped: _isFlipped,
//                       ),
//                     ),
//                   ),
//                   childWhenDragging: Container(),
//                   onDragEnd: (details) {
//                     if (details.offset.dx > 100) {
//                       _memorizeWord();
//                     } else if (details.offset.dx < -100) {
//                       _viewWord();
//                     }
//                   },
//                 ),
//               );
//             }).toList(),
//           ),
//         ),
//       ),
//     );
//   }
// }
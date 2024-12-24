import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../models/vocabulary_model.dart';
import '../services/firestore_service.dart';

class Flashcard extends StatefulWidget {
  final Vocabulary vocabulary;
  final VoidCallback onFlip;
  final bool isFlipped;
  final Key? key;

  Flashcard({
    required this.vocabulary,
    required this.onFlip,
    required this.isFlipped,
    this.key,
  });

  @override
  _FlashcardState createState() => _FlashcardState();
}

class _FlashcardState extends State<Flashcard> {
  final FlutterTts _flutterTts = FlutterTts();
  final FirestoreService _firestoreService = FirestoreService();
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    _checkIfFavorite();
  }

  @override
  void dispose() {
    _flutterTts.stop();
    super.dispose();
  }

  Future<void> _speak() async {
    try {
      await _flutterTts.setLanguage("en-US");
      await _flutterTts.setPitch(1.0);
      await _flutterTts.speak(widget.vocabulary.name);
    } catch (e) {
      print("Error in TTS: $e");
    }
  }

  String _formatName(String name) {
    return name.replaceAll(RegExp(r'_\d+$'), '');
  }

  Future<void> _addToFavorites() async {
    await _firestoreService.addVocabularyToFavorites(widget.vocabulary);
    setState(() {
      _isFavorite = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Added to favorites')),
    );
  }

  Future<void> _removeFromFavorites() async {
    await _firestoreService.removeVocabularyFromFavorites(widget.vocabulary);
    setState(() {
      _isFavorite = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Removed from favorites')),
    );
  }

  Future<void> _checkIfFavorite() async {
    bool isFavorite = await _firestoreService.isVocabularyFavorite(widget.vocabulary);
    setState(() {
      _isFavorite = isFavorite;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onFlip,
      child: Center(
        child: FractionallySizedBox(
          widthFactor: 0.9,
          heightFactor: 0.7,
          child: Card(
            color: Colors.white,
            elevation: 4,
            margin: EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: widget.isFlipped ? _buildFlippedCard() : _buildDefaultCard(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDefaultCard() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _formatName(widget.vocabulary.name),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              IconButton(
                icon: Icon(Icons.volume_up),
                onPressed: _speak,
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            widget.vocabulary.pronunciation,
            style: TextStyle(
              fontSize: 18,
              fontStyle: FontStyle.italic,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFlippedCard() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Text(
                _formatName(widget.vocabulary.name),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              IconButton(
                icon: Icon(Icons.volume_up),
                onPressed: _speak,
              ),
            ],
          ),
          Text(
            widget.vocabulary.pronunciation,
            style: TextStyle(
              fontSize: 18,
              fontStyle: FontStyle.italic,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: 8),
          Divider(thickness: 1,),
          SizedBox(height: 8),
          Text(
            'Definition:',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          Text(
            widget.vocabulary.definition,
            style: TextStyle(
              fontSize: 18,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Synonyms:',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          Text(
            widget.vocabulary.synonyms.join(', '),
            style: TextStyle(
              fontSize: 18,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Example:',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          Text(
            widget.vocabulary.example,
            style: TextStyle(
              fontSize: 18,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 16),
          Center(
            child: Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: IconButton(
                icon: Icon(
                  _isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: _isFavorite ? Colors.red : null,
                ),
                onPressed: () {
                  if (_isFavorite) {
                    _removeFromFavorites();
                  } else {
                    _addToFavorites();
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
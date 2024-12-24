import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:vocabflashcard_app/data/ielts_dataset.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: "assets/env/.env");
  
  await Firebase.initializeApp(
    options: FirebaseOptions(
      apiKey: dotenv.env['FIREBASE_API_KEY']!,
      appId: dotenv.env['FIREBASE_APP_ID']!,
      messagingSenderId: dotenv.env['FIREBASE_MESSAGING_SENDER_ID']!,
      projectId: dotenv.env['FIREBASE_PROJECT_ID']!,
      storageBucket: dotenv.env['FIREBASE_STORAGE_BUCKET']!,
    ),
  );

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // List<Map<String, dynamic>> vocabData = [
  //   {
  //     'name': 'Aberration',
  //     'definition': 'A departure from what is normal, usual, or expected, typically an unwelcome one.',
  //     'synonyms': ['anomaly', 'deviation', 'divergence'],
  //     'example': 'The outbreak of violence in the area is an aberration.',
  //     'pronunciation': 'ab-er-ray-shun',
  //   },
  //   {
  //     'name': 'Capitulate',
  //     'definition': 'Cease to resist an opponent or an unwelcome demand; surrender.',
  //     'synonyms': ['surrender', 'yield', 'submit'],
  //     'example': 'The country refused to capitulate despite the overwhelming odds.',
  //     'pronunciation': 'ka-pit-yuh-layt',
  //   },
  //   // Add more vocabulary data here...
  // ];

  for (var vocab in IELTS_vocabData) {
    await _db.collection('vocabulary').add(vocab);
  }

  print('Vocabulary data uploaded successfully.');
}

//flutter run -d chrome lib/services/upload_vocabs.dart
//dart run lib/services/upload_vocabs.dart
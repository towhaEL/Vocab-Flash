import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/vocabulary_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> addVocabularyToFavorites(Vocabulary vocab) async {
    final User? user = _auth.currentUser;
    if (user != null) {
      await _db.collection('users').doc(user.uid).collection('favorites').add({
        'name': vocab.name,
        'definition': vocab.definition,
        'synonyms': vocab.synonyms,
        'example': vocab.example,
        'pronunciation': vocab.pronunciation,
      });
    }
  }

  Future<void> removeVocabularyFromFavorites(Vocabulary vocab) async {
    final User? user = _auth.currentUser;
    if (user != null) {
      final QuerySnapshot snapshot = await _db
          .collection('users')
          .doc(user.uid)
          .collection('favorites')
          .where('name', isEqualTo: vocab.name)
          .get();

      for (var doc in snapshot.docs) {
        await doc.reference.delete();
      }
    }
  }

  Future<bool> isVocabularyFavorite(Vocabulary vocab) async {
    final User? user = _auth.currentUser;
    if (user != null) {
      final QuerySnapshot snapshot = await _db
          .collection('users')
          .doc(user.uid)
          .collection('favorites')
          .where('name', isEqualTo: vocab.name)
          .get();

      return snapshot.docs.isNotEmpty;
    }
    return false;
  }

  Future<void> addVocabularyToMemorized(Vocabulary vocab) async {
    final User? user = _auth.currentUser;
    if (user != null) {
      await _db.collection('users').doc(user.uid).collection('memorized').add({
        'name': vocab.name,
        'definition': vocab.definition,
        'synonyms': vocab.synonyms,
        'example': vocab.example,
        'pronunciation': vocab.pronunciation,
      });
      await _updateDailyWordCount(user.uid, 'memorized');
    }
  }

  Future<void> removeVocabularyFromMemorized(Vocabulary vocab) async {
    final User? user = _auth.currentUser;
    if (user != null) {
      final QuerySnapshot snapshot = await _db
          .collection('users')
          .doc(user.uid)
          .collection('memorized')
          .where('name', isEqualTo: vocab.name)
          .get();

      for (var doc in snapshot.docs) {
        await doc.reference.delete();
      }
    }
  }

  Future<List<String>> fetchMemorizedVocabulary() async {
    final User? user = _auth.currentUser;
    if (user != null) {
      final QuerySnapshot snapshot = await _db
          .collection('users')
          .doc(user.uid)
          .collection('memorized')
          .get();

      return snapshot.docs.map((doc) => doc['name'] as String).toList();
    }
    return [];
  }

  Future<void> clearMemorizedVocabularyForLetter(String letter) async {
    final User? user = _auth.currentUser;
    if (user != null) {
      final QuerySnapshot snapshot = await _db
          .collection('users')
          .doc(user.uid)
          .collection('memorized')
          .where('name', isGreaterThanOrEqualTo: letter)
          .where('name', isLessThan: letter + 'z')
          .get();

      for (var doc in snapshot.docs) {
        await doc.reference.delete();
      }
    }
  }

  Future<List<Vocabulary>> fetchVocabulary() async {
    QuerySnapshot snapshot = await _db.collection('vocabulary').get();
    return snapshot.docs.map((doc) {
      return Vocabulary(
        name: doc['name'],
        definition: doc['definition'],
        synonyms: List<String>.from(doc['synonyms']),
        example: doc['example'],
        pronunciation: doc['pronunciation'],
      );
    }).toList();
  }

  Future<int> getTotalWords() async {
    QuerySnapshot snapshot = await _db.collection('vocabulary').get();
    return snapshot.size;
  }

  Future<int> getLearnedWords(String userId) async {
    QuerySnapshot snapshot = await _db
        .collection('users')
        .doc(userId)
        .collection('memorized')
        .get();
    return snapshot.size;
  }

  Future<void> addVocabularyToViewed(Vocabulary vocab) async {
    final User? user = _auth.currentUser;
    if (user != null) {
      final QuerySnapshot result = await _db
          .collection('users')
          .doc(user.uid)
          .collection('viewed_words')
          .where('name', isEqualTo: vocab.name)
          .get();

      if (result.docs.isEmpty) {
        await _db.collection('users').doc(user.uid).collection('viewed_words').add({
          'name': vocab.name,
          'definition': vocab.definition,
          'synonyms': vocab.synonyms,
          'example': vocab.example,
          'pronunciation': vocab.pronunciation,
        });
        await _updateDailyWordCount(user.uid, 'viewed');
      }
    }
  }

  Future<int> getViewedWords(String userId) async {
    QuerySnapshot snapshot = await _db
        .collection('users')
        .doc(userId)
        .collection('viewed_words')
        .get();
    return snapshot.size;
  }


  // streak
  Future<void> _updateDailyWordCount(String userId, String type) async {
    final DateTime today = DateTime.now();
    final String todayStr = '${today.year}-${today.month}-${today.day}';

    final DocumentReference dailyCountRef = _db
        .collection('users')
        .doc(userId)
        .collection('daily_word_count')
        .doc(todayStr);

    final DocumentSnapshot dailyCountDoc = await dailyCountRef.get();

    if (dailyCountDoc.exists) {
      final Map<String, dynamic> data = dailyCountDoc.data() as Map<String, dynamic>;
      int count = data[type] ?? 0;
      count += 1;

      await dailyCountRef.update({type: count});
    } else {
      await dailyCountRef.set({
        'date': today,
        'memorized': type == 'memorized' ? 1 : 0,
        'viewed': type == 'viewed' ? 1 : 0,
      });
    }
  }


  Future<void> updateDailyStreak() async {
    final User? user = _auth.currentUser;
    if (user != null) {
      final DocumentReference streakRef = _db.collection('users').doc(user.uid).collection('streaks').doc('daily_streak');
      final DocumentSnapshot streakDoc = await streakRef.get();

      if (streakDoc.exists) {
        final Map<String, dynamic> data = streakDoc.data() as Map<String, dynamic>;
        final DateTime lastUpdated = (data['last_updated'] as Timestamp).toDate();
        final DateTime today = DateTime.now();

        if (today.difference(lastUpdated).inDays == 1) {
          // Increment current streak
          int currentStreak = data['current_streak'] + 1;
          int longestStreak = data['longest_streak'];

          if (currentStreak > longestStreak) {
            longestStreak = currentStreak;
          }

          await streakRef.update({
            'current_streak': currentStreak,
            'longest_streak': longestStreak,
            'last_updated': today,
          });
        } else if (today.difference(lastUpdated).inDays > 1) {
          // Reset current streak
          await streakRef.update({
            'current_streak': 1,
            'last_updated': today,
          });
        }
      } else {
        // Initialize streak document
        await streakRef.set({
          'current_streak': 1,
          'longest_streak': 1,
          'last_updated': DateTime.now(),
        });
      }
    }
  }

  Future<Map<String, dynamic>> getStreaks() async {
    final User? user = _auth.currentUser;
    if (user != null) {
      final DocumentSnapshot streakDoc = await _db.collection('users').doc(user.uid).collection('streaks').doc('daily_streak').get();
      if (streakDoc.exists) {
        return streakDoc.data() as Map<String, dynamic>;
      }
    }
    return {'current_streak': 0, 'longest_streak': 0};
  }

  Future<Map<String, int>> getWeeklyWordCount() async {
    final User? user = _auth.currentUser;
    if (user != null) {
      final DateTime now = DateTime.now();
      final DateTime startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      final DateTime endOfWeek = startOfWeek.add(Duration(days: 6));

      final QuerySnapshot snapshot = await _db
          .collection('users')
          .doc(user.uid)
          .collection('daily_word_count')
          .where('date', isGreaterThanOrEqualTo: startOfWeek)
          .where('date', isLessThanOrEqualTo: endOfWeek)
          .get();

      final Map<String, int> weeklyWordCount = {
        'Mon': 0,
        'Tue': 0,
        'Wed': 0,
        'Thu': 0,
        'Fri': 0,
        'Sat': 0,
        'Sun': 0,
      };

      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final DateTime date = (data['date'] as Timestamp).toDate();
        final String day = _getDayOfWeek(date.weekday);

        weeklyWordCount[day] = (data['memorized'] ?? 0);
      }

      return weeklyWordCount;
    }
    return {};
  }

  String _getDayOfWeek(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return 'Mon';
      case DateTime.tuesday:
        return 'Tue';
      case DateTime.wednesday:
        return 'Wed';
      case DateTime.thursday:
        return 'Thu';
      case DateTime.friday:
        return 'Fri';
      case DateTime.saturday:
        return 'Sat';
      case DateTime.sunday:
        return 'Sun';
      default:
        return '';
    }
  }


  // Quiz
  Future<List<QueryDocumentSnapshot>> getVocabulary() async {
    QuerySnapshot snapshot = await _db.collection('vocabulary').get();
    return snapshot.docs;
  }

  Future<void> saveQuizResult(int score, int ques_num, double accuracy) async {
    User? user = _auth.currentUser;
    if (user != null) {
      
      await _db.collection('users').doc(user.uid).collection('quiz_results').add({
        'score': score,
        'questions': ques_num,
        'accuracy': accuracy,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } else {
      throw Exception('No user is currently signed in.');
    }
  }

  Future<List<QueryDocumentSnapshot>> getQuizResults() async {
    User? user = _auth.currentUser;
    if (user != null) {
      QuerySnapshot snapshot = await _db.collection('users').doc(user.uid).collection('quiz_results').get();
      return snapshot.docs;
    } else {
      throw Exception('No user is currently signed in.');
    }
  }



  // Achivement & badges
  Future<void> updateLoginStreak() async {
    User? user = _auth.currentUser;
    if (user != null) {
      DocumentReference userDocRef = _db.collection('users').doc(user.uid).collection('user_data').doc('last_login');
      DocumentSnapshot userDoc = await userDocRef.get();

      if (userDoc.exists) {
        DateTime lastLogin = (userDoc['lastLogin'] as Timestamp).toDate();
        DateTime now = DateTime.now();
        int loginStreak = userDoc['loginStreak'];

        if (now.difference(lastLogin).inDays == 1) {
          // Increment streak if the last login was yesterday
          loginStreak++;
        } else if (now.difference(lastLogin).inDays > 1) {
          // Reset streak if the last login was more than one day ago
          loginStreak = 1;
        }

        await userDocRef.update({
          'lastLogin': now,
          'loginStreak': loginStreak,
        });
      } else {
        // Initialize login streak if the user document does not exist
        await userDocRef.set({
          'lastLogin': DateTime.now(),
          'loginStreak': 1,
        });
      }
    } else {
      throw Exception('No user is currently signed in.');
    }
  }

  // Future<List<Map<String, dynamic>>> getAchievements() async {
  //   User? user = _auth.currentUser;
  //   if (user != null) {
  //     QuerySnapshot quizSnapshot = await _db.collection('users').doc(user.uid).collection('quiz_results').get();
  //     QuerySnapshot learnedWordsSnapshot = await _db.collection('users').doc(user.uid).collection('memorized').get();
  //     DocumentSnapshot userDoc = await _db.collection('users').doc(user.uid).collection('user_data').doc('last_login').get();
  //     int learnedWords = learnedWordsSnapshot.size;
  //     int quizzesTaken = quizSnapshot.size;
  //     int loginStreak = userDoc['loginStreak'];

  //     List<Map<String, dynamic>> achievements = [];

  //     // Learning achievements
  //     if (learnedWords >= 10) {
  //       achievements.add({
  //         'title': 'Learner',
  //         'description': 'Learned 10 words',
  //         'icon': Icons.book,
  //         'color': Colors.blue,
  //       });
  //     }
  //     if (learnedWords >= 50) {
  //       achievements.add({
  //         'title': 'Scholar',
  //         'description': 'Learned 50 words',
  //         'icon': Icons.school,
  //         'color': Colors.green,
  //       });
  //     }

  //     // Quiz achievements
  //     if (quizzesTaken >= 5) {
  //       achievements.add({
  //         'title': 'Quiz Master',
  //         'description': 'Completed 5 quizzes',
  //         'icon': Icons.quiz,
  //         'color': Colors.orange,
  //       });
  //     }
  //     if (quizzesTaken >= 20) {
  //       achievements.add({
  //         'title': 'Quiz Champion',
  //         'description': 'Completed 20 quizzes',
  //         'icon': Icons.emoji_events,
  //         'color': Colors.red,
  //       });
  //     }

  //     // Login achievements
  //     if (loginStreak >= 7) {
  //       achievements.add({
  //         'title': 'Regular User',
  //         'description': 'Logged in for 7 consecutive days',
  //         'icon': Icons.login,
  //         'color': Colors.purple,
  //       });
  //     }
  //     if (loginStreak >= 30) {
  //       achievements.add({
  //         'title': 'Dedicated User',
  //         'description': 'Logged in for 30 consecutive days',
  //         'icon': Icons.star,
  //         'color': Colors.yellow,
  //       });
  //     }

  //     return achievements;
  //   } else {
  //     throw Exception('No user is currently signed in.');
  //   }
  // }

  Future<List<Map<String, dynamic>>> getAchievements() async {
    User? user = _auth.currentUser;
    if (user != null) {
      QuerySnapshot quizSnapshot = await _db.collection('users').doc(user.uid).collection('quiz_results').get();
      QuerySnapshot learnedWordsSnapshot = await _db.collection('users').doc(user.uid).collection('memorized').get();
      DocumentSnapshot userDoc = await _db.collection('users').doc(user.uid).collection('user_data').doc('last_login').get();
      int learnedWords = learnedWordsSnapshot.size;
      int quizzesTaken = quizSnapshot.size;
      int loginStreak = userDoc['loginStreak'];

      List<Map<String, dynamic>> achievements = [];

      // Learning achievements
      achievements.add({
        'title': 'Learner',
        'description': 'Learned 10 words',
        'icon': Icons.book,
        'color': Colors.blue,
        'acquired': learnedWords >= 10,
      });
      achievements.add({
        'title': 'Scholar',
        'description': 'Learned 50 words',
        'icon': Icons.school,
        'color': Colors.green,
        'acquired': learnedWords >= 50,
      });
      achievements.add({
        'title': 'Word Master',
        'description': 'Learned 100 words',
        'icon': Icons.library_books,
        'color': Colors.teal,
        'acquired': learnedWords >= 100,
      });

      // Quiz achievements
      achievements.add({
        'title': 'Quiz Master',
        'description': 'Completed 5 quizzes',
        'icon': Icons.quiz,
        'color': Colors.orange,
        'acquired': quizzesTaken >= 5,
      });
      achievements.add({
        'title': 'Quiz Champion',
        'description': 'Completed 20 quizzes',
        'icon': Icons.emoji_events,
        'color': Colors.red,
        'acquired': quizzesTaken >= 20,
      });
      achievements.add({
        'title': 'Quiz Legend',
        'description': 'Completed 50 quizzes',
        'icon': Icons.star,
        'color': Colors.purple,
        'acquired': quizzesTaken >= 50,
      });

      // Login achievements
      achievements.add({
        'title': 'Regular User',
        'description': 'Logged in for 7 consecutive days',
        'icon': Icons.login,
        'color': Colors.purple,
        'acquired': loginStreak >= 7,
      });
      achievements.add({
        'title': 'Dedicated User',
        'description': 'Logged in for 30 consecutive days',
        'icon': Icons.star,
        'color': Colors.yellow,
        'acquired': loginStreak >= 30,
      });
      achievements.add({
        'title': 'Committed User',
        'description': 'Logged in for 100 consecutive days',
        'icon': Icons.verified,
        'color': Colors.blueAccent,
        'acquired': loginStreak >= 100,
      });

      return achievements;
    } else {
      throw Exception('No user is currently signed in.');
    }
  }


  
}
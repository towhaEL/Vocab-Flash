import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tuple/tuple.dart';
import 'package:vocabflashcard_app/models/leaderboard_model.dart';
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
      await updateAchievements();
      await updateDailyStreak();

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

  // daily goal
  Future<void> setDailyGoal(int goal) async {
    final User? user = _auth.currentUser;
    if (user != null) {
      final DocumentReference dailyGoalRef = _db.collection('users').doc(user.uid).collection('user_data').doc('daily_goal');
      final DocumentSnapshot dailyGoalDoc = await dailyGoalRef.get();

      await dailyGoalRef.update({
        'dailyGoal': goal,
      });

      final QuerySnapshot streaksSnap = await _db
          .collection('users')
          .doc(user.uid)
          .collection('streaks')
          .get();
      for (var doc in streaksSnap.docs) {
        await doc.reference.delete();
      }
    }  
  }

  Future<int> getDailyGoal() async {
  final User? user = _auth.currentUser;

  if (user == null) {
    throw Exception("User is not logged in.");
  }

  final DocumentReference dailyGoalRef = _db
      .collection('users')
      .doc(user.uid)
      .collection('user_data')
      .doc('daily_goal');
  
  final DocumentSnapshot dailyGoalDoc = await dailyGoalRef.get();

  if (!dailyGoalDoc.exists) {
    throw Exception("Daily goal document does not exist.");
  }

  final data = dailyGoalDoc.data() as Map<String, dynamic>?;

  if (data == null || !data.containsKey('dailygoal')) {
    throw Exception("Daily goal not found in the document.");
  }

  final goal = data['dailygoal'];

  if (goal is! int) {
    throw Exception("Daily goal is not an integer.");
  }

  return goal;
}



  // streak
  Future<void> _updateDailyWordCount(String userId, String type) async {
    final DateTime today = DateTime.now();
    final String todayStr = '${today.year}-${today.month}-${today.day}';

    final DocumentReference dailyCountRef = _db.collection('users').doc(userId).collection('daily_word_count').doc(todayStr);
    final DocumentReference dailyGoalRef = _db.collection('users').doc(userId).collection('user_data').doc('daily_goal');
    final DocumentSnapshot dailyGoalDoc = await dailyGoalRef.get();
    final DocumentSnapshot dailyCountDoc = await dailyCountRef.get();

    // final Map<String, dynamic> data = dailyCountDoc.data() as Map<String, dynamic>;
    int daily_goal = dailyGoalDoc['dailyGoal'];

    if (dailyCountDoc.exists) {
      final Map<String, dynamic> data = dailyCountDoc.data() as Map<String, dynamic>;
      int count = data[type] ?? 0;
      count += 1;

      await dailyCountRef.update({
        type: count,
        'goalCompleted': (type=='memorized' && count>=daily_goal)? true : data['goalCompleted'],
        });
    } else {
      await dailyCountRef.set({
        'date': today,
        'memorized': type == 'memorized' ? 1 : 0,
        'viewed': type == 'viewed' ? 1 : 0,
        'goalCompleted': false
      });
    }
  }


Future<void> updateDailyStreak() async {
  final DateTime today = DateTime.now();
  final DateTime yesterday = today.subtract(Duration(days: 1));
  final String todayStr = DateFormat('yyyy-MM-dd').format(today);
  final String yesterdayStr = DateFormat('yyyy-MM-dd').format(yesterday);

  final User? user = _auth.currentUser;
  if (user != null) {
    final DocumentReference streakRef = _db.collection('users').doc(user.uid).collection('streaks').doc('daily_streak');
    final DocumentReference wordCountRef = _db.collection('users').doc(user.uid).collection('daily_word_count').doc(todayStr);
    final DocumentReference yesterdayWordCountRef = _db.collection('users').doc(user.uid).collection('daily_word_count').doc(yesterdayStr);

    try {
      final DocumentSnapshot streakDoc = await streakRef.get();
      final DocumentSnapshot wordCountDoc = await wordCountRef.get();
      final DocumentSnapshot yesterdayWordCountDoc = await yesterdayWordCountRef.get();

      final bool todayGoalCompleted = wordCountDoc.exists && wordCountDoc['goalCompleted'] == true;
      final bool yesterdayGoalCompleted = yesterdayWordCountDoc.exists && yesterdayWordCountDoc['goalCompleted'] == true;

      if (streakDoc.exists) {
        final Map<String, dynamic> data = streakDoc.data() as Map<String, dynamic>;

        if (data['last_updated'] != todayStr && todayGoalCompleted) {
          int currentStreak = yesterdayGoalCompleted ? data['current_streak'] + 1 : 1;
          int longestStreak = data['longest_streak'];

          if (currentStreak > longestStreak) {
            longestStreak = currentStreak;
          }

          await streakRef.update({
            'current_streak': currentStreak,
            'longest_streak': longestStreak,
            'last_updated': todayStr,
          });
        }
      } else {
        // Initialize streak document
        if (todayGoalCompleted) {
          await streakRef.set({
            'current_streak': 1,
            'longest_streak': 1,
            'last_updated': todayStr,
          });
        }
      }

      updateAchievements(); // Call the function to update achievements.
    } catch (e) {
      print('Error updating streak: $e');
    }
  }
}


  // Future<void> updateDailyStreak() async {
  //   final DateTime today = DateTime.now();
  //   final DateTime yesterday = DateTime.now().subtract(Duration(days: 1));
  //   final String todayStr = '${today.year}-${today.month}-${today.day}';
  //   final String yesterdayStr = '${yesterday.year}-${yesterday.month}-${yesterday.day}';

  //   final User? user = _auth.currentUser;
  //   if (user != null) {
  //     final DocumentReference streakRef = _db.collection('users').doc(user.uid).collection('streaks').doc('daily_streak');
  //     final DocumentSnapshot streakDoc = await streakRef.get();
  //     final DocumentReference wordCountRef = _db.collection('users').doc(user.uid).collection('daily_word_count').doc(todayStr);
  //     final DocumentSnapshot wordCountDoc = await wordCountRef.get();
  //     final DocumentReference yesterdayWordCountRef = _db.collection('users').doc(user.uid).collection('daily_word_count').doc(yesterdayStr);
  //     final DocumentSnapshot yesterdayWordCountDoc = await yesterdayWordCountRef.get();

  //     if (streakDoc.exists) {
  //       final Map<String, dynamic> data = streakDoc.data() as Map<String, dynamic>;
  //       // final DateTime lastUpdated = (data['last_updated'] as Timestamp).toDate();
  //       final DateTime today = DateTime.now();

  //       if (data['last_updated'] != todayStr && wordCountDoc['goalCompleted'] == true) {
  //         if (yesterdayWordCountDoc['goalCompleted'] == true ) {
  //           // Increment current streak
  //         int currentStreak = data['current_streak'] + 1;
  //         int longestStreak = data['longest_streak'];

  //         if (currentStreak > longestStreak) {
  //           longestStreak = currentStreak;
  //         }

  //         await streakRef.update({
  //           'current_streak': currentStreak,
  //           'longest_streak': longestStreak,
  //           'last_updated': todayStr,
  //         });
  //         } else {
  //           // Reset current streak
  //         await streakRef.update({
  //           'current_streak': 1,
  //           'last_updated': today,
  //         });

  //         }
  //       } else {
  //         // Reset current streak
  //         await streakRef.update({
  //           'current_streak': 1,
  //           'last_updated': today,
  //         });
  //       }
  //     } else {
  //       // Initialize streak document
  //           if (wordCountDoc['goalCompleted']) {
  //             await streakRef.set({
  //             'current_streak': 1,
  //             'longest_streak': 1,
  //             'last_updated': todayStr,
  //           });
  //       }    
  //     }

  //     updateAchievements();

  //   }
  // }


  // Future<void> updateDailyStreak() async {
  //   final DateTime today = DateTime.now();
  //   final DateTime yesterday = DateTime.now().subtract(Duration(days: 1));
  //   final String todayStr = '${today.year}-${today.month}-${today.day}';
  //   final String yesterdayStr = '${yesterday.year}-${yesterday.month}-${yesterday.day}';

  //   final User? user = _auth.currentUser;
  //   if (user != null) {
  //     final DocumentReference streakRef = _db.collection('users').doc(user.uid).collection('streaks').doc('daily_streak');
  //     final DocumentSnapshot streakDoc = await streakRef.get();
  //     final DocumentReference wordCountRef = _db.collection('users').doc(user.uid).collection('daily_word_count').doc(todayStr);
  //     final DocumentSnapshot wordCountDoc = await wordCountRef.get();
  //     final DocumentReference yesterdayWordCountRef = _db.collection('users').doc(user.uid).collection('daily_word_count').doc(yesterdayStr);
  //     final DocumentSnapshot yesterdayWordCountDoc = await yesterdayWordCountRef.get();

  //     if (streakDoc.exists) {
  //       final Map<String, dynamic> data = streakDoc.data() as Map<String, dynamic>;
  //       final DateTime lastUpdated = (data['last_updated'] as Timestamp).toDate();
  //       final DateTime today = DateTime.now();

  //       if (today.difference(lastUpdated).inDays == 1 && wordCountDoc['goalCompleted'] == true) {
  //         // Increment current streak
  //         int currentStreak = data['current_streak'] + 1;
  //         int longestStreak = data['longest_streak'];

  //         if (currentStreak > longestStreak) {
  //           longestStreak = currentStreak;
  //         }

  //         await streakRef.update({
  //           'current_streak': currentStreak,
  //           'longest_streak': longestStreak,
  //           'last_updated': today,
  //         });
  //       } else if (today.difference(lastUpdated).inDays > 1) {
  //         // Reset current streak
  //         await streakRef.update({
  //           'current_streak': 1,
  //           'last_updated': today,
  //         });
  //       }
  //     } else {
  //       // Initialize streak document
  //           if (wordCountDoc['goalCompleted']) {
  //             await streakRef.set({
  //             'current_streak': 1,
  //             'longest_streak': 1,
  //             'last_updated': DateTime.now(),
  //           });
  //       }    
  //     }
  //   }
  // }


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

  Future<Map<String, Tuple2<int, bool>>> getWeeklyWordCount() async {
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

      Map<String, Tuple2<int, bool>> _weeklyWordCount = {
        'Mon': Tuple2(0, false),
        'Tue': Tuple2(0, false),
        'Wed': Tuple2(0, false),
        'Thu': Tuple2(0, false),
        'Fri': Tuple2(0, false),
        'Sat': Tuple2(0, false),
        'Sun': Tuple2(0, false),
      };

      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final DateTime date = (data['date'] as Timestamp).toDate();
        final String day = _getDayOfWeek(date.weekday);

        _weeklyWordCount[day] = Tuple2((data['memorized'] ?? 0), data['goalCompleted'] ?? false);
      }

      return _weeklyWordCount;
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

      await updateAchievements();
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
      updateAchievements();
    } else {
      throw Exception('No user is currently signed in.');
    }
  }

  Future<void> updateAchievements() async {
    User? user = _auth.currentUser;
    if (user != null) {      
      final DocumentSnapshot streakDoc = await _db.collection('users').doc(user.uid).collection('streaks').doc('daily_streak').get();
      QuerySnapshot quizSnapshot = await _db.collection('users').doc(user.uid).collection('quiz_results').get();
      List<QueryDocumentSnapshot> quizDocs = quizSnapshot.docs;
      QuerySnapshot learnedWordsSnapshot = await _db.collection('users').doc(user.uid).collection('memorized').get();
      DocumentSnapshot userDoc = await _db.collection('users').doc(user.uid).collection('user_data').doc('last_login').get();

      int learnedWords = 0;
      int quizzesTaken = 0;
      learnedWords = learnedWordsSnapshot.size;
      quizzesTaken = quizSnapshot.size;
      int loginStreak = userDoc.exists ? userDoc['loginStreak'] : 0;
      int learningStreak = streakDoc.exists ? streakDoc['longest_streak'] : 0;
      int questionsAnsweredCorrectly = 0;
      int totalQuestions = 0;
      for (var doc in quizDocs) {
        int score = doc['score'];
        int quesCount = doc['questions'];
        questionsAnsweredCorrectly += score;
        totalQuestions +=  quesCount;
      }
        


      DocumentReference userAchievementRef = _db.collection('users').doc(user.uid).collection('user_data').doc('achievements');
      DocumentSnapshot userAchievement = await userAchievementRef.get();
      final Map<String, dynamic> data = userAchievement.data() as Map<String, dynamic>;

      if (userAchievement.exists) {
        await userAchievementRef.set({
          'Learner': (learnedWords >= 100)? true : data['Learner'],
          'Scholar': (learnedWords >= 250)? true : data['Scholar'],
          'word_master': (learnedWords >= 500)? true : data['word_master'],
          '7_day_streak': (learningStreak >= 2)? true : data['7_day_streak'],
          '14_day_streak': (learningStreak >= 14)? true : data['14_day_streak'],
          '21_day_streak': (learningStreak >= 21)? true : data['21_day_streak'],
          'quiz_master': (quizzesTaken >= 5)? true : data['quiz_master'],
          'quiz_champion': (quizzesTaken >= 20)? true : data['quiz_champion'],
          'quiz_legend': (quizzesTaken >= 50)? true : data['quiz_legend'],
          'question_novice': (questionsAnsweredCorrectly >=50)? true : data['question_novice'],
          'question_expert': (questionsAnsweredCorrectly >= 200)? true : data['question_expert'],
          'question_master': (questionsAnsweredCorrectly >= 500)? true : data['question_master'],
          'question_legend': (questionsAnsweredCorrectly >= 1000)? true : data['question_legend'],
          'regular_user': (loginStreak >= 7)? true : data['regular_user'],
          'dedicated_user': (loginStreak >= 30)? true : data['dedicated_user'],
          'committed_user': (loginStreak >= 100)? true : data['committed_user'],
          'achievement_points': data['achievement_points'],
        });

      DocumentReference leaderboardRef = _db.collection('leaderboard').doc(user.email);
      DocumentSnapshot leaderboard = await leaderboardRef.get();
      if (leaderboard.exists) {
        await leaderboardRef.set({
          'userId': user.uid,
          'email': user.email,
          'learnedWords': learnedWords,
          'totalScore': questionsAnsweredCorrectly,
          'totalQuestions': totalQuestions,
          'achievemntPoints': await getAchievementsPoints(user.uid),
        });
        
      } 
    
      } else {
        
      }

    } else {
      throw Exception('No user is currently signed in.');
    }
  }

  Future<List<Map<String, dynamic>>> getAchievements() async {
    User? user = _auth.currentUser;
    if (user != null) {      
      DocumentSnapshot adminDoc = await _db.collection('users').doc(user.uid).collection('user_data').doc('admin_status').get();
      bool isAdmin = adminDoc.exists ? adminDoc['isAdmin'] : false;

      DocumentReference userAchievementRef = _db.collection('users').doc(user.uid).collection('user_data').doc('achievements');
      DocumentSnapshot userAchievement = await userAchievementRef.get();
      final Map<String, dynamic> data = userAchievement.data() as Map<String, dynamic>;

      List<Map<String, dynamic>> achievements = [];

// Learning achievements
achievements.add({
  'title': 'Learner',
  'description': 'Learned 100 words',
  'icon': Icons.book,
  'color': Colors.blue,
  'acquired': isAdmin? true : data['Learner'],
  'points': 50, // Easy
});
achievements.add({
  'title': 'Scholar',
  'description': 'Learned 250 words',
  'icon': Icons.school,
  'color': Colors.green,
  'acquired': isAdmin? true : data['Scholar'],
  'points': 100, // Medium
});
achievements.add({
  'title': 'Word Master',
  'description': 'Learned 500 words',
  'icon': Icons.library_books,
  'color': Colors.teal,
  'acquired': isAdmin? true : data['word_master'],
  'points': 200, // Hard
});

// 7-Day Streak Achievement
achievements.add({
  'title': '7-Day Streak',
  'description': 'Learned for 7 consecutive days',
  'icon': Icons.calendar_today,
  'color': Colors.blue,
  'acquired': isAdmin? true : data['7_day_streak'],
  'points': 10, // Easy
});

// 14-Day Streak Achievement
achievements.add({
  'title': '14-Day Streak',
  'description': 'Learned for 14 consecutive days',
  'icon': Icons.calendar_view_week,
  'color': Colors.orange,
  'acquired': isAdmin? true : data['14_day_streak'],
  'points': 50, // Medium
});

// 21-Day Streak Achievement
achievements.add({
  'title': '21-Day Streak',
  'description': 'Learned for 21 consecutive days',
  'icon': Icons.calendar_month,
  'color': Colors.purple,
  'acquired': isAdmin? true : data['21_day_streak'],
  'points': 100, // Hard
});

// Quiz achievements
achievements.add({
  'title': 'Quiz Master',
  'description': 'Completed 5 quizzes',
  'icon': Icons.quiz,
  'color': Colors.orange,
  'acquired': isAdmin? true : data['quiz_master'],
  'points': 20, // Easy
});
achievements.add({
  'title': 'Quiz Champion',
  'description': 'Completed 20 quizzes',
  'icon': Icons.emoji_events,
  'color': Colors.red,
  'acquired': isAdmin? true : data['quiz_champion'],
  'points': 50, // Medium
});
achievements.add({
  'title': 'Quiz Legend',
  'description': 'Completed 50 quizzes',
  'icon': Icons.star,
  'color': Colors.purple,
  'acquired': isAdmin? true : data['quiz_legend'],
  'points': 100, // Hard
});

// Questions achievements
achievements.add({
  'title': 'Question Novice',
  'description': 'Answered 50 questions correctly',
  'icon': Icons.question_mark,
  'color': Colors.green,
  'acquired': isAdmin? true : data['question_novice'],
  'points': 30, // Easy
});
achievements.add({
  'title': 'Question Expert',
  'description': 'Answered 200 questions correctly',
  'icon': Icons.question_mark_sharp,
  'color': Colors.blue,
  'acquired': isAdmin? true : data['question_expert'],
  'points': 80, // Medium
});
achievements.add({
  'title': 'Question Master',
  'description': 'Answered 500 questions correctly',
  'icon': Icons.question_answer_outlined,
  'color': Colors.purple,
  'acquired': isAdmin? true : data['question_master'],
  'points': 150, // Hard
});
achievements.add({
  'title': 'Question Legend',
  'description': 'Answered 1000 questions correctly',
  'icon': Icons.question_answer,
  'color': Color(0xFFFFD700),
  'acquired': isAdmin? true : data['question_legend'],
  'points': 300, // Very Hard
});

// Login achievements
achievements.add({
  'title': 'Regular User',
  'description': 'Logged in for 7 consecutive days',
  'icon': Icons.login,
  'color': Colors.purple,
  'acquired': isAdmin? true : data['regular_user'],
  'points': 20, // Easy
});
achievements.add({
  'title': 'Dedicated User',
  'description': 'Logged in for 30 consecutive days',
  'icon': Icons.star,
  'color': Colors.yellow,
  'acquired': isAdmin? true : data['dedicated_user'],
  'points': 80, // Medium
});
achievements.add({
  'title': 'Committed User',
  'description': 'Logged in for 100 consecutive days',
  'icon': Icons.verified,
  'color': Colors.blueAccent,
  'acquired': isAdmin? true : data['committed_user'],
  'points': 200, // Very Hard
});


      return achievements;
    } else {
      throw Exception('No user is currently signed in.');
    }
  }

  // achivement point calculate
  Future<int> getAchievementsPoints(String uid) async {
  try {
    final adminDoc = await _db.collection('users').doc(uid).collection('user_data').doc('admin_status').get();
    bool isAdmin = adminDoc.exists ? adminDoc['isAdmin'] : false;

    DocumentReference userAchievementRef = _db.collection('users').doc(uid).collection('user_data').doc('achievements');
    DocumentSnapshot userAchievement = await userAchievementRef.get();
    final Map<String, dynamic> data = userAchievement.data() as Map<String, dynamic>;

    List<Map<String, dynamic>> achievements = [
      {'points': 50, 'acquired': isAdmin || data['Learner']},
      {'points': 100, 'acquired': isAdmin || data['Scholar']},
      {'points': 200, 'acquired': isAdmin || data['word_master']},
      {'points': 10, 'acquired': isAdmin || data['7_day_streak']},
      {'points': 50, 'acquired': isAdmin || data['14_day_streak']},
      {'points': 100, 'acquired': isAdmin || data['21_day_streak']},
      {'points': 20, 'acquired': isAdmin || data['quiz_master']},
      {'points': 50, 'acquired': isAdmin || data['quiz_champion']},
      {'points': 100, 'acquired': isAdmin || data['quiz_legend']},
      {'points': 30, 'acquired': isAdmin || data['question_novice']},
      {'points': 80, 'acquired': isAdmin || data['question_expert']},
      {'points': 150, 'acquired': isAdmin || data['question_master']},
      {'points': 300, 'acquired': isAdmin || data['question_legend']},
      {'points': 20, 'acquired': isAdmin || data['regular_user']},
      {'points': 80, 'acquired': isAdmin || data['dedicated_user']},
      {'points': 200, 'acquired': isAdmin || data['committed_user']},
    ];

    int totalPoints = 0;

  for (var achievement in achievements) {
    if(achievement['acquired']) {
      int points = achievement['points'];
      totalPoints += points;
    }
  }


  return totalPoints;
  } catch (e) {
    throw Exception('Error fetching achievements: $e');
  }
}



  // Easter egg
  Future<void> setAdmin() async {
    User? user = _auth.currentUser;
    if (user != null) {
      DocumentReference userDocRef = _db.collection('users').doc(user.uid).collection('user_data').doc('admin_status');
      DocumentSnapshot userDoc = await userDocRef.get();

      if (userDoc.exists) {
        bool isAdmin = userDoc['isAdmin'];

        await userDocRef.update({
          'isAdmin': !isAdmin,
        });
      } else {
        await userDocRef.set({
          'isAdmin': false,
        });
      }
    } else {
      throw Exception('No user is currently signed in.');
    }
  }
  // Add user data
  Future<void> addUserData() async {
    User? user = _auth.currentUser;
    String _userEmail = '';
    String _userId = '';
    if (user != null) {
      _userEmail = user.email!;
      _userId = user.uid;
      DocumentReference userDocRef = _db.collection('users').doc(user.uid).collection('user_data').doc('user_info');
      DocumentSnapshot userDoc = await userDocRef.get();
      DocumentReference adminDocRef = _db.collection('users').doc(user.uid).collection('user_data').doc('admin_status');
      DocumentSnapshot adminDoc = await adminDocRef.get();
      DocumentReference dailyGoalDocRef = _db.collection('users').doc(user.uid).collection('user_data').doc('daily_goal');
      DocumentSnapshot dailyGoalDoc = await dailyGoalDocRef.get();

      
      // Reference to Firestore collection
  CollectionReference usersCollection = _db.collection('users_data');
  // Check if a document with the same email or userId exists
  QuerySnapshot querySnapshot = await usersCollection
      .where('email', isEqualTo: _userEmail) // Check for existing email
      .get();
  if (querySnapshot.docs.isEmpty) {
    // If no document found with the same email, proceed to add user data
    Map<String, dynamic> userData = {
      'email': _userEmail,
      'userId': _userId,
    };
    await usersCollection.add(userData);
    print('User data added successfully');
  } else {
    // If document with the same email exists, skip adding
    print('User with this email already exists');
  }

      //daily_goal
      if (dailyGoalDoc.exists) {

      } else {
        await dailyGoalDocRef.set({
          'dailyGoal': 5,
        });
      }

      //admin_status
      if (adminDoc.exists) {
        await adminDocRef.update({
          'isAdmin': false,
        });
      } else {
        await adminDocRef.set({
          'isAdmin': false,
        });
      }

      //user_info
      if (userDoc.exists) {
        await userDocRef.update({
          'email': _userEmail,
          'userId': user.uid,
        });
      } else {
        await userDocRef.set({
          'email': _userEmail,
          'userId': user.uid,
        });
      }
    } else {
      throw Exception('No user is currently signed in.');
    }

    // achievements
    DocumentReference userAchievementRef = _db.collection('users').doc(user.uid).collection('user_data').doc('achievements');
      DocumentSnapshot userAchievement = await userAchievementRef.get();
      if (userAchievement.exists) {
        
      } else {
        await userAchievementRef.set({
          'Learner': false,
          'Scholar': false,
          'word_master': false,
          '7_day_streak': false,
          '14_day_streak': false,
          '21_day_streak': false,
          'quiz_master': false,
          'quiz_champion': false,
          'quiz_legend': false,
          'question_novice': false,
          'question_expert': false,
          'question_master': false,
          'question_legend': false,
          'regular_user': false,
          'dedicated_user': false,
          'committed_user': false,
          'achievement_points': 0,
        });
      }

      DocumentReference leaderboardRef = _db.collection('leaderboard').doc(user.email);
      DocumentSnapshot leaderboard = await leaderboardRef.get();
      if (leaderboard.exists) {
        
      } else {
        await leaderboardRef.set({
          'userId': user.uid,
          'email': user.email,
          'learnedWords': 0,
          'totalScore': 0,
          'totalQuestions': 0,
          'achievemntPoints': 0,
        });
      }
    

  }



// Leaderboard
Future<List<Leaderboard>> getLeaderboardData() async {
    List<Leaderboard> leaderboard = [];
    String currentUserId = _auth.currentUser?.uid ?? '';

    print('Starting to fetch leaderboard data...');

    final leaderboardRef = _db.collection('leaderboard');
    QuerySnapshot leaderboardSnapshot = await leaderboardRef.get();

    print('Successfully found ${leaderboardSnapshot.docs.length} users');

    for (var leaderboardDoc in leaderboardSnapshot.docs) {
      final Map<String, dynamic> data = leaderboardDoc.data() as Map<String, dynamic>;

      leaderboard.add(Leaderboard(
          userId: data['userId'],
          email: data['email'],
          totalPoints: await getAchievementsPoints(data['userId']),
          wordsLearned: data['learnedWords'],
          correctAnswers: data['totalScore'],
          questionAttended: data['totalQuestions'],
          owner: data['userId'] == currentUserId,
        ));

    }

    // Sort by points
    leaderboard.sort((a, b) => b.totalPoints.compareTo(a.totalPoints));
    print('Successfully compiled leaderboard with ${leaderboard.length} users');
    return leaderboard;

}


// Account settings
Future<void> resetAccount(BuildContext context, password) async {
    try {
      final User? user = _auth.currentUser;
    if (user != null) {

      // Reauthenticate user
      AuthCredential credential = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );
      await user.reauthenticateWithCredential(credential);


      final QuerySnapshot memorizedSnap = await _db
          .collection('users')
          .doc(user.uid)
          .collection('memorized')
          .get();
      for (var doc in memorizedSnap.docs) {
        await doc.reference.delete();
      }

      final QuerySnapshot daily_word_count = await _db
          .collection('users')
          .doc(user.uid)
          .collection('daily_word_count')
          .get();
      for (var doc in daily_word_count.docs) {
        await doc.reference.delete();
      }

      final QuerySnapshot viewed_wordsSnap = await _db
          .collection('users')
          .doc(user.uid)
          .collection('viewed_words')
          .get();
      for (var doc in viewed_wordsSnap.docs) {
        await doc.reference.delete();
      }

      final QuerySnapshot quiz_resultsSnap = await _db
          .collection('users')
          .doc(user.uid)
          .collection('quiz_results')
          .get();
      for (var doc in quiz_resultsSnap.docs) {
        await doc.reference.delete();
      }

      final QuerySnapshot streaksSnap = await _db
          .collection('users')
          .doc(user.uid)
          .collection('streaks')
          .get();
      for (var doc in streaksSnap.docs) {
        await doc.reference.delete();
      }

      Navigator.of(context, rootNavigator: true).pop(); // Close any active dialogs
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Account Progress is completely removed!')),
      );

    } else {
      
    }

    } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
    );
    }
  }

  Future<void> deleteUserAccount(BuildContext  context, String password) async {
  try {
    User? user = FirebaseAuth.instance.currentUser;
    String currentUser = user!.uid;
    String _userEmail = user.email!;

    // Reauthenticate user
    AuthCredential credential = EmailAuthProvider.credential(
      email: user.email!,
      password: password,
    );

    await user.reauthenticateWithCredential(credential);

    // Delete Firestore data
    await FirebaseFirestore.instance.collection('users').doc(user.uid).delete();

    // Delete Auth account
    await user.delete();

    // Optional: Delete other related collections if needed
    CollectionReference usersCollection = FirebaseFirestore.instance.collection('users_data');
    QuerySnapshot querySnapshot = await usersCollection
    .where('email', isEqualTo: _userEmail) // Check for existing email
    .get();

    for (var doc in querySnapshot.docs) {
      await doc.reference.delete();
    }

    //
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Account deleted successfully.')),
    );

    Navigator.of(context, rootNavigator: true).pop(); // Close any active dialogs
    // Navigate to login or welcome screen
    Navigator.of(context).pushReplacementNamed('/login');
    } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error: ${e.toString()}')),
    );
  }
}

 }
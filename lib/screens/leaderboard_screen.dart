import 'package:flutter/material.dart';
import 'package:vocabflashcard_app/models/leaderboard_model.dart';
import '../services/firestore_service.dart';

class LeaderboardScreen extends StatefulWidget {
  @override
  _LeaderboardScreenState createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  bool _isLoading = true;
  List<Leaderboard> _leaderboard = [];
  int _leaderboardCount = 0;
  int _rank = 0;

  @override
  void initState() {
    super.initState();
    _fetchLeaderboard();
  }

  Future<void> _fetchLeaderboard() async {
    try {
      List<Leaderboard> leaderboard = await _firestoreService.getLeaderboardData();

      setState(() {
        _leaderboard = leaderboard;
        getRank();
        _leaderboardCount = leaderboard.length;
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching leaderboard: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void getRank() {
    int index = 1;
    for (var leaderboard in _leaderboard) {
      if(leaderboard.owner) {
        _rank = index;
        break;
      }
      index++;
    }
  }

  Widget _buildLeaderboardCard(int index, Leaderboard leaderboard) {
    String email = leaderboard.email;
    int acquiredPoints = leaderboard.totalPoints;
    int learnedWords = leaderboard.wordsLearned;
    int correctAnswers = leaderboard.correctAnswers;
    int quesCount = leaderboard.questionAttended;
    bool ownerStatus = leaderboard.owner;

    return Container(
      height: 120,
      child: Card(
        // color: ownerStatus ? Colors.yellow.shade50 : null,
        elevation: 5,
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  boxShadow: (index<3)? [BoxShadow(color: Colors.amber, blurRadius: 10)] : null,
                  border: (index < 3)? Border.all(color: Colors.white, width: 2) : Border.all(color: Colors.grey, width: 2),
                  borderRadius: BorderRadius.circular(1000),
                  color: (index < 3) ? Colors.yellow.shade50 : null,
                ),
                child: Center(
                  child: Stack(
                    children: [
                      Center(
                        child: Text(
                          (index + 1).toString(),
                          style: TextStyle(fontSize: 22, color: Theme.of(context).textTheme.titleLarge?.color),
                        ),
                      ),if (index < 3) ...[
                        Center(
                          child: Icon(
                            index == 0 ? Icons.emoji_events : index == 1 ? Icons.emoji_events : Icons.emoji_events,
                            size: 50,
                            color: index == 0 ? Colors.amber : index == 1 ? Colors.grey : Colors.brown,
                          ),
                        ),
                      ],
                    ],
                  )
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${email}',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: ownerStatus ? Colors.deepPurpleAccent : Theme.of(context).textTheme.titleLarge?.color,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '${acquiredPoints} pts',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      '$learnedWords words learned',
                      style: TextStyle(fontSize: 14, color: Theme.of(context).textTheme.titleLarge?.color),
                    ),
                    Text(
                      'Quiz score: $correctAnswers / $quesCount',
                      style: TextStyle(fontSize: 14, color: Theme.of(context).textTheme.titleLarge?.color),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Global Leaderboard (Rank: ${_rank}/$_leaderboardCount)'),
        automaticallyImplyLeading: false,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _leaderboard.length,
              itemBuilder: (context, index) {
                return _buildLeaderboardCard(index, _leaderboard[index]);
              },
            ),
    );
  }
}



// import 'package:flutter/material.dart';
// import 'package:vocabflashcard_app/models/leaderboard_model.dart';
// import '../services/firestore_service.dart';

// class LeaderboardScreen extends StatefulWidget {
//   @override
//   _LeaderboardScreenState createState() => _LeaderboardScreenState();
// }

// class _LeaderboardScreenState extends State<LeaderboardScreen> {
//   final FirestoreService _firestoreService = FirestoreService();
//   bool _isLoading = true;
//   List<Leaderboard> _leaderboard = [];
//   int _leaderboardCount = 0;

//   @override
//   void initState() {
//     super.initState();
//     _fetchLeaderboard();
//   }


//   Future<void> _fetchLeaderboard() async {
//     try {
//       List<Leaderboard> leaderboard = await _firestoreService.getLeaderboardData();

//       setState(() {
//         _leaderboard = leaderboard;
//         _leaderboardCount = leaderboard.length;
//         _isLoading = false;
//       });
//     } catch (e) {
//       print('Error fetching leaderboard: $e');
//       setState(() {
//         _isLoading = false;
//       });
//     }
//   }



//   Widget _buildLeaderboardCard(index, Leaderboard leaderboard) {
//     String email = leaderboard.email;
//     int acquiredPoints = leaderboard.totalPoints;
//     int learnedWords = leaderboard.wordsLearned;
//     int correctAnswers = leaderboard.correctAnswers;
//     int quesCount = leaderboard.questionAttended;
//     bool ownerStatus = leaderboard.owner;

//     return Container(
//       height: 120,
//       child: Card(
//         elevation: 5,
//         margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
//         child: Padding(
//           padding: const EdgeInsets.all(16.0),
//           child: Row(
//             children: [
//               Opacity(
//                 opacity: 1,
//                 child: Container(
//                   width: 50,
//                   decoration: BoxDecoration(
//                     border: Border.all(),
//                     borderRadius: BorderRadius.circular(1000)
//                   ),
//                   child: Center(
//                     child: Text(
//                       index,
//                       style: TextStyle(fontSize: 36),
//                     ),
//                   ),
//                 )
//               ),
//               SizedBox(width: 16),
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Row(
//                       children: [
//                         Text(
//                           email,
//                           style: TextStyle(
//                             fontSize: 18,
//                             fontWeight: FontWeight.bold,
//                             color: (index <= 10) ? Theme.of(context).textTheme.titleLarge?.color : Colors.grey,
//                           ),
//                         ),
//                         Spacer(),
//                         Text(
//                           '1000pts.',
//                           // '${points}pts.',
//                           style: TextStyle(
//                             fontSize: 18,
//                             fontWeight: FontWeight.bold,
//                             color: (index <= 10) ? Colors.green.shade700 : Colors.grey,
//                           ),
//                         ),
//                       ],
//                     ),
//                     // SizedBox(height: 8),
//                     Text(
//                       '${learnedWords} words learned',
//                       style: TextStyle(
//                         fontSize: 16,
//                         color: (index <= 10) ? Theme.of(context).textTheme.bodyMedium?.color : Colors.grey,
//                       ),
//                     ),
//                     Text(
//                       'Quiz score ${correctAnswers}/${quesCount}',
//                       style: TextStyle(
//                         fontSize: 16,
//                         color: (index <= 10) ? Theme.of(context).textTheme.bodyMedium?.color : Colors.grey,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Global Leaderboard ${_leaderboard.length}/${_leaderboardCount}'),
//       ),
//       body: _isLoading
//           ? Center(child: CircularProgressIndicator())
//           : ListView.builder(
//               itemCount: _leaderboard.length,
//               itemBuilder: (context, index) {
//                 return _buildLeaderboardCard(index, _leaderboard[index]);
//               },
//             ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import '../services/firestore_service.dart';

class AchievementScreen extends StatefulWidget {
  @override
  _AchievementScreenState createState() => _AchievementScreenState();
}

class _AchievementScreenState extends State<AchievementScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  bool _isLoading = true;
  List<Map<String, dynamic>> _achievements = [];
  int _achivementsCount = 0;
  int _acuiredAchivement = 0;

  @override
  void initState() {
    super.initState();
    _fetchAchievements();
  }


  Future<void> _fetchAchievements() async {
    try {
      List<Map<String, dynamic>> achievements = await _firestoreService.getAchievements();
      for (var achievement in achievements) {
        if(achievement['acquired'] == true) {
          _acuiredAchivement += 1;
        }
      }

      setState(() {
        _achievements = achievements;
        _achivementsCount = achievements.length;
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching achievements: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }



  Widget _buildAchievementCard(Map<String, dynamic> achievement) {
    String title = achievement['title'];
    String description = achievement['description'];
    IconData icon = achievement['icon'];
    Color color = achievement['color'];
    bool acquired = achievement['acquired'];
    int points = achievement['points'];

    return Container(
      height: 105,
      child: Card(
        elevation: 5,
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Opacity(
                opacity: acquired ? 1.0 : 0.5,
                child: Icon(
                  icon,
                  size: 50,
                  color: acquired ? color : Colors.grey,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: acquired ? Theme.of(context).textTheme.titleLarge?.color : Colors.grey,
                          ),
                        ),
                        Spacer(),
                        Text(
                          acquired? '+${points} pts.' : '${points} pts.',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: acquired ? Colors.green.shade700 : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 16,
                        color: acquired ? Theme.of(context).textTheme.bodyMedium?.color : Colors.grey,
                      ),
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
        title: Text('Achievements unlocked ${_acuiredAchivement}/${_achivementsCount}'),
        automaticallyImplyLeading: false,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _achievements.length,
              itemBuilder: (context, index) {
                return _buildAchievementCard(_achievements[index]);
              },
            ),
    );
  }
}
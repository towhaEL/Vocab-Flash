import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:vocabflashcard_app/screens/achivement_screen.dart';
import 'statistics.dart'; // Import the new Statistics widget

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? _user;
  String _userEmail = '';
  bool _isLoading = true;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchUserData();
  }

  Future<void> _signOut() async {
    await _auth.signOut();
    Navigator.pushReplacementNamed(context, '/login');
  }

  Future<void> _fetchUserData() async {
    _user = _auth.currentUser;
    if (_user != null) {
      setState(() {
        _userEmail = _user!.email!;
        _isLoading = false;
      });
    }
  }


  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
        title: Text('User Profile'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: _signOut,
          ),
        ],
      ),
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Profile'),
        backgroundColor: Colors.blue,
        elevation: 5.0,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: _signOut,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildTopSection(),
          // SizedBox(height: 16),
          _buildMiddleSection(),
          // SizedBox(height: 16),
          // _buildBottomSection(),
        ],
      ),
    );
  }

  Widget _buildTopSection() {
    return Column(
      children: [
        CircleAvatar(
          radius: 30,
          child: Icon(Icons.person, size: 50),
        ),
        SizedBox(height: 16),
        Text(
          _userEmail,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
      ],
    );
  }

  Widget _buildMiddleSection() {
    return Column(
      children: [
        TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Statistics'),
            Tab(text: 'Achievements'),
            Tab(text: 'Preferences'),
          ],
        ),
        Container(
          height: 600, // Adjust height as needed
          child: TabBarView(
            controller: _tabController,
            children: [
              Statistics(), // Use the new Statistics widget
              AchievementScreen(),
              _buildPreferencesTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPreferencesTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Preferences', style: TextStyle(fontSize: 18)),
          // Add more details about preferences here
        ],
      ),
    );
  }

}
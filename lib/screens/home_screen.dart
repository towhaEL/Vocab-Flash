import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:vocabflashcard_app/screens/practice_screen.dart';
import '../widgets/bottom_navbar.dart';
import '../widgets/category_tile.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  User? _user;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    _user = FirebaseAuth.instance.currentUser;
    if (_user != null) {
      setState(() {
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Vocabulary App'),
        ),
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      body: _buildBody(),
      bottomNavigationBar: BottomNavbar(
        selectedIndex: _selectedIndex,
        onItemSelected: (index) {
          setState(() => _selectedIndex = index);
        },
      ),
    );
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return _buildCategoriesSection();
      case 1:
        return PracticeScreen();
      case 2:
        return ProfileScreen();
      default:
        return _buildCategoriesSection();
    }
  }

  Widget _buildCategoriesSection() {
    return 
    Scaffold(
      appBar: AppBar(
        title: Text('Select a category to start learning', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.deepPurpleAccent,
        elevation: 5.0,
        // foregroundColor: Colors.white,

      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: GridView.builder(
              padding: EdgeInsets.all(16),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 1,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: 26,
              itemBuilder: (context, index) {
                final letter = String.fromCharCode(65 + index); // A-Z
                return CategoryTile(
                  letter: letter,
                  onTap: () {
                    Navigator.pushNamed(
                      context, 
                      '/flashcard',
                      arguments: letter,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

}
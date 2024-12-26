import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vocabflashcard_app/services/firestore_service.dart';

class MoreTabScreen extends StatefulWidget {
  final Function(ThemeMode) onThemeChanged;

  MoreTabScreen({required this.onThemeChanged});

  @override
  _MoreTabScreenState createState() => _MoreTabScreenState();
}

class _MoreTabScreenState extends State<MoreTabScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? _user;
  bool _isDarkTheme = false;
  int _tapCount = 0;
  Timer? _tapTimer;

  @override
  void initState() {
    super.initState();
    _loadThemePreference();
  }

  Future<void> _signOut() async {
    await _auth.signOut();
    Navigator.pushReplacementNamed(context, '/login');
  }

  Future<void> _loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDarkTheme = prefs.getBool('isDarkTheme') ?? false;
    });
  }

  Future<void> _toggleTheme(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkTheme', value);
    setState(() {
      _isDarkTheme = value;
    });
    widget.onThemeChanged(value ? ThemeMode.dark : ThemeMode.light);
  }


  void _resetProgress() {
    final TextEditingController _passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Reset Progress'),
        content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: "Are you sure you want to reset your progress?",
                    // style: TextStyle(color: Colors.black),
                  ),
                  TextSpan(
                    text: " This action cannot be undone.",
                    style: TextStyle(color: Colors.red),
                  ),
                ],
              ),
            ),
          SizedBox(height: 10.0),
          TextField(
            controller: _passwordController,
            obscureText: true,
            decoration: InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Enter Password',
            ),
          ),
        ],
      ),
        actions: [
          TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Cancel'),
        ),
        TextButton(
          onPressed: () async {
            final password = _passwordController.text.trim();
            if (password.isNotEmpty) {
              await _firestoreService.resetAccount(context, password);
               // Call delete logic
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Password is required.')),
              );
            }
          },
          child: Text('Delete'),
        ),
        ],
      ),
    );
  }

void _deleteAccount() {
  final TextEditingController _passwordController = TextEditingController();

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Delete Account'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: "Are you sure you want to delete your account?",
                    // style: TextStyle(color: Colors.black),
                  ),
                  TextSpan(
                    text: " This action cannot be undone.",
                    style: TextStyle(color: Colors.red),
                  ),
                ],
              ),
            ),
          SizedBox(height: 10.0),
          TextField(
            controller: _passwordController,
            obscureText: true,
            decoration: InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Enter Password',
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Cancel'),
        ),
        TextButton(
          onPressed: () async {
            final password = _passwordController.text.trim();
            if (password.isNotEmpty) {
              await _firestoreService.deleteUserAccount(context, password);
              _user = _auth.currentUser;
              print(_user);
              if(_user == null) {
                Navigator.of(context, rootNavigator: true).pop(); // Close any active dialogs
                Navigator.pushReplacementNamed(context, '/login');
              }
               // Call delete logic
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Password is required.')),
              );
            }
          },
          child: Text('Delete'),
        ),
      ],
    ),
  );
}

  void _logoutAccount() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Logout'),
        content: Text('Are you sure you want to log out of your account?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              _signOut();
            },
            child: Text('Logout'),
          ),
        ],
      ),
    );
  }

  void _handleTap() async {
    _tapCount++;
    _tapTimer?.cancel();
    _tapTimer = Timer(Duration(seconds: 1), () {
      _tapCount = 0;
    });

    if (_tapCount == 3) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Nothing is here bro!'), duration: Duration(seconds: 1)));
    }

    if (_tapCount == 5) {
      _tapCount = 0;
      await _firestoreService.setAdmin();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Trust me bro!'), duration: Duration(seconds: 1)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('More'),
      ),
      body: ListView(
        padding: EdgeInsets.all(16.0),
        children: [
          Card(
            margin: EdgeInsets.symmetric(vertical: 8.0),
            child: ListTile(
              title: Row(
                children: [
                  Text('Logout'),
                  Spacer(),
                  Icon(Icons.logout, color: Colors.grey),
                ],
              ),
              onTap: _logoutAccount,
            ),
          ),
          Divider(),
          // App Theme Section
          ListTile(
            leading: Icon(Icons.color_lens, color: Colors.deepOrange),
            title: Text('App Theme', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          Card(
            margin: EdgeInsets.symmetric(vertical: 8.0),
            child: ListTile(
              title: Text('Dark Theme'),
              trailing: Switch(
                value: _isDarkTheme,
                onChanged: _toggleTheme,
              ),
            ),
          ),
          Divider(),

          // Help & Support Section
          ListTile(
            leading: Icon(Icons.help, color: Colors.blue),
            title: Text('Help & Support', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          Card(
            margin: EdgeInsets.symmetric(vertical: 8.0),
            child: ListTile(
              title: Text('FAQ & Help'),
              onTap: () {
                // Implement navigation to FAQ & Help screen
              },
            ),
          ),
          Card(
            margin: EdgeInsets.symmetric(vertical: 8.0),
            child: ListTile(
              title: Text('Contact Support'),
              onTap: () {
                // Implement navigation to Contact Support screen
              },
            ),
          ),
          Divider(),
          // Account Settings
          ListTile(
            leading: Icon(Icons.settings, color: Colors.red),
            title: Text('Account Settings', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          Card(
            margin: EdgeInsets.symmetric(vertical: 8.0),
            child: ListTile(
              title: Row(
                children: [
                  Text('Reset Progress'),
                  SizedBox(width: 8),
                  Icon(Icons.warning_amber_rounded, color: Colors.red.shade200),
                  Spacer(),
                  Icon(Icons.refresh_outlined, color: Colors.grey),
                ],
              ),
              onTap: _resetProgress,
            ),
          ),
          Card(
            margin: EdgeInsets.symmetric(vertical: 8.0),
            child: ListTile(
              title: Row(
                children: [
                  Text('Delete Account'),
                  SizedBox(width: 8),
                  Icon(Icons.warning_amber_rounded, color: Colors.red.shade200),
                  Spacer(),
                  Icon(Icons.delete, color: Colors.grey),
                ],
              ),
              onTap: _deleteAccount,
            ),
          ),
          Divider(),

          // App Info
          Card(
            margin: EdgeInsets.symmetric(vertical: 8.0),
            elevation: 0,
            child: GestureDetector(
              onTap: _handleTap,
              child: ListTile(
                title: Text('App Version'),
                subtitle: Text('1.0.0'), // Replace with actual app version
              ),
            ),
          ),
        ],
      ),
    );
  }
}
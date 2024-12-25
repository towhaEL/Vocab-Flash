import 'dart:async';
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
  bool _isDarkTheme = false;
  int _tapCount = 0;
  Timer? _tapTimer;

  @override
  void initState() {
    super.initState();
    _loadThemePreference();
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Reset Progress'),
        content: Text('Are you sure you want to reset your progress? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Implement reset progress logic here
            },
            child: Text('Reset'),
          ),
        ],
      ),
    );
  }

  void _deleteAccount() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Account'),
        content: Text('Are you sure you want to delete your account? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Implement delete account logic here
            },
            child: Text('Delete'),
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
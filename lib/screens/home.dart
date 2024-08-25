import 'package:flutter/material.dart';
import 'package:vendvibe/screens/post_screen.dart';
import 'package:vendvibe/screens/profile.dart';
import 'package:vendvibe/services/user_service.dart';

import 'login.dart';
import 'post_form.dart';

void main() {
  runApp(
    MaterialApp(
      title: 'VendVibe',
      theme: ThemeData(
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.black,
          titleTextStyle: TextStyle(color: Colors.amber[700]),
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: Colors.amber[700],
          elevation: 0,  // Remove shadow for a flat look
        ),
        bottomAppBarTheme: BottomAppBarTheme(
          color: Colors.black,
          elevation: 0, // Remove shadow for a flat look
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: Colors.black, // Background color of the bottom navigation bar
          selectedItemColor: Colors.amber[700], // Selected item color
          unselectedItemColor: Colors.white70, // Unselected item color
          showUnselectedLabels: true,
          selectedLabelStyle: TextStyle(color: Colors.amber[700]), // Label color when selected
          unselectedLabelStyle: TextStyle(color: Colors.white70), // Label color when not selected
        ),
      ),
      home: Home(),
    ),
  );
}

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int _currentIndex = 0;

  void showSnackBar(String message) {
    if (ScaffoldMessenger.maybeOf(context) != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          duration: Duration(seconds: 2),
        ),
      );
    } else {
      print('ScaffoldMessenger is not available');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'VendVibe',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.amber[700]!, Colors.amber[900]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 5,
        actions: [
          IconButton(
            icon: Icon(Icons.power_settings_new, color: Colors.white),
            onPressed: () async {
              await logout();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => Login()),
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: _currentIndex == 0 ? PostScreen() : Profile(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => PostForm(
                title: 'Add new post',
              ),
            ),
          );
          showSnackBar('Navigating to Post Form');
        },
        child: Icon(Icons.add, color: Colors.black),
        shape: CircleBorder(), // Modern circle shape
        backgroundColor: Colors.amber[900]!,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
          showSnackBar(index == 0 ? 'Home selected' : 'Profile selected');
        },
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.amber[900]!, // Background color to match app bar
        selectedItemColor: Colors.black, // Selected item color
        unselectedItemColor: Colors.white70, // Unselected item color
        selectedLabelStyle: TextStyle(color: Colors.white), // Color of selected label
        unselectedLabelStyle: TextStyle(color: Colors.white), // Color of unselected label
      ),
    );
  }
}

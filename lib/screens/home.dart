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
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.amber,
          titleTextStyle: TextStyle(color: Colors.black),
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: Colors.amber[700],
        ),
        bottomAppBarTheme: BottomAppBarTheme(
          color: Colors.amber[700],
          elevation: 10,
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
    // Ensure the ScaffoldMessenger is available
    if (ScaffoldMessenger.maybeOf(context) != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          duration: Duration(seconds: 2),
        ),
      );
    } else {
      // Handle the case when ScaffoldMessenger is not available
      print('ScaffoldMessenger is not available');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.amber[700],
        title: const Text('VendVibe', style: TextStyle(color: Colors.black),),
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app, color: Colors.black,),
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
        child: Icon(Icons.add, color: Colors.black,),
        backgroundColor: Colors.amber[700],
        shape: const CircleBorder(),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        notchMargin: 5,
        elevation: 10,
        clipBehavior: Clip.antiAlias,
        color: Colors.amber[700],
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              icon: const Icon(Icons.home, size: 40, color: Colors.black,),
              onPressed: () {
                setState(() {
                  _currentIndex = 0;
                });
                showSnackBar('Home selected');
              },
            ),
            IconButton(
              icon: const Icon(Icons.person, size: 40, color: Colors.black,),
              onPressed: () {
                setState(() {
                  _currentIndex = 1;
                });
                showSnackBar('Profile selected');
              },
            ),
          ],
        ),
      ),
    );
  }
}

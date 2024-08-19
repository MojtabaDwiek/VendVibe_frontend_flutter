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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.amber[700],
        title: Text('VendVibe', style: TextStyle(color: Colors.black),),
        actions: [
          IconButton(
            icon: Icon(Icons.exit_to_app, color: Colors.black,),
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
              icon: Icon(Icons.home, size: 40, color: Colors.black,),
              onPressed: () {
                setState(() {
                  _currentIndex = 0;
                });
              },
            ),
            IconButton(
              icon: Icon(Icons.person, size: 40, color: Colors.black,),
              onPressed: () {
                setState(() {
                  _currentIndex = 1;
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}
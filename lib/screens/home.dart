// ignore_for_file: library_private_types_in_public_api, use_build_context_synchronously

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:vendvibe/screens/post_screen.dart';
import 'package:vendvibe/screens/profile.dart';
import 'package:vendvibe/screens/search_screen.dart'; // Import the SearchScreen
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
          elevation: 0, // Remove shadow for a flat look
          shape: RoundedRectangleBorder( // Change shape to rounded rectangle
            borderRadius: BorderRadius.circular(15), // Set border radius to 15
          ),
        ),
        bottomAppBarTheme: const BottomAppBarTheme(
          color: Colors.black,
          elevation: 0, // Remove shadow for a flat look
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: Colors.black, // Background color of the bottom navigation bar
          selectedItemColor: Colors.amber[700], // Selected item color
          unselectedItemColor: Colors.white70, // Unselected item color
          showUnselectedLabels: true,
          selectedLabelStyle: TextStyle(color: Colors.amber[700]), // Label color when selected
          unselectedLabelStyle: const TextStyle(color: Colors.white70), // Label color when not selected
        ),
      ),
      home: const Home(),
    ),
  );
}

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int _currentIndex = 0;

  Future<void> _refreshPage() async {
    // Your refresh logic here, e.g., retrieving posts
    await Future.delayed(const Duration(seconds: 2));
    setState(() {
      // Trigger the refresh
    });
  }

  void showSnackBar(String message) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ScaffoldMessenger.maybeOf(context) != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        if (kDebugMode) {
          print('ScaffoldMessenger is not available');
        }
      }
    });
  }

  Future<void> _showLogoutConfirmation() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      barrierDismissible: false, // Prevent dismissing by tapping outside
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.black,
          title: const Text('Logout', style: TextStyle(color: Color.fromRGBO(255, 111, 0, 1))),
          content: const Text(
            'Are you sure you want to logout?',
            style: TextStyle(color: Color.fromRGBO(255, 111, 0, 1)),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false); // Do not logout
              },
              child: const Text('Cancel', style: TextStyle(color: Color.fromRGBO(255, 111, 0, 1))),
            ),
            TextButton(
              onPressed: () async {
                await logout();
                Navigator.of(context).pop(true); // Logout
              },
              child: const Text('Logout', style: TextStyle(color: Color.fromRGBO(255, 111, 0, 1))),
            ),
          ],
        );
      },
    );

    if (shouldLogout == true) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const Login()),
        (route) => false,
      );
    }
  }

  Future<bool> _onWillPop() async {
    return (await showDialog(
      context: context,
      barrierDismissible: false, // Prevent dismissing by tapping outside
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.black,
          title: const Text('Exit App', style: TextStyle(color: Color.fromRGBO(255, 111, 0, 1))),
          content: const Text(
            'Are you sure you want to exit the app?',
            style: TextStyle(color: Color(0xFFFF6F00)),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false); // Do not exit the app
              },
              child: const Text('Cancel', style: TextStyle(color: Color.fromRGBO(255, 111, 0, 1))),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true); // Exit the app
              },
              child: const Text('Exit', style: TextStyle(color: Color.fromRGBO(255, 111, 0, 1))),
            ),
          ],
        );
      },
    )) ?? false; // Default to false if dialog is dismissed
  }

  @override
  void initState() {
    super.initState();
    // Trigger refresh when the page is opened
    _refreshPage();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.search, color: Colors.white), // Search icon
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SearchScreen()), // Navigate to SearchScreen
              );
            },
          ),
          title: const Text(
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
              icon: const Icon(Icons.power_settings_new, color: Colors.white),
              onPressed: _showLogoutConfirmation,
            ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: _refreshPage,
          child: _currentIndex == 0 ? const PostScreen(postId: 0) : const Profile(),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const PostForm(
                  title: 'Add new post',
                ),
              ),
            );
          
          },
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15), // Rounded rectangle shape
          ),
          backgroundColor: Colors.white,
          child: Icon(Icons.add, color: Colors.amber[900]!),
        ),
        floatingActionButtonLocation: CustomFloatingActionButtonLocation(),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
            
          },
          items: const [
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
          selectedLabelStyle: const TextStyle(color: Colors.white), // Color of selected label
          unselectedLabelStyle: const TextStyle(color: Colors.white), // Color of unselected label
        ),
      ),
    );
  }
}

class CustomFloatingActionButtonLocation extends FloatingActionButtonLocation {
  @override
  Offset getOffset(ScaffoldPrelayoutGeometry scaffoldGeometry) {
    // Position the FAB lower down on the screen
    double fabX = (scaffoldGeometry.scaffoldSize.width - scaffoldGeometry.floatingActionButtonSize.width) / 2;
    double fabY = scaffoldGeometry.scaffoldSize.height - scaffoldGeometry.floatingActionButtonSize.height - 10;
    return Offset(fabX, fabY);
  }
}

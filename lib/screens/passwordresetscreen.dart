// ignore_for_file: use_build_context_synchronously, library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:vendvibe/models/api_response.dart';
import 'package:vendvibe/services/user_service.dart';
import 'login.dart';  // Importing the login screen

class ForgotPassword extends StatefulWidget {
  const ForgotPassword({super.key});

  @override
  _ForgotPasswordState createState() => _ForgotPasswordState();
}

class _ForgotPasswordState extends State<ForgotPassword> {
  final GlobalKey<FormState> formkey = GlobalKey<FormState>();
  TextEditingController txtEmail = TextEditingController();
  TextEditingController txtPassword = TextEditingController();
  TextEditingController txtPasswordConfirm = TextEditingController();
  bool loading = false;

  void _resetPassword() async {
    if (formkey.currentState!.validate()) {
      setState(() {
        loading = true;
      });
      
      ApiResponse response = await resetPassword(
        txtEmail.text,
        txtPassword.text,
        txtPasswordConfirm.text,
      );

      setState(() {
        loading = false;
      });

      if (response.error == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Password has been reset successfully'),
        ));
        
        // Redirect to login screen
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const Login()), 
          (route) => false,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${response.error}'),
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 115, 115, 115),
      body: Form(
        key: formkey,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 10),
              child: Center(
                child: Image.asset(
                  'assets/logo.png', // Adjust the logo image
                  height: 250, 
                ),
              ),
            ),
            const SizedBox(height: 0),
            Center(
              child: Text(
                'Reset Your Password',
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.amber[700], // Amber color
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 50), // Spacing
            TextFormField(
              controller: txtEmail,
              validator: (val) => val!.isEmpty ? 'Invalid email address' : null,
              decoration: InputDecoration(
                labelText: 'Email',
                labelStyle: TextStyle(fontSize: 16, color: Colors.amber[700]),
                prefixIcon: Icon(Icons.mail, color: Colors.amber[700]),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.amber[700]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide(color: Colors.amber[700]!),
                ),
              ),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: txtPassword,
              obscureText: true,
              validator: (val) => val!.length < 6 ? 'Password should be at least 6 chars' : null,
              decoration: InputDecoration(
                labelText: 'New Password',
                labelStyle: TextStyle(fontSize: 16, color: Colors.amber[700]),
                prefixIcon: Icon(Icons.lock, color: Colors.amber[700]),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.amber[700]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide(color: Colors.amber[700]!),
                ),
              ),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: txtPasswordConfirm,
              obscureText: true,
              validator: (val) => val != txtPassword.text ? 'Passwords do not match' : null,
              decoration: InputDecoration(
                labelText: 'Confirm Password',
                labelStyle: TextStyle(fontSize: 16, color: Colors.amber[700]),
                prefixIcon: Icon(Icons.lock, color: Colors.amber[700]),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.amber[700]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide(color: Colors.amber[700]!),
                ),
              ),
            ),
            const SizedBox(height: 10),
            loading
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    onPressed: _resetPassword,
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.black,
                      backgroundColor: Colors.amber[700], // Amber color
                    ),
                    child: const Text('Reset Password'),
                  ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:vendvibe/models/api_response.dart';
import 'package:vendvibe/models/user.dart';
import 'package:vendvibe/screens/home.dart';
import 'package:vendvibe/services/user_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constant.dart';
import 'login.dart';

class Register extends StatefulWidget {
  const Register({super.key});

  @override
  _RegisterState createState() => _RegisterState();
}

class _RegisterState extends State<Register> {
  GlobalKey<FormState> formKey = GlobalKey<FormState>();
  bool loading = false;
  TextEditingController
      nameController = TextEditingController(),
      emailController = TextEditingController(),
      passwordController = TextEditingController(),
      passwordConfirmController = TextEditingController(),
      phoneController = TextEditingController(); // Added phoneController

  void _registerUser() async {
    ApiResponse response = await register(
        nameController.text,
        emailController.text,
        passwordController.text,
        phoneController.text // Pass phone number
    );
    if (response.error == null) {
      _saveAndRedirectToHome(response.data as User);
    } else {
      setState(() {
        loading = !loading;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${response.error}')
      ));
    }
  }

  // Save and redirect to home
  void _saveAndRedirectToHome(User user) async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    await pref.setString('token', user.token ?? '');
    await pref.setInt('userId', user.id ?? 0);
    Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => Home()), (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 115, 115, 115),
      body: Form(
        key: formKey,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
          children: [
            const SizedBox(height: 0), // Adjusted for spacing from the top
            Padding(
              padding: const EdgeInsets.only(left: 10), // Adjust the left padding as needed
              child: Center(
                child: Image.asset(
                  'assets/logo.png',
                  height: 250, // Adjust logo size as needed
                ),
              ),
            ),
            const SizedBox(height: 0), // Spacing between logo and text
            Center(
              child: Text(
                'Welcome to VendVibe', // Replace with your desired text
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.amber[700], // Amber color
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 35), // Adjusted for spacing after the text
            TextFormField(
              controller: nameController,
              validator: (val) => val!.isEmpty ? 'Invalid name' : null,
              decoration: InputDecoration(
                labelText: 'Name',
                labelStyle: TextStyle(fontSize: 16, color: Colors.amber[700]),
                prefixIcon: Icon(Icons.person, color: Colors.amber[700]),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color.fromARGB(255, 115, 115, 115)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide(color: Colors.amber[700]!),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Colors.red),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Colors.red),
                ),
              ),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
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
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Colors.red),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Colors.red),
                ),
              ),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              validator: (val) => val!.isEmpty ? 'Invalid phone number' : null,
              decoration: InputDecoration(
                labelText: 'Phone',
                labelStyle: TextStyle(fontSize: 16, color: Colors.amber[700]),
                prefixIcon: Icon(Icons.phone, color: Colors.amber[700]),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.amber[700]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide(color: Colors.amber[700]!),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Colors.red),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Colors.red),
                ),
              ),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: passwordController,
              obscureText: true,
              validator: (val) => val!.length < 6 ? 'Required at least 6 chars' : null,
              decoration: InputDecoration(
                labelText: 'Password',
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
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Colors.red),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Colors.red),
                ),
              ),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: passwordConfirmController,
              obscureText: true,
              validator: (val) => val != passwordController.text ? 'Confirm password does not match' : null,
              decoration: InputDecoration(
                labelText: 'Confirm password',
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
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Colors.red),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Colors.red),
                ),
              ),
            ),
            const SizedBox(height: 10),
            loading
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    onPressed: () {
                      if (formKey.currentState!.validate()) {
                        setState(() {
                          loading = !loading;
                          _registerUser();
                        });
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.black,
                      backgroundColor: Colors.amber[700], // text color
                    ),
                    child: const Text('Register'),
                  ),
            const SizedBox(height: 20),
            kLoginRegisterHint('Already have an account? ', 'Login', () {
              Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => Login()), (route) => false);
            })
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:vendvibe/models/api_response.dart';
import 'package:vendvibe/models/user.dart';
import 'package:vendvibe/services/user_service.dart';

import '../constant.dart';
import 'login.dart';
import 'favorites_tab.dart';
import 'my_items_tab.dart';

class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  _ProfileState createState() => _ProfileState();
}

class _ProfileState extends State<Profile> with SingleTickerProviderStateMixin {
  User? user;
  bool loading = true;
  GlobalKey<FormState> formKey = GlobalKey<FormState>();
  TextEditingController txtNameController = TextEditingController();
  TextEditingController txtPhoneController = TextEditingController();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    getUser();
  }

  @override
  void dispose() {
    _tabController.dispose();
    txtNameController.dispose();
    txtPhoneController.dispose();
    super.dispose();
  }

  Future<void> getUser() async {
    ApiResponse response = await getUserDetail();
    if (response.error == null) {
      setState(() {
        user = response.data as User;
        txtNameController.text = user?.name ?? '';
        txtPhoneController.text = user?.phoneNumber ?? '';
        loading = false;
      });
    } else {
      if (response.error == unauthorized) {
        await logout();
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const Login()),
          (route) => false,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${response.error}')),
        );
      }
    }
  }

  Future<void> updateProfile() async {
    ApiResponse response = await updateUser(
      txtNameController.text,
      txtPhoneController.text,
      null, // Assuming no image is updated in this context
    );
    setState(() {
      loading = false;
    });
    if (response.error == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${response.data}')),
      );
    } else {
      if (response.error == unauthorized) {
        await logout();
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const Login()),
          (route) => false,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${response.error}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return loading
        ? Container(
            color: Colors.grey[700],
            child: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.amber[900]!),
              ),
            ),
          )
        : Scaffold(
            body: Column(
              children: [
                Container(
                  color: Colors.grey[700],
                  child: TabBar(
                    controller: _tabController,
                    labelColor: Colors.amber[900],
                    indicatorColor: Colors.amber[900],
                    unselectedLabelColor: Colors.white,
                    tabs: const [
                      Tab(text: 'Profile', icon: Icon(Icons.person)),
                      Tab(text: 'Favorites', icon: Icon(Icons.favorite)),
                      Tab(text: 'My Items', icon: Icon(Icons.list)),
                    ],
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: ListView(
                          children: [
                            const SizedBox(height: 20),
                            Form(
                              key: formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Name',
                                    style: TextStyle(
                                      color: Colors.amber[900],
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    decoration: InputDecoration(
                                      filled: true,
                                      fillColor: Colors.grey[800],
                                      border: const OutlineInputBorder(),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    ),
                                    controller: txtNameController,
                                    validator: (val) => val!.isEmpty ? 'Invalid Name' : null,
                                  ),
                                  const SizedBox(height: 20),
                                  Text(
                                    'Phone Number',
                                    style: TextStyle(
                                      color: Colors.amber[900],
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    decoration: InputDecoration(
                                      filled: true,
                                      fillColor: Colors.grey[800],
                                      border: const OutlineInputBorder(),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    ),
                                    controller: txtPhoneController,
                                    keyboardType: TextInputType.phone,
                                    validator: (val) {
                                      if (val!.isEmpty) {
                                        return 'Invalid Phone Number';
                                      }
                                      if (val.length != 8 || !RegExp(r'^\d+$').hasMatch(val)) {
                                        return 'Phone Number must be 8 digits';
                                      }
                                      return null; // Return null if validation passes
                                    },
                                  ),
                                  const SizedBox(height: 20),
                                  Center(
                                    child: SizedBox(
                                      width: 200, // Set the desired width here
                                      child: ElevatedButton(
                                        onPressed: () {
                                          if (formKey.currentState!.validate()) {
                                            setState(() {
                                              loading = true;
                                            });
                                            updateProfile();
                                          }
                                        },
                                        style: ElevatedButton.styleFrom(
                                          foregroundColor: Colors.white,
                                          backgroundColor: Colors.amber[900],
                                          padding: const EdgeInsets.symmetric(vertical: 14),
                                          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                        ),
                                        child: const Text('Update'),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const FavoritesTab(),
                      const MyItemsTab(),
                    ],
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.grey[700],
          );
  }
}

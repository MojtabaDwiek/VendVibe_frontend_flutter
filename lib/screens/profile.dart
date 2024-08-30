import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:vendvibe/models/api_response.dart';
import 'package:vendvibe/models/user.dart';
import 'package:vendvibe/services/user_service.dart';

import '../constant.dart';
import 'login.dart';
import 'favorites_tab.dart';
import 'my_items_tab.dart';

class Profile extends StatefulWidget {
  @override
  _ProfileState createState() => _ProfileState();
}

class _ProfileState extends State<Profile> with SingleTickerProviderStateMixin {
  User? user;
  bool loading = true;
  GlobalKey<FormState> formKey = GlobalKey<FormState>();
  File? _imageFile;
  final _picker = ImagePicker();
  TextEditingController txtNameController = TextEditingController();
  late TabController _tabController;

  Future<void> getImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  void getUser() async {
    ApiResponse response = await getUserDetail();
    if (response.error == null) {
      setState(() {
        user = response.data as User;
        loading = false;
        txtNameController.text = user!.name ?? '';
      });
    } else if (response.error == unauthorized) {
      logout().then((value) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => Login()),
          (route) => false,
        );
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${response.error}')),
      );
    }
  }

  void updateProfile() async {
    ApiResponse response = await updateUser(txtNameController.text, getStringImage(_imageFile));
    setState(() {
      loading = false;
    });
    if (response.error == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${response.data}')),
      );
    } else if (response.error == unauthorized) {
      logout().then((value) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => Login()),
          (route) => false,
        );
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${response.error}')),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    getUser();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return loading
        ? const Center(child: CircularProgressIndicator())
        : Scaffold(
            appBar: AppBar(
              title: Text('Profile', style: TextStyle(color: Colors.amber[900])),
              backgroundColor: Colors.grey[700],
              bottom: TabBar(
                controller: _tabController,
                tabs: [
                  Tab(text: 'Profile', icon: Icon(Icons.person, color: Colors.amber[900])),
                  Tab(text: 'Favorites', icon: Icon(Icons.favorite, color: Colors.amber[900])),
                  Tab(text: 'My Items', icon: Icon(Icons.list, color: Colors.amber[900])),
                ],
              ),
            ),
            body: TabBarView(
              controller: _tabController,
              children: [
                Padding(
                  padding: EdgeInsets.all(20),
                  child: ListView(
                    children: [
                      Center(
                        child: GestureDetector(
                          onTap: getImage,
                          child: CircleAvatar(
                            radius: 60,
                            backgroundColor: Colors.amber[900],
                            backgroundImage: _imageFile != null
                                ? FileImage(_imageFile!)
                                : user?.image != null
                                    ? NetworkImage('${user!.image}')
                                    : null,
                            child: _imageFile == null && user?.image == null
                                ? Icon(Icons.camera_alt, color: Colors.white, size: 30)
                                : null,
                          ),
                        ),
                      ),
                      SizedBox(height: 20),
                      Form(
                        key: formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Name',
                              style: TextStyle(color: Colors.amber[900], fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 8),
                            TextFormField(
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: Colors.grey[800],
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              ),
                              controller: txtNameController,
                              validator: (val) => val!.isEmpty ? 'Invalid Name' : null,
                            ),
                            SizedBox(height: 20),
                            ElevatedButton(
                              onPressed: () {
                                if (formKey.currentState!.validate()) {
                                  setState(() {
                                    loading = true;
                                  });
                                  updateProfile();
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                foregroundColor: Colors.white, backgroundColor: Colors.amber[900],
                                padding: EdgeInsets.symmetric(vertical: 14),
                                textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              child: Text('Update'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                FavoritesTab(),
                MyItemsTab(),
              ],
            ),
            backgroundColor: Colors.grey[700],
          );
  }
}

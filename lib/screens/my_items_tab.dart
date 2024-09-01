import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vendvibe/constant.dart';
import 'package:vendvibe/models/api_response.dart';
import 'package:vendvibe/screens/login.dart';
import 'package:vendvibe/services/post_service.dart';
import 'package:vendvibe/services/user_service.dart';

class MyItemsTab extends StatefulWidget {
  @override
  _MyItemsTabState createState() => _MyItemsTabState();
}

class _MyItemsTabState extends State<MyItemsTab> {
  List<dynamic> _items = [];
  bool _loading = false;
  bool _isGridView = true;
  late PageController _pageController;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _pageController = PageController(); // Initialize PageController
    _fetchMyItems();
  }

  @override
  void dispose() {
    _pageController.dispose(); // Dispose PageController
    super.dispose();
  }

  Future<String?> _getAuthToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<void> _fetchMyItems() async {
    setState(() {
      _loading = true;
    });

    final String? token = await _getAuthToken();
    final Uri uri = Uri.parse('http://192.168.0.113:8000/api/user/user-items');

    try {
      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _items = data.map((item) => item['post']).toList();
          _loading = false;
        });
      } else {
        print('Error: ${response.reasonPhrase}');
        setState(() {
          _items = [];
          _loading = false;
        });
      }
    } catch (e) {
      print('Error fetching items: $e');
      setState(() {
        _items = [];
        _loading = false;
      });
    }
  }

  void _showPageView(int index) {
    setState(() {
      _isGridView = false;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _pageController.jumpToPage(index);
    });
  }

  void _showGridView() {
    setState(() {
      _isGridView = true;
    });
  }

  Future<void> _launchWhatsApp(String phoneNumber) async {
    final url = 'https://wa.me/$phoneNumber';
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  void _handleDeletePost(int postId) async {
    ApiResponse response = await deletePost(postId);
    if (response.error == null) {
      _fetchMyItems();
    } else if (response.error == unauthorized) {
      logout().then((_) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => Login()),
          (route) => false,
        );
      });
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${response.error}'),
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      body: _isGridView
          ? Container(
              color: Colors.grey[700],
              child: _loading
                  ? Center(child: CircularProgressIndicator())
                  : _items.isEmpty
                      ? Center(child: Text('No items found', style: TextStyle(color: Colors.white)))
                      : GridView.builder(
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 8.0,
                            mainAxisSpacing: 8.0,
                            childAspectRatio: 0.75,
                          ),
                          itemCount: _items.length,
                          itemBuilder: (context, index) {
                            final item = _items[index];
                            final images = item['images'] as List<dynamic>? ?? [];
                            final imageUrl = images.isNotEmpty
                                ? 'http://192.168.0.113:8000/storage/${images[0]}'
                                : 'http://192.168.0.113:8000/storage/default.jpg';

                            final priceString = item['price']?.toString() ?? '0.0';
                            final price = double.tryParse(priceString) ?? 0.0;

                            return GestureDetector(
                              onTap: () {
                                _showPageView(index);
                              },
                              child: Stack(
                                children: [
                                  Positioned.fill(
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.network(
                                        imageUrl,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          return Center(child: Text('Image failed to load'));
                                        },
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    top: 10,
                                    left: 0,
                                    right: 0,
                                    child: Center(
                                      child: Container(
                                        padding: EdgeInsets.symmetric(vertical: 4, horizontal: 12),
                                        decoration: BoxDecoration(
                                          color: Colors.amber[900],
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          '\$${price.toStringAsFixed(2)}',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 10,
                                    left: 0,
                                    right: 0,
                                    child: Center(
                                      child: IconButton(
                                        icon: Icon(Icons.phone, color: Colors.amber[900]),
                                        onPressed: () {
                                          final phoneNumber = item['user']?['phone'] ?? '';
                                          if (phoneNumber.isNotEmpty) {
                                            _launchWhatsApp(phoneNumber);
                                          } else {
                                            print('No phone number available');
                                          }
                                        },
                                      ),
                                    ),
                                  ),
                                  // Delete button
                                  Positioned(
                                    top: 0,
                                    left: 0,
                                    child: IconButton(
                                      icon: Icon(Icons.delete, color: Colors.red),
                                      onPressed: () {
                                        _handleDeletePost(item['id']);
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
            )
          : PageView.builder(
              controller: _pageController,
              itemCount: _items.length,
              itemBuilder: (context, index) {
                final item = _items[index];
                final images = item['images'] as List<dynamic>? ?? [];
                final priceString = item['price']?.toString() ?? '0.0';
                final price = double.tryParse(priceString) ?? 0.0;

                final phoneNumber = item['user']?['phone'] ?? '';

                return GestureDetector(
                  onTap: () {
                    _showGridView();
                  },
                  child: Stack(
                    children: [
                      PageView.builder(
                        itemCount: images.length,
                        itemBuilder: (context, imageIndex) {
                          final imageUrl = images.isNotEmpty
                              ? 'http://192.168.0.113:8000/storage/${images[imageIndex]}'
                              : 'http://192.168.0.113:8000/storage/default.jpg';

                          return Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Center(child: Text('Image failed to load'));
                            },
                          );
                        },
                      ),
                      Positioned(
                        top: 10,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: 4, horizontal: 12),
                            decoration: BoxDecoration(
                              color: Colors.amber[900],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '\$${price.toStringAsFixed(2)}',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(8.0),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.black.withOpacity(0.7),
                                Colors.transparent,
                              ],
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item['body'] ?? 'No description',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  IconButton(
                                    icon: Icon(Icons.phone, color: Colors.amber[900]),
                                    onPressed: () {
                                      if (phoneNumber.isNotEmpty) {
                                        _launchWhatsApp(phoneNumber);
                                      } else {
                                        print('No phone number available');
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

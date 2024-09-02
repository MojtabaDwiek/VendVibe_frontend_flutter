import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vendvibe/screens/PostDetailScreen.dart';

class MyItemsTab extends StatefulWidget {
  @override
  _MyItemsTabState createState() => _MyItemsTabState();
}

class _MyItemsTabState extends State<MyItemsTab> {
  List<dynamic> _items = [];
  bool _loading = false;
  bool _isGridView = true; // Whether the current view is grid view

  @override
  void initState() {
    super.initState();
    _fetchMyItems();
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
        setState(() {
          _items = [];
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _items = [];
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
      body: Container(
        color: Colors.grey[700],
        child: _loading
            ? Center(child: CircularProgressIndicator())
            : _items.isEmpty
                ? Center(child: Text('No items found', style: TextStyle(color: Colors.white)))
                : _isGridView
                    ? GridView.builder(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 8.0,
                          mainAxisSpacing: 8.0,
                          childAspectRatio: 0.75,
                        ),
                        itemCount: _items.length,
                        itemBuilder: (context, index) {
                          final item = _items[index];
                          final user = item['user'] ?? {};
                          final userName = user['name'] ?? 'Unknown';
                          final userImage = user['image'] != null
                              ? 'http://192.168.0.113:8000/storage/${user['image']}'
                              : 'http://192.168.0.113:8000/storage/default-user.jpg';

                          final imageUrl = item['images'] != null && item['images'].isNotEmpty
                              ? 'http://192.168.0.113:8000/storage/${item['images'][0]}'
                              : 'http://192.168.0.113:8000/storage/default.jpg';

                          final priceString = item['price']?.toString() ?? '0.0';
                          final price = double.tryParse(priceString) ?? 0.0;

                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => PostDetailScreen(
                                    posts: _items,
                                    initialIndex: index,
                                  ),
                                ),
                              );
                            },
                            child: Card(
                              elevation: 4.0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
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
                                    bottom: 0,
                                    left: 0,
                                    right: 0,
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            Colors.black.withOpacity(0.7),
                                            Colors.black.withOpacity(0.1),
                                          ],
                                          begin: Alignment.bottomCenter,
                                          end: Alignment.topCenter,
                                        ),
                                        borderRadius: const BorderRadius.only(
                                          bottomLeft: Radius.circular(12),
                                          bottomRight: Radius.circular(12),
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              CircleAvatar(
                                                backgroundImage: NetworkImage(userImage),
                                                radius: 16,
                                              ),
                                              SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  userName,
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          SizedBox(height: 8),
                                          if (price > 0)
                                            Padding(
                                              padding: const EdgeInsets.only(bottom: 4.0),
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(
                                                    vertical: 4.0, horizontal: 8.0),
                                                decoration: BoxDecoration(
                                                  color: Colors.amber[900]!,
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: Text(
                                                  '\$${price.toStringAsFixed(2)}',
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          Text(
                                            item['body'] ?? 'No description',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 2,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      )
                    : PageView.builder(
                        itemCount: _items.length,
                        itemBuilder: (context, index) {
                          final item = _items[index];
                          final images = item['images'] as List<dynamic>? ?? [];
                          final phoneNumber = item['user']?['phone'] ?? '';

                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _isGridView = true; // Switch back to grid view on tap
                              });
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
                                  bottom: 0,
                                  left: 0,
                                  right: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.black.withOpacity(0.7),
                                          Colors.black.withOpacity(0.1),
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
                                        SizedBox(height: 8),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.end,
                                          children: [
                                            IconButton(
                                              icon: Icon(Icons.phone, color: Colors.amber[900]),
                                              onPressed: () {
                                                if (phoneNumber.isNotEmpty) {
                                                  final url = 'https://wa.me/$phoneNumber';
                                                  launch(url);
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
      ),
    );
  }
}

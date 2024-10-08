// ignore_for_file: library_private_types_in_public_api

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vendvibe/constant.dart';
import 'package:vendvibe/screens/PostDetailScreen.dart';

class MyItemsTab extends StatefulWidget {
  const MyItemsTab({super.key});

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
    final Uri uri = Uri.parse('$userURL/user-items');

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

  Future<void> _deletePost(int postId, int index) async {
    final String? token = await _getAuthToken();
    final Uri uri = Uri.parse('$postsURL/$postId');

    try {
      final response = await http.delete(
        uri,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (kDebugMode) {
          print('Post deleted: ${data['message']}');
        }

        setState(() {
          _items.removeAt(index);
        });
      } else {
        final data = json.decode(response.body);
        if (kDebugMode) {
          print('Failed to delete post: ${data['message']}');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting post: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Colors.grey[700],
        child: _loading
            ? const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Color.fromRGBO(255, 111, 0, 1)),))
            : _items.isEmpty
                ? const Center(child: Text('No items found', style: TextStyle(color: Colors.white)))
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
                                          return const Center(child: Text('Image failed to load'));
                                        },
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red),
                                      onPressed: () {
                                        showDialog(
  context: context,
  builder: (BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.black, // Add this line
      title: Text(
        'Confirm Deletion',
        style: TextStyle(color: Colors.amber[900]), // Add this line
      ),
      content: Text(
        'Are you sure you want to delete this post?',
        style: TextStyle(color: Colors.amber[900]), // Add this line
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text(
            'Cancel',
            style: TextStyle(color: Colors.amber[900]), // Add this line
          ),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            _deletePost(item['id'], index);
          },
          child: Text(
            'Delete',
            style: TextStyle(color: Colors.amber[900]), // Add this line
          ),
        ),
      ],
    );
  },
);
                                      },
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
                                         
                                          const SizedBox(height: 8),
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
                                        return const Center(child: Text('Image failed to load'));
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
                                              backgroundImage: NetworkImage(
                                                item['user']?['image'] != null
                                                    ? 'http://192.168.0.113:8000/storage/${item['user']['image']}'
                                                    : 'http://192.168.0.113:8000/storage/default-user.jpg',
                                              ),
                                              radius: 16,
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                item['user']?['name'] ?? 'Unknown',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        if (item['price'] != null && item['price'] > 0)
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
                                                '\$${item['price'].toStringAsFixed(2)}',
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
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () {
                                      showDialog(
                                        context: context,
                                        builder: (BuildContext context) {
                                          return AlertDialog(
                                            title: const Text('Confirm Deletion'),
                                            content: const Text('Are you sure you want to delete this post?'),
                                            actions: [
                                              TextButton(
                                                onPressed: () {
                                                  Navigator.of(context).pop();
                                                },
                                                child: const Text('Cancel'),
                                              ),
                                              TextButton(
                                                onPressed: () {
                                                  Navigator.of(context).pop();
                                                  _deletePost(item['id'], index);
                                                },
                                                child: const Text('Delete'),
                                              ),
                                            ],
                                          );
                                        },
                                      );
                                    },
                                  ),
                                ),
                                Positioned(
                                  top: 8,
                                  left: 8,
                                  child: IconButton(
                                    icon: const Icon(Icons.phone, color: Colors.white),
                                    onPressed: () async {
                                      final phoneNumber = item['user']['phone'] ?? '';
                                      final url = 'tel:$phoneNumber';

                                      if (await canLaunch(url)) {
                                        await launch(url);
                                      } else {
                                        throw 'Could not launch $url';
                                      }
                                    },
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

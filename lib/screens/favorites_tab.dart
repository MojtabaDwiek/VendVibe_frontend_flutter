// ignore_for_file: library_private_types_in_public_api

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vendvibe/constant.dart';
import 'package:vendvibe/screens/PostDetailScreen.dart';

class FavoritesTab extends StatefulWidget {
  const FavoritesTab({super.key});

  @override
  _FavoritesTabState createState() => _FavoritesTabState();
}

class _FavoritesTabState extends State<FavoritesTab> {
  List<dynamic> _favorites = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _fetchFavorites();
  }

  Future<String?> _getAuthToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<void> _fetchFavorites() async {
    setState(() {
      _loading = true;
    });

    final String? token = await _getAuthToken();
    final Uri uri = Uri.parse('$userURL/favorites');

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
          _favorites = data.map((item) => item['post']).toList();
          _loading = false;
        });
      } else {
        setState(() {
          _favorites = [];
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _favorites = [];
        _loading = false;
      });
    }
  }

  Future<void> _removeFromFavorites(int postId) async {
    setState(() {
      _loading = true;
    });

    final String? token = await _getAuthToken();
    final Uri uri = Uri.parse('$postsURL/$postId/favorites');

    try {
      final response = await http.delete(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          _favorites.removeWhere((post) => post['id'] == postId);
          _loading = false;
        });
      } else {
        // Handle error response
        setState(() {
          _loading = false;
        });
      }
    } catch (e) {
      // Handle exception
      setState(() {
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
            ? const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Color.fromRGBO(255, 111, 0, 1)),))
            : _favorites.isEmpty
                ? const Center(child: Text('No favorites found', style: TextStyle(color: Colors.white)))
                : GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2, // Two items per row
                      crossAxisSpacing: 8.0, // Spacing between columns
                      mainAxisSpacing: 8.0, // Spacing between rows
                      childAspectRatio: 0.75, // Aspect ratio for card size
                    ),
                    itemCount: _favorites.length,
                    itemBuilder: (context, index) {
                      final post = _favorites[index];

                      // Access user details
                      final user = post['user'] ?? {};
                      final userName = user['name'] ?? 'Unknown';
                      

                      // Post image
                      final imageUrl = post['images'] != null && post['images'].isNotEmpty
                          ? 'http://192.168.0.113:8000/storage/${post['images'][0]}'
                          : 'http://192.168.0.113:8000/storage/default.jpg';

                      final priceString = post['price']?.toString() ?? '0.0';
                      final price = double.tryParse(priceString) ?? 0.0;

                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PostDetailScreen(
                                posts: _favorites, // List of favorite posts
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
                              // Background image
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
                              // Overlay with post details
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
                                      // User details
                                      Row(
                                        children: [  
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  userName,
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      if (price > 0) // Check if price is greater than 0
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
                                        post['body'] ?? 'No description',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 2, // Limit to two lines
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              // Action button to remove from favorites
                              Positioned(
                                top: 8,
                                right: 8,
                                child: IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () {showDialog(
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
            _removeFromFavorites(post['id']);
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
                            ],
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}

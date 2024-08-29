import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vendvibe/screens/post_screen.dart';

class MyItemsTab extends StatefulWidget {
  @override
  _MyItemsTabState createState() => _MyItemsTabState();
}

class _MyItemsTabState extends State<MyItemsTab> {
  List<dynamic> _items = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _fetchMyItems();
  }

  void _fetchMyItems() async {
    setState(() {
      _loading = true;
    });

    try {
      final response = await http.get(
        Uri.parse('http://192.168.0.113:8000/api/user/user-items'),
        headers: {
          'Authorization': 'Bearer ${await _getToken()}',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
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

  Future<String> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token') ?? '';
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
                : GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2, // Two items per row
                      crossAxisSpacing: 8.0, // Spacing between columns
                      mainAxisSpacing: 8.0, // Spacing between rows
                      childAspectRatio: 0.75, // Aspect ratio for card size
                    ),
                    itemCount: _items.length,
                    itemBuilder: (context, index) {
                      final post = _items[index];
                      final imageUrl = post['images'].isNotEmpty
                          ? 'http://192.168.0.113:8000/storage/${post['images'][0]}'
                          : 'http://192.168.0.113:8000/storage/default.jpg'; // Provide a default image URL

                      print('Image URL: $imageUrl');

                      // Convert price to double if it's a string
                      final priceString = post['price']?.toString() ?? '0.0';
                      final price = double.tryParse(priceString) ?? 0.0;

                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PostScreen(postId: post['id']),
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
                                      return Center(child: Text('Image failed to load'));
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
                                    borderRadius: BorderRadius.only(
                                      bottomLeft: Radius.circular(12),
                                      bottomRight: Radius.circular(12),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      if (price > 0) // Check if price is greater than 0
                                        Padding(
                                          padding: const EdgeInsets.only(bottom: 4.0),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
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

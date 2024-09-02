import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:vendvibe/screens/PostDetailScreen.dart';

class SearchScreen extends StatefulWidget {
  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  TextEditingController _searchController = TextEditingController();
  List<dynamic> _searchResults = [];
  bool _loading = false;

  void _performSearch(String query) async {
    setState(() {
      _loading = true;
    });

    try {
      final response = await http.post(
        Uri.parse('http://192.168.0.113:8000/api/posts/search'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {'query': query},
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        try {
          final data = json.decode(response.body);
          print('Decoded data: $data');
          setState(() {
            _searchResults = data['posts'] ?? [];
            _loading = false;
          });
        } catch (e) {
          print('Error decoding JSON: $e');
          setState(() {
            _searchResults = [];
            _loading = false;
          });
        }
      } else {
        print('Error: ${response.reasonPhrase}');
        setState(() {
          _searchResults = [];
          _loading = false;
        });
      }
    } catch (e) {
      print('Error performing search: $e');
      setState(() {
        _searchResults = [];
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.amber[900],
        title: TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            hintText: 'Search...',
            border: InputBorder.none,
          ),
          onChanged: (query) {
            if (query.isNotEmpty) {
              _performSearch(query);
            } else {
              setState(() {
                _searchResults = [];
              });
            }
          },
        ),
      ),
      body: Container(
        color: Colors.grey[700],
        child: Column(
          children: [
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _searchResults.isEmpty
                      ? const Center(child: Text('No results found', style: TextStyle(color: Colors.white)))
                      : GridView.builder(
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2, // Two items per row
                            crossAxisSpacing: 8.0, // Spacing between columns
                            mainAxisSpacing: 8.0, // Spacing between rows
                            childAspectRatio: 0.75, // Aspect ratio for card size
                          ),
                          itemCount: _searchResults.length,
                          itemBuilder: (context, index) {
                            final post = _searchResults[index];

                            // Access user details
                            final user = post['user'] ?? {};
                            final userName = user['name'] ?? 'Unknown';
                            
                            final userImage = user['image'] != null
                                ? 'http://192.168.0.113:8000/storage/${user['image']}'
                                : 'http://192.168.0.113:8000/storage/default-user.jpg';

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
                                      posts: _searchResults, // List of posts
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
                                                CircleAvatar(
                                                  backgroundImage: NetworkImage(userImage),
                                                  radius: 16,
                                                ),
                                                const SizedBox(width: 8),
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
          ],
        ),
      ),
    );
  }
}

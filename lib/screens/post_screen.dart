import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vendvibe/screens/PostDetailScreen.dart';
import 'package:vendvibe/services/user_service.dart';

class PostScreen extends StatefulWidget {
  const PostScreen({super.key, required this.postId});
  final int postId;

  @override
  _PostScreenState createState() => _PostScreenState();
}

class _PostScreenState extends State<PostScreen> {
  List<dynamic> _posts = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchPosts();
  }

  Future<String?> _getAuthToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String token = await getToken();
    print('Token fetched: $token'); // Debugging statement for token
    return prefs.getString('token');
  }

  Future<void> _fetchPosts() async {
  setState(() {
    _loading = true;
  });

  final String? token = await _getAuthToken();
  final Uri uri = Uri.parse('http://192.168.0.113:8000/api/posts');

  try {
    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      final List<dynamic> postsJson = data['posts'] ?? [];

      setState(() {
        _posts = postsJson;
        _loading = false;
      });
    } else {
      setState(() {
        _posts = [];
        _loading = false;
      });
    }
  } catch (e) {
    print('Error fetching posts: $e');
    setState(() {
      _posts = [];
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
            ? const Center(child: CircularProgressIndicator())
            : _posts.isEmpty
                ? const Center(child: Text('No posts found', style: TextStyle(color: Colors.white)))
                : GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2, // Two items per row
                      crossAxisSpacing: 8.0, // Spacing between columns
                      mainAxisSpacing: 8.0, // Spacing between rows
                      childAspectRatio: 0.75, // Aspect ratio for card size
                    ),
                    itemCount: _posts.length,
                    itemBuilder: (context, index) {
                      final post = _posts[index];
                      print('Building UI for Post $index: $post'); // Debugging post data

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
                          print('Post tapped: $post'); // Debugging on tap
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PostDetailScreen(
                                posts: _posts, // List of posts
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
                                      print('Image loading error: $error'); // Debugging image loading error
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
                                          SizedBox(width: 8),
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
                                      SizedBox(height: 8),
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

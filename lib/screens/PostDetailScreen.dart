import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:vendvibe/constant.dart';
import 'package:vendvibe/models/api_response.dart';
import 'package:vendvibe/services/user_service.dart';
import 'comment_screen.dart'; // Add this import

class PostDetailScreen extends StatefulWidget {
  final List<dynamic> posts; // List of posts
  final int initialIndex; // Index of the initial post to show

  PostDetailScreen({required this.posts, required this.initialIndex});

  @override
  _PostDetailScreenState createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  late List<dynamic> posts;
  late int initialIndex;

  @override
  void initState() {
    super.initState();
    posts = widget.posts;
    initialIndex = widget.initialIndex;
  }

  // Handle like/dislike functionality
  Future<ApiResponse> _handlePostLikeDislike(int postId, bool isLiked) async {
    ApiResponse apiResponse = ApiResponse();
    try {
      String token = await getToken();
      final response = await http.post(
        Uri.parse('$postsURL/$postId/likes'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'liked': !isLiked}), // Include the liked state in the request
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      switch (response.statusCode) {
        case 200:
          apiResponse.data = jsonDecode(response.body)['message'];
          break;
        case 401:
          apiResponse.error = unauthorized;
          break;
        default:
          apiResponse.error = somethingWentWrong;
          break;
      }
    } catch (e) {
      print('Error liking/unliking post: $e');
      apiResponse.error = serverError;
    }
    return apiResponse;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: PageView.builder(
        itemCount: posts.length,
        scrollDirection: Axis.vertical,
        itemBuilder: (context, index) {
          final post = posts[index];
          final imageUrls = post['images'] as List<dynamic>;
          final priceString = post['price']?.toString() ?? '0.0';
          final price = double.tryParse(priceString) ?? 0.0;

          return Stack(
            fit: StackFit.expand,
            children: [
              // Image carousel
              Positioned.fill(
                child: PageView.builder(
                  itemCount: imageUrls.length,
                  itemBuilder: (context, imgIndex) {
                    final imageUrl = imageUrls.isNotEmpty
                        ? 'http://192.168.0.113:8000/storage/${imageUrls[imgIndex]}'
                        : 'http://192.168.0.113:8000/storage/default.jpg';

                    return Image.network(
                      imageUrl,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return const Center(child: Text('Image failed to load', style: TextStyle(color: Colors.white)));
                      },
                    );
                  },
                ),
              ),
              // Overlay with post details
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(16),
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
                      bottomLeft: Radius.circular(0),
                      bottomRight: Radius.circular(0),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Price tag
                      if (price > 0)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 12.0),
                            decoration: BoxDecoration(
                              color: Colors.amber[900]!,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '\$${price.toStringAsFixed(2)}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      // Post description
                      Text(
                        post['body'] ?? 'No description',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 4,
                      ),
                    ],
                  ),
                ),
              ),
              // Action buttons (like, comment, phone, save favorite, etc.)
              Positioned(
                right: 20,
                top: MediaQuery.of(context).size.height * 0.5, // Adjusted to center vertically
                child: Column(
                  children: [
                    // Like button
                    IconButton(
                      icon: Icon(
                        post['selfLiked'] == true ? Icons.favorite : Icons.favorite_border,
                        color: post['selfLiked'] == true ? Colors.red : Colors.white,
                        size: 30,
                      ),
                      onPressed: () async {
                        final isLiked = post['selfLiked'] ?? false;
                        final response = await _handlePostLikeDislike(post['id'] ?? 0, isLiked);
                        if (response.error == null) {
                          setState(() {
                            // Toggle the like status and update the likes count
                            post['selfLiked'] = !isLiked;
                            post['likesCount'] = (post['likesCount'] ?? 0) + (post['selfLiked'] == true ? 1 : -1);
                          });
                        }
                      },
                    ),
                    // Like count display
                    Text(
                      '${post['likesCount'] ?? 0}',
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    const SizedBox(height: 10),
                    // Comment button
                   IconButton(
  icon: Icon(Icons.comment, color: Colors.white),
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CommentScreen(postId: post['id']),
      ),
    );
  },
),
Text('${post['commentsCount'] ?? 0}', style: TextStyle(color: Colors.white)),
                    const SizedBox(height: 25),
                    // Phone button
                    IconButton(
                      icon: const Icon(Icons.phone, color: Colors.white, size: 30),
                      onPressed: () {
                        // Handle phone action
                      },
                    ),
                    const SizedBox(height: 20),
                    // Save favorite button
                    IconButton(
                      icon: const Icon(Icons.save_alt, color: Colors.white, size: 30), // Save favorite icon
                      onPressed: () {
                        // Handle save favorite action
                      },
                    ),
                  ],
                ),
              ),
            ],
          );
        },
        controller: PageController(initialPage: initialIndex),
      ),
    );
  }
}

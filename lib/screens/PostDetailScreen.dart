// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vendvibe/constant.dart';
import 'package:vendvibe/models/api_response.dart';
import 'package:vendvibe/screens/login.dart';
import 'package:vendvibe/services/post_service.dart';
import 'package:vendvibe/services/user_service.dart';
import 'comment_screen.dart'; // Import the CommentScreen

class PostDetailScreen extends StatefulWidget {
  final List<dynamic> posts; // List of posts
  final int initialIndex; // Index of the initial post to show

  const PostDetailScreen({super.key, required this.posts, required this.initialIndex});

  @override
  _PostDetailScreenState createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  late List<dynamic> posts;
  late int initialIndex;
  final Set<int> _favorites = <int>{};
  bool _isExpanded = false; // Track expanded state
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    posts = widget.posts;
    initialIndex = widget.initialIndex;
    _pageController = PageController(initialPage: initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // Handle like/dislike functionality

  // Toggle favorite status
  Future<void> _toggleFavorite(int postId) async {
    bool isFavorite = _favorites.contains(postId);

    ApiResponse response;
    if (isFavorite) {
      response = await removePostFromFavorites(postId);
      if (response.error == null) {
        setState(() {
          _favorites.remove(postId);
        });
      }
    } else {
      response = await addPostToFavorites(postId);
      if (response.error == null) {
        setState(() {
          _favorites.add(postId);
        });
      }
    }

    if (response.error != null) {
      if (response.error == unauthorized) {
        logout().then((_) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const Login()),
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
  }

  // Launch WhatsApp with the given phone number
  Future<void> _launchWhatsApp(String phoneNumber) async {
    if (kDebugMode) {
      print('Original phone number: $phoneNumber');
    }

    if (phoneNumber.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Phone number is not available')),
        );
      }
      return;
    }

    if (!phoneNumber.startsWith('+961')) {
      phoneNumber = '+961$phoneNumber';
    }

    final url = 'https://wa.me/$phoneNumber';
    if (kDebugMode) {
      print('WhatsApp URL: $url');
    }

    try {
      final result = await canLaunch(url);
      if (result) {
        await launch(url);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not launch WhatsApp')),
          );
        }
      }
    } on PlatformException catch (e) {
      if (kDebugMode) {
        print('Error launching WhatsApp: $e');
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch WhatsApp')),
        );
      }
    }
  }

  // Toggle the expanded/collapsed state
  void _toggleExpand() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: PageView.builder(
        controller: _pageController,
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
                        return  const Center(child: Text('Image failed to load', style: TextStyle(color: Colors.black)));
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
                      Container(
                        decoration: BoxDecoration(
                          color: _isExpanded ? Colors.grey[700] : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              post['body'] ?? 'No description',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: _isExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
                              maxLines: _isExpanded ? null : 2,
                            ),
                            TextButton(
                              onPressed: _toggleExpand,
                              child: Text(
                                _isExpanded ? 'View Less' : 'View More',
                                style: TextStyle(
                                  color: Colors.amber[900],
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Action buttons (like, comment, phone, save favorite, etc.)
              Positioned(
                right: 20,
                top: MediaQuery.of(context).size.height * 0.35, // Adjusted to center vertically
                child: Column(
                  children: [
                    const SizedBox(height: 0),
                    // Comment button
                    Container(
                      padding: const EdgeInsets.all(4.0), // Adjust padding as needed
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5), // Semi-transparent background
                        shape: BoxShape.circle, // Circular background
                      ),
                      child: IconButton(
                        iconSize: 20,
                        icon: const Icon(Icons.comment, color: Colors.blue),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CommentScreen(postId: post['id']),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 25),
                    // Phone button
                    Container(
                      padding: const EdgeInsets.all(4.0), // Adjust padding as needed
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5), // Semi-transparent background
                        shape: BoxShape.circle, // Circular background
                      ),
                      child: IconButton(
                        iconSize: 20,
                        icon: const Icon(Icons.phone, color: Colors.green),
                        onPressed: () {
                          final phoneNumber = post['user']?['phone_number']?.toString() ?? '';
                          _launchWhatsApp(phoneNumber);
                        },
                      ),
                    ),
                    const SizedBox(height: 25),
                    // Save favorite button
                    Container(
                      padding: const EdgeInsets.all(4.0), // Adjust padding as needed
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5), // Semi-transparent background
                        shape: BoxShape.circle, // Circular background
                      ),
                      child: IconButton(
                        iconSize: 20,
                        icon: Icon(
                          _favorites.contains(post['id']) ? Icons.favorite : Icons.favorite_border,
                          color: _favorites.contains(post['id']) ? Colors.red : Colors.white,
                        ),
                        onPressed: () {
                          _toggleFavorite(post['id']);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:vendvibe/constant.dart';
import 'package:vendvibe/models/api_response.dart';
import 'package:vendvibe/models/post.dart';
import 'package:vendvibe/screens/comment_screen.dart';
import 'package:vendvibe/services/post_service.dart';
import 'package:vendvibe/services/user_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'login.dart';
import 'post_form.dart';
import 'package:flutter/services.dart';

class PostScreen extends StatefulWidget {
  const PostScreen({super.key});

  @override
  _PostScreenState createState() => _PostScreenState();
}

class _PostScreenState extends State<PostScreen> {
  List<dynamic> _postList = [];
  int userId = 0;
  bool _loading = true;

  Future<void> retrievePosts() async {
    userId = await getUserId();
    ApiResponse response = await getPosts();

    if (response.error == null) {
      setState(() {
        _postList = response.data as List<dynamic>;
        print('Post list: $_postList'); // Debugging line
        _loading = false;
      });
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

  void _handleDeletePost(int postId) async {
    ApiResponse response = await deletePost(postId);
    if (response.error == null) {
      retrievePosts();
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

  void _handlePostLikeDislike(int postId) async {
    ApiResponse response = await likeUnlikePost(postId);

    if (response.error == null) {
      retrievePosts();
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

  Future<void> _launchWhatsApp(String phoneNumber) async {
    print('Original phone number: $phoneNumber');

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
    print('WhatsApp URL: $url');

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
      print('Error launching WhatsApp: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch WhatsApp')),
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    retrievePosts();
  }

  @override
  Widget build(BuildContext context) {
    return _loading
        ? const Center(child: CircularProgressIndicator())
        : PageView.builder(
            scrollDirection: Axis.vertical,
            itemCount: _postList.length,
            itemBuilder: (BuildContext context, int index) {
              Post post = _postList[index];
              return LayoutBuilder(
                builder: (context, constraints) {
                  return Stack(
                    children: [
                      // Background container with black color
                      Positioned.fill(
                        child: Container(
                          color: Colors.black,
                        ),
                      ),
                      // Image carousel with smaller images
                      Positioned.fill(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 50.0),
                          child: post.images != null && post.images!.isNotEmpty
                              ? PageView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: post.images!.length,
                                  itemBuilder: (context, imgIndex) {
                                    final imageUrl = post.images![imgIndex];
                                    print('Image URL: $imageUrl'); // Debugging line
                                    return SizedBox(
                                      width: constraints.maxWidth, // Full width of the available space
                                      height: constraints.maxHeight * 0.6, // Adjust height as needed
                                      child: Image.network(
                                        'http://192.168.0.113:8000/storage/$imageUrl',
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          return const Center(child: Text('Image failed to load'));
                                        },
                                      ),
                                    );
                                  },
                                )
                              : const SizedBox(),
                        ),
                      ),
                      // Post details
                      Positioned(
                        bottom: 20,
                        left: 10,
                        right: 10,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Display price if available
                            if (post.price != null)
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.amber[900]!,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '\$${post.price!.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 20,
                                  backgroundImage: post.user?.image != null
                                      ? NetworkImage('${post.user!.image}')
                                      : null,
                                  backgroundColor: Colors.black,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    post.user?.name ?? 'Unknown',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (post.user?.id == userId)
                                  PopupMenuButton(
                                    icon: const Icon(Icons.more_vert, color: Colors.white),
                                    itemBuilder: (context) => [
                                      const PopupMenuItem(
                                        value: 'edit',
                                        child: Text('Edit'),
                                      ),
                                      const PopupMenuItem(
                                        value: 'delete',
                                        child: Text('Delete'),
                                      ),
                                    ],
                                    onSelected: (val) {
                                      if (val == 'edit') {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (context) => PostForm(
                                              title: 'Edit Post',
                                              post: post,
                                            ),
                                          ),
                                        );
                                      } else if (val == 'delete') {
                                        _handleDeletePost(post.id ?? 0);
                                      }
                                    },
                                  ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            _buildPostBody(post.body ?? '', post.id ?? 0),
                            const SizedBox(height: 10),
                          ],
                        ),
                      ),
                      // Action icons
                      Positioned(
                        right: 10,
                        bottom: 100,
                        child: Column(
                          children: [
                            _buildTikTokIcon(
                              icon: post.selfLiked == true
                                  ? Icons.favorite
                                  : Icons.favorite_outline,
                              color: post.selfLiked == true
                                  ? Colors.red
                                  : Colors.white,
                              count: post.likesCount ?? 0,
                              onTap: () {
                                _handlePostLikeDislike(post.id ?? 0);
                              },
                            ),
                            const SizedBox(height: 20),
                            _buildTikTokIcon(
                              icon: Icons.comment,
                              count: post.commentsCount ?? 0,
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => CommentScreen(postId: post.id ?? 0),
                                  ),
                                );
                              },
                            ),
                            // WhatsApp icon
                            const SizedBox(height: 20),
                            _buildTikTokIcon(
                              icon: Icons.phone,
                              count: 0, // You can use this to display a specific count if needed
                              onTap: () {
                               if (post.user?.phoneNumber != null) {
    _launchWhatsApp(post.user?.phoneNumber ?? '');
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          );
  }

  Widget _buildPostBody(String body, int postId) {
    // Wrap the body text with a Text widget and limit its length as desired
    return Text(
      body.length > 100 ? '${body.substring(0, 100)}...' : body,
      style: const TextStyle(color: Colors.white, fontSize: 14),
    );
  }

  Widget _buildTikTokIcon({
    required IconData icon,
    required int count,
    required VoidCallback onTap,
    Color? color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, color: color ?? Colors.white, size: 30),
          const SizedBox(height: 4),
          Text(count.toString(), style: const TextStyle(color: Colors.white)),
        ],
      ),
    );
  }
}

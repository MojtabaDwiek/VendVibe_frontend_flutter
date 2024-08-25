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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('${response.error}'),
      ));
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('${response.error}'),
      ));
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('${response.error}'),
      ));
    }
  }

  Future<void> _launchWhatsApp(String phoneNumber) async {
    print('Original phone number: $phoneNumber');

    if (phoneNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Phone number is not available')),
      );
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch WhatsApp')),
        );
      }
    } on PlatformException catch (e) {
      print('Error launching WhatsApp: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not launch WhatsApp')),
      );
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
              return Stack(
                children: [
                  // Background container with black color
                  Positioned.fill(
                    child: Container(
                      color: Colors.black,
                    ),
                  ),
                  // Image with padding
                  Positioned.fill(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 50.0),
                      child: post.image != null
                          ? Image.network(
                              '${post.image}',
                              fit: BoxFit.fitWidth, // Fit width while keeping height unchanged
                              errorBuilder: (context, error, stackTrace) {
                                return const Center(
                                    child: Text('Image failed to load'));
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
                                                )));
                                  } else if (val == 'delete') {
                                    _handleDeletePost(post.id ?? 0);
                                  }
                                },
                              ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        _buildPostBody(post.body ?? ''),
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
                          icon: Icons.sms_outlined,
                          color: Colors.white,
                          count: post.commentsCount ?? 0,
                          onTap: () {
                            Navigator.of(context).push(MaterialPageRoute(
                              builder: (context) => CommentScreen(
                                postId: post.id,
                              ),
                            ));
                          },
                        ),
                        const SizedBox(height: 20),
                        _buildTikTokIcon(
                          icon: Icons.phone,
                          color: Colors.white,
                          onTap: () {
                            _launchWhatsApp(post.user?.phoneNumber ?? '');
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          );
  }

  Widget _buildPostBody(String body) {
    bool _isExpanded = false;

    // ignore: dead_code
    final int? maxLines = _isExpanded ?  null: 2; // Show 2 lines by default

    return StatefulBuilder(
      builder: (context, setState) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              body,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
              maxLines: maxLines,
              overflow: _isExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
            ),
            if (body.length > 100) // Adjust this length as needed
              GestureDetector(
                onTap: () {
                  setState(() {
                    _isExpanded = !_isExpanded;
                  });
                },
                child: Text(
                  _isExpanded ? 'View Less' : 'View More',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildTikTokIcon({
    required IconData icon,
    required Color color,
    int? count,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, color: color, size: 30), // Adjusted icon size
          if (count != null)
            const SizedBox(height: 4),
          if (count != null)
            Text(
              '$count',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
        ],
      ),
    );
  }
}

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

class PostScreen extends StatefulWidget {
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
    // Debugging statement
    print('Original phone number: $phoneNumber');

    // Ensure the phone number is not empty
    if (phoneNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Phone number is not available')),
      );
      return;
    }

    // Prepend +961 if not present
    if (!phoneNumber.startsWith('+961')) {
      phoneNumber = '+961$phoneNumber';
    }

    final url = 'https://wa.me/$phoneNumber';
    print('WhatsApp URL: $url'); // Debugging statement

    if (await canLaunch(url)) {
      await launch(url);
    } else {
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
        : RefreshIndicator(
            onRefresh: () => retrievePosts(),
            child: Container(
              color: Colors.grey[700],
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, // Number of columns
                  crossAxisSpacing: 8.0, // Spacing between columns
                  mainAxisSpacing: 8.0, // Spacing between rows
                  childAspectRatio: 0.75, // Aspect ratio of the items
                ),
                padding: const EdgeInsets.all(10.0),
                itemCount: _postList.length,
                itemBuilder: (BuildContext context, int index) {
                  Post post = _postList[index];
                  return Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 15,
                                      backgroundImage: post.user?.image != null
                                          ? NetworkImage('${post.user!.image}')
                                          : null,
                                      backgroundColor: Colors.amber,
                                    ),
                                    const SizedBox(width: 8), // Reduced padding
                                    Expanded(
                                      child: Text(
                                        post.user?.name ?? 'Unknown',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                        ),
                                        overflow: TextOverflow.ellipsis, // Ensure text does not overflow
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (post.user?.id == userId)
                                PopupMenuButton(
                                  icon: const Icon(Icons.more_vert, color: Colors.black),
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
                                      Navigator.of(context).push(MaterialPageRoute(
                                        builder: (context) => PostForm(
                                          title: 'Edit Post',
                                          post: post,
                                        ),
                                      ));
                                    } else {
                                      _handleDeletePost(post.id ?? 0);
                                    }
                                  },
                                ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Container(
                            width: double.infinity,
                            margin: const EdgeInsets.all(8.0),
                            child: post.image != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      '${post.image}',
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return const Center(child: Text('Image failed to load'));
                                      },
                                    ),
                                  )
                                : const SizedBox(),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 0),
                          child: Text(
                            '${post.body}',
                            style: const TextStyle(fontSize: 12),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              kLikeAndComment(
                                post.likesCount ?? 0,
                                post.selfLiked == true ? Icons.favorite : Icons.favorite_outline,
                                post.selfLiked == true ? Colors.red : Colors.black54,
                                () {
                                  _handlePostLikeDislike(post.id ?? 0);
                                },
                              ),
                              kLikeAndComment(
                                post.commentsCount ?? 0,
                                Icons.sms_outlined,
                                Colors.black54,
                                () {
                                  Navigator.of(context).push(MaterialPageRoute(
                                    builder: (context) => CommentScreen(
                                      postId: post.id,
                                    ),
                                  ));
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.phone, color: Colors.black54),
                                onPressed: () {
                                  _launchWhatsApp(post.user?.phoneNumber ?? '');
                                },
                              ),
                            ],
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

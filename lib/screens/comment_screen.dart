import 'package:flutter/material.dart';
import 'package:vendvibe/models/api_response.dart';
import 'package:vendvibe/models/comment.dart';
import 'package:vendvibe/services/comment_service.dart';
import 'package:vendvibe/services/user_service.dart';
import '../constant.dart';
import 'login.dart';

class CommentScreen extends StatefulWidget {
  final int? postId;

  const CommentScreen({this.postId});

  @override
  _CommentScreenState createState() => _CommentScreenState();
}

class _CommentScreenState extends State<CommentScreen> {
  List<dynamic> _commentsList = [];
  bool _loading = true;
  int userId = 0;
  int _editCommentId = 0;
  final TextEditingController _txtCommentController = TextEditingController();

  Future<void> _getComments() async {
    userId = await getUserId();
    ApiResponse response = await getComments(widget.postId ?? 0);

    if (response.error == null) {
      setState(() {
        _commentsList = response.data as List<dynamic>;
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${response.error}')),
      );
    }
  }

  void _createComment() async {
    ApiResponse response = await createComment(widget.postId ?? 0, _txtCommentController.text);

    if (response.error == null) {
      _txtCommentController.clear();
      _getComments();
    } else if (response.error == unauthorized) {
      logout().then((_) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => Login()),
          (route) => false,
        );
      });
    } else {
      setState(() {
        _loading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${response.error}')),
      );
    }
  }

  void _editComment() async {
    ApiResponse response = await editComment(_editCommentId, _txtCommentController.text);

    if (response.error == null) {
      _editCommentId = 0;
      _txtCommentController.clear();
      _getComments();
    } else if (response.error == unauthorized) {
      logout().then((_) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => Login()),
          (route) => false,
        );
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${response.error}')),
      );
    }
  }

  void _deleteComment(int commentId) async {
    ApiResponse response = await deleteComment(commentId);

    if (response.error == null) {
      _getComments();
    } else if (response.error == unauthorized) {
      logout().then((_) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => Login()),
          (route) => false,
        );
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${response.error}')),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _getComments();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Comments'),
        backgroundColor: Colors.amber[900]!, // Modern color
        elevation: 4, // Slight shadow for depth
      ),
      backgroundColor: Colors.grey[200], // Light background color for modern look
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _getComments,
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      itemCount: _commentsList.length,
                      itemBuilder: (BuildContext context, int index) {
                        Comment comment = _commentsList[index];
                        return Container(
                          padding: const EdgeInsets.all(15),
                          margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                          decoration: BoxDecoration(
                            color: Colors.white, // White background for comments
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                spreadRadius: 2,
                                blurRadius: 5,
                                offset: Offset(0, 3), // Shadow position
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 15,
                                        backgroundImage: comment.user!.image != null
                                            ? NetworkImage('${comment.user!.image}')
                                            : null,
                                        backgroundColor: Colors.grey[300],
                                      ),
                                      const SizedBox(width: 10),
                                      Text(
                                        '${comment.user!.name}',
                                        style: const TextStyle(
                                          color: Colors.black,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (comment.user!.id == userId)
                                    PopupMenuButton<String>(
                                      icon: Icon(
                                        Icons.more_vert,
                                        color: Colors.black,
                                      ),
                                      itemBuilder: (context) => [
                                        const PopupMenuItem(value: 'edit', child: Text('Edit')),
                                        const PopupMenuItem(value: 'delete', child: Text('Delete')),
                                      ],
                                      onSelected: (val) {
                                        if (val == 'edit') {
                                          setState(() {
                                            _editCommentId = comment.id ?? 0;
                                            _txtCommentController.text = comment.comment ?? '';
                                          });
                                        } else if (val == 'delete') {
                                          _deleteComment(comment.id ?? 0);
                                        }
                                      },
                                    ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(
                                '${comment.comment}',
                                style: const TextStyle(
                                  color: Colors.black,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        spreadRadius: 2,
                        blurRadius: 5,
                        offset: Offset(0, -3), // Shadow position
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: 'Add a comment...',
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                          ),
                          controller: _txtCommentController,
                        ),
                      ),
                      IconButton(
                        icon:  Icon(Icons.send, color: Colors.amber[900]!),
                        onPressed: () {
                          if (_txtCommentController.text.isNotEmpty) {
                            setState(() {
                              _loading = true;
                            });
                            if (_editCommentId > 0) {
                              _editComment();
                            } else {
                              _createComment();
                            }
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

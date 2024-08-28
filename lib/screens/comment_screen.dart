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
        backgroundColor: Colors.black, // Dark background for a sleek look
        elevation: 0, // Flat look
        leading: null, // Remove the back button
        actions: [
          IconButton(
            icon: Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      backgroundColor: Colors.black, // Dark background for comments
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  itemCount: _commentsList.length,
                  itemBuilder: (BuildContext context, int index) {
                    Comment comment = _commentsList[index];
                    return Container(
                      padding: const EdgeInsets.all(10),
                      margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                      decoration: BoxDecoration(
                        color: Colors.grey[800], // Slightly dark background for comments
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            spreadRadius: 2,
                            blurRadius: 5,
                            offset: Offset(0, 3), // Shadow position
                          ),
                        ],
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundImage: comment.user!.image != null
                                ? NetworkImage('${comment.user!.image}')
                                : null,
                            backgroundColor: Colors.grey[600],
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '${comment.user!.name}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    if (comment.user!.id == userId)
                                      PopupMenuButton<String>(
                                        icon: Icon(Icons.more_vert, color: Colors.white),
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
                                const SizedBox(height: 5),
                                Text(
                                  '${comment.comment}',
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    color: Colors.grey[900],
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            decoration: InputDecoration(
                              hintText: 'Add a comment...',
                              hintStyle: TextStyle(color: Colors.grey[600]),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                            ),
                            style: const TextStyle(color: Colors.white),
                            controller: _txtCommentController,
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.send, color: Colors.amber[900]!),
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
                ),
              ],
            ),
    );
  }
}

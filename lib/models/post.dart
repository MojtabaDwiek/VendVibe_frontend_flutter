import 'user.dart';

class Post {
  int? id;
  String? body;
  String? image;
  int? likesCount;
  int? commentsCount;
  User? user;
  bool? selfLiked;

  Post({
    this.id,
    this.body,
    this.image,
    this.likesCount,
    this.commentsCount,
    this.user,
    this.selfLiked,
  });

  // Convert json data to post model
  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['id'],
      body: json['body'],
      image: json['image'],
      likesCount: json['likes_count'],
      commentsCount: json['comments_count'],
      selfLiked: json['likes'].isNotEmpty, // Update to handle empty lists
      user: User.fromJson(json['user']),
    );
  }
}

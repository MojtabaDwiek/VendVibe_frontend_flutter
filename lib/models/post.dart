import 'user.dart';

class Post {
  int? id;
  String? body;
  List<String>? images;
  double? price;
  int? likesCount;
  int? commentsCount;
  User? user;
  bool? selfLiked;

  Post({
    this.id,
    this.body,
    this.images,
    this.price,
    this.likesCount,
    this.commentsCount,
    this.user,
    this.selfLiked,
  });

  // Convert JSON data to Post model
  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['id'],
      body: json['body'],
      images: json['images'] != null 
          ? List<String>.from(json['images']) 
          : [], // Ensure images is a list or empty list
      price: json['price'] != null 
          ? (json['price'] is String 
              ? double.tryParse(json['price']) 
              : (json['price'] as num).toDouble()) 
          : null, // Handle both String and num for price
      likesCount: json['likes_count'],
      commentsCount: json['comments_count'],
      selfLiked: json['likes'] != null && (json['likes'] as List).isNotEmpty,
      user: json['user'] != null ? User.fromJson(json['user']) : null,
    );
  }
}

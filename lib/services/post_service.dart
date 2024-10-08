import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:vendvibe/models/api_response.dart';
import 'package:vendvibe/models/post.dart';
import 'package:vendvibe/services/user_service.dart';
import '../constant.dart';

// Get all posts
Future<ApiResponse> getPosts() async {
  ApiResponse apiResponse = ApiResponse();
  try {
    String token = await getToken();
    if (kDebugMode) {
      print('Token: $token');
    }

    // Simulate response for debugging
    final data = {
      'posts': [
        {
          'id': 1,
          'body': 'Sample Post Description',
          'price': 9.99,
          'images': ['image1.jpg'],
          'user': {
            'name': 'Sample User',
            'image': 'user-image.jpg'
          }
        }
      ]
    };
    if (kDebugMode) {
      print('Simulated response data: $data');
    }

    final List<dynamic> postsJson = data['posts'] ?? [];
    if (kDebugMode) {
      print('Simulated posts JSON: $postsJson');
    }
    
    apiResponse.data = postsJson.map((p) {
      try {
        return Post.fromJson(p);
      } catch (e) {
        if (kDebugMode) {
          print('Error parsing post: $e');
        }
        return null;
      }
    }).where((post) => post != null).toList();
  } catch (e) {
    if (kDebugMode) {
      print('Error fetching posts: $e');
    }
    apiResponse.error = serverError;
  }
  return apiResponse;
}



// Create post
Future<ApiResponse> createPost(String body, List<File>? images, double? price) async {
  ApiResponse apiResponse = ApiResponse();
  try {
    String token = await getToken();
    var request = http.MultipartRequest('POST', Uri.parse(postsURL));
    request.headers['Accept'] = 'application/json';
    request.headers['Authorization'] = 'Bearer $token';

    request.fields['body'] = body;
    request.fields['price'] = price?.toString() ?? '0';

    if (images != null && images.isNotEmpty) {
      for (var image in images) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'images[]',
            image.path,
            contentType: MediaType('image', 'jpeg'),
          ),
        );
      }
    }

    var response = await request.send();
    final responseBody = await response.stream.bytesToString();

    switch (response.statusCode) {
      case 200:
        apiResponse.data = jsonDecode(responseBody);
        break;
      case 422:
        final errors = jsonDecode(responseBody)['errors'];
        apiResponse.error = errors[errors.keys.elementAt(0)][0];
        break;
      case 401:
        apiResponse.error = unauthorized;
        break;
      
    }
  } catch (e) {
    if (kDebugMode) {
      print('Error creating post: $e');
    }
    apiResponse.error = serverError;
  }
  return apiResponse;
}

// Edit post
Future<ApiResponse> editPost(int postId, String body, List<File>? images, double? price) async {
  ApiResponse apiResponse = ApiResponse();
  try {
    String token = await getToken();
    var request = http.MultipartRequest('PUT', Uri.parse('$postsURL/$postId'));
    request.headers['Accept'] = 'application/json';
    request.headers['Authorization'] = 'Bearer $token';

    request.fields['body'] = body;
    request.fields['price'] = price?.toString() ?? '0';

    if (images != null && images.isNotEmpty) {
      for (var image in images) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'images[]',
            image.path,
            contentType: MediaType('image', 'jpeg'),
          ),
        );
      }
    }

    var response = await request.send();
    final responseBody = await response.stream.bytesToString();

    switch (response.statusCode) {
      case 200:
        apiResponse.data = jsonDecode(responseBody)['message'];
        break;
      case 403:
        apiResponse.error = jsonDecode(responseBody)['message'];
        break;
      case 401:
        apiResponse.error = unauthorized;
        break;
      default:
        apiResponse.error = somethingWentWrong;
        break;
    }
  } catch (e) {
    if (kDebugMode) {
      print('Error editing post: $e');
    }
    apiResponse.error = serverError;
  }
  return apiResponse;
}

// Delete post
Future<ApiResponse> deletePost(int postId) async {
  ApiResponse apiResponse = ApiResponse();
  try {
    String token = await getToken();
    final response = await http.delete(
      Uri.parse('$postsURL/$postId'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    switch (response.statusCode) {
      case 200:
        apiResponse.data = jsonDecode(response.body)['message'];
        break;
      case 403:
        apiResponse.error = jsonDecode(response.body)['message'];
        break;
      case 401:
        apiResponse.error = unauthorized;
        break;
      default:
        apiResponse.error = somethingWentWrong;
        break;
    }
  } catch (e) {
    if (kDebugMode) {
      print('Error deleting post: $e');
    }
    apiResponse.error = serverError;
  }
  return apiResponse;
}

// Like or unlike post
Future<ApiResponse> likeUnlikePost(int postId) async {
  ApiResponse apiResponse = ApiResponse();
  try {
    String token = await getToken();
    final response = await http.post(
      Uri.parse('$postsURL/$postId/likes'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

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
    if (kDebugMode) {
      print('Error liking/unliking post: $e');
    }
    apiResponse.error = serverError;
  }
  return apiResponse;
}


// Add post to favorites
Future<ApiResponse> addPostToFavorites(int postId) async {
  ApiResponse apiResponse = ApiResponse();
  try {
    String token = await getToken();
    final response = await http.post(
      Uri.parse('$postsURL/favorites'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json', // Add content type header
      },
      body: jsonEncode({'post_id': postId}), // Send post_id in the body
    );

    if (kDebugMode) {
      print('Response status: ${response.statusCode}');
    }
    if (kDebugMode) {
      print('Response body: ${response.body}');
    }

    switch (response.statusCode) {
      case 200:
        final responseData = jsonDecode(response.body);
        if (kDebugMode) {
          print('Response message: ${responseData['message']}');
        }
        if (kDebugMode) {
          print('Favorite data: ${responseData['favorite']}');
        }
        apiResponse.data = responseData['message'];
        break;
      case 401:
        apiResponse.error = unauthorized;
        break;
      case 422:
        final errors = jsonDecode(response.body)['errors'];
        apiResponse.error = errors[errors.keys.elementAt(0)][0];
        break;
     
    }
  } catch (e) {
    if (kDebugMode) {
      print('Error adding post to favorites: $e');
    }
    apiResponse.error = serverError;
  }
  return apiResponse;
}



// Remove post from favorites
Future<ApiResponse> removePostFromFavorites(int postId) async {
  ApiResponse apiResponse = ApiResponse();
  try {
    String token = await getToken();
    final response = await http.delete(
      Uri.parse('$postsURL/$postId/favorites'), // Use postsURL here
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

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
    if (kDebugMode) {
      print('Error removing post from favorites: $e');
    }
    apiResponse.error = serverError;
  }
  return apiResponse;
}


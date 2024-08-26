import 'dart:convert';
import 'package:vendvibe/models/api_response.dart';
import 'package:vendvibe/models/post.dart';
import 'package:vendvibe/services/user_service.dart';
import 'package:http/http.dart' as http;

import '../constant.dart';

// Get all posts
Future<ApiResponse> getPosts() async {
  ApiResponse apiResponse = ApiResponse();
  try {
    String token = await getToken();
    final response = await http.get(
      Uri.parse(postsURL),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    switch (response.statusCode) {
      case 200:
        final data = jsonDecode(response.body);
        final List<dynamic> postsJson = data['posts'];

        // Handle type conversion issues
        apiResponse.data = postsJson.map((p) {
          try {
            return Post.fromJson(p);
          } catch (e) {
            print('Error parsing post: $e');
            return null; // Handle or ignore errors as needed
          }
        }).where((post) => post != null).toList();
        break;
      case 401:
        apiResponse.error = unauthorized;
        break;
      default:
        apiResponse.error = somethingWentWrong;
        break;
    }
  } catch (e) {
    print('Error fetching posts: $e'); // Log error
    apiResponse.error = serverError;
  }
  return apiResponse;
}

// Create post
Future<ApiResponse> createPost(String body, List<String>? images, double? price) async {
  ApiResponse apiResponse = ApiResponse();
  try {
    String token = await getToken();
    final response = await http.post(
      Uri.parse(postsURL),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json', // Make sure to specify the content type
      },
      body: jsonEncode({
        'body': body,
        'images': images ?? [], // Handle null by using empty list
        'price': price ?? 0, // Handle null by using default value
      }),
    );

    switch (response.statusCode) {
      case 200:
        apiResponse.data = jsonDecode(response.body);
        break;
      case 422:
        final errors = jsonDecode(response.body)['errors'];
        apiResponse.error = errors[errors.keys.elementAt(0)][0];
        break;
      case 401:
        apiResponse.error = unauthorized;
        break;
      default:
        apiResponse.error = somethingWentWrong;
        break;
    }
  } catch (e) {
    print('Error creating post: $e'); // Log error
    apiResponse.error = serverError;
  }
  return apiResponse;
}

// Edit post
Future<ApiResponse> editPost(int postId, String body, List<String>? images, double? price) async {
  ApiResponse apiResponse = ApiResponse();
  try {
    String token = await getToken();
    final response = await http.put(
      Uri.parse('$postsURL/$postId'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json', // Make sure to specify the content type
      },
      body: jsonEncode({
        'body': body,
        'images': images ?? [], // Handle null by using empty list
        'price': price ?? 0, // Handle null by using default value
      }),
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
    print('Error editing post: $e'); // Log error
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
    print('Error deleting post: $e'); // Log error
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
    print('Error liking/unliking post: $e'); // Log error
    apiResponse.error = serverError;
  }
  return apiResponse;
}

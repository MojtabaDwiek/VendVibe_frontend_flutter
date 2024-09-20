// ignore_for_file: use_build_context_synchronously, library_private_types_in_public_api

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

import 'login.dart';
import 'package:vendvibe/constant.dart';
import 'package:vendvibe/models/api_response.dart';
import 'package:vendvibe/models/post.dart';
import 'package:vendvibe/services/post_service.dart';
import 'package:vendvibe/services/user_service.dart';

class PostForm extends StatefulWidget {
  final Post? post;
  final String? title;

  const PostForm({super.key, this.post, this.title});

  @override
  _PostFormState createState() => _PostFormState();
}

class _PostFormState extends State<PostForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _txtControllerBody = TextEditingController();
  final TextEditingController _txtControllerPrice = TextEditingController();
  bool _loading = false;
  List<File> _imageFiles = [];
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    if (widget.post != null) {
      _txtControllerBody.text = widget.post!.body ?? '';
      _txtControllerPrice.text = widget.post!.price?.toString() ?? '';
      // Handle images if post contains any
      // Add logic here if needed
    }
  }

  Future<void> requestPermission() async {
    final status = await Permission.photos.request();
    if (status.isGranted) {
      getImages();
    } else if (status.isDenied) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gallery access is required to select images. Please enable it in settings.'),
        ),
      );
    } else if (status.isPermanentlyDenied) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gallery access has been permanently denied. Please enable it in settings.'),
        ),
      );
      await openAppSettings();
    }
  }

  Future<void> getImages() async {
    try {
      final pickedFiles = await _picker.pickMultiImage();
      List<File> imageFiles = [];
      for (var pickedFile in pickedFiles) {
        File imageFile = File(pickedFile.path);
        final resizedImage = await resizeImage(imageFile);
        imageFiles.add(resizedImage);
      }
      setState(() {
        _imageFiles = imageFiles;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to pick images: $e'),
        ),
      );
    }
  }

  Future<File> resizeImage(File file) async {
    final result = await FlutterImageCompress.compressWithFile(
      file.absolute.path,
      minWidth: 800,
      minHeight: 600,
      quality: 88,
    );
    final resizedFile = File(file.path)..writeAsBytesSync(result!);
    return resizedFile;
  }

  void _createPost() async {
    if (!_formKey.currentState!.validate()) {
      if (kDebugMode) {
        print("Form validation failed.");
      }
      return;
    }

    setState(() {
      _loading = true;
    });

    ApiResponse response = await createPost(
      _txtControllerBody.text,
      _imageFiles.isNotEmpty ? _imageFiles : null,
      _txtControllerPrice.text.isNotEmpty ? double.tryParse(_txtControllerPrice.text) : null,
    );

    setState(() {
      _loading = false;
    });

    if (response.error == null) {
      Navigator.of(context).pop();
    } else if (response.error == unauthorized) {
      await logout();
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const Login()),
        (route) => false,
      );
    } else {
      if (kDebugMode) {
        print("API Response Error: ${response.error}");
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('${response.error}'),
      ));
    }
  }

  void _editPost(int? postId) async {
    if (postId == null) {
      if (kDebugMode) {
        print("Post ID is null");
      }
      return;
    }

    if (!_formKey.currentState!.validate()) {
      if (kDebugMode) {
        print("Form validation failed.");
      }
      return;
    }

    setState(() {
      _loading = true;
    });

    ApiResponse response = await editPost(
      postId,
      _txtControllerBody.text,
      _imageFiles.isNotEmpty ? _imageFiles : null,
      _txtControllerPrice.text.isNotEmpty ? double.tryParse(_txtControllerPrice.text) : null,
    );

    setState(() {
      _loading = false;
    });

    if (response.error == null) {
      Navigator.of(context).pop();
    } else if (response.error == unauthorized) {
      await logout();
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const Login()),
        (route) => false,
      );
    } else {
      if (kDebugMode) {
        print("API Response Error: ${response.error}");
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('${response.error}'),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${widget.title}',
          style: TextStyle(color: Colors.amber[900]), // Set text color here
        ),
        backgroundColor: Colors.grey[900],
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.amber[900]), // Set icon color here
        actions: [
          if (_imageFiles.isEmpty)
            IconButton(
              icon: Icon(Icons.camera_alt, color: Colors.amber[900]),
              onPressed: requestPermission,
            ),
        ],
      ),
      backgroundColor: Colors.grey[900],
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Color.fromRGBO(255, 111, 0, 1)),),
            )
          : Stack(
              children: [
                _imageFiles.isEmpty
                    ? const Center(
                        child: Text(
                          'Tap the camera icon to select images',
                          style: TextStyle(color: Colors.white, fontSize: 18),
                        ),
                      )
                    : PageView.builder(
                        itemCount: _imageFiles.length,
                        itemBuilder: (context, index) {
                          return Image.file(
                            _imageFiles[index],
                            fit: BoxFit.cover,
                          );
                        },
                      ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    color: Colors.grey[850],
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              TextFormField(
                                controller: _txtControllerBody,
                                keyboardType: TextInputType.multiline,
                                maxLines: 4,
                                validator: (val) {
                                  if (val == null || val.isEmpty) {
                                    return 'Post body is required';
                                  }
                                  return null;
                                },
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: Colors.grey[800],
                                  hintText: "What's on your mind?",
                                  hintStyle: TextStyle(color: Colors.amber[900]!),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                  contentPadding: const EdgeInsets.all(16),
                                ),
                                style: const TextStyle(color: Colors.white),
                              ),
                              const SizedBox(height: 10),
                              TextFormField(
                                controller: _txtControllerPrice,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: Colors.grey[800],
                                  hintText: "Price (optional)",
                                   hintStyle: TextStyle(color: Colors.amber[900]!),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                  contentPadding: const EdgeInsets.all(16),
                                ),
                                style: const TextStyle(color: Colors.white),
                              ),
                              const SizedBox(height: 20),
                              ElevatedButton(
                                onPressed: widget.post != null 
                                    ? (widget.post!.id != null ? () => _editPost(widget.post!.id) : null) 
                                    : _createPost,
                                style: ElevatedButton.styleFrom(
                                  foregroundColor: Colors.white, 
                                  backgroundColor: Colors.amber[900]!,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  textStyle: const TextStyle(fontSize: 16),
                                ),
                                child: Text(widget.post != null ? 'Update Post' : 'Create Post'),
                              ),
                            ],
                          ),
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

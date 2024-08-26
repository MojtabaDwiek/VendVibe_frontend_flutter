import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
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

  PostForm({this.post, this.title});

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

  Future<List<String>> getStringImages() async {
    List<String> base64Images = [];
    for (var imageFile in _imageFiles) {
      Uint8List imageBytes = await imageFile.readAsBytes();
      base64Images.add(base64Encode(imageBytes));
    }
    return base64Images;
  }

  void _createPost() async {
    if (!_formKey.currentState!.validate()) {
      print("Form validation failed.");
      return;
    }

    setState(() {
      _loading = true;
    });

    List<String> images = await getStringImages();
    print("Creating post with body: ${_txtControllerBody.text}");
    ApiResponse response = await createPost(
      _txtControllerBody.text,
      images.isNotEmpty ? images : null,
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
        MaterialPageRoute(builder: (context) => Login()),
        (route) => false,
      );
    } else {
      print("API Response Error: ${response.error}");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('${response.error}'),
      ));
    }
  }

  void _editPost(int postId) async {
    if (!_formKey.currentState!.validate()) {
      print("Form validation failed.");
      return;
    }

    setState(() {
      _loading = true;
    });

    List<String> images = await getStringImages();
    ApiResponse response = await editPost(
      postId,
      _txtControllerBody.text,
      images.isNotEmpty ? images : null,
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
        MaterialPageRoute(builder: (context) => Login()),
        (route) => false,
      );
    } else {
      print("API Response Error: ${response.error}");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('${response.error}'),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.title}'),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : ListView(
              children: [
                widget.post != null
                    ? SizedBox()
                    : Container(
                        width: MediaQuery.of(context).size.width,
                        height: 200,
                        decoration: BoxDecoration(
                            image: _imageFiles.isEmpty
                                ? null
                                : DecorationImage(
                                    image: FileImage(_imageFiles.first),
                                    fit: BoxFit.cover)),
                        child: Center(
                          child: IconButton(
                            icon: Icon(Icons.image, size: 50, color: Colors.black38),
                            onPressed: requestPermission,
                          ),
                        ),
                      ),
                Form(
                  key: _formKey,
                  child: Padding(
                    padding: EdgeInsets.all(8),
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _txtControllerBody,
                          keyboardType: TextInputType.multiline,
                          maxLines: 9,
                          validator: (val) {
                            print('Validating body: $val'); // Debugging line
                            if (val == null || val.isEmpty) {
                              return 'Post body is required';
                            }
                            return null;
                          },
                          decoration: const InputDecoration(
                              hintText: "Post body...",
                              border: OutlineInputBorder(
                                  borderSide: BorderSide(width: 1, color: Colors.black38))),
                        ),
                        SizedBox(height: 10),
                        TextFormField(
                          controller: _txtControllerPrice,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                              hintText: "Price (optional)",
                              border: OutlineInputBorder(
                                  borderSide: BorderSide(width: 1, color: Colors.black38))),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: ElevatedButton(
                    onPressed: () {
                      if (widget.post == null) {
                        _createPost();
                      } else {
                        _editPost(widget.post!.id ?? 0);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.amber, // text color
                    ),
                    child: Text(widget.post == null ? 'Create Post' : 'Update Post'),
                  ),
                )
              ],
            ),
    );
  }
}

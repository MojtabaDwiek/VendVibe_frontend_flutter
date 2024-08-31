import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class FavoritesTab extends StatefulWidget {
  @override
  _FavoritesTabState createState() => _FavoritesTabState();
}

class _FavoritesTabState extends State<FavoritesTab> {
  List<dynamic> _favorites = [];
  bool _loading = false;
  bool _isGridView = true;
  late PageController _pageController;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _pageController = PageController(); // Initialize PageController
    _fetchFavorites();
  }

  @override
  void dispose() {
    _pageController.dispose(); // Dispose PageController
    super.dispose();
  }

  Future<String?> _getAuthToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<void> _fetchFavorites() async {
    setState(() {
      _loading = true;
    });

    final String? token = await _getAuthToken();
    final Uri uri = Uri.parse('http://192.168.0.113:8000/api/user/favorites');

    try {
      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _favorites = data.map((item) => item['post']).toList();
          _loading = false;
        });
      } else {
        print('Error: ${response.reasonPhrase}');
        setState(() {
          _favorites = [];
          _loading = false;
        });
      }
    } catch (e) {
      print('Error fetching favorites: $e');
      setState(() {
        _favorites = [];
        _loading = false;
      });
    }
  }

  void _showPageView(int index) {
    setState(() {
      _isGridView = false;
    });
    // Ensure PageController is attached before calling jumpToPage
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _pageController.jumpToPage(index);
    });
  }

  void _showGridView() {
    setState(() {
      _isGridView = true;
    });
  }

  Future<void> _launchWhatsApp(String phoneNumber) async {
    final url = 'https://wa.me/$phoneNumber';
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      body: _isGridView
          ? Container(
              color: Colors.grey[700],
              child: _loading
                  ? Center(child: CircularProgressIndicator())
                  : _favorites.isEmpty
                      ? Center(child: Text('No favorites found', style: TextStyle(color: Colors.white)))
                      : GridView.builder(
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 8.0,
                            mainAxisSpacing: 8.0,
                            childAspectRatio: 0.75,
                          ),
                          itemCount: _favorites.length,
                          itemBuilder: (context, index) {
                            final favorite = _favorites[index];
                            final images = favorite['images'] as List<dynamic>? ?? [];
                            final imageUrl = images.isNotEmpty
                                ? 'http://192.168.0.113:8000/storage/${images[0]}'
                                : 'http://192.168.0.113:8000/storage/default.jpg';

                            final priceString = favorite['price']?.toString() ?? '0.0';
                            final price = double.tryParse(priceString) ?? 0.0;

                            return GestureDetector(
                              onTap: () {
                                _showPageView(index);
                              },
                              child: Card(
                                elevation: 4.0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Stack(
                                  children: [
                                    Positioned.fill(
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Image.network(
                                          imageUrl,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) {
                                            return Center(child: Text('Image failed to load'));
                                          },
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      bottom: 0,
                                      left: 0,
                                      right: 0,
                                      child: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              Colors.black.withOpacity(0.7),
                                              Colors.black.withOpacity(0.1),
                                            ],
                                            begin: Alignment.bottomCenter,
                                            end: Alignment.topCenter,
                                          ),
                                          borderRadius: BorderRadius.only(
                                            bottomLeft: Radius.circular(12),
                                            bottomRight: Radius.circular(12),
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                favorite['body'] ?? 'No description',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                                maxLines: 2,
                                              ),
                                            ),
                                            if (price > 0)
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                                child: Text(
                                                  '\$${price.toStringAsFixed(2)}',
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      right: 0,
                                      bottom: 0,
                                      child: IconButton(
                                        icon: Icon(Icons.phone, color: Colors.white),
                                        onPressed: () {
                                          final phoneNumber = favorite['user']?['phone'] ?? '';
                                          if (phoneNumber.isNotEmpty) {
                                            _launchWhatsApp(phoneNumber);
                                          } else {
                                            print('No phone number available');
                                          }
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            )
          : PageView.builder(
              controller: _pageController,
              itemCount: _favorites.length,
              itemBuilder: (context, index) {
                final favorite = _favorites[index];
                final images = favorite['images'] as List<dynamic>? ?? [];
                final priceString = favorite['price']?.toString() ?? '0.0';
                final price = double.tryParse(priceString) ?? 0.0;

                final phoneNumber = favorite['user']?['phone'] ?? '';

                return GestureDetector(
                  onTap: () {
                    _showGridView();
                  },
                  child: Container(
                    color: Colors.grey[700],
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: PageView.builder(
                            itemCount: images.length,
                            itemBuilder: (context, imageIndex) {
                              final imageUrl = images.isNotEmpty
                                  ? 'http://192.168.0.113:8000/storage/${images[imageIndex]}'
                                  : 'http://192.168.0.113:8000/storage/default.jpg';

                              return Image.network(
                                imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Center(child: Text('Image failed to load'));
                                },
                              );
                            },
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  favorite['body'] ?? 'No description',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.left,
                                ),
                              ),
                              if (price > 0)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                  child: Text(
                                    '\$${price.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Align(
                            alignment: Alignment.bottomRight,
                            child: IconButton(
                              icon: Icon(Icons.phone, color: Colors.white),
                              onPressed: () {
                                if (phoneNumber.isNotEmpty) {
                                  _launchWhatsApp(phoneNumber);
                                } else {
                                  print('No phone number available');
                                }
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
              onPageChanged: (index) {
                setState(() {
                });
              },
            ),
    );
  }
}

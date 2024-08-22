class User {
  int? id;
  String? name;
  String? image;
  String? email;
  String? token;
  String? phoneNumber; // Add this new property

  User({
    this.id,
    this.name,
    this.image,
    this.email,
    this.token,
    this.phoneNumber, // Add this to the constructor
  });

  // Function to convert json data to user model
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['user']['id'],
      name: json['user']['name'],
      image: json['user']['image'],
      email: json['user']['email'],
      token: json['token'],
      phoneNumber: json['user']['phone_number'], // Add this to the fromJson method
    );
  }

  // Convert user model to json
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'image': image,
      'email': email,
      'token': token,
      'phone_number': phoneNumber, // Add this to the toJson method
    };
  }
}

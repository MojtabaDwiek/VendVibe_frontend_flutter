class User {
  int? id;
  String? name;
  String? image;
  String? email;
  String? token;
  String? phoneNumber;

  User({
    this.id,
    this.name,
    this.image,
    this.email,
    this.token,
    this.phoneNumber,
  });

  // Convert json data to user model
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      image: json['image'],
      email: json['email'],
      token: json['token'],
      phoneNumber: json['phone_number'],
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
      'phone_number': phoneNumber,
    };
  }
}

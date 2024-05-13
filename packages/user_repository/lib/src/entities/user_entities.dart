class MyUserEntity {
  String userId;
  String email;
  String password;
  String username;
  String phoneNumber;
  bool hasActiveLocations;

  MyUserEntity({
    required this.userId,
    required this.email,
    required this.password,
    required this.username,
    required this.phoneNumber,
    required this.hasActiveLocations,
  });

  Map<String, Object?> toDocument() {
    return {
      'userId': userId,
      'email': email,
      'password': password,
      'username': username,
      'phoneNumber': phoneNumber,
      'hasActiveLocations': hasActiveLocations,
    };
  }

  static MyUserEntity fromDocument(Map<String, dynamic> doc) {
    return MyUserEntity(
      userId: doc['userId'],
      email: doc['email'],
      password: doc['password'],
      username: doc['username'],
      phoneNumber: doc['phoneNumber'],
      hasActiveLocations: doc['hasActiveLocations'],
    );
  }
}
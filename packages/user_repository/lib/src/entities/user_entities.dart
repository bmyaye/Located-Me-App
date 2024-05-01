class MyUserEntity {
  String userId;
  String email;
  // String password;
  String name;
  String phoneNumber;
  bool hasActiveLocations;

  MyUserEntity({
    required this.userId,
    required this.email,
    required this.name,
    required this.phoneNumber,
    required this.hasActiveLocations,
  });

  Map<String, Object?> toDocument() {
    return {
      'userId': userId,
      'email': email,
      'name': name,
      'phoneNumber': phoneNumber,
      'hasActiveLocations': hasActiveLocations,
    };
  }

  static MyUserEntity fromDocument(Map<String, dynamic> doc) {
    return MyUserEntity(
      userId: doc['userId'],
      email: doc['email'],
      name: doc['name'],
      phoneNumber: doc['phoneNumber'],
      hasActiveLocations: doc['hasActiveLocations'],
    );
  }
}
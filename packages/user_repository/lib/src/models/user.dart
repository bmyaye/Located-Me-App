import '../entities/entities.dart';

class MyUser {
  String userId;
  String email;
  // String password;
  String name;
  String phoneNumber;
  bool hasActiveLocations;

  MyUser({
    required this.userId,
    required this.email,
    required this.name,
    required this.phoneNumber,
    required this.hasActiveLocations,
  });

  static final empty = MyUser(
    userId: '',
    email: '',
    name: '',
    phoneNumber: '',
    hasActiveLocations: false,
  );

  MyUserEntity toEntity() {
    return MyUserEntity(
      userId: userId,
      email: email,
      name: name,
      phoneNumber: phoneNumber,
      hasActiveLocations: hasActiveLocations,
    );
  }

  static MyUser fromEntity(MyUserEntity entity) {
    return MyUser(
      userId: entity.userId,
      email: entity.email,
      name: entity.name,
      phoneNumber: entity.phoneNumber,
      hasActiveLocations: entity.hasActiveLocations,
    );
  }

  @override
  String toString() {
    return 'MyUser{userId: $userId, email: $email, name: $name, phoneNumber: $phoneNumber, hasActiveLocations: $hasActiveLocations}';
  }
}
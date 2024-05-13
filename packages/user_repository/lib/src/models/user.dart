import '../entities/entities.dart';

class MyUser {
  String userId;
  String email;
  String password;
  String username;
  String phoneNumber;
  bool hasActiveLocations;

  MyUser({
    required this.userId,
    required this.email,
    required this.password,
    required this.username,
    required this.phoneNumber,
    required this.hasActiveLocations,
  });

  static final empty = MyUser(
    userId: '',
    email: '',
    password: '',
    username: '',
    phoneNumber: '',
    hasActiveLocations: false,
  );

  MyUserEntity toEntity() {
    return MyUserEntity(
      userId: userId,
      email: email,
      password: password,
      username: username,
      phoneNumber: phoneNumber,
      hasActiveLocations: hasActiveLocations,
    );
  }

  static MyUser fromEntity(MyUserEntity entity) {
    return MyUser(
      userId: entity.userId,
      email: entity.email,
      password: entity.password,
      username: entity.username,
      phoneNumber: entity.phoneNumber,
      hasActiveLocations: entity.hasActiveLocations,
    );
  }

  @override
  String toString() {
    return 'MyUser{userId: $userId, email: $email, password: $password, username: $username, phoneNumber: $phoneNumber, hasActiveLocations: $hasActiveLocations}';
  }
}
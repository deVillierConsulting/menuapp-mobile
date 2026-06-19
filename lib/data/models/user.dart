import 'package:equatable/equatable.dart';

class User extends Equatable {
  final int userId;
  final String name;
  final String email;

  const User({
    required this.userId,
    required this.name,
    required this.email,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
        userId: json['user_id'] as int,
        name: json['name'] as String,
        email: json['email'] as String,
      );

  @override
  List<Object?> get props => [userId, name, email];
}

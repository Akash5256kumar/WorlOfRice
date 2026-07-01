import 'package:equatable/equatable.dart';

/// Represents the auth form input data.
final class AuthModel extends Equatable {
  const AuthModel({
    this.fullName,
    required this.email,
    required this.password,
  });

  final String? fullName;
  final String email;
  final String password;

  @override
  List<Object?> get props => [fullName, email, password];
}

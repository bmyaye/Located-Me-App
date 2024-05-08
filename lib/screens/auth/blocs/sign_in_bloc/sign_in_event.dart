part of 'sign_in_bloc.dart';

sealed class SignInEvent extends Equatable {
  const SignInEvent();

  @override
  List<Object> get props => [];
}

class SignInRequired extends SignInEvent {
  final String email;
  final String password;
  // final String username;

  const SignInRequired(this.email, this.password);

  @override
  List<Object> get props => [email, password];
}

class SignOutRequired extends SignInEvent {}
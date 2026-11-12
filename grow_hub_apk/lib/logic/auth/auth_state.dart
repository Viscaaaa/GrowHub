import 'package:equatable/equatable.dart';
import '../../data/models/user_model.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthAuthenticated extends AuthState {
  final UserModel user;
  final bool mustChangePassword;
  final bool showEthicsNotice;

  const AuthAuthenticated({
    required this.user,
    required this.mustChangePassword,
    this.showEthicsNotice = false,
  });

  @override
  List<Object?> get props => [user, mustChangePassword, showEthicsNotice];
}

class AuthUnauthenticated extends AuthState {
  final String? message;

  const AuthUnauthenticated({this.message});

  @override
  List<Object?> get props => [message];
}

class AuthFailure extends AuthState {
  final String message;

  const AuthFailure({required this.message});

  @override
  List<Object?> get props => [message];
}

class AuthPasswordChangeSuccess extends AuthState {
  final UserModel user;

  const AuthPasswordChangeSuccess(this.user);

  @override
  List<Object?> get props => [user];
}

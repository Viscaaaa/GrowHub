import 'package:equatable/equatable.dart';
import '../../data/models/user_model.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class AuthCheckRequested extends AuthEvent {}

class AuthLoginRequested extends AuthEvent {
  final String nip;
  final String password;

  const AuthLoginRequested({required this.nip, required this.password});

  @override
  List<Object?> get props => [nip, password];
}

class AuthLogoutRequested extends AuthEvent {}

class AuthFirstPasswordChangeRequested extends AuthEvent {
  final String otpVerificationToken;
  final String password;
  final String passwordConfirmation;

  const AuthFirstPasswordChangeRequested({
    required this.otpVerificationToken,
    required this.password,
    required this.passwordConfirmation,
  });

  @override
  List<Object?> get props =>
      [otpVerificationToken, password, passwordConfirmation];
}

class AuthUserUpdated extends AuthEvent {
  final UserModel user;

  const AuthUserUpdated(this.user);

  @override
  List<Object?> get props => [user];
}

class AuthEthicsNoticeAcknowledged extends AuthEvent {}

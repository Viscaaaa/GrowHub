import 'package:equatable/equatable.dart';

abstract class ProfileEvent extends Equatable {
  const ProfileEvent();

  @override
  List<Object?> get props => [];
}

class ProfileFetchRequested extends ProfileEvent {
  final int? userId;
  final bool refresh;

  const ProfileFetchRequested({this.userId, this.refresh = false});

  @override
  List<Object?> get props => [userId, refresh];
}

class ProfileUpdateRequested extends ProfileEvent {
  final String name;
  final String? email;
  final String? bio;
  final String? location;

  const ProfileUpdateRequested({
    required this.name,
    this.email,
    this.bio,
    this.location,
  });

  @override
  List<Object?> get props => [name, email, bio, location];
}

class ProfilePasswordChangeRequested extends ProfileEvent {
  final String otpVerificationToken;
  final String currentPassword;
  final String newPassword;
  final String confirmPassword;

  const ProfilePasswordChangeRequested({
    required this.otpVerificationToken,
    required this.currentPassword,
    required this.newPassword,
    required this.confirmPassword,
  });

  @override
  List<Object?> get props => [
        otpVerificationToken,
        currentPassword,
        newPassword,
        confirmPassword,
      ];
}

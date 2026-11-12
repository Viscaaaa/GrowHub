import 'package:equatable/equatable.dart';
import '../../data/repositories/profile_repository.dart';

abstract class ProfileState extends Equatable {
  const ProfileState();

  @override
  List<Object?> get props => [];
}

class ProfileInitial extends ProfileState {}

class ProfileLoading extends ProfileState {}

class ProfileLoaded extends ProfileState {
  final UserProfileDetails details;
  final bool isUpdating;
  final String? successMessage;

  const ProfileLoaded({
    required this.details,
    this.isUpdating = false,
    this.successMessage,
  });

  ProfileLoaded copyWith({
    UserProfileDetails? details,
    bool? isUpdating,
    String? successMessage,
    bool clearMessage = false,
  }) {
    return ProfileLoaded(
      details: details ?? this.details,
      isUpdating: isUpdating ?? this.isUpdating,
      successMessage:
          clearMessage ? null : (successMessage ?? this.successMessage),
    );
  }

  @override
  List<Object?> get props => [details, isUpdating, successMessage];
}

class ProfileError extends ProfileState {
  final String message;

  const ProfileError(this.message);

  @override
  List<Object?> get props => [message];
}

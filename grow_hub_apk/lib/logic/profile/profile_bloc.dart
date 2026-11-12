import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/network/api_exceptions.dart';
import '../../core/storage/local_storage.dart';
import '../../data/repositories/profile_repository.dart';
import 'profile_event.dart';
import 'profile_state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final ProfileRepository profileRepository;
  final LocalStorage localStorage;

  ProfileBloc({
    required this.profileRepository,
    required this.localStorage,
  }) : super(ProfileInitial()) {
    on<ProfileFetchRequested>(_onFetchRequested);
    on<ProfileUpdateRequested>(_onUpdateRequested);
    on<ProfilePasswordChangeRequested>(_onPasswordChangeRequested);
  }

  Future<void> _onFetchRequested(
    ProfileFetchRequested event,
    Emitter<ProfileState> emit,
  ) async {
    final targetId = event.userId ?? localStorage.getUser()?.id;
    if (targetId == null) {
      emit(const ProfileError('ID Pengguna tidak ditemukan.'));
      return;
    }

    if (!event.refresh && state is! ProfileLoaded) {
      emit(ProfileLoading());
    }

    try {
      final details = await profileRepository.getProfile(targetId);
      emit(ProfileLoaded(details: details));
    } catch (e) {
      emit(ProfileError(
        e is ApiException ? e.message : 'Gagal memuat profil pengguna.',
      ));
    }
  }

  Future<void> _onUpdateRequested(
    ProfileUpdateRequested event,
    Emitter<ProfileState> emit,
  ) async {
    if (state is! ProfileLoaded) return;
    final current = state as ProfileLoaded;

    emit(current.copyWith(isUpdating: true, clearMessage: true));
    try {
      final updatedUser = await profileRepository.updateProfile(
        name: event.name,
        email: event.email,
        bio: event.bio,
        location: event.location,
      );

      final updatedDetails = UserProfileDetails(
        user: updatedUser,
        rank: current.details.rank,
        stats: current.details.stats,
        contents: current.details.contents,
      );

      emit(current.copyWith(
        details: updatedDetails,
        isUpdating: false,
        successMessage: 'Profil berhasil diperbarui.',
      ));
    } catch (e) {
      emit(current.copyWith(isUpdating: false));
      emit(ProfileError(
        e is ApiException ? e.message : 'Gagal memperbarui profil.',
      ));
    }
  }

  Future<void> _onPasswordChangeRequested(
    ProfilePasswordChangeRequested event,
    Emitter<ProfileState> emit,
  ) async {
    if (state is! ProfileLoaded) return;
    final current = state as ProfileLoaded;

    emit(current.copyWith(isUpdating: true, clearMessage: true));
    try {
      await profileRepository.changePassword(
        otpVerificationToken: event.otpVerificationToken,
        currentPassword: event.currentPassword,
        newPassword: event.newPassword,
        confirmPassword: event.confirmPassword,
      );

      emit(current.copyWith(
        isUpdating: false,
        successMessage: 'Password berhasil diubah.',
      ));
    } catch (e) {
      emit(current.copyWith(isUpdating: false));
      emit(ProfileError(
        e is ApiException ? e.message : 'Gagal mengganti password.',
      ));
    }
  }
}

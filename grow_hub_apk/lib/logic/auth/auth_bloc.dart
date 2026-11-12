import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/network/api_exceptions.dart';
import '../../data/repositories/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository authRepository;

  AuthBloc({required this.authRepository}) : super(AuthInitial()) {
    on<AuthCheckRequested>(_onCheckRequested);
    on<AuthLoginRequested>(_onLoginRequested);
    on<AuthLogoutRequested>(_onLogoutRequested);
    on<AuthFirstPasswordChangeRequested>(_onFirstPasswordChangeRequested);
    on<AuthUserUpdated>(_onUserUpdated);
    on<AuthEthicsNoticeAcknowledged>(_onEthicsNoticeAcknowledged);
  }

  Future<void> _onCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      if (!authRepository.isAuthenticated()) {
        emit(const AuthUnauthenticated());
        return;
      }

      final cachedUser = await authRepository.getCachedUser();
      if (cachedUser != null) {
        if (!cachedUser.isEmployee) {
          await authRepository.logout();
          emit(const AuthUnauthenticated(
            message:
                'Akses Ditolak: Aplikasi ini khusus untuk karyawan (role employee).',
          ));
          return;
        }

        emit(AuthAuthenticated(
          user: cachedUser,
          mustChangePassword: cachedUser.mustChangePassword,
        ));
      }

      // Refresh in background
      final freshUser = await authRepository.getCurrentUser();
      if (freshUser != null) {
        if (!freshUser.isEmployee) {
          await authRepository.logout();
          emit(const AuthUnauthenticated(
            message:
                'Akses Ditolak: Aplikasi ini khusus untuk karyawan (role employee).',
          ));
          return;
        }

        emit(AuthAuthenticated(
          user: freshUser,
          mustChangePassword: freshUser.mustChangePassword,
        ));
      } else if (cachedUser == null) {
        emit(const AuthUnauthenticated());
      }
    } catch (e) {
      if (e is ApiException && e.statusCode == 401) {
        await authRepository.logout();
        emit(const AuthUnauthenticated());
      } else {
        final cached = await authRepository.getCachedUser();
        if (cached != null && cached.isEmployee) {
          emit(AuthAuthenticated(
            user: cached,
            mustChangePassword: cached.mustChangePassword,
          ));
        } else {
          emit(const AuthUnauthenticated());
        }
      }
    }
  }

  Future<void> _onLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final user = await authRepository.login(
        nip: event.nip.trim(),
        password: event.password,
      );

      // Verify role strictly
      if (!user.isEmployee) {
        await authRepository.logout();
        emit(AuthFailure(
          message:
              'Akses Ditolak: Aplikasi ini khusus untuk user dengan role Employee. Akun Anda memiliki role "${user.role}".',
        ));
        return;
      }

      emit(AuthAuthenticated(
        user: user,
        mustChangePassword: user.mustChangePassword,
        showEthicsNotice: true,
      ));
    } catch (e) {
      emit(AuthFailure(
        message: e is ApiException
            ? e.message
            : 'Gagal login. Periksa NIP dan password Anda.',
      ));
    }
  }

  Future<void> _onLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    await authRepository.logout();
    emit(const AuthUnauthenticated());
  }

  Future<void> _onFirstPasswordChangeRequested(
    AuthFirstPasswordChangeRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final updatedUser = await authRepository.firstChangePassword(
        otpVerificationToken: event.otpVerificationToken,
        password: event.password,
        passwordConfirmation: event.passwordConfirmation,
      );
      emit(AuthAuthenticated(
        user: updatedUser,
        mustChangePassword: false,
        showEthicsNotice: true,
      ));
    } catch (e) {
      emit(AuthFailure(
        message: e is ApiException
            ? e.message
            : 'Gagal mengganti password. Silakan coba lagi.',
      ));
    }
  }

  void _onUserUpdated(
    AuthUserUpdated event,
    Emitter<AuthState> emit,
  ) {
    if (state is AuthAuthenticated) {
      final current = state as AuthAuthenticated;
      emit(AuthAuthenticated(
        user: event.user,
        mustChangePassword: event.user.mustChangePassword,
        showEthicsNotice: current.showEthicsNotice,
      ));
    }
  }

  void _onEthicsNoticeAcknowledged(
    AuthEthicsNoticeAcknowledged event,
    Emitter<AuthState> emit,
  ) {
    if (state is AuthAuthenticated) {
      final current = state as AuthAuthenticated;
      emit(AuthAuthenticated(
        user: current.user,
        mustChangePassword: current.mustChangePassword,
        showEthicsNotice: false,
      ));
    }
  }
}

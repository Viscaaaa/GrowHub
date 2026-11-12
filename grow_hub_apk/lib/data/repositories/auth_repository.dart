import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_exceptions.dart';
import '../../core/storage/local_storage.dart';
import '../models/ethics_policy_model.dart';
import '../models/user_model.dart';

class AuthRepository {
  final ApiClient apiClient;
  final LocalStorage localStorage;

  AuthRepository({
    required this.apiClient,
    required this.localStorage,
  });

  Future<UserModel> login({
    required String nip,
    required String password,
  }) async {
    final response = await apiClient.post(
      ApiEndpoints.login,
      data: {
        'nip': nip,
        'password': password,
      },
    );

    final data = response.data;
    if (data is Map<String, dynamic> && data.containsKey('token')) {
      final token = data['token'] as String;
      final userJson = data['user'] as Map<String, dynamic>;
      final user = UserModel.fromJson(userJson);

      // Check role restriction: ONLY employee allowed
      if (!user.isEmployee) {
        throw ApiException(
          message:
              'Akses Ditolak: Aplikasi ini khusus untuk user dengan role Employee. Akun Anda memiliki role "${user.role}".',
        );
      }

      await localStorage.saveToken(token);
      await localStorage.saveUser(user);
      return user;
    } else {
      throw ApiException(message: 'Respon login tidak valid.');
    }
  }

  Future<UserModel?> getCachedUser() async {
    final user = localStorage.getUser();
    if (user != null && !user.isEmployee) {
      await localStorage.clearAuth();
      return null;
    }
    return user;
  }

  Future<UserModel?> getCurrentUser() async {
    final token = localStorage.getToken();
    if (token == null) return null;

    try {
      final response = await apiClient.get(ApiEndpoints.me);
      final user = UserModel.fromJson(response.data as Map<String, dynamic>);
      if (!user.isEmployee) {
        await localStorage.clearAuth();
        throw ApiException(
          message:
              'Akses Ditolak: Aplikasi ini khusus untuk user dengan role Employee.',
        );
      }
      await localStorage.saveUser(user);
      return user;
    } catch (_) {
      return getCachedUser();
    }
  }

  Future<void> logout() async {
    try {
      await apiClient.post(ApiEndpoints.logout);
    } catch (_) {
      // Ignore network errors on logout
    } finally {
      await localStorage.clearAuth();
    }
  }

  Future<Map<String, dynamic>> sendChangePasswordOtp() async {
    final response = await apiClient.post(ApiEndpoints.sendChangePasswordOtp);
    if (response.data is Map<String, dynamic>) {
      return response.data as Map<String, dynamic>;
    }
    throw ApiException(message: 'Gagal mengirim kode OTP.');
  }

  Future<String> verifyChangePasswordOtp({required String otp}) async {
    final response = await apiClient.post(
      ApiEndpoints.verifyChangePasswordOtp,
      data: {'otp': otp},
    );

    final data = response.data;
    if (data is Map<String, dynamic> &&
        data['otp_verification_token'] is String) {
      return data['otp_verification_token'] as String;
    }
    throw ApiException(message: 'Gagal memverifikasi kode OTP.');
  }

  Future<UserModel> firstChangePassword({
    required String otpVerificationToken,
    required String password,
    required String passwordConfirmation,
  }) async {
    final response = await apiClient.post(
      ApiEndpoints.firstChangePassword,
      data: {
        'otp_verification_token': otpVerificationToken,
        'password': password,
        'password_confirmation': passwordConfirmation,
      },
    );

    final data = response.data;
    if (data is Map<String, dynamic> && data.containsKey('user')) {
      final user = UserModel.fromJson(data['user'] as Map<String, dynamic>);
      await localStorage.saveUser(user);
      return user;
    }
    throw ApiException(message: 'Gagal memperbarui password.');
  }

  Future<List<EthicsPolicyModel>> getEthicsPolicies() async {
    final response = await apiClient.get(ApiEndpoints.ethicsPolicies);
    final data = response.data;
    if (data is Map<String, dynamic> && data['policies'] is List) {
      return (data['policies'] as List)
          .map((item) =>
              EthicsPolicyModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  bool isAuthenticated() {
    final token = localStorage.getToken();
    return token != null && token.isNotEmpty;
  }
}

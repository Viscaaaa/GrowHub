import 'package:dio/dio.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_exceptions.dart';
import '../../core/storage/local_storage.dart';
import '../models/content_model.dart';
import '../models/user_model.dart';

class UserProfileDetails {
  final UserModel user;
  final int rank;
  final Map<String, dynamic> stats;
  final List<ContentModel> contents;

  UserProfileDetails({
    required this.user,
    required this.rank,
    required this.stats,
    required this.contents,
  });
}

class ProfileRepository {
  final ApiClient apiClient;
  final LocalStorage localStorage;

  ProfileRepository({
    required this.apiClient,
    required this.localStorage,
  });

  Future<UserProfileDetails> getProfile(int userId) async {
    final response = await apiClient.get(ApiEndpoints.userProfile(userId));
    final data = response.data as Map<String, dynamic>;

    final user = UserModel.fromJson(data['user'] as Map<String, dynamic>);
    final rank = data['rank'] is int
        ? data['rank']
        : int.tryParse('${data['rank']}') ?? 0;
    final stats = data['stats'] is Map<String, dynamic>
        ? data['stats'] as Map<String, dynamic>
        : <String, dynamic>{};

    List<ContentModel> contents = [];
    if (data['contents'] is List) {
      contents = (data['contents'] as List)
          .map((c) => ContentModel.fromJson(c as Map<String, dynamic>))
          .toList();
    }

    return UserProfileDetails(
      user: user,
      rank: rank,
      stats: stats,
      contents: contents,
    );
  }

  Future<UserModel> updateProfile({
    required String name,
    String? email,
    String? bio,
    String? location,
  }) async {
    final response = await apiClient.put(
      ApiEndpoints.profileUpdate,
      data: {
        'name': name,
        if (email != null && email.isNotEmpty) 'email': email,
        if (bio != null) 'bio': bio,
        if (location != null) 'location': location,
      },
    );

    final data = response.data as Map<String, dynamic>;
    final user = UserModel.fromJson(data['user'] as Map<String, dynamic>);
    await localStorage.saveUser(user);
    return user;
  }

  Future<Map<String, dynamic>> sendPasswordOtp() async {
    final response = await apiClient.post(ApiEndpoints.sendProfilePasswordOtp);
    if (response.data is Map<String, dynamic>) {
      return response.data as Map<String, dynamic>;
    }
    throw ApiException(message: 'Gagal mengirim kode OTP.');
  }

  Future<String> verifyPasswordOtp({required String otp}) async {
    final response = await apiClient.post(
      ApiEndpoints.verifyProfilePasswordOtp,
      data: {'otp': otp},
    );

    final data = response.data;
    if (data is Map<String, dynamic> &&
        data['otp_verification_token'] is String) {
      return data['otp_verification_token'] as String;
    }
    throw ApiException(message: 'Gagal memverifikasi kode OTP.');
  }

  Future<void> changePassword({
    required String otpVerificationToken,
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    await apiClient.put(
      ApiEndpoints.profilePassword,
      data: {
        'otp_verification_token': otpVerificationToken,
        'current_password': currentPassword,
        'password': newPassword,
        'password_confirmation': confirmPassword,
      },
    );
  }

  Future<UserModel> uploadAvatar(MultipartFile file) async {
    final formData = FormData.fromMap({
      'avatar': file,
    });

    final response = await apiClient.post(
      ApiEndpoints.profileAvatar,
      data: formData,
    );

    final data = response.data as Map<String, dynamic>;
    final user = UserModel.fromJson(data['user'] as Map<String, dynamic>);
    await localStorage.saveUser(user);
    return user;
  }
}

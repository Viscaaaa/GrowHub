import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';
import '../models/leaderboard_model.dart';

class LeaderboardRepository {
  final ApiClient apiClient;

  LeaderboardRepository({required this.apiClient});

  Future<LeaderboardResponseModel> getLeaderboard({
    String period = 'all', // 'all', 'month', 'week'
    String? department,
  }) async {
    final Map<String, dynamic> params = {'period': period};
    if (department != null && department.isNotEmpty && department != 'Semua') {
      params['department'] = department;
    }

    final response = await apiClient.get(
      ApiEndpoints.leaderboard,
      queryParameters: params,
    );

    return LeaderboardResponseModel.fromJson(
        response.data as Map<String, dynamic>);
  }
}

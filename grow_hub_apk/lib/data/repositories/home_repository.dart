import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';
import '../models/dashboard_model.dart';

class HomeRepository {
  final ApiClient apiClient;

  HomeRepository({required this.apiClient});

  Future<HomeDataModel> getHomeData() async {
    final response = await apiClient.get(ApiEndpoints.home);
    return HomeDataModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<DashboardMeModel> getMyDashboard() async {
    final response = await apiClient.get(ApiEndpoints.dashboard);
    return DashboardMeModel.fromJson(response.data as Map<String, dynamic>);
  }
}

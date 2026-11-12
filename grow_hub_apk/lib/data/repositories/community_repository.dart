import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';
import '../models/community_model.dart';
import '../models/content_model.dart';

class CommunityDetailResponse {
  final CommunityModel community;
  final List<ContentModel> contents;

  CommunityDetailResponse({
    required this.community,
    required this.contents,
  });
}

class CommunityRepository {
  final ApiClient apiClient;

  CommunityRepository({required this.apiClient});

  Future<List<CommunityModel>> getCommunities({
    String? q,
    bool joinedOnly = false,
  }) async {
    final Map<String, dynamic> params = {};
    if (q != null && q.isNotEmpty) {
      params['q'] = q;
    }
    if (joinedOnly) {
      params['joined'] = 1;
    }

    final response = await apiClient.get(
      ApiEndpoints.communities,
      queryParameters: params,
    );

    if (response.data is List) {
      return (response.data as List)
          .map((c) => CommunityModel.fromJson(c as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  Future<CommunityDetailResponse> getCommunityDetail(String slug) async {
    final response = await apiClient.get(ApiEndpoints.communityDetail(slug));
    final data = response.data as Map<String, dynamic>;

    final community = CommunityModel.fromJson(data);
    List<ContentModel> contents = [];
    if (data['contents'] is List) {
      contents = (data['contents'] as List)
          .map((c) => ContentModel.fromJson(c as Map<String, dynamic>))
          .toList();
    }

    return CommunityDetailResponse(
      community: community,
      contents: contents,
    );
  }

  Future<Map<String, dynamic>> toggleJoin(int communityId) async {
    final response =
        await apiClient.post(ApiEndpoints.communityJoin(communityId));
    return response.data as Map<String, dynamic>;
  }
}

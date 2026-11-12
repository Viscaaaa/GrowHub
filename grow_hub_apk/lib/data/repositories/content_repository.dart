import 'package:dio/dio.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';
import '../models/category_model.dart';
import '../models/comment_model.dart';
import '../models/content_model.dart';

class ContentDetailResponse {
  final ContentModel content;
  final List<ContentModel> related;

  ContentDetailResponse({
    required this.content,
    required this.related,
  });
}

class MyContentsResponse {
  final List<ContentModel> contents;
  final Map<String, int> counts;
  final Map<String, dynamic>? engagement;

  MyContentsResponse({
    required this.contents,
    required this.counts,
    this.engagement,
  });
}

class ContentRepository {
  final ApiClient apiClient;

  ContentRepository({required this.apiClient});

  Future<List<CategoryModel>> getCategories() async {
    final response = await apiClient.get(ApiEndpoints.categories);
    if (response.data is List) {
      return (response.data as List)
          .map((c) => CategoryModel.fromJson(c as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  Future<List<ContentModel>> getContents({
    String? category,
    int? communityId,
    String? q,
    String? sort = 'latest',
    int page = 1,
  }) async {
    final Map<String, dynamic> params = {
      'page': page,
      'sort': sort,
    };
    if (category != null && category.isNotEmpty) {
      params['category'] = category;
    }
    if (communityId != null) {
      params['community_id'] = communityId;
    }
    if (q != null && q.isNotEmpty) {
      params['q'] = q;
    }

    final response = await apiClient.get(
      ApiEndpoints.contents,
      queryParameters: params,
    );

    final data = response.data;
    if (data is Map<String, dynamic> && data.containsKey('data')) {
      final list = data['data'] as List;
      return list
          .map((c) => ContentModel.fromJson(c as Map<String, dynamic>))
          .toList();
    } else if (data is List) {
      return data
          .map((c) => ContentModel.fromJson(c as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  Future<ContentDetailResponse> getContentDetail(int id) async {
    final response = await apiClient.get(ApiEndpoints.contentDetail(id));
    final data = response.data as Map<String, dynamic>;

    final content = ContentModel.fromJson(data['content'] as Map<String, dynamic>);
    List<ContentModel> related = [];
    if (data['related'] is List) {
      related = (data['related'] as List)
          .map((r) => ContentModel.fromJson(r as Map<String, dynamic>))
          .toList();
    }

    return ContentDetailResponse(content: content, related: related);
  }

  Future<Map<String, dynamic>> toggleLike(int contentId) async {
    final response = await apiClient.post(ApiEndpoints.contentLike(contentId));
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> toggleSave(int contentId) async {
    final response = await apiClient.post(ApiEndpoints.contentSave(contentId));
    return response.data as Map<String, dynamic>;
  }

  Future<void> shareContent(int contentId) async {
    await apiClient.post(ApiEndpoints.contentShare(contentId));
  }

  Future<List<CommentModel>> getComments(int contentId) async {
    final response = await apiClient.get(ApiEndpoints.contentComments(contentId));
    if (response.data is List) {
      return (response.data as List)
          .map((c) => CommentModel.fromJson(c as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  Future<CommentModel> postComment(int contentId, String body) async {
    final response = await apiClient.post(
      ApiEndpoints.contentComments(contentId),
      data: {'body': body},
    );
    final data = response.data;
    if (data is Map<String, dynamic> && data.containsKey('comment')) {
      return CommentModel.fromJson(data['comment'] as Map<String, dynamic>);
    }
    return CommentModel.fromJson(data as Map<String, dynamic>);
  }

  Future<void> deleteComment(int commentId) async {
    await apiClient.delete(ApiEndpoints.commentDelete(commentId));
  }

  Future<ContentModel> createContent({
    required String title,
    required String body,
    required int categoryId,
    int? communityId,
    List<String>? tags,
    String action = 'submit', // 'submit' or 'draft'
    List<MultipartFile>? mediaFiles,
  }) async {
    final formData = FormData.fromMap({
      'title': title,
      'body': body,
      'category_id': categoryId,
      'action': action,
      if (communityId != null) 'community_id': communityId,
      if (tags != null && tags.isNotEmpty) 'tags': tags.join(','),
    });

    if (mediaFiles != null) {
      for (var file in mediaFiles) {
        formData.files.add(MapEntry('media[]', file));
      }
    }

    final response = await apiClient.post(
      ApiEndpoints.contents,
      data: formData,
    );

    final data = response.data as Map<String, dynamic>;
    return ContentModel.fromJson(data['content'] as Map<String, dynamic>);
  }

  Future<ContentModel> updateContent({
    required int id,
    required String title,
    required String body,
    required int categoryId,
    int? communityId,
    List<String>? tags,
    String action = 'submit',
    List<MultipartFile>? mediaFiles,
    List<int>? removeMedia,
  }) async {
    final formData = FormData.fromMap({
      'title': title,
      'body': body,
      'category_id': categoryId,
      'action': action,
      if (communityId != null) 'community_id': communityId,
      if (tags != null && tags.isNotEmpty) 'tags': tags.join(','),
    });

    if (removeMedia != null) {
      for (var id in removeMedia) {
        formData.fields.add(MapEntry('remove_media[]', id.toString()));
      }
    }

    if (mediaFiles != null) {
      for (var file in mediaFiles) {
        formData.files.add(MapEntry('media[]', file));
      }
    }

    final response = await apiClient.post(
      ApiEndpoints.contentDetail(id),
      data: formData,
    );

    final data = response.data as Map<String, dynamic>;
    return ContentModel.fromJson(data['content'] as Map<String, dynamic>);
  }

  Future<void> deleteContent(int id) async {
    await apiClient.delete(ApiEndpoints.contentDetail(id));
  }

  Future<MyContentsResponse> getMyContents({
    String? status,
    int page = 1,
  }) async {
    final Map<String, dynamic> params = {'page': page};
    if (status != null && status != 'all') {
      params['status'] = status;
    }

    final response = await apiClient.get(
      ApiEndpoints.myContents,
      queryParameters: params,
    );

    final data = response.data as Map<String, dynamic>;
    List<ContentModel> contents = [];
    if (data['data'] is Map && data['data']['data'] is List) {
      contents = (data['data']['data'] as List)
          .map((c) => ContentModel.fromJson(c as Map<String, dynamic>))
          .toList();
    }

    Map<String, int> counts = {};
    if (data['counts'] is Map) {
      data['counts'].forEach((k, v) {
        counts[k.toString()] = v is int ? v : int.tryParse('$v') ?? 0;
      });
    }

    return MyContentsResponse(
      contents: contents,
      counts: counts,
      engagement: data['engagement'] as Map<String, dynamic>?,
    );
  }

  Future<List<ContentModel>> getSavedContents() async {
    final response = await apiClient.get(ApiEndpoints.mySaved);
    final data = response.data;
    if (data is List) {
      return data
          .map((c) => ContentModel.fromJson(c as Map<String, dynamic>))
          .toList();
    } else if (data is Map && data.containsKey('data') && data['data'] is List) {
      return (data['data'] as List)
          .map((c) => ContentModel.fromJson(c as Map<String, dynamic>))
          .toList();
    }
    return [];
  }
}

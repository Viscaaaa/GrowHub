import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';
import '../models/course_model.dart';

class CoursesResponse {
  final List<CourseModel> courses;
  final List<String> categories;
  final int completed;
  final int total;

  CoursesResponse({
    required this.courses,
    required this.categories,
    required this.completed,
    required this.total,
  });
}

class CourseCompleteResponse {
  final String message;
  final int pointsEarned;

  CourseCompleteResponse({
    required this.message,
    required this.pointsEarned,
  });
}

class CourseRepository {
  final ApiClient apiClient;

  CourseRepository({required this.apiClient});

  Future<CoursesResponse> getCourses({
    String? category,
    String? q,
  }) async {
    final Map<String, dynamic> params = {};
    if (category != null && category.isNotEmpty && category != 'Semua') {
      params['category'] = category;
    }
    if (q != null && q.isNotEmpty) {
      params['q'] = q;
    }

    final response = await apiClient.get(
      ApiEndpoints.courses,
      queryParameters: params,
    );

    final data = response.data as Map<String, dynamic>;
    List<CourseModel> courses = [];
    if (data['courses'] is List) {
      courses = (data['courses'] as List)
          .map((c) => CourseModel.fromJson(c as Map<String, dynamic>))
          .toList();
    }

    List<String> categories = [];
    if (data['categories'] is List) {
      categories = (data['categories'] as List)
          .map((cat) => cat.toString())
          .toList();
    }

    return CoursesResponse(
      courses: courses,
      categories: categories,
      completed: data['completed'] is int
          ? data['completed']
          : int.tryParse('${data['completed']}') ?? 0,
      total: data['total'] is int
          ? data['total']
          : int.tryParse('${data['total']}') ?? 0,
    );
  }

  Future<CourseModel> getCourseDetail(String slug) async {
    final response = await apiClient.get(ApiEndpoints.courseDetail(slug));
    return CourseModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<CourseCompleteResponse> completeCourse(int id) async {
    final response = await apiClient.post(ApiEndpoints.courseComplete(id));
    final data = response.data as Map<String, dynamic>;
    return CourseCompleteResponse(
      message: data['message'] ?? 'Materi selesai.',
      pointsEarned: data['points_earned'] is int
          ? data['points_earned']
          : int.tryParse('${data['points_earned']}') ?? 0,
    );
  }
}

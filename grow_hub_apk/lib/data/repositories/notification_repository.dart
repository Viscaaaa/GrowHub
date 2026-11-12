import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';
import '../models/notification_model.dart';

class NotificationsResponse {
  final List<NotificationModel> notifications;
  final int unreadCount;

  NotificationsResponse({
    required this.notifications,
    required this.unreadCount,
  });
}

class NotificationRepository {
  final ApiClient apiClient;

  NotificationRepository({required this.apiClient});

  Future<NotificationsResponse> getNotifications({
    String? filter, // 'unread' or null
    int page = 1,
  }) async {
    final Map<String, dynamic> params = {'page': page};
    if (filter != null) {
      params['filter'] = filter;
    }

    final response = await apiClient.get(
      ApiEndpoints.notifications,
      queryParameters: params,
    );

    final data = response.data as Map<String, dynamic>;
    List<NotificationModel> list = [];
    if (data['data'] is Map && data['data']['data'] is List) {
      list = (data['data']['data'] as List)
          .map((n) => NotificationModel.fromJson(n as Map<String, dynamic>))
          .toList();
    }

    return NotificationsResponse(
      notifications: list,
      unreadCount: data['unread'] is int
          ? data['unread']
          : int.tryParse('${data['unread']}') ?? 0,
    );
  }

  Future<int> getUnreadCount() async {
    try {
      final response = await apiClient.get(ApiEndpoints.notificationsUnreadCount);
      final data = response.data as Map<String, dynamic>;
      return data['unread'] is int
          ? data['unread']
          : int.tryParse('${data['unread']}') ?? 0;
    } catch (_) {
      return 0;
    }
  }

  Future<void> markRead(int id) async {
    await apiClient.post(ApiEndpoints.notificationMarkRead(id));
  }

  Future<void> markAllRead() async {
    await apiClient.post(ApiEndpoints.notificationsReadAll);
  }
}

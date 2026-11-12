import 'user_model.dart';

class NotificationModel {
  final int id;
  final int userId;
  final String type;
  final String title;
  final String body;
  final Map<String, dynamic>? data;
  final String? readAt;
  final String? createdAt;
  final UserModel? actor;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.body,
    this.data,
    this.readAt,
    this.createdAt,
    this.actor,
  });

  bool get isRead => readAt != null;

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] is int ? json['id'] : int.tryParse('${json['id']}') ?? 0,
      userId: json['user_id'] is int
          ? json['user_id']
          : int.tryParse('${json['user_id']}') ?? 0,
      type: json['type'] ?? 'info',
      title: json['title'] ?? '',
      body: json['body'] ?? '',
      data: json['data'] is Map<String, dynamic> ? json['data'] : null,
      readAt: json['read_at'],
      createdAt: json['created_at'],
      actor: json['actor'] is Map<String, dynamic>
          ? UserModel.fromJson(json['actor'])
          : null,
    );
  }

  NotificationModel copyWith({
    String? readAt,
  }) {
    return NotificationModel(
      id: id,
      userId: userId,
      type: type,
      title: title,
      body: body,
      data: data,
      readAt: readAt ?? this.readAt,
      createdAt: createdAt,
      actor: actor,
    );
  }
}

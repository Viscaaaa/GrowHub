import 'user_model.dart';

class CommentModel {
  final int id;
  final int contentId;
  final int userId;
  final String body;
  final String? createdAt;
  final UserModel? user;

  CommentModel({
    required this.id,
    required this.contentId,
    required this.userId,
    required this.body,
    this.createdAt,
    this.user,
  });

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    return CommentModel(
      id: json['id'] is int ? json['id'] : int.tryParse('${json['id']}') ?? 0,
      contentId: json['content_id'] is int
          ? json['content_id']
          : int.tryParse('${json['content_id']}') ?? 0,
      userId: json['user_id'] is int
          ? json['user_id']
          : int.tryParse('${json['user_id']}') ?? 0,
      body: json['body'] ?? '',
      createdAt: json['created_at'],
      user: json['user'] is Map<String, dynamic>
          ? UserModel.fromJson(json['user'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content_id': contentId,
      'user_id': userId,
      'body': body,
      'created_at': createdAt,
      'user': user?.toJson(),
    };
  }
}

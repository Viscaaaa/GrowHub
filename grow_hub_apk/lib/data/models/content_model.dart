import 'category_model.dart';
import 'user_model.dart';

class ContentMediaModel {
  final int id;
  final String path;
  final String filename;
  final String type; // 'image', 'video', 'document'
  final int size;
  final String? url;

  ContentMediaModel({
    required this.id,
    required this.path,
    required this.filename,
    required this.type,
    required this.size,
    this.url,
  });

  factory ContentMediaModel.fromJson(Map<String, dynamic> json) {
    return ContentMediaModel(
      id: json['id'] is int ? json['id'] : int.tryParse('${json['id']}') ?? 0,
      path: json['path'] ?? '',
      filename: json['filename'] ?? '',
      type: json['type'] ?? 'image',
      size: json['size'] is int ? json['size'] : int.tryParse('${json['size']}') ?? 0,
      url: json['url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'path': path,
      'filename': filename,
      'type': type,
      'size': size,
      'url': url,
    };
  }
}

class ContentModel {
  final int id;
  final int userId;
  final int categoryId;
  final int? communityId;
  final String title;
  final String body;
  final List<String> tags;
  final String status; // 'published', 'pending', 'draft', 'rejected'
  final String? publishedAt;
  final int likesCount;
  final int commentsCount;
  final int viewsCount;
  final int sharesCount;
  final int savesCount;
  final UserModel? author;
  final CategoryModel? category;
  final String? communityName;
  final String? communitySlug;
  final List<ContentMediaModel> media;
  final bool isLiked;
  final bool isSaved;
  final String? reviewNote;
  final String? reviewerName;
  final String? createdAt;
  final String? updatedAt;

  ContentModel({
    required this.id,
    required this.userId,
    required this.categoryId,
    this.communityId,
    required this.title,
    required this.body,
    this.tags = const [],
    required this.status,
    this.publishedAt,
    this.likesCount = 0,
    this.commentsCount = 0,
    this.viewsCount = 0,
    this.sharesCount = 0,
    this.savesCount = 0,
    this.author,
    this.category,
    this.communityName,
    this.communitySlug,
    this.media = const [],
    this.isLiked = false,
    this.isSaved = false,
    this.reviewNote,
    this.reviewerName,
    this.createdAt,
    this.updatedAt,
  });

  bool get isPublished => status == 'published';
  bool get isPending => status == 'pending';
  bool get isDraft => status == 'draft';
  bool get isRejected => status == 'rejected';

  factory ContentModel.fromJson(Map<String, dynamic> json) {
    List<String> parsedTags = [];
    if (json['tags'] is List) {
      parsedTags = (json['tags'] as List).map((e) => e.toString()).toList();
    }

    List<ContentMediaModel> mediaList = [];
    if (json['media'] is List) {
      mediaList = (json['media'] as List)
          .map((m) => ContentMediaModel.fromJson(m as Map<String, dynamic>))
          .toList();
    }

    String? commName;
    String? commSlug;
    if (json['community'] is Map<String, dynamic>) {
      commName = json['community']['name'];
      commSlug = json['community']['slug'];
    }

    String? revName;
    if (json['reviewer'] is Map<String, dynamic>) {
      revName = json['reviewer']['name'];
    }

    return ContentModel(
      id: json['id'] is int ? json['id'] : int.tryParse('${json['id']}') ?? 0,
      userId: json['user_id'] is int ? json['user_id'] : int.tryParse('${json['user_id']}') ?? 0,
      categoryId: json['category_id'] is int ? json['category_id'] : int.tryParse('${json['category_id']}') ?? 0,
      communityId: json['community_id'] != null ? (json['community_id'] is int ? json['community_id'] : int.tryParse('${json['community_id']}')) : null,
      title: json['title'] ?? '',
      body: json['body'] ?? '',
      tags: parsedTags,
      status: json['status'] ?? 'published',
      publishedAt: json['published_at'],
      likesCount: json['likes_count'] is int ? json['likes_count'] : int.tryParse('${json['likes_count']}') ?? 0,
      commentsCount: json['comments_count'] is int ? json['comments_count'] : int.tryParse('${json['comments_count']}') ?? 0,
      viewsCount: json['views_count'] is int ? json['views_count'] : int.tryParse('${json['views_count']}') ?? 0,
      sharesCount: json['shares_count'] is int ? json['shares_count'] : int.tryParse('${json['shares_count']}') ?? 0,
      savesCount: json['saves_count'] is int ? json['saves_count'] : int.tryParse('${json['saves_count']}') ?? 0,
      author: json['author'] is Map<String, dynamic> ? UserModel.fromJson(json['author']) : null,
      category: json['category'] is Map<String, dynamic> ? CategoryModel.fromJson(json['category']) : null,
      communityName: commName,
      communitySlug: commSlug,
      media: mediaList,
      isLiked: json['is_liked'] == true || json['is_liked'] == 1,
      isSaved: json['is_saved'] == true || json['is_saved'] == 1,
      reviewNote: json['review_note'],
      reviewerName: revName,
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }

  ContentModel copyWith({
    bool? isLiked,
    bool? isSaved,
    int? likesCount,
    int? savesCount,
    int? commentsCount,
    String? status,
    String? title,
    String? body,
  }) {
    return ContentModel(
      id: id,
      userId: userId,
      categoryId: categoryId,
      communityId: communityId,
      title: title ?? this.title,
      body: body ?? this.body,
      tags: tags,
      status: status ?? this.status,
      publishedAt: publishedAt,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      viewsCount: viewsCount,
      sharesCount: sharesCount,
      savesCount: savesCount ?? this.savesCount,
      author: author,
      category: category,
      communityName: communityName,
      communitySlug: communitySlug,
      media: media,
      isLiked: isLiked ?? this.isLiked,
      isSaved: isSaved ?? this.isSaved,
      reviewNote: reviewNote,
      reviewerName: reviewerName,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

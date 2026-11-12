import 'user_model.dart';

class CommunityModel {
  final int id;
  final String name;
  final String slug;
  final String? description;
  final String? icon;
  final String? color;
  final int membersCount;
  final int contentsCount;
  final bool isMember;
  final List<UserModel> members;

  CommunityModel({
    required this.id,
    required this.name,
    required this.slug,
    this.description,
    this.icon,
    this.color,
    this.membersCount = 0,
    this.contentsCount = 0,
    this.isMember = false,
    this.members = const [],
  });

  factory CommunityModel.fromJson(Map<String, dynamic> json) {
    List<UserModel> memberList = [];
    if (json['members'] is List) {
      memberList = (json['members'] as List)
          .map((m) => UserModel.fromJson(m as Map<String, dynamic>))
          .toList();
    }

    return CommunityModel(
      id: json['id'] is int ? json['id'] : int.tryParse('${json['id']}') ?? 0,
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
      description: json['description'],
      icon: json['icon'],
      color: json['color'],
      membersCount: json['members_count'] is int
          ? json['members_count']
          : int.tryParse('${json['members_count']}') ?? 0,
      contentsCount: json['contents_count'] is int
          ? json['contents_count']
          : int.tryParse('${json['contents_count']}') ?? 0,
      isMember: json['is_member'] == true || json['is_member'] == 1,
      members: memberList,
    );
  }

  CommunityModel copyWith({
    bool? isMember,
    int? membersCount,
  }) {
    return CommunityModel(
      id: id,
      name: name,
      slug: slug,
      description: description,
      icon: icon,
      color: color,
      membersCount: membersCount ?? this.membersCount,
      contentsCount: contentsCount,
      isMember: isMember ?? this.isMember,
      members: members,
    );
  }
}

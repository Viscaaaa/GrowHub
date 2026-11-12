import 'category_model.dart';
import 'content_model.dart';
import 'course_model.dart';
import 'leaderboard_model.dart';
import 'user_model.dart';

class HomeStatsModel {
  final int publishedContents;
  final int contributors;
  final int employees;
  final int contentsThisWeek;

  HomeStatsModel({
    this.publishedContents = 0,
    this.contributors = 0,
    this.employees = 0,
    this.contentsThisWeek = 0,
  });

  factory HomeStatsModel.fromJson(Map<String, dynamic> json) {
    return HomeStatsModel(
      publishedContents: json['published_contents'] is int
          ? json['published_contents']
          : int.tryParse('${json['published_contents']}') ?? 0,
      contributors: json['contributors'] is int
          ? json['contributors']
          : int.tryParse('${json['contributors']}') ?? 0,
      employees: json['employees'] is int
          ? json['employees']
          : int.tryParse('${json['employees']}') ?? 0,
      contentsThisWeek: json['contents_this_week'] is int
          ? json['contents_this_week']
          : int.tryParse('${json['contents_this_week']}') ?? 0,
    );
  }
}

class HomeDataModel {
  final HomeStatsModel stats;
  final int myRank;
  final List<ContentModel> trending;
  final List<ContentModel> latest;
  final List<LeaderboardItemModel> topWeekly;
  final List<CategoryModel> categories;
  final List<CourseModel> courses;

  HomeDataModel({
    required this.stats,
    this.myRank = 0,
    this.trending = const [],
    this.latest = const [],
    this.topWeekly = const [],
    this.categories = const [],
    this.courses = const [],
  });

  factory HomeDataModel.fromJson(Map<String, dynamic> json) {
    return HomeDataModel(
      stats: json['stats'] is Map<String, dynamic>
          ? HomeStatsModel.fromJson(json['stats'])
          : HomeStatsModel(),
      myRank: json['my_rank'] is int
          ? json['my_rank']
          : int.tryParse('${json['my_rank']}') ?? 0,
      trending: json['trending'] is List
          ? (json['trending'] as List)
              .map((c) => ContentModel.fromJson(c as Map<String, dynamic>))
              .toList()
          : [],
      latest: json['latest'] is List
          ? (json['latest'] as List)
              .map((c) => ContentModel.fromJson(c as Map<String, dynamic>))
              .toList()
          : [],
      topWeekly: json['top_weekly'] is List
          ? (json['top_weekly'] as List)
              .map((u) =>
                  LeaderboardItemModel.fromJson(u as Map<String, dynamic>))
              .toList()
          : [],
      categories: json['categories'] is List
          ? (json['categories'] as List)
              .map((c) => CategoryModel.fromJson(c as Map<String, dynamic>))
              .toList()
          : [],
      courses: json['courses'] is List
          ? (json['courses'] as List)
              .map((c) => CourseModel.fromJson(c as Map<String, dynamic>))
              .toList()
          : [],
    );
  }
}

class BadgeModel {
  final String key;
  final String name;
  final String desc;
  final String icon;
  final bool earned;
  final int progress;
  final int target;

  BadgeModel({
    required this.key,
    required this.name,
    required this.desc,
    required this.icon,
    this.earned = false,
    this.progress = 0,
    this.target = 1,
  });

  factory BadgeModel.fromJson(Map<String, dynamic> json) {
    return BadgeModel(
      key: json['key'] ?? '',
      name: json['name'] ?? '',
      desc: json['desc'] ?? '',
      icon: json['icon'] ?? 'Sprout',
      earned: json['earned'] == true,
      progress: json['progress'] is int
          ? json['progress']
          : int.tryParse('${json['progress']}') ?? 0,
      target: json['target'] is int
          ? json['target']
          : int.tryParse('${json['target']}') ?? 1,
    );
  }
}

class PointTransactionModel {
  final int id;
  final String action;
  final int points;
  final String? description;
  final String? createdAt;

  PointTransactionModel({
    required this.id,
    required this.action,
    required this.points,
    this.description,
    this.createdAt,
  });

  factory PointTransactionModel.fromJson(Map<String, dynamic> json) {
    return PointTransactionModel(
      id: json['id'] is int ? json['id'] : int.tryParse('${json['id']}') ?? 0,
      action: json['action'] ?? '',
      points: json['points'] is int
          ? json['points']
          : int.tryParse('${json['points']}') ?? 0,
      description: json['description'],
      createdAt: json['created_at'],
    );
  }
}

class DashboardMeModel {
  final UserModel user;
  final int rank;
  final int departmentRank;
  final int pointsThisWeek;
  final int pointsThisMonth;
  final Map<String, int> contentCounts;
  final List<BadgeModel> badges;
  final List<PointTransactionModel> recentPoints;

  DashboardMeModel({
    required this.user,
    this.rank = 0,
    this.departmentRank = 0,
    this.pointsThisWeek = 0,
    this.pointsThisMonth = 0,
    this.contentCounts = const {},
    this.badges = const [],
    this.recentPoints = const [],
  });

  factory DashboardMeModel.fromJson(Map<String, dynamic> json) {
    Map<String, int> counts = {};
    if (json['content_counts'] is Map) {
      json['content_counts'].forEach((k, v) {
        counts[k.toString()] = v is int ? v : int.tryParse('$v') ?? 0;
      });
    }

    return DashboardMeModel(
      user: json['user'] is Map<String, dynamic>
          ? UserModel.fromJson(json['user'])
          : UserModel(id: 0, nip: '', name: '', role: 'employee'),
      rank: json['rank'] is int ? json['rank'] : int.tryParse('${json['rank']}') ?? 0,
      departmentRank: json['department_rank'] is int
          ? json['department_rank']
          : int.tryParse('${json['department_rank']}') ?? 0,
      pointsThisWeek: json['points_this_week'] is int
          ? json['points_this_week']
          : int.tryParse('${json['points_this_week']}') ?? 0,
      pointsThisMonth: json['points_this_month'] is int
          ? json['points_this_month']
          : int.tryParse('${json['points_this_month']}') ?? 0,
      contentCounts: counts,
      badges: json['badges'] is List
          ? (json['badges'] as List)
              .map((b) => BadgeModel.fromJson(b as Map<String, dynamic>))
              .toList()
          : [],
      recentPoints: json['recent_points'] is List
          ? (json['recent_points'] as List)
              .map((p) =>
                  PointTransactionModel.fromJson(p as Map<String, dynamic>))
              .toList()
          : [],
    );
  }
}

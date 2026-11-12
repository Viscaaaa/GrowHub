class CourseModel {
  final int id;
  final String title;
  final String slug;
  final String category;
  final String level;
  final String summary;
  final String? body;
  final String? coverColor;
  final int durationMinutes;
  final int pointsReward;
  final bool isCompleted;
  final int completionsCount;

  CourseModel({
    required this.id,
    required this.title,
    required this.slug,
    required this.category,
    required this.level,
    required this.summary,
    this.body,
    this.coverColor,
    required this.durationMinutes,
    required this.pointsReward,
    this.isCompleted = false,
    this.completionsCount = 0,
  });

  factory CourseModel.fromJson(Map<String, dynamic> json) {
    return CourseModel(
      id: json['id'] is int ? json['id'] : int.tryParse('${json['id']}') ?? 0,
      title: json['title'] ?? '',
      slug: json['slug'] ?? '',
      category: json['category'] ?? '',
      level: json['level'] ?? 'Dasar',
      summary: json['summary'] ?? '',
      body: json['body'],
      coverColor: json['cover_color'],
      durationMinutes: json['duration_minutes'] is int
          ? json['duration_minutes']
          : int.tryParse('${json['duration_minutes']}') ?? 15,
      pointsReward: json['points_reward'] is int
          ? json['points_reward']
          : int.tryParse('${json['points_reward']}') ?? 25,
      isCompleted: json['is_completed'] == true || json['is_completed'] == 1,
      completionsCount: json['completions_count'] is int
          ? json['completions_count']
          : int.tryParse('${json['completions_count']}') ?? 0,
    );
  }

  CourseModel copyWith({
    bool? isCompleted,
    int? completionsCount,
  }) {
    return CourseModel(
      id: id,
      title: title,
      slug: slug,
      category: category,
      level: level,
      summary: summary,
      body: body,
      coverColor: coverColor,
      durationMinutes: durationMinutes,
      pointsReward: pointsReward,
      isCompleted: isCompleted ?? this.isCompleted,
      completionsCount: completionsCount ?? this.completionsCount,
    );
  }
}

class LevelInfo {
  final int level;
  final String name;
  final int min;
  final int? nextLevel;
  final String? nextName;
  final int? nextMin;
  final int pointsToNext;
  final int progress; // percentage 0-100

  LevelInfo({
    required this.level,
    required this.name,
    required this.min,
    this.nextLevel,
    this.nextName,
    this.nextMin,
    required this.pointsToNext,
    required this.progress,
  });

  factory LevelInfo.fromJson(Map<String, dynamic> json) {
    return LevelInfo(
      level: json['level'] is int ? json['level'] : int.tryParse('${json['level']}') ?? 1,
      name: json['name'] ?? 'Seedling',
      min: json['min'] is int ? json['min'] : int.tryParse('${json['min']}') ?? 0,
      nextLevel: json['next_level'] != null ? (json['next_level'] is int ? json['next_level'] : int.tryParse('${json['next_level']}')) : null,
      nextName: json['next_name'],
      nextMin: json['next_min'] != null ? (json['next_min'] is int ? json['next_min'] : int.tryParse('${json['next_min']}')) : null,
      pointsToNext: json['points_to_next'] is int ? json['points_to_next'] : int.tryParse('${json['points_to_next']}') ?? 0,
      progress: json['progress'] is int ? json['progress'] : int.tryParse('${json['progress']}') ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'level': level,
      'name': name,
      'min': min,
      'next_level': nextLevel,
      'next_name': nextName,
      'next_min': nextMin,
      'points_to_next': pointsToNext,
      'progress': progress,
    };
  }
}

class UserModel {
  final int id;
  final String nip;
  final String name;
  final String? email;
  final String role;
  final String? department;
  final String? position;
  final String? location;
  final String? avatar;
  final String? avatarUrl;
  final String? bio;
  final int points;
  final int currentStreak;
  final int longestStreak;
  final bool isActive;
  final bool mustChangePassword;
  final LevelInfo? levelInfo;
  final int unreadNotifications;
  final int pointsToday;
  final bool defaultPassword;
  final bool isReviewer;

  UserModel({
    required this.id,
    required this.nip,
    required this.name,
    this.email,
    required this.role,
    this.department,
    this.position,
    this.location,
    this.avatar,
    this.avatarUrl,
    this.bio,
    this.points = 0,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.isActive = true,
    this.mustChangePassword = false,
    this.levelInfo,
    this.unreadNotifications = 0,
    this.pointsToday = 0,
    this.defaultPassword = false,
    this.isReviewer = false,
  });

  bool get isEmployee => role.toLowerCase() == 'employee';

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] is int ? json['id'] : int.tryParse('${json['id']}') ?? 0,
      nip: json['nip'] ?? '',
      name: json['name'] ?? '',
      email: json['email'],
      role: json['role'] ?? 'employee',
      department: json['department'],
      position: json['position'],
      location: json['location'],
      avatar: json['avatar'],
      avatarUrl: json['avatar_url'],
      bio: json['bio'],
      points: json['points'] is int ? json['points'] : int.tryParse('${json['points']}') ?? 0,
      currentStreak: json['current_streak'] is int ? json['current_streak'] : int.tryParse('${json['current_streak']}') ?? 0,
      longestStreak: json['longest_streak'] is int ? json['longest_streak'] : int.tryParse('${json['longest_streak']}') ?? 0,
      isActive: json['is_active'] == true || json['is_active'] == 1,
      mustChangePassword: json['must_change_password'] == true || json['must_change_password'] == 1,
      levelInfo: json['level_info'] is Map<String, dynamic> ? LevelInfo.fromJson(json['level_info']) : null,
      unreadNotifications: json['unread_notifications'] is int ? json['unread_notifications'] : int.tryParse('${json['unread_notifications']}') ?? 0,
      pointsToday: json['points_today'] is int ? json['points_today'] : int.tryParse('${json['points_today']}') ?? 0,
      defaultPassword: json['default_password'] == true || json['default_password'] == 1,
      isReviewer: json['is_reviewer'] == true || json['is_reviewer'] == 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nip': nip,
      'name': name,
      'email': email,
      'role': role,
      'department': department,
      'position': position,
      'location': location,
      'avatar': avatar,
      'avatar_url': avatarUrl,
      'bio': bio,
      'points': points,
      'current_streak': currentStreak,
      'longest_streak': longestStreak,
      'is_active': isActive,
      'must_change_password': mustChangePassword,
      'level_info': levelInfo?.toJson(),
      'unread_notifications': unreadNotifications,
      'points_today': pointsToday,
      'default_password': defaultPassword,
      'is_reviewer': isReviewer,
    };
  }

  UserModel copyWith({
    String? name,
    String? email,
    String? department,
    String? position,
    String? location,
    String? bio,
    String? avatar,
    String? avatarUrl,
    int? points,
    int? currentStreak,
    LevelInfo? levelInfo,
    int? unreadNotifications,
    bool? mustChangePassword,
  }) {
    return UserModel(
      id: id,
      nip: nip,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role,
      department: department ?? this.department,
      position: position ?? this.position,
      location: location ?? this.location,
      avatar: avatar ?? this.avatar,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bio: bio ?? this.bio,
      points: points ?? this.points,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak,
      isActive: isActive,
      mustChangePassword: mustChangePassword ?? this.mustChangePassword,
      levelInfo: levelInfo ?? this.levelInfo,
      unreadNotifications: unreadNotifications ?? this.unreadNotifications,
      pointsToday: pointsToday,
      defaultPassword: defaultPassword,
      isReviewer: isReviewer,
    );
  }
}

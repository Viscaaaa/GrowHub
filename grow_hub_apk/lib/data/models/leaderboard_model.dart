class LeaderboardItemModel {
  final int id;
  final int? rank;
  final String name;
  final String nip;
  final String? avatar;
  final String? department;
  final String? position;
  final int points;
  final int currentStreak;
  final int score;

  LeaderboardItemModel({
    required this.id,
    this.rank,
    required this.name,
    required this.nip,
    this.avatar,
    this.department,
    this.position,
    this.points = 0,
    this.currentStreak = 0,
    this.score = 0,
  });

  factory LeaderboardItemModel.fromJson(Map<String, dynamic> json) {
    return LeaderboardItemModel(
      id: json['id'] is int ? json['id'] : int.tryParse('${json['id']}') ?? 0,
      rank: json['rank'] != null
          ? (json['rank'] is int
              ? json['rank']
              : int.tryParse('${json['rank']}'))
          : null,
      name: json['name'] ?? '',
      nip: json['nip'] ?? '',
      avatar: json['avatar'],
      department: json['department'],
      position: json['position'],
      points: json['points'] is int
          ? json['points']
          : int.tryParse('${json['points']}') ?? 0,
      currentStreak: json['current_streak'] is int
          ? json['current_streak']
          : int.tryParse('${json['current_streak']}') ?? 0,
      score: json['score'] is int
          ? json['score']
          : int.tryParse('${json['score']}') ?? 0,
    );
  }
}

class LeaderboardResponseModel {
  final String period;
  final List<LeaderboardItemModel> leaders;
  final LeaderboardItemModel? me;
  final List<String> departments;

  LeaderboardResponseModel({
    required this.period,
    required this.leaders,
    this.me,
    required this.departments,
  });

  factory LeaderboardResponseModel.fromJson(Map<String, dynamic> json) {
    List<LeaderboardItemModel> leaderList = [];
    if (json['leaders'] is List) {
      leaderList = (json['leaders'] as List)
          .map((item) =>
              LeaderboardItemModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    List<String> deptList = [];
    if (json['departments'] is List) {
      deptList = (json['departments'] as List)
          .map((dept) => dept.toString())
          .toList();
    }

    LeaderboardItemModel? myLeader;
    if (json['me'] is Map<String, dynamic>) {
      myLeader = LeaderboardItemModel.fromJson(json['me']);
    }

    return LeaderboardResponseModel(
      period: json['period'] ?? 'all',
      leaders: leaderList,
      me: myLeader,
      departments: deptList,
    );
  }
}

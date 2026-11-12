import 'package:equatable/equatable.dart';
import '../../data/models/leaderboard_model.dart';

abstract class LeaderboardState extends Equatable {
  const LeaderboardState();

  @override
  List<Object?> get props => [];
}

class LeaderboardInitial extends LeaderboardState {}

class LeaderboardLoading extends LeaderboardState {}

class LeaderboardLoaded extends LeaderboardState {
  final LeaderboardResponseModel data;
  final String period;
  final String? department;

  const LeaderboardLoaded({
    required this.data,
    required this.period,
    this.department,
  });

  LeaderboardLoaded copyWith({
    LeaderboardResponseModel? data,
    String? period,
    String? department,
    bool clearDepartment = false,
  }) {
    return LeaderboardLoaded(
      data: data ?? this.data,
      period: period ?? this.period,
      department: clearDepartment ? null : (department ?? this.department),
    );
  }

  @override
  List<Object?> get props => [data, period, department];
}

class LeaderboardError extends LeaderboardState {
  final String message;

  const LeaderboardError(this.message);

  @override
  List<Object?> get props => [message];
}

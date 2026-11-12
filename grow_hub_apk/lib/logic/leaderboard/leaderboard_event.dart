import 'package:equatable/equatable.dart';

abstract class LeaderboardEvent extends Equatable {
  const LeaderboardEvent();

  @override
  List<Object?> get props => [];
}

class LeaderboardFetchRequested extends LeaderboardEvent {
  final bool refresh;

  const LeaderboardFetchRequested({this.refresh = false});

  @override
  List<Object?> get props => [refresh];
}

class LeaderboardPeriodChanged extends LeaderboardEvent {
  final String period;

  const LeaderboardPeriodChanged(this.period);

  @override
  List<Object?> get props => [period];
}

class LeaderboardDepartmentChanged extends LeaderboardEvent {
  final String? department;

  const LeaderboardDepartmentChanged(this.department);

  @override
  List<Object?> get props => [department];
}

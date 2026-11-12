import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/network/api_exceptions.dart';
import '../../data/repositories/leaderboard_repository.dart';
import 'leaderboard_event.dart';
import 'leaderboard_state.dart';

class LeaderboardBloc extends Bloc<LeaderboardEvent, LeaderboardState> {
  final LeaderboardRepository leaderboardRepository;

  LeaderboardBloc({required this.leaderboardRepository})
      : super(LeaderboardInitial()) {
    on<LeaderboardFetchRequested>(_onFetchRequested);
    on<LeaderboardPeriodChanged>(_onPeriodChanged);
    on<LeaderboardDepartmentChanged>(_onDepartmentChanged);
  }

  Future<void> _onFetchRequested(
    LeaderboardFetchRequested event,
    Emitter<LeaderboardState> emit,
  ) async {
    String period = 'all';
    String? department;

    if (state is LeaderboardLoaded) {
      final current = state as LeaderboardLoaded;
      period = current.period;
      department = current.department;
    }

    if (!event.refresh && state is! LeaderboardLoaded) {
      emit(LeaderboardLoading());
    }

    try {
      final data = await leaderboardRepository.getLeaderboard(
        period: period,
        department: department,
      );

      emit(LeaderboardLoaded(
        data: data,
        period: period,
        department: department,
      ));
    } catch (e) {
      emit(LeaderboardError(
        e is ApiException ? e.message : 'Gagal memuat papan peringkat.',
      ));
    }
  }

  Future<void> _onPeriodChanged(
    LeaderboardPeriodChanged event,
    Emitter<LeaderboardState> emit,
  ) async {
    if (state is LeaderboardLoaded) {
      final current = state as LeaderboardLoaded;
      emit(current.copyWith(period: event.period));
      add(const LeaderboardFetchRequested());
    }
  }

  Future<void> _onDepartmentChanged(
    LeaderboardDepartmentChanged event,
    Emitter<LeaderboardState> emit,
  ) async {
    if (state is LeaderboardLoaded) {
      final current = state as LeaderboardLoaded;
      emit(current.copyWith(
        department: event.department,
        clearDepartment:
            event.department == null || event.department == 'Semua',
      ));
      add(const LeaderboardFetchRequested());
    }
  }
}

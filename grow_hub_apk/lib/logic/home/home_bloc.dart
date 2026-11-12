import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/network/api_exceptions.dart';
import '../../data/repositories/home_repository.dart';
import 'home_event.dart';
import 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final HomeRepository homeRepository;

  HomeBloc({required this.homeRepository}) : super(HomeInitial()) {
    on<HomeFetchRequested>(_onFetchRequested);
    on<HomeRefreshRequested>(_onRefreshRequested);
  }

  Future<void> _onFetchRequested(
    HomeFetchRequested event,
    Emitter<HomeState> emit,
  ) async {
    emit(HomeLoading());
    try {
      final homeData = await homeRepository.getHomeData();
      final myDashboard = await homeRepository.getMyDashboard().catchError((_) => null);
      emit(HomeLoaded(homeData: homeData, myDashboard: myDashboard));
    } catch (e) {
      emit(HomeError(
        e is ApiException ? e.message : 'Gagal memuat data beranda.',
      ));
    }
  }

  Future<void> _onRefreshRequested(
    HomeRefreshRequested event,
    Emitter<HomeState> emit,
  ) async {
    try {
      final homeData = await homeRepository.getHomeData();
      final myDashboard = await homeRepository.getMyDashboard().catchError((_) => null);
      emit(HomeLoaded(homeData: homeData, myDashboard: myDashboard));
    } catch (e) {
      // Keep existing state if refresh fails
      if (state is! HomeLoaded) {
        emit(HomeError(
          e is ApiException ? e.message : 'Gagal memperbarui beranda.',
        ));
      }
    }
  }
}

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/network/api_exceptions.dart';
import '../../data/repositories/community_repository.dart';
import 'community_event.dart';
import 'community_state.dart';

class CommunityBloc extends Bloc<CommunityEvent, CommunityState> {
  final CommunityRepository communityRepository;

  CommunityBloc({required this.communityRepository})
      : super(CommunityInitial()) {
    on<CommunityFetchRequested>(_onFetchRequested);
    on<CommunityToggleJoinRequested>(_onToggleJoinRequested);
  }

  Future<void> _onFetchRequested(
    CommunityFetchRequested event,
    Emitter<CommunityState> emit,
  ) async {
    bool joined = false;
    String q = '';
    if (state is CommunityLoaded) {
      final current = state as CommunityLoaded;
      joined = current.joinedOnly;
      q = current.searchQuery;
    }

    if (event.joinedOnly != null) joined = event.joinedOnly!;
    if (event.query != null) q = event.query!;

    if (!event.refresh && state is! CommunityLoaded) {
      emit(CommunityLoading());
    }

    try {
      final communities = await communityRepository.getCommunities(
        q: q.isEmpty ? null : q,
        joinedOnly: joined,
      );

      emit(CommunityLoaded(
        communities: communities,
        joinedOnly: joined,
        searchQuery: q,
      ));
    } catch (e) {
      emit(CommunityError(
        e is ApiException ? e.message : 'Gagal memuat daftar komunitas.',
      ));
    }
  }

  Future<void> _onToggleJoinRequested(
    CommunityToggleJoinRequested event,
    Emitter<CommunityState> emit,
  ) async {
    if (state is! CommunityLoaded) return;
    final current = state as CommunityLoaded;

    final updated = current.communities.map((c) {
      if (c.id == event.communityId) {
        final newIsMember = !c.isMember;
        final newCount = c.membersCount + (newIsMember ? 1 : -1);
        return c.copyWith(
          isMember: newIsMember,
          membersCount: newCount < 0 ? 0 : newCount,
        );
      }
      return c;
    }).toList();

    emit(current.copyWith(communities: updated));

    try {
      await communityRepository.toggleJoin(event.communityId);
    } catch (_) {
      emit(current);
    }
  }
}

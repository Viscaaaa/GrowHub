import 'package:equatable/equatable.dart';

abstract class CommunityEvent extends Equatable {
  const CommunityEvent();

  @override
  List<Object?> get props => [];
}

class CommunityFetchRequested extends CommunityEvent {
  final bool refresh;
  final String? query;
  final bool? joinedOnly;

  const CommunityFetchRequested({
    this.refresh = false,
    this.query,
    this.joinedOnly,
  });

  @override
  List<Object?> get props => [refresh, query, joinedOnly];
}

class CommunityToggleJoinRequested extends CommunityEvent {
  final int communityId;

  const CommunityToggleJoinRequested(this.communityId);

  @override
  List<Object?> get props => [communityId];
}

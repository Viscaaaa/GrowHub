import 'package:equatable/equatable.dart';
import '../../data/models/community_model.dart';

abstract class CommunityState extends Equatable {
  const CommunityState();

  @override
  List<Object?> get props => [];
}

class CommunityInitial extends CommunityState {}

class CommunityLoading extends CommunityState {}

class CommunityLoaded extends CommunityState {
  final List<CommunityModel> communities;
  final bool joinedOnly;
  final String searchQuery;

  const CommunityLoaded({
    required this.communities,
    this.joinedOnly = false,
    this.searchQuery = '',
  });

  CommunityLoaded copyWith({
    List<CommunityModel>? communities,
    bool? joinedOnly,
    String? searchQuery,
  }) {
    return CommunityLoaded(
      communities: communities ?? this.communities,
      joinedOnly: joinedOnly ?? this.joinedOnly,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  @override
  List<Object?> get props => [communities, joinedOnly, searchQuery];
}

class CommunityError extends CommunityState {
  final String message;

  const CommunityError(this.message);

  @override
  List<Object?> get props => [message];
}

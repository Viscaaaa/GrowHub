import 'package:equatable/equatable.dart';
import '../../data/models/content_model.dart';

abstract class MyContentState extends Equatable {
  const MyContentState();

  @override
  List<Object?> get props => [];
}

class MyContentInitial extends MyContentState {}

class MyContentLoading extends MyContentState {}

class MyContentLoaded extends MyContentState {
  final List<ContentModel> contents;
  final Map<String, int> counts;
  final String currentStatus;
  final Map<String, dynamic>? engagement;

  const MyContentLoaded({
    required this.contents,
    required this.counts,
    this.currentStatus = 'all',
    this.engagement,
  });

  MyContentLoaded copyWith({
    List<ContentModel>? contents,
    Map<String, int>? counts,
    String? currentStatus,
    Map<String, dynamic>? engagement,
  }) {
    return MyContentLoaded(
      contents: contents ?? this.contents,
      counts: counts ?? this.counts,
      currentStatus: currentStatus ?? this.currentStatus,
      engagement: engagement ?? this.engagement,
    );
  }

  @override
  List<Object?> get props => [contents, counts, currentStatus, engagement];
}

class MyContentError extends MyContentState {
  final String message;

  const MyContentError(this.message);

  @override
  List<Object?> get props => [message];
}

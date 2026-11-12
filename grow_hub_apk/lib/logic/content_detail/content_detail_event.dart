import 'package:equatable/equatable.dart';

abstract class ContentDetailEvent extends Equatable {
  const ContentDetailEvent();

  @override
  List<Object?> get props => [];
}

class ContentDetailFetchRequested extends ContentDetailEvent {
  final int contentId;

  const ContentDetailFetchRequested(this.contentId);

  @override
  List<Object?> get props => [contentId];
}

class ContentDetailLikeToggled extends ContentDetailEvent {}

class ContentDetailSaveToggled extends ContentDetailEvent {}

class ContentDetailCommentSubmitted extends ContentDetailEvent {
  final String body;

  const ContentDetailCommentSubmitted(this.body);

  @override
  List<Object?> get props => [body];
}

class ContentDetailCommentDeleteRequested extends ContentDetailEvent {
  final int commentId;

  const ContentDetailCommentDeleteRequested(this.commentId);

  @override
  List<Object?> get props => [commentId];
}

import 'package:equatable/equatable.dart';
import '../../data/models/comment_model.dart';
import '../../data/models/content_model.dart';

abstract class ContentDetailState extends Equatable {
  const ContentDetailState();

  @override
  List<Object?> get props => [];
}

class ContentDetailInitial extends ContentDetailState {}

class ContentDetailLoading extends ContentDetailState {}

class ContentDetailLoaded extends ContentDetailState {
  final ContentModel content;
  final List<ContentModel> related;
  final List<CommentModel> comments;
  final bool isPostingComment;

  const ContentDetailLoaded({
    required this.content,
    required this.related,
    required this.comments,
    this.isPostingComment = false,
  });

  ContentDetailLoaded copyWith({
    ContentModel? content,
    List<ContentModel>? related,
    List<CommentModel>? comments,
    bool? isPostingComment,
  }) {
    return ContentDetailLoaded(
      content: content ?? this.content,
      related: related ?? this.related,
      comments: comments ?? this.comments,
      isPostingComment: isPostingComment ?? this.isPostingComment,
    );
  }

  @override
  List<Object?> get props => [content, related, comments, isPostingComment];
}

class ContentDetailError extends ContentDetailState {
  final String message;

  const ContentDetailError(this.message);

  @override
  List<Object?> get props => [message];
}

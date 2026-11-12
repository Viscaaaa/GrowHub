import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/network/api_exceptions.dart';
import '../../data/repositories/content_repository.dart';
import 'content_detail_event.dart';
import 'content_detail_state.dart';

class ContentDetailBloc extends Bloc<ContentDetailEvent, ContentDetailState> {
  final ContentRepository contentRepository;

  ContentDetailBloc({required this.contentRepository})
      : super(ContentDetailInitial()) {
    on<ContentDetailFetchRequested>(_onFetchRequested);
    on<ContentDetailLikeToggled>(_onLikeToggled);
    on<ContentDetailSaveToggled>(_onSaveToggled);
    on<ContentDetailCommentSubmitted>(_onCommentSubmitted);
    on<ContentDetailCommentDeleteRequested>(_onCommentDeleteRequested);
  }

  Future<void> _onFetchRequested(
    ContentDetailFetchRequested event,
    Emitter<ContentDetailState> emit,
  ) async {
    emit(ContentDetailLoading());
    try {
      final res = await contentRepository.getContentDetail(event.contentId);
      final comments = await contentRepository.getComments(event.contentId);
      emit(ContentDetailLoaded(
        content: res.content,
        related: res.related,
        comments: comments,
      ));
    } catch (e) {
      emit(ContentDetailError(
        e is ApiException ? e.message : 'Gagal memuat detail konten.',
      ));
    }
  }

  Future<void> _onLikeToggled(
    ContentDetailLikeToggled event,
    Emitter<ContentDetailState> emit,
  ) async {
    if (state is! ContentDetailLoaded) return;
    final current = state as ContentDetailLoaded;
    final newIsLiked = !current.content.isLiked;
    final newLikesCount =
        current.content.likesCount + (newIsLiked ? 1 : -1);

    final updated = current.content.copyWith(
      isLiked: newIsLiked,
      likesCount: newLikesCount < 0 ? 0 : newLikesCount,
    );

    emit(current.copyWith(content: updated));

    try {
      await contentRepository.toggleLike(current.content.id);
    } catch (_) {
      emit(current);
    }
  }

  Future<void> _onSaveToggled(
    ContentDetailSaveToggled event,
    Emitter<ContentDetailState> emit,
  ) async {
    if (state is! ContentDetailLoaded) return;
    final current = state as ContentDetailLoaded;
    final newIsSaved = !current.content.isSaved;
    final newSavesCount =
        current.content.savesCount + (newIsSaved ? 1 : -1);

    final updated = current.content.copyWith(
      isSaved: newIsSaved,
      savesCount: newSavesCount < 0 ? 0 : newSavesCount,
    );

    emit(current.copyWith(content: updated));

    try {
      await contentRepository.toggleSave(current.content.id);
    } catch (_) {
      emit(current);
    }
  }

  Future<void> _onCommentSubmitted(
    ContentDetailCommentSubmitted event,
    Emitter<ContentDetailState> emit,
  ) async {
    if (state is! ContentDetailLoaded) return;
    final current = state as ContentDetailLoaded;

    emit(current.copyWith(isPostingComment: true));
    try {
      final newComment = await contentRepository.postComment(
        current.content.id,
        event.body,
      );

      final updatedComments = [newComment, ...current.comments];
      final updatedContent = current.content.copyWith(
        commentsCount: current.content.commentsCount + 1,
      );

      emit(current.copyWith(
        content: updatedContent,
        comments: updatedComments,
        isPostingComment: false,
      ));
    } catch (e) {
      emit(current.copyWith(isPostingComment: false));
    }
  }

  Future<void> _onCommentDeleteRequested(
    ContentDetailCommentDeleteRequested event,
    Emitter<ContentDetailState> emit,
  ) async {
    if (state is! ContentDetailLoaded) return;
    final current = state as ContentDetailLoaded;

    final updatedComments =
        current.comments.where((c) => c.id != event.commentId).toList();
    final updatedContent = current.content.copyWith(
      commentsCount: current.content.commentsCount > 0
          ? current.content.commentsCount - 1
          : 0,
    );

    emit(current.copyWith(
      content: updatedContent,
      comments: updatedComments,
    ));

    try {
      await contentRepository.deleteComment(event.commentId);
    } catch (_) {
      emit(current);
    }
  }
}

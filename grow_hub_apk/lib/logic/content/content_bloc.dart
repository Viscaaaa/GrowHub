import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/network/api_exceptions.dart';
import '../../data/models/category_model.dart';
import '../../data/models/content_model.dart';
import '../../data/repositories/content_repository.dart';
import 'content_event.dart';
import 'content_state.dart';

class ContentBloc extends Bloc<ContentEvent, ContentState> {
  final ContentRepository contentRepository;

  ContentBloc({required this.contentRepository}) : super(ContentInitial()) {
    on<ContentFetchRequested>(_onFetchRequested);
    on<ContentFilterCategoryChanged>(_onFilterCategoryChanged);
    on<ContentSearchChanged>(_onSearchChanged);
    on<ContentSortChanged>(_onSortChanged);
    on<ContentLikeToggled>(_onLikeToggled);
    on<ContentSaveToggled>(_onSaveToggled);
  }

  Future<void> _onFetchRequested(
    ContentFetchRequested event,
    Emitter<ContentState> emit,
  ) async {
    String? category;
    String search = '';
    String sort = 'latest';
    List<CategoryModel> categories = [];

    if (state is ContentLoaded) {
      final current = state as ContentLoaded;
      category = current.selectedCategory;
      search = current.searchQuery;
      sort = current.sort;
      categories = current.categories;
    }

    if (!event.refresh && state is! ContentLoaded) {
      emit(ContentLoading());
    }

    try {
      if (categories.isEmpty) {
        categories = await contentRepository.getCategories();
      }

      final contents = await contentRepository.getContents(
        category: category,
        q: search.isEmpty ? null : search,
        sort: sort,
      );

      emit(ContentLoaded(
        contents: contents,
        categories: categories,
        selectedCategory: category,
        searchQuery: search,
        sort: sort,
      ));
    } catch (e) {
      emit(ContentError(
        e is ApiException ? e.message : 'Gagal memuat feed pengetahuan.',
      ));
    }
  }

  Future<void> _onFilterCategoryChanged(
    ContentFilterCategoryChanged event,
    Emitter<ContentState> emit,
  ) async {
    if (state is ContentLoaded) {
      final current = state as ContentLoaded;
      emit(current.copyWith(
        selectedCategory: event.categorySlug,
        clearCategory: event.categorySlug == null,
      ));
      add(const ContentFetchRequested());
    }
  }

  Future<void> _onSearchChanged(
    ContentSearchChanged event,
    Emitter<ContentState> emit,
  ) async {
    if (state is ContentLoaded) {
      final current = state as ContentLoaded;
      emit(current.copyWith(searchQuery: event.query));
      add(const ContentFetchRequested());
    }
  }

  Future<void> _onSortChanged(
    ContentSortChanged event,
    Emitter<ContentState> emit,
  ) async {
    if (state is ContentLoaded) {
      final current = state as ContentLoaded;
      emit(current.copyWith(sort: event.sort));
      add(const ContentFetchRequested());
    }
  }

  Future<void> _onLikeToggled(
    ContentLikeToggled event,
    Emitter<ContentState> emit,
  ) async {
    if (state is! ContentLoaded) return;
    final current = state as ContentLoaded;

    // Optimistic update
    final updatedList = current.contents.map((item) {
      if (item.id == event.contentId) {
        final newIsLiked = !item.isLiked;
        final newCount = item.likesCount + (newIsLiked ? 1 : -1);
        return item.copyWith(
          isLiked: newIsLiked,
          likesCount: newCount < 0 ? 0 : newCount,
        );
      }
      return item;
    }).toList();

    emit(current.copyWith(contents: updatedList));

    try {
      await contentRepository.toggleLike(event.contentId);
    } catch (_) {
      // Revert if network error
      emit(current);
    }
  }

  Future<void> _onSaveToggled(
    ContentSaveToggled event,
    Emitter<ContentState> emit,
  ) async {
    if (state is! ContentLoaded) return;
    final current = state as ContentLoaded;

    // Optimistic update
    final updatedList = current.contents.map((item) {
      if (item.id == event.contentId) {
        final newIsSaved = !item.isSaved;
        final newCount = item.savesCount + (newIsSaved ? 1 : -1);
        return item.copyWith(
          isSaved: newIsSaved,
          savesCount: newCount < 0 ? 0 : newCount,
        );
      }
      return item;
    }).toList();

    emit(current.copyWith(contents: updatedList));

    try {
      await contentRepository.toggleSave(event.contentId);
    } catch (_) {
      // Revert if network error
      emit(current);
    }
  }
}

import 'package:equatable/equatable.dart';
import '../../data/models/category_model.dart';
import '../../data/models/content_model.dart';

abstract class ContentState extends Equatable {
  const ContentState();

  @override
  List<Object?> get props => [];
}

class ContentInitial extends ContentState {}

class ContentLoading extends ContentState {}

class ContentLoaded extends ContentState {
  final List<ContentModel> contents;
  final List<CategoryModel> categories;
  final String? selectedCategory;
  final String searchQuery;
  final String sort;

  const ContentLoaded({
    required this.contents,
    required this.categories,
    this.selectedCategory,
    this.searchQuery = '',
    this.sort = 'latest',
  });

  ContentLoaded copyWith({
    List<ContentModel>? contents,
    List<CategoryModel>? categories,
    String? selectedCategory,
    bool clearCategory = false,
    String? searchQuery,
    String? sort,
  }) {
    return ContentLoaded(
      contents: contents ?? this.contents,
      categories: categories ?? this.categories,
      selectedCategory:
          clearCategory ? null : (selectedCategory ?? this.selectedCategory),
      searchQuery: searchQuery ?? this.searchQuery,
      sort: sort ?? this.sort,
    );
  }

  @override
  List<Object?> get props =>
      [contents, categories, selectedCategory, searchQuery, sort];
}

class ContentError extends ContentState {
  final String message;

  const ContentError(this.message);

  @override
  List<Object?> get props => [message];
}

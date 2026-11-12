import 'package:equatable/equatable.dart';

abstract class ContentEvent extends Equatable {
  const ContentEvent();

  @override
  List<Object?> get props => [];
}

class ContentFetchRequested extends ContentEvent {
  final bool refresh;

  const ContentFetchRequested({this.refresh = false});

  @override
  List<Object?> get props => [refresh];
}

class ContentFilterCategoryChanged extends ContentEvent {
  final String? categorySlug;

  const ContentFilterCategoryChanged(this.categorySlug);

  @override
  List<Object?> get props => [categorySlug];
}

class ContentSearchChanged extends ContentEvent {
  final String query;

  const ContentSearchChanged(this.query);

  @override
  List<Object?> get props => [query];
}

class ContentSortChanged extends ContentEvent {
  final String sort;

  const ContentSortChanged(this.sort);

  @override
  List<Object?> get props => [sort];
}

class ContentLikeToggled extends ContentEvent {
  final int contentId;

  const ContentLikeToggled(this.contentId);

  @override
  List<Object?> get props => [contentId];
}

class ContentSaveToggled extends ContentEvent {
  final int contentId;

  const ContentSaveToggled(this.contentId);

  @override
  List<Object?> get props => [contentId];
}

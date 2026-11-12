import 'package:equatable/equatable.dart';

abstract class CourseEvent extends Equatable {
  const CourseEvent();

  @override
  List<Object?> get props => [];
}

class CourseFetchRequested extends CourseEvent {
  final bool refresh;

  const CourseFetchRequested({this.refresh = false});

  @override
  List<Object?> get props => [refresh];
}

class CourseCategoryChanged extends CourseEvent {
  final String? category;

  const CourseCategoryChanged(this.category);

  @override
  List<Object?> get props => [category];
}

class CourseSearchChanged extends CourseEvent {
  final String query;

  const CourseSearchChanged(this.query);

  @override
  List<Object?> get props => [query];
}

class CourseCompleteRequested extends CourseEvent {
  final int courseId;

  const CourseCompleteRequested(this.courseId);

  @override
  List<Object?> get props => [courseId];
}

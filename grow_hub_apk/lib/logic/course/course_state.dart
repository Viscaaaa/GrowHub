import 'package:equatable/equatable.dart';
import '../../data/models/course_model.dart';

abstract class CourseState extends Equatable {
  const CourseState();

  @override
  List<Object?> get props => [];
}

class CourseInitial extends CourseState {}

class CourseLoading extends CourseState {}

class CourseLoaded extends CourseState {
  final List<CourseModel> courses;
  final List<String> categories;
  final String? selectedCategory;
  final String searchQuery;
  final int completed;
  final int total;
  final int? newlyEarnedPoints;

  const CourseLoaded({
    required this.courses,
    required this.categories,
    this.selectedCategory,
    this.searchQuery = '',
    this.completed = 0,
    this.total = 0,
    this.newlyEarnedPoints,
  });

  CourseLoaded copyWith({
    List<CourseModel>? courses,
    List<String>? categories,
    String? selectedCategory,
    bool clearCategory = false,
    String? searchQuery,
    int? completed,
    int? total,
    int? newlyEarnedPoints,
    bool clearNewlyEarned = false,
  }) {
    return CourseLoaded(
      courses: courses ?? this.courses,
      categories: categories ?? this.categories,
      selectedCategory:
          clearCategory ? null : (selectedCategory ?? this.selectedCategory),
      searchQuery: searchQuery ?? this.searchQuery,
      completed: completed ?? this.completed,
      total: total ?? this.total,
      newlyEarnedPoints: clearNewlyEarned
          ? null
          : (newlyEarnedPoints ?? this.newlyEarnedPoints),
    );
  }

  @override
  List<Object?> get props => [
        courses,
        categories,
        selectedCategory,
        searchQuery,
        completed,
        total,
        newlyEarnedPoints,
      ];
}

class CourseError extends CourseState {
  final String message;

  const CourseError(this.message);

  @override
  List<Object?> get props => [message];
}

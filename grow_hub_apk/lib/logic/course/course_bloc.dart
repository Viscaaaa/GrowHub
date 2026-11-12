import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/network/api_exceptions.dart';
import '../../data/repositories/course_repository.dart';
import 'course_event.dart';
import 'course_state.dart';

class CourseBloc extends Bloc<CourseEvent, CourseState> {
  final CourseRepository courseRepository;

  CourseBloc({required this.courseRepository}) : super(CourseInitial()) {
    on<CourseFetchRequested>(_onFetchRequested);
    on<CourseCategoryChanged>(_onCategoryChanged);
    on<CourseSearchChanged>(_onSearchChanged);
    on<CourseCompleteRequested>(_onCompleteRequested);
  }

  Future<void> _onFetchRequested(
    CourseFetchRequested event,
    Emitter<CourseState> emit,
  ) async {
    String? category;
    String q = '';
    if (state is CourseLoaded) {
      final current = state as CourseLoaded;
      category = current.selectedCategory;
      q = current.searchQuery;
    }

    if (!event.refresh && state is! CourseLoaded) {
      emit(CourseLoading());
    }

    try {
      final res = await courseRepository.getCourses(
        category: category,
        q: q.isEmpty ? null : q,
      );

      emit(CourseLoaded(
        courses: res.courses,
        categories: ['Semua', ...res.categories],
        selectedCategory: category,
        searchQuery: q,
        completed: res.completed,
        total: res.total,
      ));
    } catch (e) {
      emit(CourseError(
        e is ApiException ? e.message : 'Gagal memuat Learning Center.',
      ));
    }
  }

  Future<void> _onCategoryChanged(
    CourseCategoryChanged event,
    Emitter<CourseState> emit,
  ) async {
    if (state is CourseLoaded) {
      final current = state as CourseLoaded;
      emit(current.copyWith(
        selectedCategory: event.category,
        clearCategory: event.category == null || event.category == 'Semua',
      ));
      add(const CourseFetchRequested());
    }
  }

  Future<void> _onSearchChanged(
    CourseSearchChanged event,
    Emitter<CourseState> emit,
  ) async {
    if (state is CourseLoaded) {
      final current = state as CourseLoaded;
      emit(current.copyWith(searchQuery: event.query));
      add(const CourseFetchRequested());
    }
  }

  Future<void> _onCompleteRequested(
    CourseCompleteRequested event,
    Emitter<CourseState> emit,
  ) async {
    if (state is! CourseLoaded) return;
    final current = state as CourseLoaded;

    try {
      final res = await courseRepository.completeCourse(event.courseId);

      final updatedCourses = current.courses.map((c) {
        if (c.id == event.courseId) {
          return c.copyWith(
            isCompleted: true,
            completionsCount: c.completionsCount + 1,
          );
        }
        return c;
      }).toList();

      emit(current.copyWith(
        courses: updatedCourses,
        completed: current.completed + 1,
        newlyEarnedPoints: res.pointsEarned,
      ));
    } catch (e) {
      emit(CourseError(
        e is ApiException ? e.message : 'Gagal menyelesaikan materi.',
      ));
    }
  }
}

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/network/api_exceptions.dart';
import '../../data/repositories/content_repository.dart';
import 'my_content_event.dart';
import 'my_content_state.dart';

class MyContentBloc extends Bloc<MyContentEvent, MyContentState> {
  final ContentRepository contentRepository;

  MyContentBloc({required this.contentRepository})
      : super(MyContentInitial()) {
    on<MyContentFetchRequested>(_onFetchRequested);
    on<MyContentStatusChanged>(_onStatusChanged);
    on<MyContentDeleteRequested>(_onDeleteRequested);
  }

  Future<void> _onFetchRequested(
    MyContentFetchRequested event,
    Emitter<MyContentState> emit,
  ) async {
    String status = 'all';
    if (state is MyContentLoaded) {
      status = (state as MyContentLoaded).currentStatus;
    }

    if (!event.refresh && state is! MyContentLoaded) {
      emit(MyContentLoading());
    }

    try {
      final res = await contentRepository.getMyContents(
        status: status == 'all' ? null : status,
      );
      emit(MyContentLoaded(
        contents: res.contents,
        counts: res.counts,
        currentStatus: status,
        engagement: res.engagement,
      ));
    } catch (e) {
      emit(MyContentError(
        e is ApiException ? e.message : 'Gagal memuat kontribusi Anda.',
      ));
    }
  }

  Future<void> _onStatusChanged(
    MyContentStatusChanged event,
    Emitter<MyContentState> emit,
  ) async {
    if (state is MyContentLoaded) {
      final current = state as MyContentLoaded;
      emit(current.copyWith(currentStatus: event.status));
      add(const MyContentFetchRequested());
    }
  }

  Future<void> _onDeleteRequested(
    MyContentDeleteRequested event,
    Emitter<MyContentState> emit,
  ) async {
    if (state is! MyContentLoaded) return;
    final current = state as MyContentLoaded;

    try {
      await contentRepository.deleteContent(event.contentId);
      final updatedList =
          current.contents.where((c) => c.id != event.contentId).toList();
      emit(current.copyWith(contents: updatedList));
      add(const MyContentFetchRequested(refresh: true));
    } catch (e) {
      emit(MyContentError(
        e is ApiException ? e.message : 'Gagal menghapus konten.',
      ));
    }
  }
}

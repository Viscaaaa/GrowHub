import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/network/api_exceptions.dart';
import '../../data/repositories/notification_repository.dart';
import 'notification_event.dart';
import 'notification_state.dart';

class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  final NotificationRepository notificationRepository;

  NotificationBloc({required this.notificationRepository})
      : super(NotificationInitial()) {
    on<NotificationFetchRequested>(_onFetchRequested);
    on<NotificationMarkReadRequested>(_onMarkReadRequested);
    on<NotificationMarkAllReadRequested>(_onMarkAllReadRequested);
  }

  Future<void> _onFetchRequested(
    NotificationFetchRequested event,
    Emitter<NotificationState> emit,
  ) async {
    String? filter;
    if (state is NotificationLoaded) {
      filter = (state as NotificationLoaded).filter;
    }
    if (event.filter != null) filter = event.filter;

    if (!event.refresh && state is! NotificationLoaded) {
      emit(NotificationLoading());
    }

    try {
      final res = await notificationRepository.getNotifications(
        filter: filter == 'all' ? null : filter,
      );

      emit(NotificationLoaded(
        notifications: res.notifications,
        unreadCount: res.unreadCount,
        filter: filter,
      ));
    } catch (e) {
      emit(NotificationError(
        e is ApiException ? e.message : 'Gagal memuat notifikasi.',
      ));
    }
  }

  Future<void> _onMarkReadRequested(
    NotificationMarkReadRequested event,
    Emitter<NotificationState> emit,
  ) async {
    if (state is! NotificationLoaded) return;
    final current = state as NotificationLoaded;

    final updated = current.notifications.map((n) {
      if (n.id == event.notificationId) {
        return n.copyWith(readAt: DateTime.now().toIso8601String());
      }
      return n;
    }).toList();

    final newCount = current.unreadCount > 0 ? current.unreadCount - 1 : 0;
    emit(current.copyWith(
      notifications: updated,
      unreadCount: newCount,
    ));

    try {
      await notificationRepository.markRead(event.notificationId);
    } catch (_) {}
  }

  Future<void> _onMarkAllReadRequested(
    NotificationMarkAllReadRequested event,
    Emitter<NotificationState> emit,
  ) async {
    if (state is! NotificationLoaded) return;
    final current = state as NotificationLoaded;

    final nowStr = DateTime.now().toIso8601String();
    final updated = current.notifications.map((n) {
      return n.copyWith(readAt: nowStr);
    }).toList();

    emit(current.copyWith(
      notifications: updated,
      unreadCount: 0,
    ));

    try {
      await notificationRepository.markAllRead();
    } catch (_) {}
  }
}

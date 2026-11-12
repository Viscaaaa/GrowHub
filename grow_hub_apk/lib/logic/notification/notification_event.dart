import 'package:equatable/equatable.dart';

abstract class NotificationEvent extends Equatable {
  const NotificationEvent();

  @override
  List<Object?> get props => [];
}

class NotificationFetchRequested extends NotificationEvent {
  final bool refresh;
  final String? filter;

  const NotificationFetchRequested({this.refresh = false, this.filter});

  @override
  List<Object?> get props => [refresh, filter];
}

class NotificationMarkReadRequested extends NotificationEvent {
  final int notificationId;

  const NotificationMarkReadRequested(this.notificationId);

  @override
  List<Object?> get props => [notificationId];
}

class NotificationMarkAllReadRequested extends NotificationEvent {}

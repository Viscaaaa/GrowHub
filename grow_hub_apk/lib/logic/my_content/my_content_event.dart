import 'package:equatable/equatable.dart';

abstract class MyContentEvent extends Equatable {
  const MyContentEvent();

  @override
  List<Object?> get props => [];
}

class MyContentFetchRequested extends MyContentEvent {
  final bool refresh;

  const MyContentFetchRequested({this.refresh = false});

  @override
  List<Object?> get props => [refresh];
}

class MyContentStatusChanged extends MyContentEvent {
  final String status;

  const MyContentStatusChanged(this.status);

  @override
  List<Object?> get props => [status];
}

class MyContentDeleteRequested extends MyContentEvent {
  final int contentId;

  const MyContentDeleteRequested(this.contentId);

  @override
  List<Object?> get props => [contentId];
}

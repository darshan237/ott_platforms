part of 'show_bloc.dart';

abstract class ShowEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadVideos extends ShowEvent {
  final List<String> urls;
  LoadVideos(this.urls);
}

class LoadMoreVideos extends ShowEvent {
  final Future<List<String>> Function() fetchMore;

  LoadMoreVideos(this.fetchMore);
}

class PageChanged extends ShowEvent {
  final int index;
  PageChanged(this.index);
}

class DisposeAll extends ShowEvent {}

class TogglePlayPause extends ShowEvent {
  final int index;
  TogglePlayPause(this.index);

  @override
  List<Object?> get props => [index];
}


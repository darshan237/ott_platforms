part of 'show_bloc.dart';

abstract class ShowEvent {}

class LoadVideos extends ShowEvent {
  final List<String> urls;
  LoadVideos(this.urls);
}

class PageChanged extends ShowEvent {
  final int index;
  PageChanged(this.index);
}

class TogglePlayPause extends ShowEvent {
  final int index;
  TogglePlayPause(this.index);
}

class DisposeAll extends ShowEvent {}

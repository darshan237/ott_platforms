import 'package:equatable/equatable.dart';

abstract class BottomNavEvent extends Equatable {
  const BottomNavEvent();

  @override
  List<Object?> get props => [];
}

/// Fired when user taps bottom item (or programmatic change)
class BottomNavItemTapped extends BottomNavEvent {
  final int index;
  const BottomNavItemTapped(this.index);

  @override
  List<Object?> get props => [index];
}

/// Fired to load persisted/initial index (on app start)
class BottomNavLoadInitial extends BottomNavEvent {}

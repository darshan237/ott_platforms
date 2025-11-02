import 'package:equatable/equatable.dart';

class BottomNavState extends Equatable {
  final int selectedIndex;
  final bool isLoading;

  const BottomNavState({required this.selectedIndex, this.isLoading = false});

  BottomNavState copyWith({int? selectedIndex, bool? isLoading}) {
    return BottomNavState(
      selectedIndex: selectedIndex ?? this.selectedIndex,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  @override
  List<Object?> get props => [selectedIndex, isLoading];
}

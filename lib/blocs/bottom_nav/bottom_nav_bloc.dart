import 'package:bloc/bloc.dart';
import '../../repositories/navigation_repository.dart';
import 'bottom_nav_event.dart';
import 'bottom_nav_state.dart';

class BottomNavBloc extends Bloc<BottomNavEvent, BottomNavState> {
  final NavigationRepository _navigationRepository;

  BottomNavBloc(this._navigationRepository) : super(const BottomNavState(selectedIndex: 0, isLoading: true)) {
    on<BottomNavLoadInitial>(_onLoadInitial);
    on<BottomNavItemTapped>(_onItemTapped);
  }

  Future<void> _onLoadInitial(BottomNavLoadInitial event, Emitter<BottomNavState> emit) async {
    emit(state.copyWith(isLoading: true));
    final index = await _navigationRepository.getLastIndex();
    emit(state.copyWith(selectedIndex: index, isLoading: false));
  }

  Future<void> _onItemTapped(BottomNavItemTapped event, Emitter<BottomNavState> emit) async {
    emit(state.copyWith(selectedIndex: event.index));
    // persist
    await _navigationRepository.saveIndex(event.index);
  }
}

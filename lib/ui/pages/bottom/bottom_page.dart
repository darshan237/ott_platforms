import 'package:dd_box/blocs/bottom_nav/bottom_nav_bloc.dart';
import 'package:dd_box/blocs/bottom_nav/bottom_nav_event.dart';
import 'package:dd_box/ui/pages/shows/show_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import '../../../blocs/bottom_nav/bottom_nav_state.dart';

class BottomPage extends StatefulWidget {
  const BottomPage({super.key});

  @override
  State<BottomPage> createState() => _BottomPageState();
}

class _BottomPageState extends State<BottomPage> {
  static const Color skyBlue = Color(0xFF00AEEF);

  final List<Widget> _screens = [
    Container(),
    Container(),
    ShowPage(),
    Container(),
  ];

  @override
  void initState() {
    super.initState();
    // Trigger the bloc to load initial (persisted) index
    context.read<BottomNavBloc>().add(BottomNavLoadInitial());
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BottomNavBloc, BottomNavState>(
      builder: (context, state) {
        if (state.isLoading) {
          // show a splash loader while loading persisted index
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final currentIndex = state.selectedIndex;
        const double iconSize = 24;
        return Scaffold(
          body: SafeArea(child: _screens[currentIndex]),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: currentIndex,
            onTap: (index) => context.read<BottomNavBloc>().add(BottomNavItemTapped(index)),
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.white,
            selectedItemColor: Colors.black,
            unselectedItemColor: Colors.grey.shade600,
            showSelectedLabels: true,      // show label for selected item
            showUnselectedLabels: false,   // hide labels for unselected items
            selectedLabelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            items:  [
              BottomNavigationBarItem(
                icon: SvgPicture.asset(
                  'assets/icons/home.svg',
                  width: iconSize,
                  height: iconSize,
                ),
                activeIcon: SvgPicture.asset(
                  'assets/icons/home.svg',
                  width: iconSize,
                  height: iconSize,
                ),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: SvgPicture.asset(
                  'assets/icons/yours.svg',
                  width: iconSize,
                  height: iconSize,
                ),
                activeIcon: SvgPicture.asset(
                  'assets/icons/yours.svg',
                  width: iconSize,
                  height: iconSize,
                ),
                label: 'Yours',
              ),
              BottomNavigationBarItem(
                icon: SvgPicture.asset(
                  'assets/icons/shows.svg',
                  width: iconSize,
                  height: iconSize,
                ),
                activeIcon: SvgPicture.asset(
                  'assets/icons/shows.svg',
                  width: iconSize,
                  height: iconSize,
                ),
                label: 'Shows',
              ),
              BottomNavigationBarItem(
                icon: SvgPicture.asset(
                  'assets/icons/tv.svg',
                  width: iconSize,
                  height: iconSize,
                ),
                activeIcon: SvgPicture.asset(
                  'assets/icons/tv.svg',
                  width: iconSize,
                  height: iconSize,
                ),
                label: 'Channels',
              ),
            ],
          ),
        );
      },
    );
  }
}

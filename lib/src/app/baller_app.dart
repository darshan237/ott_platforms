import 'package:dd_box/blocs/bottom_nav/bottom_nav_bloc.dart';
import 'package:dd_box/blocs/bottom_nav/bottom_nav_event.dart';
import 'package:dd_box/blocs/show_bloc/show_bloc.dart';
import 'package:dd_box/repositories/navigation_repository.dart';
import 'package:dd_box/ui/pages/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class BallerApp extends StatefulWidget {
  const BallerApp({super.key});

  static BallerAppState of(BuildContext context) {
    final state = context.findAncestorStateOfType<BallerAppState>();
    assert(state != null, 'No BallerApp found in context!');
    return state!;
  }

  @override
  State<BallerApp> createState() => BallerAppState();
}

class BallerAppState extends State<BallerApp> {
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey();
  final RouteObserver routeObserver = RouteObserver();
  final NavigationRepository _navigationRepository = NavigationRepository();


  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<NavigationRepository>.value(value: _navigationRepository),
      ],

      child: MultiBlocProvider(
        providers: [
          // Provide the BottomNavBloc app-wide (so any page can read it)
          BlocProvider<BottomNavBloc>(
            create: (_) => BottomNavBloc(_navigationRepository)
              ..add(BottomNavLoadInitial()), // load persisted index on start
          ),

          BlocProvider<ShowBloc>(create: (_) => ShowBloc(), ),

          // Add other global Blocs here if needed
        ],
        child: MaterialApp(
            debugShowCheckedModeBanner: false,
            restorationScopeId: 'baller_app',
            themeMode: ThemeMode.dark,
            navigatorKey: navigatorKey,
            navigatorObservers: [routeObserver],
            theme: ThemeData(
              primaryColor: Color(0xFF00AEEF),
              colorScheme: ColorScheme.fromSeed(seedColor: Color(0xFF00AEEF)),
              useMaterial3: true,
            ),
            home: SplashScreen()),
      ),
    );
  }
}

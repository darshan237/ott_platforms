


import 'dart:async';

import 'package:dd_box/utils/log.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

typedef AsyncAppBuilder = FutureOr<Widget> Function();


Future<void> bootstrap(AsyncAppBuilder builder) async {
  return runZonedGuarded(
      () async{
        WidgetsFlutterBinding.ensureInitialized();
        _configureSystemUi().ignore();
        final app = await builder();
        runApp(
          Builder(
            builder: (context) {
              final mediaQuerySize = MediaQuery.sizeOf(context);
              return ScreenUtilInit(
                designSize: mediaQuerySize,
                useInheritedMediaQuery: true,
                minTextAdapt: true,
                splitScreenMode: true,
                child: app,
              );
            },
          ),
        );
        },
        (error, stackTrace) {
      Log.debug(error);
      Log.debug(stackTrace);
    },
  );
}

Future<void> _configureSystemUi() async {
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
      systemNavigationBarContrastEnforced: false,
      systemStatusBarContrastEnforced: false,
    ),
  );
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
}

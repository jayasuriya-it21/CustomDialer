import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:permission_handler/permission_handler.dart';

import 'core/constants/app_constants.dart';
import 'core/di/service_locator.dart';
import 'core/routing/app_router.dart';
import 'core/services/call_service.dart';
import 'core/services/contact_service.dart';
import 'core/storage/app_storage.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_cubit.dart';
import 'core/theme/theme_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive FIRST — before anything reads storage.
  await AppStorage.init();

  setupServiceLocator();

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light));

  // Load theme prefs asynchronously to prevent blocking the first frame.
  // The app will render instantly with the default theme, then update smoothly.
  final themeCubit = getIt<ThemeCubit>();
  unawaited(themeCubit.loadPreferences());

  runApp(DialerApp(themeCubit: themeCubit));

  WidgetsBinding.instance.addPostFrameCallback((_) {
    unawaited(_bootstrapApp());
  });
}

Future<void> _bootstrapApp() async {
  // Start native call events.
  getIt<CallService>().listenToCallEvents();

  // Ask only essential permissions after first frame without blocking startup.
  unawaited(() async {
    await _requestEssentialPermissions();
    if (await Permission.contacts.isGranted) {
      await getIt<ContactService>().preload();
    }
  }());

  // Optional delayed storage warm-up for later reads.
  AppStorage.instance.ensureReady();
}

Future<void> _requestEssentialPermissions() async {
  final permissions = <Permission>[
    Permission.phone,
    Permission.contacts,
    Permission.microphone,
    Permission.notification,
  ];

  final toRequest = <Permission>[];
  for (final permission in permissions) {
    final status = await permission.status;
    if (!status.isGranted) {
      toRequest.add(permission);
    }
  }

  if (toRequest.isNotEmpty) {
    await toRequest.request();
  }
}

class _BouncingScrollBehavior extends ScrollBehavior {
  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics());
  }
}

class DialerApp extends StatelessWidget {
  const DialerApp({super.key, required this.themeCubit});

  final ThemeCubit themeCubit;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ThemeCubit>.value(
      value: themeCubit,
      child: BlocBuilder<ThemeCubit, ThemeState>(
        builder: (context, themeState) {
          return DynamicColorBuilder(
            builder: (lightDynamic, darkDynamic) {
              return MaterialApp.router(
                title: AppConstants.appTitle,
                debugShowCheckedModeBanner: false,
                theme: AppTheme.buildLightTheme(
                  seedColor: themeState.seedColor,
                  useDynamicColor: themeState.useDynamicColor,
                  dynamicScheme: lightDynamic,
                ),
                darkTheme: AppTheme.buildDarkTheme(
                  seedColor: themeState.seedColor,
                  useDynamicColor: themeState.useDynamicColor,
                  dynamicScheme: darkDynamic,
                ),
                themeMode: themeState.themeMode,
                routerConfig: appRouter,
                scrollBehavior: _BouncingScrollBehavior(),
              );
            },
          );
        },
      ),
    );
  }
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:permission_handler/permission_handler.dart';
import 'config/app_router.dart';
import 'core/constants/app_constants.dart';
import 'core/di/service_locator.dart';
import 'core/storage/app_storage.dart';
import 'services/call_service.dart';
import 'theme/theme_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  setupServiceLocator();

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(statusBarColor: Colors.transparent, statusBarIconBrightness: Brightness.light));

  runApp(const DialerApp());
  WidgetsBinding.instance.addPostFrameCallback((_) {
    unawaited(_bootstrapApp());
  });
}

Future<void> _bootstrapApp() async {
  // Keep launch path minimal: only start native call events.
  getIt<CallService>().listenToCallEvents();

  // Ask only essential permissions after first frame without blocking startup.
  unawaited(_requestEssentialPermissions());

  // Optional delayed storage warm-up for later reads.
  await Future<void>.delayed(const Duration(milliseconds: 300));
  await AppStorage.instance.ensureReady();
}

Future<void> _requestEssentialPermissions() async {
  await Future<void>.delayed(const Duration(milliseconds: 900));

  final permissions = <Permission>[Permission.phone, Permission.contacts, Permission.microphone];

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

class DialerApp extends StatefulWidget {
  const DialerApp({super.key});

  @override
  State<DialerApp> createState() => _DialerAppState();
}

class _DialerAppState extends State<DialerApp> {
  final ThemeProvider _theme = getIt<ThemeProvider>();

  @override
  void initState() {
    super.initState();
    _theme.addListener(_onThemeChanged);
  }

  void _onThemeChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _theme.removeListener(_onThemeChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DynamicColorBuilder(
      builder: (lightDynamic, darkDynamic) {
        return MaterialApp.router(
          title: AppConstants.appTitle,
          debugShowCheckedModeBanner: false,
          theme: _theme.buildLightTheme(dynamicScheme: lightDynamic).copyWith(pageTransitionsTheme: const PageTransitionsTheme(builders: {TargetPlatform.android: CupertinoPageTransitionsBuilder()})),
          darkTheme: _theme.buildDarkTheme(dynamicScheme: darkDynamic).copyWith(pageTransitionsTheme: const PageTransitionsTheme(builders: {TargetPlatform.android: CupertinoPageTransitionsBuilder()})),
          themeMode: _theme.themeMode,
          routerConfig: appRouter,
        );
      },
    );
  }
}

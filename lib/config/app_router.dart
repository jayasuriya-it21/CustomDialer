import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/constants/app_routes.dart';
import '../features/call/presentation/screens/in_call_screen.dart';
import '../features/call/presentation/screens/incoming_call_screen.dart';
import '../features/dialer/presentation/screens/dialpad_screen_bloc.dart';
import '../features/search/presentation/screens/search_screen_bloc.dart';
import '../features/app/presentation/home_shell_screen.dart';
import '../features/settings/presentation/screens/settings_screen.dart';

final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

final GoRouter appRouter = GoRouter(
  navigatorKey: appNavigatorKey,
  initialLocation: AppRoutes.home,
  routes: [
    GoRoute(path: AppRoutes.home, builder: (context, state) => const HomeShellScreen()),
    GoRoute(path: AppRoutes.dialpad, builder: (context, state) => const DialpadScreenBloc()),
    GoRoute(path: AppRoutes.search, builder: (context, state) => const SearchScreenBloc()),
    GoRoute(path: AppRoutes.settings, builder: (context, state) => const SettingsScreen()),
    GoRoute(
      path: '/incoming-call',
      builder: (context, state) {
        final callerName = state.extra is Map ? (state.extra as Map)['callerName']?.toString() ?? 'Unknown' : 'Unknown';
        final callerNumber = state.extra is Map ? (state.extra as Map)['callerNumber']?.toString() ?? 'Unknown' : 'Unknown';
        return IncomingCallScreen(callerName: callerName, callerNumber: callerNumber);
      },
    ),
    GoRoute(
      path: '/in-call',
      builder: (context, state) {
        final callerName = state.extra is Map ? (state.extra as Map)['callerName']?.toString() ?? 'Unknown' : 'Unknown';
        final isIncoming = state.extra is Map ? (state.extra as Map)['isIncoming'] as bool? ?? false : false;
        return InCallScreen(callerName: callerName, isIncoming: isIncoming);
      },
    ),
  ],
);

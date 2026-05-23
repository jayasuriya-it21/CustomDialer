import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/constants/ui_constants.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/services/call_service.dart';
import '../../contacts/screen/contacts_screen_bloc.dart';
import '../../recents/screen/recents_screen_bloc.dart';
import '../bloc/home_nav_cubit.dart';

class HomeShellScreen extends StatefulWidget {
  const HomeShellScreen({super.key});

  @override
  State<HomeShellScreen> createState() => _HomeShellScreenState();
}

class _HomeShellScreenState extends State<HomeShellScreen> {
  static const int _initialTab = 0;
  final Set<int> _visitedTabs = <int>{_initialTab};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      getIt<CallService>().requestDefaultDialer();
    });
  }

  Widget _buildTab(int index) {
    switch (index) {
      case 0:
        return const RepaintBoundary(child: RecentsScreenBloc());
      case 1:
      default:
        return const RepaintBoundary(child: ContactsScreenBloc());
    }
  }

  void _onDestinationSelected(BuildContext context, int index) {
    if (_visitedTabs.add(index)) {
      setState(() {});
    }
    context.read<HomeNavCubit>().changeTab(index);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: cs.brightness == Brightness.dark ? Brightness.light : Brightness.dark,
        systemNavigationBarColor: cs.surface,
        systemNavigationBarIconBrightness: cs.brightness == Brightness.dark ? Brightness.light : Brightness.dark,
      ),
      child: BlocProvider(
        create: (_) => HomeNavCubit(),
        child: Scaffold(
          body: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: UiConstants.homeSearchPadding,
                  child: Hero(
                    tag: 'search_bar_hero',
                    child: SearchBar(
                      hintText: AppConstants.searchHint,
                      leading: Icon(Icons.search_rounded, color: cs.onSurfaceVariant.withValues(alpha: 0.8)),
                      trailing: [
                        GestureDetector(
                          onTap: () => context.push(AppRoutes.settings),
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [cs.primary, cs.secondary],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: cs.primary.withValues(alpha: 0.25),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                )
                              ],
                            ),
                            child: Icon(Icons.person_rounded, size: 16, color: cs.onPrimary),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      elevation: const WidgetStatePropertyAll(0),
                      backgroundColor: WidgetStatePropertyAll(cs.surfaceContainerLow),
                      overlayColor: WidgetStatePropertyAll(cs.primary.withValues(alpha: 0.05)),
                      shape: WidgetStatePropertyAll(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                          side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.15), width: 1.2),
                        ),
                      ),
                      onTap: () => context.push(AppRoutes.search),
                    ),
                  ),
                ),
                Expanded(
                  child: BlocBuilder<HomeNavCubit, int>(
                    builder: (context, currentIndex) {
                      return IndexedStack(
                        index: currentIndex,
                        children: List<Widget>.generate(2, (index) {
                          if (!_visitedTabs.contains(index)) {
                            if (index == currentIndex) {
                              return _buildTabLoadingPlaceholder(context);
                            }
                            return const SizedBox.shrink();
                          }
                          return _buildTab(index);
                        }),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: BlocBuilder<HomeNavCubit, int>(
            builder: (context, currentIndex) {
              return Container(
                decoration: BoxDecoration(
                  color: cs.surface,
                  border: Border(
                    top: BorderSide(
                      color: cs.outlineVariant.withValues(alpha: 0.12),
                      width: 1,
                    ),
                  ),
                ),
                child: NavigationBar(
                  selectedIndex: currentIndex,
                  onDestinationSelected: (index) => _onDestinationSelected(context, index),
                  destinations: const [
                    NavigationDestination(
                      icon: Icon(Icons.access_time_rounded),
                      selectedIcon: Icon(Icons.access_time_filled_rounded),
                      label: 'Recents',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.people_outline_rounded),
                      selectedIcon: Icon(Icons.people_rounded),
                      label: 'Contacts',
                    ),
                  ],
                ),
              );
            },
          ),
          floatingActionButton: Container(
            margin: const EdgeInsets.only(bottom: 8, right: 4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: cs.primary.withValues(alpha: 0.35),
                  blurRadius: 14,
                  spreadRadius: 1,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: FloatingActionButton(
              onPressed: () => context.push(AppRoutes.dialpad),
              backgroundColor: cs.primary,
              foregroundColor: cs.onPrimary,
              elevation: 0,
              highlightElevation: 0,
              shape: const CircleBorder(),
              child: const Icon(Icons.dialpad_rounded, size: 26),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabLoadingPlaceholder(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      children: List<Widget>.generate(7, (index) {
        final widthFactor = index.isEven ? 1.0 : 0.72;
        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Align(
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: widthFactor,
              child: Container(
                height: 16,
                decoration: BoxDecoration(color: cs.surfaceContainerHighest, borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        );
      }),
    );
  }
}

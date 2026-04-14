import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/constants/ui_constants.dart';
import '../../../features/contacts/presentation/screens/contacts_screen_bloc.dart';
import '../../../features/favorites/presentation/screens/favourites_screen_bloc.dart';
import '../../../features/recents/presentation/screens/recents_screen_bloc.dart';
import 'bloc/home_nav_cubit.dart';

class HomeShellScreen extends StatefulWidget {
  const HomeShellScreen({super.key});

  @override
  State<HomeShellScreen> createState() => _HomeShellScreenState();
}

class _HomeShellScreenState extends State<HomeShellScreen> {
  static const int _initialTab = 1;
  final Set<int> _visitedTabs = <int>{};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _visitedTabs.add(_initialTab);
      });
    });
  }

  Widget _buildTab(int index) {
    switch (index) {
      case 0:
        return const RepaintBoundary(child: FavouritesScreenBloc());
      case 1:
        return const RepaintBoundary(child: RecentsScreenBloc());
      case 2:
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
      value: SystemUiOverlayStyle(statusBarColor: Colors.transparent, statusBarIconBrightness: cs.brightness == Brightness.dark ? Brightness.light : Brightness.dark, systemNavigationBarColor: cs.surfaceContainerLow),
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
                      leading: const Icon(Icons.search_rounded),
                      trailing: [
                        GestureDetector(
                          onTap: () => context.push(AppRoutes.settings),
                          child: CircleAvatar(
                            radius: 16,
                            backgroundColor: cs.primary,
                            child: Icon(Icons.person_rounded, size: 18, color: cs.onPrimary),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      elevation: const WidgetStatePropertyAll(0),
                      backgroundColor: WidgetStatePropertyAll(cs.surfaceContainerHigh),
                      onTap: () => context.push(AppRoutes.search),
                    ),
                  ),
                ),
                Expanded(
                  child: BlocBuilder<HomeNavCubit, int>(
                    builder: (context, currentIndex) {
                      return IndexedStack(
                        index: currentIndex,
                        children: List<Widget>.generate(3, (index) {
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
              return NavigationBar(
                selectedIndex: currentIndex,
                onDestinationSelected: (index) => _onDestinationSelected(context, index),
                destinations: const [
                  NavigationDestination(icon: Icon(Icons.star_outline_rounded), selectedIcon: Icon(Icons.star_rounded), label: 'Favourites'),
                  NavigationDestination(icon: Icon(Icons.access_time_rounded), selectedIcon: Icon(Icons.access_time_filled_rounded), label: 'Recents'),
                  NavigationDestination(icon: Icon(Icons.people_outline_rounded), selectedIcon: Icon(Icons.people_rounded), label: 'Contacts'),
                ],
              );
            },
          ),
          floatingActionButton: FloatingActionButton(onPressed: () => context.push(AppRoutes.dialpad), child: const Icon(Icons.dialpad_rounded, size: 26)),
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

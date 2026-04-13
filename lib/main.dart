import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'theme/theme_provider.dart';
import 'screens/recents_screen.dart';
import 'screens/contacts_screen.dart';
import 'screens/dialpad_screen.dart';
import 'screens/search_screen.dart';
import 'screens/settings_screen.dart';
import 'services/call_service.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));
  runApp(const GoogleDialerApp());
}

class GoogleDialerApp extends StatefulWidget {
  const GoogleDialerApp({super.key});

  @override
  State<GoogleDialerApp> createState() => _GoogleDialerAppState();
}

class _GoogleDialerAppState extends State<GoogleDialerApp> {
  final ThemeProvider _theme = ThemeProvider();

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
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Phone',
      debugShowCheckedModeBanner: false,
      theme: _theme.buildLightTheme(),
      darkTheme: _theme.buildDarkTheme(),
      themeMode: _theme.themeMode,
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 1;
  final CallService _callService = CallService();

  @override
  void initState() {
    super.initState();
    _initApp();
  }

  Future<void> _initApp() async {
    await [
      Permission.phone,
      Permission.contacts,
      Permission.microphone,
      Permission.storage,
    ].request();
    _callService.listenToCallEvents();
    _callService.requestDefaultDialer();
  }

  void _openDialpad() {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const DialpadScreen(),
        transitionsBuilder: (_, animation, __, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 1),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            )),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 280),
        reverseTransitionDuration: const Duration(milliseconds: 220),
      ),
    );
  }

  void _openSearch() {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const SearchScreen(),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 200),
      ),
    );
  }

  void _openSettings() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SettingsScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: cs.brightness == Brightness.dark
            ? Brightness.light
            : Brightness.dark,
        systemNavigationBarColor: cs.surfaceContainerLow,
      ),
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              // Search Bar
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 2),
                child: Material(
                  color: cs.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(28),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: _openSearch,
                    borderRadius: BorderRadius.circular(28),
                    child: SizedBox(
                      height: 48,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            Icon(Icons.search_rounded, color: cs.onSurfaceVariant, size: 22),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                'Search contacts & places',
                                style: TextStyle(color: cs.onSurfaceVariant, fontSize: 16),
                              ),
                            ),
                            GestureDetector(
                              onTap: _openSettings,
                              child: CircleAvatar(
                                radius: 16,
                                backgroundColor: cs.primary,
                                child: Icon(Icons.person_rounded, size: 18, color: cs.onPrimary),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Body - IndexedStack keeps tab state alive
              Expanded(
                child: IndexedStack(
                  index: _currentIndex,
                  children: const [
                    _FavouritesPlaceholder(),
                    RecentsScreen(),
                    ContactsScreen(),
                  ],
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (i) => setState(() => _currentIndex = i),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.star_outline_rounded),
              selectedIcon: Icon(Icons.star_rounded),
              label: 'Favourites',
            ),
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
        floatingActionButton: FloatingActionButton(
          onPressed: _openDialpad,
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: const Icon(Icons.dialpad_rounded, size: 26),
        ),
      ),
    );
  }
}

class _FavouritesPlaceholder extends StatelessWidget {
  const _FavouritesPlaceholder();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star_outline_rounded, size: 64, color: cs.onSurfaceVariant.withOpacity(0.3)),
          const SizedBox(height: 16),
          Text('No favourites yet', style: TextStyle(fontSize: 16, color: cs.onSurfaceVariant)),
          const SizedBox(height: 8),
          Text(
            'Add favourites from your contacts',
            style: TextStyle(fontSize: 14, color: cs.onSurfaceVariant.withOpacity(0.6)),
          ),
        ],
      ),
    );
  }
}

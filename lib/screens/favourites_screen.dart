import 'package:flutter/material.dart';
import '../services/call_service.dart';
import '../services/contact_service.dart';
import '../services/favorites_service.dart';
import '../widgets/contact_avatar.dart';
import 'contact_detail_screen.dart';

class FavouritesScreen extends StatefulWidget {
  const FavouritesScreen({super.key});

  @override
  State<FavouritesScreen> createState() => _FavouritesScreenState();
}

class _FavouritesScreenState extends State<FavouritesScreen>
    with AutomaticKeepAliveClientMixin {
  final ContactService _contactService = ContactService();
  final FavoritesService _favoritesService = FavoritesService();
  final CallService _callService = CallService();
  List<Map<String, dynamic>> _favorites = [];
  bool _isLoading = true;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    await _favoritesService.load();
    List<Map<String, dynamic>> contacts;
    if (_contactService.isLoaded) {
      contacts = _contactService.cachedContacts;
    } else {
      contacts = await _contactService.getContacts();
    }
    if (mounted) {
      setState(() {
        _favorites = _favoritesService.filterFavorites(contacts);
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final cs = Theme.of(context).colorScheme;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }

    if (_favorites.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.star_outline_rounded, size: 64,
                color: cs.onSurfaceVariant.withOpacity(0.25)),
            const SizedBox(height: 16),
            Text('No favourites',
                style: TextStyle(fontSize: 16, color: cs.onSurfaceVariant)),
            const SizedBox(height: 8),
            Text('Star contacts to add them here',
                style: TextStyle(
                    fontSize: 14,
                    color: cs.onSurfaceVariant.withOpacity(0.6))),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadFavorites,
      child: GridView.builder(
        physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics()),
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 0.85,
        ),
        itemCount: _favorites.length,
        itemBuilder: (_, i) {
          final c = _favorites[i];
          final name = (c['name'] as String?) ?? '';
          final number = (c['number'] as String?) ?? '';

          return GestureDetector(
            onTap: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) =>
                          ContactDetailScreen(name: name, number: number)));
            },
            child: Column(
              children: [
                Stack(
                  children: [
                    ContactAvatar(name: name, radius: 32),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: cs.surface,
                        ),
                        child: Icon(Icons.star_rounded,
                            size: 14, color: Colors.amber),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(name,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center),
                GestureDetector(
                  onTap: () => _callService.makeCall(number),
                  child: Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Icon(Icons.call_rounded,
                        size: 18, color: cs.primary),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

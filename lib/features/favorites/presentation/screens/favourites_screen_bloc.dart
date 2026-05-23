import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../../contacts/presentation/screens/contact_detail_screen.dart';
import '../../../../core/services/call_service.dart';
import '../../../../core/widgets/contact_avatar.dart';
import '../../../contacts/domain/entities/contact_entity.dart';
import '../bloc/favorites_bloc.dart';
import '../bloc/favorites_event.dart';
import '../bloc/favorites_state.dart';

class FavouritesScreenBloc extends StatelessWidget {
  const FavouritesScreenBloc({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(create: (_) => getIt<FavoritesBloc>()..add(const FavoritesRequested()), child: const _FavouritesView());
  }
}

class _FavouritesView extends StatelessWidget {
  const _FavouritesView();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final callService = getIt<CallService>();

    return BlocBuilder<FavoritesBloc, FavoritesState>(
      builder: (context, state) {
        if (state is FavoritesInitial || state is FavoritesLoading) {
          return const Center(child: CircularProgressIndicator(strokeWidth: 2));
        }

        if (state is FavoritesError) {
          return Center(
            child: Text(state.message, style: TextStyle(color: cs.onSurfaceVariant)),
          );
        }

        final favorites = state is FavoritesLoaded ? state.contacts : <ContactEntity>[];

        if (favorites.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.star_outline_rounded, size: 64, color: cs.onSurfaceVariant.withValues(alpha: 0.25)),
                const SizedBox(height: 16),
                Text('No favourites', style: TextStyle(fontSize: 16, color: cs.onSurfaceVariant)),
                const SizedBox(height: 8),
                Text('Star contacts to add them here', style: TextStyle(fontSize: 14, color: cs.onSurfaceVariant.withValues(alpha: 0.6))),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            context.read<FavoritesBloc>().add(const FavoritesRequested(forceRefresh: true));
          },
          child: GridView.builder(
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.76,
            ),
            itemCount: favorites.length,
            itemBuilder: (_, i) {
              final contact = favorites[i];
              final heroTag = 'fav_${contact.name}_${contact.number}';

              return Card(
                elevation: 0,
                color: cs.surfaceContainerLow,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.15), width: 1),
                ),
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ContactDetailScreen(name: contact.name, number: contact.number, heroTag: heroTag),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Stack(
                          children: [
                            ContactAvatar(name: contact.name, radius: 26, heroTag: heroTag),
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: Container(
                                padding: const EdgeInsets.all(1.5),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: cs.surfaceContainerLow,
                                  border: Border.all(color: cs.surface, width: 1),
                                ),
                                child: const Icon(Icons.star_rounded, size: 10, color: Colors.amber),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          contact.name,
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: cs.onSurface),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () => callService.makeCall(contact.number),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: cs.primary.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.call_rounded, size: 11, color: cs.primary),
                                const SizedBox(width: 4),
                                Text(
                                  'Call',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: cs.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

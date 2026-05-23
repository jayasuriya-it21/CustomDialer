import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import 'contact_detail_screen.dart';
import '../../../../core/services/call_service.dart';
import '../../../../core/widgets/contact_avatar.dart';
import '../../domain/entities/contact_entity.dart';
import '../bloc/contacts_bloc.dart';
import '../bloc/contacts_event.dart';
import '../bloc/contacts_state.dart';

class ContactsScreenBloc extends StatelessWidget {
  const ContactsScreenBloc({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(create: (_) => getIt<ContactsBloc>()..add(const ContactsRequested()), child: const _ContactsView());
  }
}

class _ContactsView extends StatelessWidget {
  const _ContactsView();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final callService = getIt<CallService>();

    return BlocBuilder<ContactsBloc, ContactsState>(
      builder: (context, state) {
        if (state is ContactsLoading || state is ContactsInitial) {
          return const Center(child: CircularProgressIndicator(strokeWidth: 2));
        }

        if (state is ContactsError) {
          return Center(
            child: Text(state.message, style: TextStyle(color: cs.onSurfaceVariant)),
          );
        }

        final contacts = state is ContactsLoaded ? state.contacts : <ContactEntity>[];

        if (contacts.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.people_outline_rounded, size: 64, color: cs.onSurfaceVariant.withValues(alpha: 0.25)),
                const SizedBox(height: 16),
                Text('No contacts', style: TextStyle(fontSize: 16, color: cs.onSurfaceVariant)),
              ],
            ),
          );
        }

        final grouped = state is ContactsLoaded ? state.groupedItems : <ContactListItem>[];

        return RefreshIndicator(
          onRefresh: () async {
            context.read<ContactsBloc>().add(const ContactsRequested(forceRefresh: true));
          },
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            padding: const EdgeInsets.only(top: 4, bottom: 24),
            itemCount: grouped.length,
            itemBuilder: (_, i) {
              final item = grouped[i];
              if (item.isHeader) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: cs.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          item.letter!,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: cs.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Divider(
                          color: cs.outlineVariant.withValues(alpha: 0.15),
                          thickness: 1,
                        ),
                      ),
                    ],
                  ),
                );
              }

              final contact = item.contact!;
              final heroTag = 'contacts_${contact.name}_${contact.number}';
              final isDark = Theme.of(context).brightness == Brightness.dark;

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Card(
                  elevation: 0,
                  margin: EdgeInsets.zero,
                  color: cs.surfaceContainerLow,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: cs.outlineVariant.withValues(alpha: isDark ? 0.08 : 0.15),
                      width: 1,
                    ),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ContactDetailScreen(name: contact.name, number: contact.number, heroTag: heroTag),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      child: Row(
                        children: [
                          ContactAvatar(name: contact.name, heroTag: heroTag, radius: 22),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  contact.name,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14.5,
                                    color: cs.onSurface,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  contact.number,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: cs.onSurfaceVariant.withValues(alpha: 0.8),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () => callService.makeCall(contact.number),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: cs.primary.withValues(alpha: 0.08),
                              ),
                              child: Icon(
                                Icons.call_rounded,
                                size: 16,
                                color: cs.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
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

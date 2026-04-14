import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import 'contact_detail_screen.dart';
import '../../../../services/call_service.dart';
import '../../../../widgets/contact_avatar.dart';
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

        final grouped = _buildGroupedItems(contacts);

        return RefreshIndicator(
          onRefresh: () async {
            context.read<ContactsBloc>().add(const ContactsRequested(forceRefresh: true));
          },
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            padding: const EdgeInsets.only(top: 4),
            itemCount: grouped.length,
            itemBuilder: (_, i) {
              final item = grouped[i];
              if (item.isHeader) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                  child: Text(
                    item.letter!,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: cs.primary),
                  ),
                );
              }

              final contact = item.contact!;
              final heroTag = 'contacts_${contact.name}_${contact.number}';

              return ListTile(
                leading: ContactAvatar(name: contact.name, heroTag: heroTag),
                title: Text(
                  contact.name,
                  style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(contact.number, style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ContactDetailScreen(name: contact.name, number: contact.number, heroTag: heroTag),
                    ),
                  );
                },
                trailing: IconButton(
                  icon: Icon(Icons.call_rounded, size: 20, color: cs.primary),
                  visualDensity: VisualDensity.compact,
                  onPressed: () => callService.makeCall(contact.number),
                ),
              );
            },
          ),
        );
      },
    );
  }

  List<_ListItem> _buildGroupedItems(List<ContactEntity> contacts) {
    final grouped = <String, List<ContactEntity>>{};
    for (final contact in contacts) {
      final letter = contact.name.isNotEmpty ? contact.name[0].toUpperCase() : '#';
      grouped.putIfAbsent(letter, () => []).add(contact);
    }

    final keys = grouped.keys.toList()..sort();
    final items = <_ListItem>[];
    for (final key in keys) {
      items.add(_ListItem.header(key));
      for (final contact in grouped[key]!) {
        items.add(_ListItem.contact(contact));
      }
    }

    return items;
  }
}

class _ListItem {
  const _ListItem._({this.letter, this.contact});

  const _ListItem.header(String letter) : this._(letter: letter);
  const _ListItem.contact(ContactEntity contact) : this._(contact: contact);

  final String? letter;
  final ContactEntity? contact;

  bool get isHeader => letter != null;
}

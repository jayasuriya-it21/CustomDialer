import 'package:flutter/material.dart';
import '../services/call_service.dart';
import '../widgets/contact_avatar.dart';
import 'contact_detail_screen.dart';

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  final CallService _callService = CallService();
  List<Map<String, dynamic>> _contacts = [];
  bool _isLoading = true;

  List<_ListItem> _items = [];

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    setState(() => _isLoading = true);
    final contacts = await _callService.getContacts();

    // Group by first letter
    final Map<String, List<Map<String, dynamic>>> grouped = {};
    for (final c in contacts) {
      final name = (c['name'] as String?) ?? '';
      final letter = name.isNotEmpty ? name[0].toUpperCase() : '#';
      (grouped[letter] ??= []).add(c);
    }
    final keys = grouped.keys.toList()..sort();

    // Build flat list with headers for better scroll performance
    final items = <_ListItem>[];
    for (final key in keys) {
      items.add(_ListItem(isHeader: true, letter: key));
      for (final c in grouped[key]!) {
        items.add(_ListItem(contact: c));
      }
    }

    if (mounted) {
      setState(() {
        _contacts = contacts;
        _items = items;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }

    if (_contacts.isEmpty) {
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

    return RefreshIndicator(
      onRefresh: _loadContacts,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        padding: const EdgeInsets.only(top: 4),
        itemCount: _items.length,
        itemBuilder: (_, i) {
          final item = _items[i];
          if (item.isHeader) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
              child: Text(
                item.letter!,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: cs.primary),
              ),
            );
          }
          final c = item.contact!;
          final name = (c['name'] as String?) ?? '';
          final number = (c['number'] as String?) ?? '';

          return ListTile(
            leading: ContactAvatar(name: name),
            title: Text(
              name,
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(number, style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ContactDetailScreen(name: name, number: number),
                ),
              );
            },
            trailing: IconButton(
              icon: Icon(Icons.call_rounded, size: 20, color: cs.primary),
              visualDensity: VisualDensity.compact,
              onPressed: () => _callService.makeCall(number),
            ),
          );
        },
      ),
    );
  }
}

class _ListItem {
  final bool isHeader;
  final String? letter;
  final Map<String, dynamic>? contact;
  _ListItem({this.isHeader = false, this.letter, this.contact});
}

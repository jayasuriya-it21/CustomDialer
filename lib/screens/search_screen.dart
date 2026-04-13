import 'package:flutter/material.dart';
import '../services/call_service.dart';
import '../services/contact_service.dart';
import '../widgets/contact_avatar.dart';
import 'contact_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final CallService _callService = CallService();
  final ContactService _contactService = ContactService();

  List<Map<String, dynamic>> _allContacts = [];
  List<Map<String, dynamic>> _allLogs = [];
  List<Map<String, dynamic>> _results = [];
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadData();
    _focusNode.requestFocus();
    _controller.addListener(_search);
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (_contactService.isLoaded) {
      _allContacts = _contactService.cachedContacts;
    } else {
      _allContacts = await _contactService.getContacts();
    }
    final logs = await _callService.getCallLog();
    if (mounted) {
      setState(() {
        _allLogs = logs;
        _loaded = true;
      });
    }
  }

  void _search() {
    final q = _controller.text.trim().toLowerCase();
    if (q.isEmpty) {
      setState(() => _results = []);
      return;
    }

    final Set<String> seen = {};
    final matches = <Map<String, dynamic>>[];

    // Search contacts first
    for (final c in _allContacts) {
      final name = (c['name'] as String? ?? '').toLowerCase();
      final number = (c['number'] as String? ?? '');
      if (name.contains(q) || number.contains(q)) {
        final key = '$name|$number';
        if (!seen.contains(key)) {
          seen.add(key);
          matches.add({...c, 'source': 'contact'});
        }
      }
    }

    // Search call logs
    for (final l in _allLogs) {
      final name = (l['name'] as String? ?? '').toLowerCase();
      final number = (l['number'] as String? ?? '');
      if (name.contains(q) || number.contains(q)) {
        final key = '$name|$number';
        if (!seen.contains(key)) {
          seen.add(key);
          matches.add({...l, 'source': 'log'});
        }
      }
    }

    setState(() => _results = matches.take(20).toList());
  }

  void _navigateToDetail(String name, String number, String? heroTag) {
    if (name.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ContactDetailScreen(name: name, number: number, heroTag: heroTag),
        ),
      );
    } else {
      // Unknown contact — just call
      _callService.makeCall(number);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Search field
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 2),
              child: Hero(
                tag: 'search_bar_hero',
                child: SearchBar(
                  controller: _controller,
                  focusNode: _focusNode,
                  hintText: 'Search contacts & places',
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back_rounded),
                    onPressed: () => Navigator.pop(context),
                    tooltip: 'Back',
                  ),
                  trailing: [
                    if (_controller.text.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        tooltip: 'Clear',
                        onPressed: () {
                          _controller.clear();
                          setState(() => _results = []);
                        },
                      ),
                    const SizedBox(width: 8)
                  ],
                  elevation: const WidgetStatePropertyAll(0),
                  backgroundColor: WidgetStatePropertyAll(cs.surfaceContainerHigh),
                ),
              ),
            ),
            const Divider(height: 1),

            // Results
            Expanded(
              child: _controller.text.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.search_rounded,
                              size: 48,
                              color: cs.onSurfaceVariant.withOpacity(0.2)),
                          const SizedBox(height: 12),
                          Text('Search by name or number',
                              style: TextStyle(
                                  color: cs.onSurfaceVariant.withOpacity(0.5))),
                        ],
                      ),
                    )
                  : _results.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.search_off_rounded,
                                  size: 48,
                                  color:
                                      cs.onSurfaceVariant.withOpacity(0.2)),
                              const SizedBox(height: 12),
                              Text('No results',
                                  style: TextStyle(
                                      color: cs.onSurfaceVariant)),
                            ],
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.only(top: 4),
                          itemCount: _results.length,
                          separatorBuilder: (_, __) =>
                              const Divider(height: 1, indent: 72),
                          itemBuilder: (_, i) {
                            final r = _results[i];
                            final name = (r['name'] as String?) ?? '';
                            final number = (r['number'] as String?) ?? '';
                            final displayName =
                                name.isNotEmpty ? name : number;
                            final isContact = r['source'] == 'contact';
                            final String? heroTag = isContact ? 'search_${displayName}_$number' : null;

                            return ListTile(
                              leading: ContactAvatar(
                                name: displayName,
                                heroTag: heroTag,
                              ),
                              title: Text(displayName,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w500)),
                              subtitle: name.isNotEmpty
                                  ? Text(number,
                                      style: TextStyle(
                                          fontSize: 13,
                                          color: cs.onSurfaceVariant))
                                  : null,
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: Icon(Icons.call_rounded,
                                        color: cs.primary, size: 20),
                                    tooltip: 'Call',
                                    onPressed: () =>
                                        _callService.makeCall(number),
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.message_rounded,
                                        color: cs.onSurfaceVariant,
                                        size: 20),
                                    tooltip: 'Message',
                                    onPressed: () =>
                                        _contactService.openSms(number),
                                  ),
                                ],
                              ),
                              onTap: () =>
                                  _navigateToDetail(name, number, heroTag),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

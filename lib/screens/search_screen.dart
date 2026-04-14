import 'package:flutter/material.dart';
import '../services/call_service.dart';
import '../widgets/contact_avatar.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final CallService _callService = CallService();

  List<Map<String, dynamic>> _allContacts = [];
  List<Map<String, dynamic>> _allLogs = [];
  List<Map<String, dynamic>> _results = [];

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
    final contacts = await _callService.getContacts();
    final logs = await _callService.getCallLog();
    if (mounted) {
      setState(() {
        _allContacts = contacts;
        _allLogs = logs;
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

    // Search contacts
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

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Search field
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 16, 0),
              child: Row(
                children: [
                  IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => Navigator.pop(context)),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      style: const TextStyle(fontSize: 16),
                      decoration: InputDecoration(
                        hintText: 'Search contacts & places',
                        hintStyle: TextStyle(color: cs.onSurfaceVariant),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  if (_controller.text.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () {
                        _controller.clear();
                        setState(() => _results = []);
                      },
                    ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Results
            Expanded(
              child: _controller.text.isEmpty
                  ? Center(
                      child: Text('Search by name or number', style: TextStyle(color: cs.onSurfaceVariant.withValues(alpha: 0.5))),
                    )
                  : _results.isEmpty
                  ? Center(
                      child: Text('No results', style: TextStyle(color: cs.onSurfaceVariant)),
                    )
                  : ListView.builder(
                      itemCount: _results.length,
                      itemBuilder: (_, i) {
                        final r = _results[i];
                        final name = (r['name'] as String?) ?? '';
                        final number = (r['number'] as String?) ?? '';
                        final displayName = name.isNotEmpty ? name : number;

                        return ListTile(
                          leading: ContactAvatar(name: displayName),
                          title: Text(displayName, style: const TextStyle(fontWeight: FontWeight.w500)),
                          subtitle: name.isNotEmpty ? Text(number, style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant)) : null,
                          trailing: IconButton(
                            icon: Icon(Icons.call_rounded, color: cs.primary, size: 20),
                            onPressed: () => _callService.makeCall(number),
                          ),
                          onTap: () => _callService.makeCall(number),
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

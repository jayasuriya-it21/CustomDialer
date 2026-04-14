import 'dart:async';

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
  Timer? _searchDebounce;

  List<Map<String, dynamic>> _results = [];
  List<_SearchEntry> _searchPool = [];

  @override
  void initState() {
    super.initState();
    _loadData();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
    _controller.addListener(_onQueryChanged);
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _controller.removeListener(_onQueryChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final contacts = await _callService.getContacts();
    final logs = await _callService.getCallLog();
    final searchPool = <_SearchEntry>[];
    for (final c in contacts) {
      searchPool.add(_SearchEntry(item: c, nameLc: ((c['name'] as String?) ?? '').toLowerCase(), number: (c['number'] as String?) ?? ''));
    }
    for (final l in logs) {
      searchPool.add(_SearchEntry(item: l, nameLc: ((l['name'] as String?) ?? '').toLowerCase(), number: (l['number'] as String?) ?? ''));
    }
    if (mounted) {
      setState(() {
        _searchPool = searchPool;
      });
    }
  }

  void _onQueryChanged() {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 110), _search);
  }

  void _search() {
    final q = _controller.text.trim().toLowerCase();
    if (q.isEmpty) {
      setState(() => _results = []);
      return;
    }

    final Set<String> seen = {};
    final matches = <Map<String, dynamic>>[];

    for (final entry in _searchPool) {
      if (entry.nameLc.contains(q) || entry.number.contains(q)) {
        final key = '${entry.nameLc}|${entry.number}';
        if (seen.add(key)) {
          matches.add(entry.item);
        }
      }
      if (matches.length >= 20) {
        break;
      }
    }

    setState(() => _results = matches);
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
                        _searchDebounce?.cancel();
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

class _SearchEntry {
  final Map<String, dynamic> item;
  final String nameLc;
  final String number;

  const _SearchEntry({required this.item, required this.nameLc, required this.number});
}

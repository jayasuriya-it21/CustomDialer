import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/call_service.dart';
import '../services/contact_service.dart';
import '../widgets/contact_avatar.dart';

class DialpadScreen extends StatefulWidget {
  const DialpadScreen({super.key});

  @override
  State<DialpadScreen> createState() => _DialpadScreenState();
}

class _DialpadScreenState extends State<DialpadScreen> {
  String _number = '';
  final CallService _callService = CallService();
  final ContactService _contactService = ContactService();
  List<Map<String, dynamic>> _allContacts = [];
  List<Map<String, dynamic>> _matchingContacts = [];
  bool _contactsLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    if (_contactService.isLoaded) {
      _allContacts = _contactService.cachedContacts;
    } else {
      _allContacts = await _contactService.getContacts();
    }
    _contactsLoaded = true;
  }

  // T9 matching
  static const Map<String, String> _t9Map = {
    '2': 'abcABC', '3': 'defDEF', '4': 'ghiGHI',
    '5': 'jklJKL', '6': 'mnoMNO', '7': 'pqrsPQRS',
    '8': 'tuvTUV', '9': 'wxyzWXYZ',
  };

  void _updateMatches() {
    if (!_contactsLoaded || _number.isEmpty) {
      _matchingContacts = [];
      return;
    }
    _matchingContacts = _allContacts.where((c) {
      final name = (c['name'] as String?) ?? '';
      final num = (c['number'] as String?) ?? '';
      if (num.replaceAll(RegExp(r'[\s\-\(\)\+]'), '').contains(_number)) return true;
      if (_matchesT9(name, _number)) return true;
      return false;
    }).take(10).toList();
  }

  bool _matchesT9(String name, String digits) {
    if (name.isEmpty || digits.isEmpty) return false;
    final cleanName = name.replaceAll(RegExp(r'[^a-zA-Z]'), '').toLowerCase();
    if (cleanName.length < digits.length) return false;

    for (int i = 0; i < digits.length; i++) {
      final d = digits[i];
      final letters = _t9Map[d];
      if (letters == null) continue;
      if (i >= cleanName.length) return false;
      if (!letters.toLowerCase().contains(cleanName[i])) return false;
    }
    return true;
  }

  void _onKey(String d) {
    HapticFeedback.lightImpact();
    setState(() {
      _number += d;
      _updateMatches();
    });
  }

  void _onBackspace() {
    if (_number.isNotEmpty) {
      HapticFeedback.lightImpact();
      setState(() {
        _number = _number.substring(0, _number.length - 1);
        _updateMatches();
      });
    }
  }

  void _onClear() {
    HapticFeedback.mediumImpact();
    setState(() { _number = ''; _matchingContacts = []; });
  }

  Future<void> _makeCall() async {
    if (_number.isEmpty) return;
    HapticFeedback.mediumImpact();
    await _callService.makeCall(_number);
  }

  void _addToContacts() {
    if (_number.isEmpty) return;
    _contactService.addContact(_number);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: Column(
          children: [
            // Back button
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () => Navigator.pop(context),
              ),
            ),

            // Number display
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
              child: Text(
                _number.isEmpty ? '\u200B' : _formatNum(_number),
                style: TextStyle(
                  fontSize: _number.length > 14 ? 26 : 34,
                  fontWeight: FontWeight.w300,
                  letterSpacing: 1.5,
                  color: cs.onSurface,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // Matching contacts
            if (_matchingContacts.isNotEmpty)
              Expanded(
                child: ListView.builder(
                  itemCount: _matchingContacts.length,
                  itemBuilder: (_, i) {
                    final c = _matchingContacts[i];
                    final name = c['name'] as String? ?? '';
                    final num = c['number'] as String? ?? '';
                    return ListTile(
                      dense: true,
                      leading: ContactAvatar(name: name, radius: 18),
                      title: Text(name,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      subtitle: Text(num,
                          style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
                      onTap: () {
                        setState(() => _number = num.replaceAll(RegExp(r'[\s\-\(\)]'), ''));
                      },
                      trailing: IconButton(
                        icon: Icon(Icons.call_rounded, size: 18, color: cs.primary),
                        visualDensity: VisualDensity.compact,
                        onPressed: () => _callService.makeCall(num),
                      ),
                    );
                  },
                ),
              )
            else if (_number.isNotEmpty)
              Expanded(
                child: Align(
                  alignment: Alignment.topCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 4, bottom: 8),
                    child: TextButton.icon(
                      onPressed: _addToContacts,
                      icon: Icon(Icons.person_add_rounded, size: 16, color: cs.primary),
                      label: Text('Add to contacts',
                          style: TextStyle(color: cs.primary, fontSize: 14)),
                    ),
                  ),
                ),
              )
            else
              const Spacer(),

            // Dialpad
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  _row(['1', '2', '3'], ['', 'ABC', 'DEF']),
                  _row(['4', '5', '6'], ['GHI', 'JKL', 'MNO']),
                  _row(['7', '8', '9'], ['PQRS', 'TUV', 'WXYZ']),
                  _row(['*', '0', '#'], ['', '+', '']),
                ],
              ),
            ),

            // Bottom row
            Padding(
              padding: const EdgeInsets.fromLTRB(32, 16, 32, 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SizedBox(
                    width: 56,
                    child: _number.isEmpty
                        ? IconButton(
                            icon: Icon(Icons.voicemail_rounded, color: cs.onSurfaceVariant),
                            onPressed: () {},
                          )
                        : null,
                  ),
                  _callButton(),
                  SizedBox(
                    width: 56,
                    child: _number.isNotEmpty
                        ? GestureDetector(
                            onLongPress: _onClear,
                            child: IconButton(
                              icon: Icon(Icons.backspace_outlined, color: cs.onSurfaceVariant),
                              iconSize: 24,
                              onPressed: _onBackspace,
                            ),
                          )
                        : null,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatNum(String n) {
    if (n.length <= 5) return n;
    if (n.length <= 10) return '${n.substring(0, 5)} ${n.substring(5)}';
    return n;
  }

  Widget _callButton() {
    return SizedBox(
      width: 68,
      height: 68,
      child: Material(
        color: const Color(0xFF34A853),
        shape: const CircleBorder(),
        elevation: 3,
        shadowColor: const Color(0xFF34A853).withOpacity(0.3),
        child: InkWell(
          onTap: _makeCall,
          customBorder: const CircleBorder(),
          child: const Center(
              child: Icon(Icons.call_rounded, color: Colors.white, size: 30)),
        ),
      ),
    );
  }

  Widget _row(List<String> digits, List<String> letters) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(3, (i) => _key(digits[i], letters[i])),
      ),
    );
  }

  Widget _key(String digit, String letters) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _onKey(digit),
        onLongPress: digit == '0' ? () => _onKey('+') : null,
        borderRadius: BorderRadius.circular(40),
        splashColor: cs.primary.withOpacity(0.08),
        child: SizedBox(
          width: 80,
          height: 64,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(digit,
                  style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w300,
                      color: cs.onSurface)),
              if (letters.isNotEmpty)
                Text(letters,
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 1.5,
                        color: cs.onSurfaceVariant)),
            ],
          ),
        ),
      ),
    );
  }
}

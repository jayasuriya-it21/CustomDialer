import 'package:flutter/material.dart';
import '../services/call_service.dart';
import '../services/contact_service.dart';
import '../services/favorites_service.dart';
import '../widgets/contact_avatar.dart';

class ContactDetailScreen extends StatefulWidget {
  final String name;
  final String number;

  const ContactDetailScreen({super.key, required this.name, required this.number});

  @override
  State<ContactDetailScreen> createState() => _ContactDetailScreenState();
}

class _ContactDetailScreenState extends State<ContactDetailScreen> {
  final CallService _callService = CallService();
  final ContactService _contactService = ContactService();
  final FavoritesService _favoritesService = FavoritesService();
  List<Map<String, dynamic>> _phoneNumbers = [];
  bool _isLoading = true;
  bool _isFavorite = false;
  String _contactId = '';

  @override
  void initState() {
    super.initState();
    _loadDetails();
  }

  Future<void> _loadDetails() async {
    final details = await _contactService.getContactDetails(widget.number);
    await _favoritesService.load();

    if (mounted) {
      final nums = details['numbers'];
      if (nums is List) {
        _phoneNumbers = nums.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
      if (_phoneNumbers.isEmpty) {
        _phoneNumbers = [{'number': widget.number, 'type': 'Mobile'}];
      }

      // Find contactId for favorites
      final contacts = _contactService.cachedContacts;
      for (final c in contacts) {
        if ((c['name'] as String?) == widget.name) {
          _contactId = c['contactId']?.toString() ?? '';
          break;
        }
      }
      _isFavorite = _contactId.isNotEmpty && _favoritesService.isFavorite(_contactId);

      setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleFavorite() async {
    if (_contactId.isEmpty) return;
    await _favoritesService.toggleFavorite(_contactId);
    setState(() => _isFavorite = !_isFavorite);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: cs.surfaceContainerLow,
            actions: [
              IconButton(
                icon: Icon(
                  _isFavorite ? Icons.star_rounded : Icons.star_outline_rounded,
                  color: _isFavorite ? Colors.amber : cs.onSurfaceVariant,
                ),
                onPressed: _toggleFavorite,
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              title: Text(widget.name,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              centerTitle: false,
            ),
          ),
          SliverToBoxAdapter(
            child: Column(
              children: [
                const SizedBox(height: 16),
                Hero(
                  tag: 'avatar_${widget.name}',
                  child: ContactAvatar(name: widget.name, radius: 48),
                ),
                const SizedBox(height: 16),

                // Quick actions
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _quickAction(Icons.call_rounded, 'Call',
                          const Color(0xFF34A853),
                          () => _callService.makeCall(widget.number)),
                      _quickAction(Icons.message_rounded, 'Text', cs.primary,
                          () => _contactService.openSms(widget.number)),
                      _quickAction(Icons.videocam_rounded, 'Video', cs.primary,
                          () => _contactService.openVideoCall(widget.number)),
                      _quickAction(Icons.chat_rounded, 'WhatsApp',
                          const Color(0xFF25D366), () async {
                        final success = await _contactService.openWhatsApp(widget.number);
                        if (!success && mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('WhatsApp is not installed'),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                          );
                        }
                      }),
                    ],
                  ),
                ),

                const SizedBox(height: 24),
                const Divider(indent: 16, endIndent: 16),

                // Phone numbers section
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Contact info',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: cs.primary)),
                  ),
                ),

                if (_isLoading)
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  ..._phoneNumbers.map((phone) {
                    final num = phone['number'] as String? ?? '';
                    final type = phone['type'] as String? ?? 'Mobile';
                    return ListTile(
                      leading: Icon(Icons.call_rounded, color: cs.primary),
                      title: Text(num, style: const TextStyle(fontSize: 16)),
                      subtitle: Text(type,
                          style: TextStyle(
                              fontSize: 13, color: cs.onSurfaceVariant)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.call_rounded,
                                color: cs.primary, size: 20),
                            onPressed: () => _callService.makeCall(num),
                          ),
                          IconButton(
                            icon: Icon(Icons.message_rounded,
                                color: cs.primary, size: 20),
                            onPressed: () => _contactService.openSms(num),
                          ),
                        ],
                      ),
                      onTap: () => _callService.makeCall(num),
                    );
                  }),

                const SizedBox(height: 100),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _quickAction(
      IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
                shape: BoxShape.circle, color: color.withOpacity(0.12)),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 8),
          Text(label,
              style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}

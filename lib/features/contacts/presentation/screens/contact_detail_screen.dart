import 'package:flutter/material.dart';
import '../../../../services/call_service.dart';
import '../../../../services/contact_service.dart';
import '../../../../services/favorites_service.dart';
import '../../../../widgets/contact_avatar.dart';

class ContactDetailScreen extends StatefulWidget {
  final String name;
  final String number;
  final String? heroTag;

  const ContactDetailScreen({super.key, required this.name, required this.number, this.heroTag});

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
        _phoneNumbers = [
          {'number': widget.number, 'type': 'Mobile'},
        ];
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
      backgroundColor: cs.surface,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            stretch: true,
            elevation: 0,
            scrolledUnderElevation: 2,
            backgroundColor: cs.surface,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: () => Navigator.of(context).pop(),
            ),
            actions: [
              IconButton(
                icon: Icon(
                  _isFavorite ? Icons.star_rounded : Icons.star_outline_rounded,
                  color: _isFavorite ? Colors.amber : cs.onSurface,
                ),
                onPressed: _toggleFavorite,
              ),
            ],
            flexibleSpace: LayoutBuilder(
              builder: (context, constraints) {
                final double top = constraints.biggest.height;
                final double statusBarHeight = MediaQuery.of(context).padding.top;
                final double collapsedHeight = kToolbarHeight + statusBarHeight;
                final double percent = ((top - collapsedHeight) / (280 - collapsedHeight)).clamp(0.0, 1.0);

                return FlexibleSpaceBar(
                  centerTitle: true,
                  titlePadding: EdgeInsets.only(
                    bottom: 16 + (percent * 10),
                    left: 56,
                    right: 56,
                  ),
                  title: Opacity(
                    opacity: (1.0 - percent).clamp(0.0, 1.0),
                    child: Text(
                      widget.name,
                      style: TextStyle(
                        color: cs.onSurface,
                        fontWeight: FontWeight.w600,
                        fontSize: 18,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          cs.primaryContainer.withValues(alpha: 0.25),
                          cs.surface,
                        ],
                      ),
                    ),
                    child: Opacity(
                      opacity: percent,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(height: statusBarHeight + 16),
                          ContactAvatar(
                            name: widget.name,
                            radius: 54,
                            heroTag: widget.heroTag,
                          ),
                          const SizedBox(height: 16),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Text(
                              widget.name,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: cs.onSurface,
                                letterSpacing: -0.5,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            widget.number,
                            style: TextStyle(
                              fontSize: 14,
                              color: cs.onSurfaceVariant,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Quick actions capsule card
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Card(
                    elevation: 0,
                    color: cs.surfaceContainerLow,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                      side: BorderSide(
                        color: cs.outlineVariant.withValues(alpha: 0.4),
                        width: 1.0,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _quickAction(Icons.call_rounded, 'Call', cs.primary, () => _callService.makeCall(widget.number)),
                          _quickAction(Icons.message_rounded, 'Text', cs.primary, () => _contactService.openSms(widget.number)),
                          _quickAction(Icons.videocam_rounded, 'Video', cs.primary, () => _contactService.openVideoCall(widget.number)),
                          _quickAction(Icons.chat_rounded, 'WhatsApp', const Color(0xFF25D366), () async {
                            final messenger = ScaffoldMessenger.of(context);
                            final success = await _contactService.openWhatsApp(widget.number);
                            if (success) {
                              return;
                            }
                            if (!mounted) {
                              return;
                            }
                            messenger.showSnackBar(
                              SnackBar(
                                content: const Text('WhatsApp is not installed'),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Phone numbers section inside elegant card
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 8, bottom: 8),
                        child: Text(
                          'Contact info',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: cs.primary,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      Card(
                        elevation: 0,
                        color: cs.surfaceContainerLow,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                            color: cs.outlineVariant.withValues(alpha: 0.4),
                            width: 1.0,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Column(
                            children: [
                              if (_isLoading)
                                const Padding(
                                  padding: EdgeInsets.all(24),
                                  child: Center(
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                                )
                              else if (_phoneNumbers.isEmpty)
                                Padding(
                                  padding: const EdgeInsets.all(24),
                                  child: Center(
                                    child: Text(
                                      'No phone numbers found',
                                      style: TextStyle(color: cs.onSurfaceVariant),
                                    ),
                                  ),
                                )
                              else
                                ListView.separated(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  padding: EdgeInsets.zero,
                                  itemCount: _phoneNumbers.length,
                                  separatorBuilder: (context, index) => Divider(
                                    height: 1,
                                    indent: 56,
                                    endIndent: 16,
                                    color: cs.outlineVariant.withValues(alpha: 0.3),
                                  ),
                                  itemBuilder: (context, index) {
                                    final phone = _phoneNumbers[index];
                                    final num = phone['number'] as String? ?? '';
                                    final type = phone['type'] as String? ?? 'Mobile';
                                    return ListTile(
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                      leading: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: cs.primary.withValues(alpha: 0.1),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(Icons.phone_outlined, color: cs.primary, size: 20),
                                      ),
                                      title: Text(
                                        num,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                          color: cs.onSurface,
                                        ),
                                      ),
                                      subtitle: Text(
                                        type,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: cs.onSurfaceVariant,
                                        ),
                                      ),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: Container(
                                              padding: const EdgeInsets.all(6),
                                              decoration: BoxDecoration(
                                                color: cs.primary.withValues(alpha: 0.08),
                                                shape: BoxShape.circle,
                                              ),
                                              child: Icon(Icons.call_rounded, color: cs.primary, size: 18),
                                            ),
                                            onPressed: () => _callService.makeCall(num),
                                          ),
                                          IconButton(
                                            icon: Container(
                                              padding: const EdgeInsets.all(6),
                                              decoration: BoxDecoration(
                                                color: cs.primary.withValues(alpha: 0.08),
                                                shape: BoxShape.circle,
                                              ),
                                              child: Icon(Icons.message_rounded, color: cs.primary, size: 18),
                                            ),
                                            onPressed: () => _contactService.openSms(num),
                                          ),
                                        ],
                                      ),
                                      onTap: () => _callService.makeCall(num),
                                    );
                                  },
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 100),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _quickAction(IconData icon, String label, Color color, VoidCallback onTap) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withValues(alpha: isDark ? 0.18 : 0.08),
                  border: Border.all(
                    color: color.withValues(alpha: isDark ? 0.3 : 0.15),
                    width: 1,
                  ),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

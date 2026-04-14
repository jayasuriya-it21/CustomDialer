import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/call_service.dart';
import '../widgets/contact_avatar.dart';

class RecentsScreen extends StatefulWidget {
  const RecentsScreen({super.key});

  @override
  State<RecentsScreen> createState() => _RecentsScreenState();
}

class _RecentsScreenState extends State<RecentsScreen> with SingleTickerProviderStateMixin {
  final CallService _callService = CallService();
  List<Map<String, dynamic>> _allLogs = [];
  bool _isLoading = true;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadCallLogs();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadCallLogs() async {
    final logs = await _callService.getCallLog();
    if (mounted) {
      setState(() {
        _allLogs = logs;
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> get _filteredLogs {
    if (_tabController.index == 1) {
      return _allLogs.where((l) => l['type'] == 3 || l['type'] == 5).toList();
    }
    return _allLogs;
  }

  String _formatTime(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24 && date.day == now.day) return DateFormat.jm().format(date);
    if (diff.inDays < 2) return 'Yesterday';
    if (diff.inDays < 7) return DateFormat.EEEE().format(date);
    return DateFormat.MMMd().format(date);
  }

  String _formatDuration(int s) {
    if (s == 0) return '';
    final m = s ~/ 60;
    final sec = s % 60;
    if (m > 0) return '${m}m ${sec}s';
    return '${sec}s';
  }

  IconData _typeIcon(int t) {
    switch (t) {
      case 1:
        return Icons.call_received_rounded;
      case 2:
        return Icons.call_made_rounded;
      case 3:
        return Icons.call_missed_rounded;
      case 5:
        return Icons.call_missed_outgoing_rounded;
      default:
        return Icons.call_rounded;
    }
  }

  Color _typeColor(int t) {
    switch (t) {
      case 3:
      case 5:
        return Colors.red;
      case 2:
        return const Color(0xFF34A853);
      case 1:
        return const Color(0xFF1A73E8);
      default:
        return Theme.of(context).colorScheme.onSurfaceVariant;
    }
  }

  String _typeLabel(int t) {
    switch (t) {
      case 1:
        return 'Incoming';
      case 2:
        return 'Outgoing';
      case 3:
        return 'Missed';
      case 5:
        return 'Rejected';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      children: [
        // Filter tabs
        TabBar(
          controller: _tabController,
          onTap: (_) => setState(() {}),
          labelColor: cs.primary,
          unselectedLabelColor: cs.onSurfaceVariant,
          indicatorColor: cs.primary,
          indicatorSize: TabBarIndicatorSize.label,
          dividerHeight: 0,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Missed'),
          ],
        ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
              : _filteredLogs.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadCallLogs,
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                    padding: const EdgeInsets.only(top: 4),
                    itemCount: _filteredLogs.length,
                    itemBuilder: _buildLogItem,
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.call_rounded, size: 64, color: cs.onSurfaceVariant.withValues(alpha: 0.25)),
          const SizedBox(height: 16),
          Text('No recent calls', style: TextStyle(fontSize: 16, color: cs.onSurfaceVariant)),
        ],
      ),
    );
  }

  Widget _buildLogItem(BuildContext context, int index) {
    final log = _filteredLogs[index];
    final name = (log['name'] as String?) ?? '';
    final number = (log['number'] as String?) ?? '';
    final type = (log['type'] as int?) ?? 0;
    final date = (log['date'] as int?) ?? 0;
    final duration = (log['duration'] as int?) ?? 0;
    final displayName = name.isNotEmpty ? name : number;
    final isMissed = type == 3 || type == 5;
    final cs = Theme.of(context).colorScheme;

    return Dismissible(
      key: Key(log['id']?.toString() ?? index.toString()),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        color: Colors.red,
        child: const Icon(Icons.delete_rounded, color: Colors.white),
      ),
      onDismissed: (_) {
        final id = log['id']?.toString() ?? '';
        _allLogs.removeAt(_allLogs.indexOf(log));
        _callService.deleteCallLog(id);
        setState(() {});
      },
      child: ListTile(
        leading: ContactAvatar(name: displayName, radius: 22),
        title: Text(
          displayName,
          style: TextStyle(fontWeight: FontWeight.w500, fontSize: 15, color: isMissed ? Colors.red : null),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Row(
          children: [
            Icon(_typeIcon(type), size: 14, color: _typeColor(type)),
            const SizedBox(width: 4),
            Text(_typeLabel(type), style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
            if (duration > 0) ...[Text(' · ', style: TextStyle(color: cs.onSurfaceVariant)), Text(_formatDuration(duration), style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant))],
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_formatTime(date), style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
            const SizedBox(width: 4),
            IconButton(
              icon: Icon(Icons.call_rounded, size: 20, color: cs.primary),
              visualDensity: VisualDensity.compact,
              onPressed: () => _callService.makeCall(number),
            ),
          ],
        ),
        onTap: () => _showCallDetails(displayName, number, type, date, duration),
      ),
    );
  }

  void _showCallDetails(String name, String number, int type, int date, int duration) {
    final cs = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      backgroundColor: cs.surfaceContainerLow,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: cs.outlineVariant, borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                ContactAvatar(name: name, radius: 28),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text(number, style: TextStyle(fontSize: 14, color: cs.onSurfaceVariant)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _sheetAction(Icons.call_rounded, 'Call', const Color(0xFF34A853), () {
                  Navigator.pop(ctx);
                  _callService.makeCall(number);
                }),
                _sheetAction(Icons.message_rounded, 'Message', cs.primary, () => Navigator.pop(ctx)),
                _sheetAction(Icons.info_outline_rounded, 'Details', cs.primary, () => Navigator.pop(ctx)),
              ],
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _sheetAction(IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(shape: BoxShape.circle, color: color.withValues(alpha: 0.12)),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}

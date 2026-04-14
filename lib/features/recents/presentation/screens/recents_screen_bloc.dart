import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/di/service_locator.dart';
import '../../../contacts/presentation/screens/contact_detail_screen.dart';
import '../../../../services/call_service.dart';
import '../../../../services/contact_service.dart';
import '../../../../widgets/contact_avatar.dart';
import '../../../contacts/domain/entities/contact_entity.dart';
import '../../domain/entities/call_log_entity.dart';
import '../bloc/recents_bloc.dart';
import '../bloc/recents_event.dart';
import '../bloc/recents_state.dart';

class RecentsScreenBloc extends StatefulWidget {
  const RecentsScreenBloc({super.key});

  @override
  State<RecentsScreenBloc> createState() => _RecentsScreenBlocState();
}

class _RecentsScreenBlocState extends State<RecentsScreenBloc> with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late final TabController _tabController;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) {
      return;
    }
    final filter = _tabController.index == 1 ? RecentsFilter.missed : RecentsFilter.all;
    context.read<RecentsBloc>().add(RecentsFilterChanged(filter));
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return BlocProvider(
      create: (_) => getIt<RecentsBloc>()..add(const RecentsRequested()),
      child: BlocConsumer<RecentsBloc, RecentsState>(
        listenWhen: (previous, current) => previous.lastDeletedLog != current.lastDeletedLog && current.lastDeletedLog != null,
        listener: (context, state) {
          final log = state.lastDeletedLog;
          final index = state.lastDeletedIndex;
          if (log == null || index == null) {
            return;
          }

          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Call log deleted'),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              action: SnackBarAction(
                label: 'Undo',
                onPressed: () {
                  context.read<RecentsBloc>().add(RecentsRestoreRequested(log: log, index: index));
                },
              ),
            ),
          );
        },
        builder: (context, state) {
          final cs = Theme.of(context).colorScheme;

          if (state.isLoading) {
            return _buildLoadingPlaceholder(context);
          }

          return Column(
            children: [
              TabBar(
                controller: _tabController,
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
                child: RefreshIndicator(
                  onRefresh: () async {
                    context.read<RecentsBloc>().add(const RecentsRequested(forceRefresh: true));
                  },
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                    slivers: [
                      if (state.favorites.isNotEmpty && state.filter == RecentsFilter.all) SliverToBoxAdapter(child: _buildFavoritesStrip(context, state.favorites)),
                      if (state.visibleLogs.isEmpty) SliverFillRemaining(child: _buildEmptyState(context)) else SliverList(delegate: SliverChildBuilderDelegate((ctx, index) => _buildLogItem(context, state.visibleLogs[index]), childCount: state.visibleLogs.length)),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFavoritesStrip(BuildContext context, List<ContactEntity> favorites) {
    final cs = Theme.of(context).colorScheme;
    final callService = getIt<CallService>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Text(
            'Favourites',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: cs.primary, letterSpacing: 0.3),
          ),
        ),
        SizedBox(
          height: 90,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: favorites.length,
            itemBuilder: (_, i) {
              final contact = favorites[i];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: GestureDetector(
                  onTap: () => callService.makeCall(contact.number),
                  onLongPress: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ContactDetailScreen(name: contact.name, number: contact.number),
                      ),
                    );
                  },
                  child: SizedBox(
                    width: 64,
                    child: Column(
                      children: [
                        ContactAvatar(name: contact.name, radius: 24),
                        const SizedBox(height: 6),
                        Text(
                          contact.name.split(' ').first,
                          style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        Divider(height: 1, indent: 16, endIndent: 16, color: cs.outlineVariant.withValues(alpha: 0.3)),
      ],
    );
  }

  Widget _buildLoadingPlaceholder(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      children: List<Widget>.generate(8, (index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(color: cs.surfaceContainerHighest, shape: BoxShape.circle),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 14,
                      decoration: BoxDecoration(color: cs.surfaceContainerHighest, borderRadius: BorderRadius.circular(7)),
                    ),
                    const SizedBox(height: 8),
                    FractionallySizedBox(
                      widthFactor: 0.55,
                      child: Container(
                        height: 12,
                        decoration: BoxDecoration(color: cs.surfaceContainerHighest, borderRadius: BorderRadius.circular(6)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
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

  Widget _buildLogItem(BuildContext context, CallLogEntity log) {
    final cs = Theme.of(context).colorScheme;
    final callService = getIt<CallService>();

    return InkWell(
      onLongPress: () => _showContextMenu(context, log),
      child: ListTile(
        leading: ContactAvatar(name: log.displayName, radius: 22),
        title: Text(
          log.displayName,
          style: TextStyle(fontWeight: FontWeight.w500, fontSize: 15, color: log.isMissed ? Colors.red : null),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Row(
          children: [
            Icon(_typeIcon(log.type), size: 14, color: _typeColor(context, log.type)),
            const SizedBox(width: 4),
            Text(_typeLabel(log.type), style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
            if (log.duration > 0) ...[Text(' · ', style: TextStyle(color: cs.onSurfaceVariant)), Text(_formatDuration(log.duration), style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant))],
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_formatTime(log.date), style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
            const SizedBox(width: 4),
            IconButton(
              icon: Icon(Icons.call_rounded, size: 20, color: cs.primary),
              visualDensity: VisualDensity.compact,
              onPressed: () => callService.makeCall(log.number),
            ),
          ],
        ),
        onTap: () => _showCallDetails(context, log),
      ),
    );
  }

  void _showContextMenu(BuildContext context, CallLogEntity log) {
    final cs = Theme.of(context).colorScheme;
    final callService = getIt<CallService>();
    final contactService = getIt<ContactService>();

    showModalBottomSheet(
      context: context,
      backgroundColor: cs.surfaceContainerLow,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: cs.outlineVariant, borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.call_rounded),
              title: Text('Call ${log.displayName}'),
              onTap: () {
                Navigator.pop(sheetContext);
                callService.makeCall(log.number);
              },
            ),
            ListTile(
              leading: const Icon(Icons.message_rounded),
              title: const Text('Send message'),
              onTap: () {
                Navigator.pop(sheetContext);
                contactService.openSms(log.number);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded),
              title: const Text('Delete'),
              onTap: () {
                Navigator.pop(sheetContext);
                context.read<RecentsBloc>().add(RecentsDeleteRequested(log));
              },
            ),
            ListTile(
              leading: const Icon(Icons.block_rounded),
              title: const Text('Block number'),
              onTap: () {
                Navigator.pop(sheetContext);
                callService.openBlockedNumbers();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showCallDetails(BuildContext context, CallLogEntity log) {
    final cs = Theme.of(context).colorScheme;
    final callService = getIt<CallService>();
    final contactService = getIt<ContactService>();
    final dateObj = DateTime.fromMillisecondsSinceEpoch(log.date);
    final exactTime = DateFormat('EEEE, MMM d · h:mm a').format(dateObj);

    showModalBottomSheet(
      context: context,
      backgroundColor: cs.surfaceContainerLow,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheetContext) => Padding(
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
                ContactAvatar(name: log.displayName, radius: 28),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(log.displayName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text(log.number, style: TextStyle(fontSize: 14, color: cs.onSurfaceVariant)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(_typeIcon(log.type), size: 16, color: _typeColor(context, log.type)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('$exactTime${log.duration > 0 ? ' · ${_formatDuration(log.duration)}' : ''}', style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _sheetAction(context, Icons.call_rounded, 'Call', const Color(0xFF34A853), () {
                  Navigator.pop(sheetContext);
                  callService.makeCall(log.number);
                }),
                _sheetAction(context, Icons.message_rounded, 'Message', cs.primary, () {
                  Navigator.pop(sheetContext);
                  contactService.openSms(log.number);
                }),
                _sheetAction(context, Icons.info_outline_rounded, 'Details', cs.primary, () {
                  Navigator.pop(sheetContext);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ContactDetailScreen(name: log.displayName, number: log.number),
                    ),
                  );
                }),
              ],
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _sheetAction(BuildContext context, IconData icon, String label, Color color, VoidCallback onTap) {
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

  String _formatTime(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 1) {
      return 'Just now';
    }
    if (diff.inHours < 1) {
      return '${diff.inMinutes}m ago';
    }
    if (diff.inHours < 24 && date.day == now.day) {
      return DateFormat.jm().format(date);
    }
    if (diff.inDays < 2) {
      return 'Yesterday';
    }
    if (diff.inDays < 7) {
      return DateFormat.E().format(date);
    }
    return DateFormat.MMMd().format(date);
  }

  String _formatDuration(int seconds) {
    if (seconds == 0) {
      return '';
    }
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    if (minutes > 0) {
      return '${minutes}m ${secs}s';
    }
    return '${secs}s';
  }

  IconData _typeIcon(int type) {
    switch (type) {
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

  Color _typeColor(BuildContext context, int type) {
    switch (type) {
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

  String _typeLabel(int type) {
    switch (type) {
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
}

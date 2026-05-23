import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/di/service_locator.dart';
import '../../contacts/screen/contact_detail_screen.dart';
import '../../../../core/services/call_service.dart';
import '../../../../core/services/contact_service.dart';
import '../../../../core/widgets/contact_avatar.dart';
import '../../../../core/models/contact_entity.dart';
import '../../../../core/models/call_log_entity.dart';
import '../bloc/recents_bloc.dart';
import '../bloc/recents_event.dart';
import '../bloc/recents_state.dart';

class RecentsScreenBloc extends StatelessWidget {
  const RecentsScreenBloc({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<RecentsBloc>()..add(const RecentsRequested()),
      child: const _RecentsView(),
    );
  }
}

class _RecentsView extends StatefulWidget {
  const _RecentsView();

  @override
  State<_RecentsView> createState() => _RecentsViewState();
}

class _RecentsViewState extends State<_RecentsView> with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
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

    return BlocConsumer<RecentsBloc, RecentsState>(
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

          final groupedItems = state.groupedLogs;

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
                      if (state.favorites.isNotEmpty && state.filter == RecentsFilter.all)
                        SliverToBoxAdapter(child: _buildFavoritesStrip(context, state.favorites)),
                      if (groupedItems.isEmpty)
                        SliverFillRemaining(child: _buildEmptyState(context))
                      else
                        SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (ctx, index) {
                              final item = groupedItems[index];
                              if (item is HeaderItem) {
                                return _buildHeaderItem(context, item.title);
                              } else {
                                return _buildLogItem(context, (item as LogItem).log);
                              }
                            },
                            childCount: groupedItems.length,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      );
  }

  Widget _buildHeaderItem(BuildContext context, String title) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.bold,
              color: cs.primary.withValues(alpha: 0.8),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Divider(
              color: cs.outlineVariant.withValues(alpha: 0.15),
              thickness: 1,
            ),
          ),
        ],
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
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
          child: Text(
            'Favourites',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: cs.primary, letterSpacing: 0.3),
          ),
        ),
        SizedBox(
          height: 105,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            itemCount: favorites.length,
            itemBuilder: (_, i) {
              final contact = favorites[i];
              final heroTag = 'recents_fav_${contact.name}_${contact.number}';
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: GestureDetector(
                  onTap: () => callService.makeCall(contact.number),
                  onLongPress: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ContactDetailScreen(
                          name: contact.name,
                          number: contact.number,
                          heroTag: heroTag,
                        ),
                      ),
                    );
                  },
                  child: SizedBox(
                    width: 70,
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(2.5),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [
                                cs.primary.withValues(alpha: 0.8),
                                cs.tertiary.withValues(alpha: 0.8),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(1.5),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: cs.surface,
                            ),
                            child: ContactAvatar(
                              name: contact.name,
                              radius: 22,
                              heroTag: heroTag,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          contact.name.split(' ').first,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                            color: cs.onSurfaceVariant,
                          ),
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
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Divider(height: 1, color: cs.outlineVariant.withValues(alpha: 0.15)),
        ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final heroTag = 'recent_${log.id}_${log.date}';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Card(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: cs.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: cs.outlineVariant.withValues(alpha: isDark ? 0.08 : 0.15),
            width: 1,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showCallDetails(context, log),
          onLongPress: () => _showContextMenu(context, log),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Stack(
                  children: [
                    ContactAvatar(
                      name: log.displayName,
                      radius: 22,
                      heroTag: heroTag,
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.all(2.5),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _typeColor(context, log.type),
                          border: Border.all(color: cs.surfaceContainerLow, width: 1.5),
                        ),
                        child: Icon(
                          _typeIcon(log.type),
                          size: 9,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        log.displayName,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14.5,
                          color: log.isMissed ? cs.error : cs.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Text(
                            _typeLabel(log.type),
                            style: TextStyle(
                              fontSize: 12,
                              color: cs.onSurfaceVariant.withValues(alpha: 0.8),
                            ),
                          ),
                          if (log.duration > 0) ...[
                            Text(
                              ' · ',
                              style: TextStyle(color: cs.onSurfaceVariant.withValues(alpha: 0.6)),
                            ),
                            Text(
                              _formatDuration(log.duration),
                              style: TextStyle(
                                fontSize: 12,
                                color: cs.onSurfaceVariant.withValues(alpha: 0.8),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _formatTime(log.date),
                      style: TextStyle(
                        fontSize: 11,
                        color: cs.onSurfaceVariant.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 4),
                    GestureDetector(
                      onTap: () => callService.makeCall(log.number),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: cs.primary.withValues(alpha: 0.08),
                        ),
                        child: Icon(
                          Icons.call_rounded,
                          size: 16,
                          color: cs.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
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
    final heroTag = 'recent_${log.id}_${log.date}';

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
                ContactAvatar(name: log.displayName, radius: 28, heroTag: heroTag),
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
                      builder: (_) => ContactDetailScreen(
                        name: log.displayName,
                        number: log.number,
                        heroTag: heroTag,
                      ),
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

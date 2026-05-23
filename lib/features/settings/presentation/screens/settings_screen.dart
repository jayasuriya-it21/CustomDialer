import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../theme/theme_provider.dart';
import '../../../recordings/presentation/screens/recordings_screen.dart';
import '../bloc/settings_cubit.dart';
import '../bloc/settings_state.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final SettingsCubit _settingsCubit;

  @override
  void initState() {
    super.initState();
    _settingsCubit = getIt<SettingsCubit>();
    _settingsCubit.initialize();
  }

  @override
  void dispose() {
    _settingsCubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return BlocProvider.value(
      value: _settingsCubit,
      child: BlocBuilder<SettingsCubit, SettingsState>(
        builder: (context, state) => Scaffold(
          backgroundColor: cs.surface,
          appBar: AppBar(
            title: const Text(
              'Settings',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 20),
            ),
            backgroundColor: cs.surface,
            elevation: 0,
            scrolledUnderElevation: 2,
          ),
          body: ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 32),
            children: [
              // ---- Calling ----
              _sectionHeader('Calling'),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: _buildGroupedCard(
                  context,
                  [
                    if (state.sims.isNotEmpty)
                      _buildTile(
                        context: context,
                        icon: Icons.sim_card_rounded,
                        title: 'SIM cards',
                        subtitle: '${state.sims.length} SIM${state.sims.length > 1 ? 's' : ''} detected',
                        onTap: () => _showSimInfo(state.sims),
                      )
                    else
                      const SizedBox.shrink(),
                    _buildTile(
                      context: context,
                      icon: Icons.call_missed_outgoing_rounded,
                      title: 'Call forwarding',
                      subtitle: 'Manage redirected calls',
                      onTap: () => _settingsCubit.openCallForwardingSettings(),
                    ),
                    _buildTile(
                      context: context,
                      icon: Icons.block_rounded,
                      title: 'Blocked numbers',
                      subtitle: 'Manage blocked callers',
                      onTap: () => _settingsCubit.openBlockedNumbers(),
                    ),
                    _buildTile(
                      context: context,
                      icon: Icons.phone_in_talk_rounded,
                      title: 'Default dialer',
                      subtitle: 'Set as default phone app',
                      onTap: () => _settingsCubit.requestDefaultDialer(),
                    ),
                  ],
                ),
              ),

              // ---- Sounds ----
              _sectionHeader('Sounds & vibration'),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: _buildGroupedCard(
                  context,
                  [
                    _buildTile(
                      context: context,
                      icon: Icons.music_note_rounded,
                      title: 'Ringtone',
                      subtitle: 'Choose your ringtone',
                      onTap: () => _settingsCubit.openRingtonePicker(),
                    ),
                  ],
                ),
              ),

              // ---- Recording ----
              _sectionHeader('Call recording'),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildGroupedCard(
                      context,
                      [
                        _buildSwitchTile(
                          context: context,
                          icon: Icons.fiber_manual_record_rounded,
                          title: 'Auto-record calls',
                          subtitle: 'Automatically start recording when call connects',
                          value: state.autoRecord,
                          onChanged: (v) => _settingsCubit.setAutoRecord(v),
                        ),
                        _buildTile(
                          context: context,
                          icon: Icons.playlist_play_rounded,
                          title: 'Recordings',
                          subtitle: 'View and manage call recordings',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const RecordingsScreen(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                      child: Text(
                        'Recording uses the microphone. On Android 10+, recording may not capture the other party\'s voice on all devices.',
                        style: TextStyle(
                          fontSize: 11,
                          color: cs.onSurfaceVariant.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ---- Appearance ----
              _sectionHeader('Appearance'),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: _buildGroupedCard(
                  context,
                  [
                    _buildTile(
                      context: context,
                      icon: Icons.brightness_6_rounded,
                      title: 'Theme mode',
                      subtitle: _themeModeLabel(state.themeMode),
                      onTap: () => _showThemePicker(state),
                    ),
                    _buildSwitchTile(
                      context: context,
                      icon: Icons.color_lens_rounded,
                      title: 'Dynamic color',
                      subtitle: 'Match theme with your wallpaper (Android 12+)',
                      value: state.useDynamicColor,
                      onChanged: (v) => _settingsCubit.setUseDynamicColor(v),
                    ),
                    if (!state.useDynamicColor)
                      _buildTile(
                        context: context,
                        icon: Icons.palette_rounded,
                        title: 'Accent colour',
                        subtitle: 'Choose your theme colour',
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: state.seedColor,
                                border: Border.all(
                                  color: cs.onSurface.withValues(alpha: 0.2),
                                  width: 1,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              Icons.chevron_right_rounded,
                              color: cs.onSurfaceVariant.withValues(alpha: 0.7),
                              size: 20,
                            ),
                          ],
                        ),
                        onTap: () => _showColorPicker(state),
                      )
                    else
                      const SizedBox.shrink(),
                  ],
                ),
              ),

              // ---- About ----
              _sectionHeader('About'),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: _buildGroupedCard(
                  context,
                  [
                    _buildTile(
                      context: context,
                      icon: Icons.info_outline_rounded,
                      title: 'Phone',
                      subtitle: 'Version 1.0.0',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 16, 28, 6),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: cs.primary,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildGroupedCard(BuildContext context, List<Widget> children) {
    final cs = Theme.of(context).colorScheme;
    final activeChildren = children.where((w) => w is! SizedBox).toList();

    return Card(
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
          children: List.generate(activeChildren.length * 2 - 1, (index) {
            if (index.isOdd) {
              return Divider(
                height: 1,
                indent: 56,
                endIndent: 16,
                color: cs.outlineVariant.withValues(alpha: 0.3),
              );
            }
            return activeChildren[index ~/ 2];
          }),
        ),
      ),
    );
  }

  Widget _buildTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    final cs = Theme.of(context).colorScheme;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: cs.primary.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: cs.primary, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
      ),
      trailing: trailing ?? (onTap != null
          ? Icon(
              Icons.chevron_right_rounded,
              color: cs.onSurfaceVariant.withValues(alpha: 0.7),
              size: 20,
            )
          : null),
      onTap: onTap,
    );
  }

  Widget _buildSwitchTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final cs = Theme.of(context).colorScheme;
    return SwitchListTile.adaptive(
      contentPadding: const EdgeInsets.only(left: 16, right: 8, top: 4, bottom: 4),
      secondary: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: cs.primary.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: cs.primary, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
      ),
      value: value,
      onChanged: onChanged,
    );
  }

  String _themeModeLabel(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return 'System default';
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
    }
  }

  void _showSimInfo(List<Map<String, dynamic>> sims) {
    final cs = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      backgroundColor: cs.surfaceContainerLow,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: cs.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'SIM Cards',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            ...sims.map(
              (sim) => ListTile(
                leading: CircleAvatar(
                  backgroundColor: cs.primaryContainer,
                  child: Text(
                    '${(sim['slot'] as int? ?? 0) + 1}',
                    style: TextStyle(
                      color: cs.onPrimaryContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                title: Text(sim['carrier'] as String? ?? 'SIM'),
                subtitle: Text(sim['number'] as String? ?? 'No number'),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showThemePicker(SettingsState state) {
    final cs = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      backgroundColor: cs.surfaceContainerLow,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: cs.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Theme mode',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            ...ThemeMode.values.map(
              (mode) => ListTile(
                leading: Icon(
                  state.themeMode == mode
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_unchecked_rounded,
                  color: state.themeMode == mode ? cs.primary : cs.onSurfaceVariant,
                ),
                title: Text(_themeModeLabel(mode)),
                onTap: () {
                  _settingsCubit.setThemeMode(mode);
                  Navigator.pop(context);
                },
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showColorPicker(SettingsState state) {
    final cs = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      backgroundColor: cs.surfaceContainerLow,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: cs.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Accent colour',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: ThemeProvider.presetColors.map((color) {
                final isSelected = state.seedColor.toARGB32() == color.toARGB32();
                return GestureDetector(
                  onTap: () {
                    _settingsCubit.setSeedColor(color);
                    Navigator.pop(context);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color,
                      border: isSelected
                          ? Border.all(color: cs.onSurface, width: 3)
                          : null,
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: color.withValues(alpha: 0.4),
                                blurRadius: 8,
                                spreadRadius: 1,
                              )
                            ]
                          : null,
                    ),
                    child: isSelected
                        ? const Icon(Icons.check_rounded, color: Colors.white, size: 22)
                        : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

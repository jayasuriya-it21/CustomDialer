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
          appBar: AppBar(title: const Text('Settings'), backgroundColor: cs.surface, surfaceTintColor: Colors.transparent),
          body: ListView(
            children: [
              // ---- Calling ----
              _sectionHeader('Calling'),

              if (state.sims.isNotEmpty)
                ListTile(
                  leading: Icon(Icons.sim_card_rounded, color: cs.primary),
                  title: const Text('SIM cards'),
                  subtitle: Text('${state.sims.length} SIM${state.sims.length > 1 ? 's' : ''} detected'),
                  onTap: () => _showSimInfo(state.sims),
                ),

              ListTile(
                leading: Icon(Icons.call_missed_outgoing_rounded, color: cs.primary),
                title: const Text('Call forwarding'),
                subtitle: const Text('Manage redirected calls'),
                onTap: () => _settingsCubit.openCallForwardingSettings(),
              ),

              ListTile(
                leading: Icon(Icons.block_rounded, color: cs.primary),
                title: const Text('Blocked numbers'),
                subtitle: const Text('Manage blocked callers'),
                onTap: () => _settingsCubit.openBlockedNumbers(),
              ),

              ListTile(
                leading: Icon(Icons.phone_in_talk_rounded, color: cs.primary),
                title: const Text('Default dialer'),
                subtitle: const Text('Set as default phone app'),
                onTap: () => _settingsCubit.requestDefaultDialer(),
              ),

              const Divider(indent: 16, endIndent: 16),

              // ---- Sounds ----
              _sectionHeader('Sounds & vibration'),

              ListTile(
                leading: Icon(Icons.music_note_rounded, color: cs.primary),
                title: const Text('Ringtone'),
                subtitle: const Text('Choose your ringtone'),
                onTap: () => _settingsCubit.openRingtonePicker(),
              ),

              const Divider(indent: 16, endIndent: 16),

              // ---- Recording ----
              _sectionHeader('Call recording'),

              SwitchListTile.adaptive(
                secondary: Icon(Icons.fiber_manual_record_rounded, color: cs.primary),
                title: const Text('Auto-record calls'),
                subtitle: const Text('Automatically start recording when call connects'),
                value: state.autoRecord,
                onChanged: (v) => _settingsCubit.setAutoRecord(v),
              ),

              ListTile(
                leading: Icon(Icons.playlist_play_rounded, color: cs.primary),
                title: const Text('Recordings'),
                subtitle: const Text('View and manage call recordings'),
                trailing: Icon(Icons.chevron_right_rounded, color: cs.onSurfaceVariant),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RecordingsScreen())),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Text('Recording uses the microphone. On Android 10+, recording may not capture the other party\'s voice on all devices.', style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant.withValues(alpha: 0.6))),
              ),

              const Divider(indent: 16, endIndent: 16),

              // ---- Appearance ----
              _sectionHeader('Appearance'),

              ListTile(
                leading: Icon(Icons.brightness_6_rounded, color: cs.primary),
                title: const Text('Theme mode'),
                subtitle: Text(_themeModeLabel(state.themeMode)),
                onTap: () => _showThemePicker(state),
              ),

              SwitchListTile.adaptive(
                secondary: Icon(Icons.color_lens_rounded, color: cs.primary),
                title: const Text('Dynamic color'),
                subtitle: const Text('Match theme with your wallpaper (Android 12+)'),
                value: state.useDynamicColor,
                onChanged: (v) => _settingsCubit.setUseDynamicColor(v),
              ),

              if (!state.useDynamicColor)
                ListTile(
                  leading: Icon(Icons.palette_rounded, color: cs.primary),
                  title: const Text('Accent colour'),
                  subtitle: const Text('Choose your theme colour'),
                  trailing: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: state.seedColor),
                  ),
                  onTap: () => _showColorPicker(state),
                ),

              const Divider(indent: 16, endIndent: 16),

              // ---- About ----
              _sectionHeader('About'),

              ListTile(
                leading: Icon(Icons.info_outline_rounded, color: cs.primary),
                title: const Text('Phone'),
                subtitle: const Text('Version 1.0.0'),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title,
        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: cs.primary, letterSpacing: 0.2),
      ),
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
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
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
                decoration: BoxDecoration(color: cs.outlineVariant, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 20),
            const Text('SIM Cards', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            ...sims.map(
              (sim) => ListTile(
                leading: CircleAvatar(
                  backgroundColor: cs.primaryContainer,
                  child: Text(
                    '${(sim['slot'] as int? ?? 0) + 1}',
                    style: TextStyle(color: cs.onPrimaryContainer, fontWeight: FontWeight.w600),
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
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
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
                decoration: BoxDecoration(color: cs.outlineVariant, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Theme mode', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            ...ThemeMode.values.map(
              (mode) => ListTile(
                leading: Icon(state.themeMode == mode ? Icons.radio_button_checked_rounded : Icons.radio_button_unchecked_rounded, color: state.themeMode == mode ? cs.primary : cs.onSurfaceVariant),
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
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
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
                decoration: BoxDecoration(color: cs.outlineVariant, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Accent colour', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
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
                      border: isSelected ? Border.all(color: cs.onSurface, width: 3) : null,
                      boxShadow: isSelected ? [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 8, spreadRadius: 1)] : null,
                    ),
                    child: isSelected ? const Icon(Icons.check_rounded, color: Colors.white, size: 22) : null,
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

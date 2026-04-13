import 'package:flutter/material.dart';
import '../theme/theme_provider.dart';
import '../services/call_service.dart';
import '../services/recording_service.dart';
import 'recordings_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final ThemeProvider _theme = ThemeProvider();
  final CallService _callService = CallService();
  final RecordingService _recordingService = RecordingService();
  bool _autoRecord = false;
  List<Map<String, dynamic>> _sims = [];

  @override
  void initState() {
    super.initState();
    _theme.addListener(_refresh);
    _loadSettings();
  }

  @override
  void dispose() {
    _theme.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  Future<void> _loadSettings() async {
    _autoRecord = await _recordingService.autoRecordEnabled;
    _sims = await _callService.getSimInfo();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: cs.surface,
        surfaceTintColor: Colors.transparent,
      ),
      body: ListView(
        children: [
          // ---- Calling ----
          _sectionHeader('Calling'),

          if (_sims.isNotEmpty)
            ListTile(
              leading: Icon(Icons.sim_card_rounded, color: cs.primary),
              title: const Text('SIM cards'),
              subtitle: Text('${_sims.length} SIM${_sims.length > 1 ? 's' : ''} detected'),
              onTap: () => _showSimInfo(),
            ),

          ListTile(
            leading: Icon(Icons.call_missed_outgoing_rounded, color: cs.primary),
            title: const Text('Call forwarding'),
            subtitle: const Text('Manage redirected calls'),
            onTap: () => _callService.openCallForwardingSettings(),
          ),

          ListTile(
            leading: Icon(Icons.block_rounded, color: cs.primary),
            title: const Text('Blocked numbers'),
            subtitle: const Text('Manage blocked callers'),
            onTap: () => _callService.openBlockedNumbers(),
          ),

          ListTile(
            leading: Icon(Icons.phone_in_talk_rounded, color: cs.primary),
            title: const Text('Default dialer'),
            subtitle: const Text('Set as default phone app'),
            onTap: () => _callService.requestDefaultDialer(),
          ),

          const Divider(indent: 16, endIndent: 16),

          // ---- Sounds ----
          _sectionHeader('Sounds & vibration'),

          ListTile(
            leading: Icon(Icons.music_note_rounded, color: cs.primary),
            title: const Text('Ringtone'),
            subtitle: const Text('Choose your ringtone'),
            onTap: () => _callService.openRingtonePicker(),
          ),

          const Divider(indent: 16, endIndent: 16),

          // ---- Recording ----
          _sectionHeader('Call recording'),

          SwitchListTile.adaptive(
            secondary: Icon(Icons.fiber_manual_record_rounded, color: cs.primary),
            title: const Text('Auto-record calls'),
            subtitle: const Text('Automatically start recording when call connects'),
            value: _autoRecord,
            onChanged: (v) async {
              await _recordingService.setAutoRecord(v);
              setState(() => _autoRecord = v);
            },
          ),

          ListTile(
            leading: Icon(Icons.playlist_play_rounded, color: cs.primary),
            title: const Text('Recordings'),
            subtitle: const Text('View and manage call recordings'),
            trailing: Icon(Icons.chevron_right_rounded, color: cs.onSurfaceVariant),
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const RecordingsScreen())),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Text(
              'Recording uses the microphone. On Android 10+, recording may not capture the other party\'s voice on all devices.',
              style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant.withOpacity(0.6)),
            ),
          ),

          const Divider(indent: 16, endIndent: 16),

          // ---- Appearance ----
          _sectionHeader('Appearance'),

          ListTile(
            leading: Icon(Icons.brightness_6_rounded, color: cs.primary),
            title: const Text('Theme mode'),
            subtitle: Text(_themeModeLabel(_theme.themeMode)),
            onTap: () => _showThemePicker(),
          ),

          SwitchListTile.adaptive(
            secondary: Icon(Icons.color_lens_rounded, color: cs.primary),
            title: const Text('Dynamic color'),
            subtitle: const Text('Match theme with your wallpaper (Android 12+)'),
            value: _theme.useDynamicColor,
            onChanged: (v) {
              _theme.setUseDynamicColor(v);
              setState(() {});
            },
          ),

          if (!_theme.useDynamicColor)
            ListTile(
              leading: Icon(Icons.palette_rounded, color: cs.primary),
              title: const Text('Accent colour'),
              subtitle: const Text('Choose your theme colour'),
              trailing: Container(
                width: 28, height: 28,
                decoration: BoxDecoration(
                    shape: BoxShape.circle, color: _theme.seedColor),
              ),
              onTap: () => _showColorPicker(),
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
    );
  }

  Widget _sectionHeader(String title) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(title,
          style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: cs.primary,
              letterSpacing: 0.2)),
    );
  }

  String _themeModeLabel(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system: return 'System default';
      case ThemeMode.light: return 'Light';
      case ThemeMode.dark: return 'Dark';
    }
  }

  void _showSimInfo() {
    final cs = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      backgroundColor: cs.surfaceContainerLow,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(
                color: cs.outlineVariant,
                borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 20),
            const Text('SIM Cards',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            ..._sims.map((sim) => ListTile(
                  leading: CircleAvatar(
                    backgroundColor: cs.primaryContainer,
                    child: Text('${(sim['slot'] as int? ?? 0) + 1}',
                        style: TextStyle(color: cs.onPrimaryContainer, fontWeight: FontWeight.w600)),
                  ),
                  title: Text(sim['carrier'] as String? ?? 'SIM'),
                  subtitle: Text(sim['number'] as String? ?? 'No number'),
                )),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showThemePicker() {
    final cs = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      backgroundColor: cs.surfaceContainerLow,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(
                color: cs.outlineVariant,
                borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 20),
            const Text('Theme mode',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            ...ThemeMode.values.map((mode) => RadioListTile<ThemeMode>(
                  value: mode,
                  groupValue: _theme.themeMode,
                  title: Text(_themeModeLabel(mode)),
                  onChanged: (v) {
                    if (v != null) _theme.setThemeMode(v);
                    Navigator.pop(context);
                  },
                )),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showColorPicker() {
    final cs = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      backgroundColor: cs.surfaceContainerLow,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(
                color: cs.outlineVariant,
                borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 20),
            const Text('Accent colour',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 20),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: ThemeProvider.presetColors.map((color) {
                final isSelected = _theme.seedColor.value == color.value;
                return GestureDetector(
                  onTap: () {
                    _theme.setSeedColor(color);
                    Navigator.pop(context);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 48, height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color,
                      border: isSelected
                          ? Border.all(color: cs.onSurface, width: 3)
                          : null,
                      boxShadow: isSelected
                          ? [BoxShadow(color: color.withOpacity(0.4),
                              blurRadius: 8, spreadRadius: 1)]
                          : null,
                    ),
                    child: isSelected
                        ? const Icon(Icons.check_rounded,
                            color: Colors.white, size: 22)
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

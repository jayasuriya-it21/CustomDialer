import 'package:flutter/material.dart';
import '../theme/theme_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final ThemeProvider _theme = ThemeProvider();

  @override
  void initState() {
    super.initState();
    _theme.addListener(_refresh);
  }

  @override
  void dispose() {
    _theme.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings'), backgroundColor: cs.surface),
      body: ListView(
        children: [
          const SizedBox(height: 8),

          // Theme section
          _sectionHeader('Appearance'),

          // Theme Mode
          ListTile(
            leading: Icon(Icons.brightness_6_rounded, color: cs.primary),
            title: const Text('Theme mode'),
            subtitle: Text(_themeModeLabel(_theme.themeMode)),
            onTap: () => _showThemePicker(),
          ),

          // Accent Color
          ListTile(
            leading: Icon(Icons.palette_rounded, color: cs.primary),
            title: const Text('Accent colour'),
            subtitle: const Text('Choose your theme colour'),
            trailing: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(shape: BoxShape.circle, color: _theme.seedColor),
            ),
            onTap: () => _showColorPicker(),
          ),

          const Divider(indent: 16, endIndent: 16),

          // About section
          _sectionHeader('About'),
          ListTile(
            leading: Icon(Icons.info_outline_rounded, color: cs.primary),
            title: const Text('Google Dialer Clone'),
            subtitle: const Text('Version 1.0.0'),
          ),
          ListTile(
            leading: Icon(Icons.call_rounded, color: cs.primary),
            title: const Text('Default dialer'),
            subtitle: const Text('Set as default phone app'),
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title,
        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: cs.primary),
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

  void _showThemePicker() {
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
            ...ThemeMode.values.map((mode) {
              final isSelected = _theme.themeMode == mode;
              return ListTile(
                title: Text(_themeModeLabel(mode)),
                trailing: isSelected ? Icon(Icons.check_rounded, color: cs.primary) : null,
                onTap: () {
                  _theme.setThemeMode(mode);
                  Navigator.pop(context);
                },
              );
            }),
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
                final isSelected = _theme.seedColor.toARGB32() == color.toARGB32();
                return GestureDetector(
                  onTap: () {
                    _theme.setSeedColor(color);
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

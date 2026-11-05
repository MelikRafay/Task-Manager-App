import 'package:flutter/material.dart';

import '../state/app_state.dart';
import '../utils/constants.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text('Theme', style: text.titleMedium),
              const SizedBox(height: 10),
              SegmentedButton<ThemeMode>(
                segments: const [
                  ButtonSegment(
                      value: ThemeMode.light,
                      icon: Icon(Icons.light_mode_outlined),
                      label: Text('Light')),
                  ButtonSegment(
                      value: ThemeMode.dark,
                      icon: Icon(Icons.dark_mode_outlined),
                      label: Text('Dark')),
                  ButtonSegment(
                      value: ThemeMode.system,
                      icon: Icon(Icons.brightness_auto_outlined),
                      label: Text('System')),
                ],
                selected: {state.themeMode},
                onSelectionChanged: (s) => state.setThemeMode(s.first),
              ),
              const SizedBox(height: 28),
              Text('Notification sound', style: text.titleMedium),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                children: [
                  for (final e in kSoundOptions.entries)
                    ChoiceChip(
                      label: Text(e.value),
                      selected: state.soundId == e.key,
                      onSelected: (_) => state.setSound(e.key),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await state.sendTestNotification();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Test notification sent')));
                    }
                  },
                  icon: const Icon(Icons.notifications_active_outlined),
                  label: const Text('Send test notification'),
                ),
              ),
              const SizedBox(height: 28),
              Text(
                'Reminders fire at each task\'s due time. On Android/iOS they are '
                'scheduled with the system; in the browser they are shown while '
                'this tab is open (allow browser notifications when asked).',
                style: text.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

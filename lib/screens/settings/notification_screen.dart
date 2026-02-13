import 'package:anidong/utils/app_colors.dart';
import 'package:anidong/widgets/glass_card.dart';
import 'package:flutter/material.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  bool _newEpisodes = true;
  bool _appUpdates = true;
  bool _promotions = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Notifications', style: TextStyle(color: Theme.of(context).textTheme.titleLarge?.color, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: Theme.of(context).iconTheme.color),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 8.0, bottom: 8.0),
              child: Text(
                'PREFERENCES',
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodySmall?.color,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                ),
              ),
            ),
            GlassCard(
              child: Column(
                children: [
                  _buildSwitchTile(
                    'New Episodes',
                    'Get notified when new episodes apply',
                    _newEpisodes,
                    (val) => setState(() => _newEpisodes = val),
                  ),
                  Divider(color: Theme.of(context).dividerColor, height: 1),
                  _buildSwitchTile(
                    'App Updates',
                    'Receive updates about new features',
                    _appUpdates,
                    (val) => setState(() => _appUpdates = val),
                  ),
                  Divider(color: Theme.of(context).dividerColor, height: 1),
                  _buildSwitchTile(
                    'Promotions',
                    'Get offers and special events',
                    _promotions,
                    (val) => setState(() => _promotions = val),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchTile(String title, String subtitle, bool value, ValueChanged<bool> onChanged) {
    return SwitchListTile(
      title: Text(title, style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color, fontWeight: FontWeight.w600, fontSize: 16)),
      subtitle: Text(subtitle, style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color, fontSize: 13)),
      value: value,
      onChanged: onChanged,
      thumbColor: WidgetStateProperty.resolveWith<Color?>((states) {
        if (states.contains(WidgetState.selected)) {
          return AppColors.accent;
        }
        return Colors.grey.shade400;
      }),
      activeTrackColor: AppColors.accent.withValues(alpha: 0.3),
      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
    );
  }
}

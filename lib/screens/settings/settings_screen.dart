// lib/screens/settings/settings_screen.dart

import 'package:anidong/widgets/glass_card.dart';
import 'package:flutter/material.dart';
import 'package:anidong/utils/app_colors.dart';


class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _selectedQuality = 'Auto';
  bool _newEpisodesNotification = true;
  bool _wifiOnlyDownload = true;
  bool _autoDownload = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          Container(
            height: MediaQuery.of(context).size.height * 0.3,
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.accent, AppColors.orangeAccent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          SingleChildScrollView(
            child: SafeArea(
              bottom: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16.0, 56.0, 16.0, 24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('⚙️ Settings', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primaryText)),
                        const SizedBox(height: 4),
                        Text('Customize your experience', style: TextStyle(fontSize: 14, color: AppColors.primaryText.withValues(alpha: 0.8))),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildVideoQualityCard(),
                        const SizedBox(height: 24),
                        _buildNotificationsCard(),
                        const SizedBox(height: 24),
                        _buildDownloadSettingsCard(),
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoQualityCard() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Video Quality', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primaryText)),
          const SizedBox(height: 8),
          _buildRadioTile('Auto'),
          _buildRadioTile('1080p'),
          _buildRadioTile('720p'),
        ],
      ),
    );
  }

  Widget _buildRadioTile(String value) {
    return RadioListTile<String>(
      title: Text(value, style: const TextStyle(color: AppColors.primaryText)),
      value: value,
      groupValue: _selectedQuality,
      onChanged: (newValue) {
        if (newValue != null) {
          setState(() { _selectedQuality = newValue; });
        }
      },
      activeColor: AppColors.accent,
      contentPadding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _buildNotificationsCard() {
    return GlassCard(
      child: SwitchListTile(
        title: const Text('New Episodes', style: TextStyle(fontSize: 16, color: AppColors.primaryText, fontWeight: FontWeight.w600)),
        value: _newEpisodesNotification,
        onChanged: (bool value) {
          setState(() { _newEpisodesNotification = value; });
        },
        activeColor: AppColors.accent,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
    );
  }

  Widget _buildDownloadSettingsCard() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
            child: Text('Download Settings', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primaryText)),
          ),
          _buildSwitchTile(
            title: 'WiFi only',
            subtitle: 'Download only on WiFi',
            value: _wifiOnlyDownload,
            onChanged: (bool value) {
              setState(() { _wifiOnlyDownload = value; });
            },
          ),
          Divider(color: Colors.white.withValues(alpha: 0.1), height: 1),
          _buildSwitchTile(
            title: 'Auto Download',
            subtitle: 'Automatically download new episodes',
            value: _autoDownload,
            onChanged: (bool value) {
              setState(() { _autoDownload = value; });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 16, color: AppColors.primaryText, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(subtitle, style: TextStyle(color: AppColors.secondaryText, fontSize: 13)),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.accent,
          ),
        ],
      ),
    );
  }
}

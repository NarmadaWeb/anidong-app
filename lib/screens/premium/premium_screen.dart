// lib/screens/premium/premium_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_boxicons/flutter_boxicons.dart';
import 'package:anidong/utils/app_colors.dart';
import 'package:anidong/widgets/glass_card.dart';

class PremiumScreen extends StatelessWidget {
  const PremiumScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.primaryText),
      ),
      extendBodyBehindAppBar: true,
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
                  // PERBAIKAN: Menghapus `const` dari Padding ini
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16.0, 24.0, 16.0, 24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '👑 Go Premium',
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primaryText),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Unlock the ultimate anime experience',
                          style: TextStyle(fontSize: 14, color: AppColors.primaryText.withValues(alpha: 0.8)),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildPremiumFeatures(),
                        const SizedBox(height: 32),
                        _buildPlanOptions(),
                        const SizedBox(height: 32),
                        _buildTrialInfo(),
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

  // Sisa kode tidak berubah...
  Widget _buildPremiumFeatures() {
    return Column(
      children: [
        _buildFeatureItem(
          icon: Boxicons.bx_check_circle, iconColor: AppColors.green500,
          title: 'Ad-Free Experience', subtitle: 'Watch without interruptions',
        ),
        const SizedBox(height: 12),
        _buildFeatureItem(
          icon: Boxicons.bx_film, iconColor: AppColors.blue500,
          title: '4K Ultra HD', subtitle: 'Premium video quality',
        ),
        const SizedBox(height: 12),
        _buildFeatureItem(
          icon: Boxicons.bx_download, iconColor: AppColors.purple500,
          title: 'Offline Downloads', subtitle: 'Watch anywhere, anytime',
        ),
        const SizedBox(height: 12),
        _buildFeatureItem(
          icon: Boxicons.bx_time_five, iconColor: AppColors.yellow400,
          title: 'Early Access', subtitle: 'Watch episodes before everyone',
        ),
      ],
    );
  }

  Widget _buildFeatureItem({ required IconData icon, required Color iconColor, required String title, required String subtitle}) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(icon, size: 28, color: iconColor),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryText, fontSize: 16)),
                const SizedBox(height: 2),
                Text(subtitle, style: TextStyle(fontSize: 14, color: AppColors.secondaryText)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Choose Your Plan', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primaryText)),
        const SizedBox(height: 24),
        GlassCard(
          padding: const EdgeInsets.all(20),
          border: Border.all(color: AppColors.darkSurface),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Monthly', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryText, fontSize: 18)),
                  Text('\$9.99', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.accent)),
                ],
              ),
              const SizedBox(height: 8),
              Text('Perfect for trying out premium features', style: TextStyle(fontSize: 14, color: AppColors.secondaryText)),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent, foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Start Monthly Plan', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Stack(
          clipBehavior: Clip.none,
          children: [
            GlassCard(
              padding: const EdgeInsets.all(20),
              border: Border.all(color: AppColors.accent, width: 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Yearly', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryText, fontSize: 18)),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('\$79.99', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.accent)),
                          Text('\$119.88', style: TextStyle(fontSize: 12, color: AppColors.secondaryText, decoration: TextDecoration.lineThrough)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('Save 33% with annual billing', style: TextStyle(fontSize: 14, color: AppColors.secondaryText)),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent, foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Start Yearly Plan', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: -14, left: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(color: AppColors.accent, borderRadius: BorderRadius.circular(9999)),
                child: const Text('MOST POPULAR', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTrialInfo() {
    return Center(child: Text('7-day free trial • Cancel anytime • No hidden fees', style: TextStyle(fontSize: 13, color: AppColors.secondaryText)));
  }
}

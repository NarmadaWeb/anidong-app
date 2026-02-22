import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService {
  static final AdService instance = AdService._internal();

  factory AdService() {
    return instance;
  }

  AdService._internal();

  RewardedAd? _rewardedAd;
  bool _hasWatchedAdSession = false;
  bool _isAdLoading = false;

  // Real Ad Unit ID provided by user
  final String _adUnitId = 'ca-app-pub-3802258742710450/7162582093';

  Future<void> initialize() async {
    await MobileAds.instance.initialize();
  }

  void loadRewardedAd() {
    if (_hasWatchedAdSession) return; // No need to load if already watched
    if (_isAdLoading) return; // Prevent multiple loads

    _isAdLoading = true;
    RewardedAd.load(
      adUnitId: _adUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (RewardedAd ad) {
          debugPrint('$ad loaded.');
          _rewardedAd = ad;
          _isAdLoading = false;
        },
        onAdFailedToLoad: (LoadAdError error) {
          debugPrint('RewardedAd failed to load: $error');
          _rewardedAd = null;
          _isAdLoading = false;
        },
      ),
    );
  }

  void showAdIfAvailable(VoidCallback onComplete) {
    // Logic: Only show ad once per session.
    if (_hasWatchedAdSession) {
      debugPrint('Ad already watched this session. Skipping.');
      onComplete();
      return;
    }

    if (_rewardedAd == null) {
      debugPrint('Warning: Ad not loaded yet. Skipping ad.');
      // Attempt to load for next time (if strict "must watch" wasn't enforced, but here we just proceed)
      loadRewardedAd();
      onComplete();
      return;
    }

    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (RewardedAd ad) =>
          debugPrint('Ad showed fullscreen content.'),
      onAdDismissedFullScreenContent: (RewardedAd ad) {
        debugPrint('Ad dismissed fullscreen content.');
        ad.dispose();
        _rewardedAd = null;
        // Mark as watched even if dismissed, to avoid annoying user repeatedly if they closed it
        // Requirement says: "iklan hanya muncul hanya pertama kali"
        _hasWatchedAdSession = true;
        onComplete();
      },
      onAdFailedToShowFullScreenContent: (RewardedAd ad, AdError error) {
        debugPrint('Ad failed to show fullscreen content.');
        ad.dispose();
        _rewardedAd = null;
        // If it failed to show, we might want to try again later, or just let them pass.
        // Let's let them pass to avoid blocking app usage.
        onComplete();
      },
    );

    _rewardedAd!.setImmersiveMode(true);
    _rewardedAd!.show(
      onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
        debugPrint('User earned reward: ${reward.amount} ${reward.type}');
        _hasWatchedAdSession = true;
      },
    );
  }
}

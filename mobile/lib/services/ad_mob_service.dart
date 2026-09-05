import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdMobService {
  static const String liveRewardedAdUnitId = 'ca-app-pub-7125012606848968/1582412035';
  static const String testRewardedAdUnitId = 'ca-app-pub-3940256099942544/5224354917';
  static const String testBannerAdUnitId = 'ca-app-pub-3940256099942544/6300978111';

  RewardedAd? _rewardedAd;
  bool isAdLoaded = false;

  String get rewardedAdUnitId => kReleaseMode ? liveRewardedAdUnitId : testRewardedAdUnitId;
  String get bannerAdUnitId => testBannerAdUnitId;

  static Future<void> initialize() async {
    await MobileAds.instance.initialize();
  }

  void loadRewardedAd({required Function() onLoaded, required Function() onFailed}) {
    RewardedAd.load(
      adUnitId: rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          isAdLoaded = true;
          onLoaded();
        },
        onAdFailedToLoad: (error) {
          _rewardedAd = null;
          isAdLoaded = false;
          onFailed();
        },
      ),
    );
  }

  void showRewardedAd({required Function(int amount) onEarnedReward}) {
    if (_rewardedAd != null && isAdLoaded) {
      _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          loadRewardedAd(onLoaded: () {}, onFailed: () {});
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          ad.dispose();
          loadRewardedAd(onLoaded: () {}, onFailed: () {});
        },
      );

      _rewardedAd!.show(
        onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
          onEarnedReward(reward.amount.toInt());
        },
      );
      _rewardedAd = null;
      isAdLoaded = false;
    }
  }

  BannerAd createInFeedBannerAd({required Function() onAdLoaded}) {
    return BannerAd(
      adUnitId: bannerAdUnitId,
      size: AdSize.mediumRectangle,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          onAdLoaded();
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
        },
      ),
    )..load();
  }
}

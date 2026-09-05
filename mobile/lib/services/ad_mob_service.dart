import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdMobService {
  // Canlý Ad Unit ID (AdMob panelinden alýnan)
  static const String liveAdUnitId = 'ca-app-pub-7125012606848968/1582412035';
  
  // Google'ýn resmi test reklam ID'si (Geliþtirme / Test aþamasýnda banlanmamak için)
  static const String testAdUnitId = 'ca-app-pub-3940256099942544/5224354917';

  RewardedAd? _rewardedAd;
  bool isAdLoaded = false;

  // Geliþtirme aþamasýnda test reklamý, release'de canlý reklam birimini kullanýr
  String get rewardedAdUnitId => kReleaseMode ? liveAdUnitId : testAdUnitId;

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
          // Reklam kapanýnca bir sonraki reklamý önceden belleðe al
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
}

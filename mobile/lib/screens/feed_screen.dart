import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../theme.dart';
import '../services/ad_mob_service.dart';
import '../services/api_service.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  final AdMobService _adMobService = AdMobService();
  final ApiService _apiService = ApiService();

  bool _isRewardedAdReady = false;
  int _userPoints = 0;
  int _currentPage = 0;
  bool _isOnline = true;
  bool _isSyncing = false;

  final Map<int, BannerAd> _bannerAds = {};
  final Map<int, bool> _bannerAdLoaded = {};

  // Circular Watch Dwell Timer (TikTok Lite Style)
  late AnimationController _progressController;
  Timer? _dwellTimer;
  static const int _requiredWatchSeconds = 4;
  int _currentWatchSeconds = 0;
  bool _rewardGivenForCurrentCard = false;

  @override
  void initState() {
    super.initState();
    _syncWalletFromBackend();
    _loadNextRewardedAd();

    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: _requiredWatchSeconds),
    );

    _startDwellTimer();
  }

  @override
  void dispose() {
    _dwellTimer?.cancel();
    _progressController.dispose();
    _pageController.dispose();
    for (var ad in _bannerAds.values) {
      ad.dispose();
    }
    super.dispose();
  }

  void _syncWalletFromBackend() async {
    try {
      final wallet = await _apiService.getWallet();
      if (mounted) {
        setState(() {
          final balance = wallet['balance_points'] ?? 0;
          _userPoints = (balance is num) ? balance.toInt() : (double.tryParse(balance.toString())?.toInt() ?? 0);
          _isOnline = true;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isOnline = false);
      }
    }
  }

  void _startDwellTimer() {
    _dwellTimer?.cancel();
    _progressController.reset();
    _currentWatchSeconds = 0;
    _rewardGivenForCurrentCard = false;

    _progressController.forward();

    _dwellTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      _currentWatchSeconds++;

      if (_currentWatchSeconds >= _requiredWatchSeconds && !_rewardGivenForCurrentCard) {
        _rewardGivenForCurrentCard = true;
        _claimDwellReward();
      }
    });
  }

  void _claimDwellReward() async {
    if (_isSyncing) return;
    _isSyncing = true;

    try {
      final res = await _apiService.sendAdEvent(
        adId: "in_feed_ad_$_currentPage",
        durationSeconds: _requiredWatchSeconds,
        isRewarded: false,
      );

      if (mounted) {
        final newBal = res['new_balance_points'];
        setState(() {
          _userPoints = (newBal is num) ? newBal.toInt() : (double.tryParse(newBal.toString())?.toInt() ?? (_userPoints + 1));
          _isOnline = true;
        });

        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            duration: const Duration(milliseconds: 1200),
            backgroundColor: Colors.purple.shade900,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.only(bottom: 90, left: 40, right: 40),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            content: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.monetization_on, color: Colors.amberAccent, size: 18),
                SizedBox(width: 8),
                Text(
                  "+1 Point Earned! (\$0.001)",
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ],
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.redAccent,
            content: Text("Could not sync reward. Please check internet / server connection."),
          ),
        );
      }
    } finally {
      _isSyncing = false;
    }
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentPage = index;
    });
    _startDwellTimer();
  }

  void _loadNextRewardedAd() {
    _adMobService.loadRewardedAd(
      onLoaded: () {
        if (mounted) setState(() => _isRewardedAdReady = true);
      },
      onFailed: () {
        if (mounted) setState(() => _isRewardedAdReady = false);
      },
    );
  }

  void _watchBonusAd() {
    if (!_isRewardedAdReady) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bonus video is loading, please wait a moment...')),
      );
      _loadNextRewardedAd();
      return;
    }

    _adMobService.showRewardedAd(
      onEarnedReward: (amount) async {
        try {
          final res = await _apiService.sendAdEvent(
            adId: "bonus_rewarded_video_${DateTime.now().millisecondsSinceEpoch}",
            durationSeconds: 15,
            isRewarded: true,
          );

          if (mounted) {
            final newBal = res['new_balance_points'];
            setState(() {
              _userPoints = (newBal is num) ? newBal.toInt() : (double.tryParse(newBal.toString())?.toInt() ?? (_userPoints + 30));
              _isRewardedAdReady = false;
            });
            _loadNextRewardedAd();

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                backgroundColor: Color(0xFF1E3A2B),
                content: Text(
                  '🔥 Mega Bonus! +30 Points (\$0.030) verified on server.',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                backgroundColor: Colors.redAccent,
                content: Text("Reward verification failed. Check internet connection."),
              ),
            );
          }
        }
      },
    );
  }

  BannerAd _getOrCreateBannerAd(int index) {
    if (!_bannerAds.containsKey(index)) {
      _bannerAds[index] = _adMobService.createInFeedBannerAd(
        onAdLoaded: () {
          if (mounted) {
            setState(() {
              _bannerAdLoaded[index] = true;
            });
          }
        },
      );
    }
    return _bannerAds[index]!;
  }

  @override
  Widget build(BuildContext context) {
    final double dollarEquivalent = _userPoints * 0.001;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0E),
      body: Stack(
        children: [
          // 100% In-Feed Google AdMob Stream
          PageView.builder(
            controller: _pageController,
            scrollDirection: Axis.vertical,
            onPageChanged: _onPageChanged,
            itemBuilder: (context, index) {
              final bannerAd = _getOrCreateBannerAd(index);
              final bool isLoaded = _bannerAdLoaded[index] ?? false;

              return Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF0F0C20),
                      Color(0xFF0A0A0E),
                      Color(0xFF150A21),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Positioned(
                      top: 120,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Container(
                          width: 260,
                          height: 260,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.purpleAccent.withOpacity(0.08),
                          ),
                        ),
                      ),
                    ),

                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.purple.withOpacity(0.25),
                              border: Border.all(color: Colors.purpleAccent.withOpacity(0.6)),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(Icons.play_arrow, size: 14, color: Colors.purpleAccent),
                                SizedBox(width: 6),
                                Text(
                                  "SPONSORED GOOGLE ADS",
                                  style: TextStyle(
                                    color: Colors.purpleAccent,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          
                          isLoaded
                              ? Container(
                                  width: bannerAd.size.width.toDouble(),
                                  height: bannerAd.size.height.toDouble(),
                                  decoration: BoxDecoration(
                                    color: Colors.black,
                                    border: Border.all(color: Colors.purpleAccent.withOpacity(0.3), width: 1.5),
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.purpleAccent.withOpacity(0.15),
                                        blurRadius: 20,
                                        spreadRadius: 2,
                                      )
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: AdWidget(ad: bannerAd),
                                  ),
                                )
                              : Container(
                                  width: 300,
                                  height: 250,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.03),
                                    border: Border.all(color: Colors.white12),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: const [
                                      CircularProgressIndicator(color: Colors.purpleAccent, strokeWidth: 2.5),
                                      SizedBox(height: 16),
                                      Text(
                                        "Loading Sponsored Content...",
                                        style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                        ],
                      ),
                    ),

                    Positioned(
                      bottom: 30,
                      left: 20,
                      right: 20,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Vidreel Global Stream",
                            style: TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            "Rewards are verified and deposited instantly to your cloud wallet.",
                            style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            height: 46,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.purpleAccent,
                                foregroundColor: Colors.black,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                              onPressed: _watchBonusAd,
                              icon: Icon(
                                _isRewardedAdReady ? Icons.play_circle_filled : Icons.hourglass_empty,
                                size: 20,
                                color: Colors.black,
                              ),
                              label: Text(
                                _isRewardedAdReady
                                    ? "WATCH BONUS AD (+30 PTS)"
                                    : "LOADING BONUS...",
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 12,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          // Header
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 28,
                          height: 28,
                          child: AnimatedBuilder(
                            animation: _progressController,
                            builder: (context, child) {
                              return CircularProgressIndicator(
                                value: _progressController.value,
                                strokeWidth: 3,
                                backgroundColor: Colors.white24,
                                valueColor: const AlwaysStoppedAnimation<Color>(Colors.amberAccent),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          "+1 Pt",
                          style: TextStyle(
                            color: Colors.amberAccent,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.surface.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.stars, size: 16, color: Colors.purpleAccent),
                        const SizedBox(width: 6),
                        Text(
                          "$_userPoints Pts (\$${dollarEquivalent.toStringAsFixed(3)})",
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
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
}

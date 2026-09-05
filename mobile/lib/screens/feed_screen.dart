import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../theme.dart';
import '../services/ad_mob_service.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  final AdMobService _adMobService = AdMobService();
  bool _isRewardedAdReady = false;
  int _userPoints = 0;
  int _currentPage = 0;

  // In-Feed Google Banner Reklamları Belleği
  final Map<int, BannerAd> _bannerAds = {};
  final Map<int, bool> _bannerAdLoaded = {};

  // Dönen Ödül Sayacı (TikTok Lite Tarzı)
  late AnimationController _progressController;
  Timer? _dwellTimer;
  static const int _requiredWatchSeconds = 4;
  int _currentWatchSeconds = 0;
  bool _rewardGivenForCurrentCard = false;

  @override
  void initState() {
    super.initState();
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
        _giveMicroReward();
      }
    });
  }

  void _giveMicroReward() {
    setState(() {
      _userPoints += 1; // +1 Puan ($0.001)
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
              "+1 Puan Kazandın! (\$0.001)",
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ],
        ),
      ),
    );
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
    if (!mounted) return;
    if (_isRewardedAdReady) {
      _adMobService.showRewardedAd(
        onEarnedReward: (amount) {
          if (!mounted) return;
          final earned = amount > 0 ? amount : 30;
          setState(() {
            _userPoints += earned;
            _isRewardedAdReady = false;
          });
          _loadNextRewardedAd();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: const Color(0xFF1E3A2B),
              content: Text(
                '🔥 Büyük Bonus! +$earned Puan (\$${(earned * 0.001).toStringAsFixed(3)}) kazandınız.',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          );
        },
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bonus video hazırlanıyor, lütfen birkaç saniye bekleyin...')),
      );
      _loadNextRewardedAd();
    }
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

  final List<Map<String, String>> _feedItems = [
    {
      "title": "Sürdürülebilir Mimarlık Sergisi",
      "advertiser": "Studio Nord",
      "image": "https://images.unsplash.com/photo-1600585154340-be6161a56a0c",
      "tag": "Sponsorlu Vitrin"
    },
    {
      "title": "Geleceğin Finans Yönetimi",
      "advertiser": "Vanguard Labs",
      "image": "https://images.unsplash.com/photo-1551836022-d5d88e9218df",
      "tag": "Fintech & Web3"
    },
    {
      "title": "Doğa Kaçamağı & Keşif Rotaları",
      "advertiser": "WildTrails Co.",
      "image": "https://images.unsplash.com/photo-1506905925346-21bda4d32df4",
      "tag": "Seyahat & Macera"
    },
  ];

  @override
  Widget build(BuildContext context) {
    final double dollarEquivalent = _userPoints * 0.001;

    return Scaffold(
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            scrollDirection: Axis.vertical,
            onPageChanged: _onPageChanged,
            itemBuilder: (context, index) {
              // Her 2 kartta bir GERÇEK GOOGLE REKLAMI (In-Feed AdMob) göster
              final bool isAdMobCard = (index % 2 == 1);

              if (isAdMobCard) {
                final bannerAd = _getOrCreateBannerAd(index);
                final bool isLoaded = _bannerAdLoaded[index] ?? false;

                return Container(
                  color: const Color(0xFF0F0F14),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Arka Plan Deseni
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.purple.withOpacity(0.2),
                                border: Border.all(color: Colors.purpleAccent.withOpacity(0.5)),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                "GOOGLE ADMOB SPONSORLU REKLAM",
                                style: TextStyle(
                                  color: Colors.purpleAccent,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            
                            // Gerçek Google Reklam Kutusu
                            isLoaded
                                ? Container(
                                    width: bannerAd.size.width.toDouble(),
                                    height: bannerAd.size.height.toDouble(),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.white12),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: AdWidget(ad: bannerAd),
                                  )
                                : Container(
                                    width: 300,
                                    height: 250,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.05),
                                      border: Border.all(color: Colors.white12),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Center(
                                      child: CircularProgressIndicator(
                                        color: Colors.purpleAccent,
                                      ),
                                    ),
                                  ),
                          ],
                        ),
                      ),

                      // Alt Bilgi ve Bonus Butonu
                      Positioned(
                        bottom: 30,
                        left: 20,
                        right: 20,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Sponsorlu Reklam Yayını",
                              style: TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              "Google Ads Network tarafından sunulmaktadır.",
                              style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              height: 44,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.purpleAccent,
                                  foregroundColor: Colors.black,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4),
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
                                      ? "BONUS REKLAM İZLE (+30 PUAN)"
                                      : "BONUS YÜKLENİYOR...",
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
              }

              // Normal İçerik Kartı
              final item = _feedItems[(index ~/ 2) % _feedItems.length];
              return Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    item["image"]!,
                    fit: BoxFit.cover,
                    errorBuilder: (c, e, s) => Container(color: AppTheme.surface),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.black.withOpacity(0.85),
                          Colors.transparent,
                          Colors.black.withOpacity(0.95),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 30,
                    left: 20,
                    right: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.purpleAccent.withOpacity(0.6)),
                            color: Colors.purple.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            item["tag"]!,
                            style: const TextStyle(
                              color: Colors.purpleAccent,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          item["title"]!,
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item["advertiser"]!,
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          height: 44,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.purpleAccent,
                              foregroundColor: Colors.black,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
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
                                  ? "BONUS REKLAM İZLE (+30 PUAN)"
                                  : "BONUS YÜKLENİYOR...",
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
              );
            },
          ),

          // Üst Header
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
                          "+1 Puan",
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
                          "$_userPoints Puan (\$${dollarEquivalent.toStringAsFixed(3)})",
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

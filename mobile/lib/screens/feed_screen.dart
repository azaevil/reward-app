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

  // Her kart için AdMob Reklamları
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

  @override
  Widget build(BuildContext context) {
    final double dollarEquivalent = _userPoints * 0.001;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0E),
      body: Stack(
        children: [
          // %100 GOOGLE ADMOB REKLAM AKIŞI (Sonsuz Kaydırma)
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
                    // Arka Plan Işıklandırması
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

                    // Ortadaki Gerçek Google Reklamı (Video / Görsel / Medya)
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
                                  "SPONSORLU GOOGLE REKLAMI",
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
                          
                          // Google AdMob Reklam Çerçevesi
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
                                        "Google Reklamı Yükleniyor...",
                                        style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                        ],
                      ),
                    ),

                    // Alt Panel & Bonus Butonu
                    Positioned(
                      bottom: 30,
                      left: 20,
                      right: 20,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Vidreel Sponsorlu Akış",
                            style: TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            "İzledikçe puanlar otomatik olarak cüzdanınıza eklenir.",
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
                                    ? "TAM EKRAN BONUS İZLE (+30 PUAN)"
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

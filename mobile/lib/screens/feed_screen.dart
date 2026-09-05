import 'dart:async';
import 'package:flutter/material.dart';
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
  bool _isAdReady = false;
  int _userPoints = 0; // Puan havuzu
  int _currentPage = 0;
  
  // Dönen Ödül Sayacı (TikTok Lite Tarzı)
  late AnimationController _progressController;
  Timer? _dwellTimer;
  static const int _requiredWatchSeconds = 4; // 4 saniye izleme şartı
  int _currentWatchSeconds = 0;
  bool _rewardGivenForCurrentCard = false;

  @override
  void initState() {
    super.initState();
    _loadNextAd();
    
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
    
    // Küçük başarı animasyonu / SnackBar
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
    // Yeni karta geçince sayacı yeniden başlat
    _startDwellTimer();
  }

  void _loadNextAd() {
    _adMobService.loadRewardedAd(
      onLoaded: () {
        if (mounted) setState(() => _isAdReady = true);
      },
      onFailed: () {
        if (mounted) setState(() => _isAdReady = false);
      },
    );
  }

  void _watchBonusAd() {
    if (!mounted) return;
    if (_isAdReady) {
      _adMobService.showRewardedAd(
        onEarnedReward: (amount) {
          if (!mounted) return;
          final earned = amount > 0 ? amount : 30; // +30 Puan Bonus
          setState(() {
            _userPoints += earned;
            _isAdReady = false;
          });
          _loadNextAd();
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
      _loadNextAd();
    }
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
    {
      "title": "Şehir İçi Elektrikli Ulaşım Devrimi",
      "advertiser": "MoveX Global",
      "image": "https://images.unsplash.com/photo-1558618666-fcd25c85cd64",
      "tag": "Teknoloji Trend"
    },
    {
      "title": "Minimalist Yaşam ve Tasarım Koleksiyonu",
      "advertiser": "Forma Studio",
      "image": "https://images.unsplash.com/photo-1555041469-a586c61ea9bc",
      "tag": "Tasarım & Dekor"
    },
    {
      "title": "Kişiselleştirilmiş Sağlıklı Yaşam Planı",
      "advertiser": "NutriLife AI",
      "image": "https://images.unsplash.com/photo-1490645935967-10de6ba17061",
      "tag": "Sağlık & Yaşam"
    },
  ];

  @override
  Widget build(BuildContext context) {
    final double dollarEquivalent = _userPoints * 0.001;

    return Scaffold(
      body: Stack(
        children: [
          // Dikey Reels / Feed Kaydırma
          PageView.builder(
            controller: _pageController,
            scrollDirection: Axis.vertical,
            onPageChanged: _onPageChanged,
            itemBuilder: (context, index) {
              final item = _feedItems[index % _feedItems.length];
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
                  
                  // Kart Bilgisi ve Aksiyon Alanı
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
                        
                        // Ekstra Bonus Butonu
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
                              _isAdReady ? Icons.play_circle_filled : Icons.hourglass_empty,
                              size: 20,
                              color: Colors.black,
                            ),
                            label: Text(
                              _isAdReady
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

          // Üst Header (Sol: TikTok Tarzı Dönen Sayaç, Sağ: Canlı Bakiye)
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Sol: Dönen Ödül Sayacı
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

                  // Sağ: Toplam Bakiye & Dolar Göstergesi
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
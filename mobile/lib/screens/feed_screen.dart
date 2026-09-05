import 'package:flutter/material.dart';
import '../theme.dart';
import '../services/ad_mob_service.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  final PageController _pageController = PageController();
  final AdMobService _adMobService = AdMobService();
  bool _isAdReady = false;
  int _userPoints = 0; // Başlangıçta 0 puan
  int _swipeCount = 0; // Kaç kez kaydırıldı
  static const int _adEvery = 3; // Her 3 kaydırmada 1 reklam

  @override
  void initState() {
    super.initState();
    _loadNextAd();
    _pageController.addListener(_onPageScroll);
  }

  @override
  void dispose() {
    _pageController.removeListener(_onPageScroll);
    _pageController.dispose();
    super.dispose();
  }

  void _onPageScroll() {
    // Sayfa değiştiğinde (tam kaydırma tamamlandığında) tetikle
    if (_pageController.page != null &&
        _pageController.page! == _pageController.page!.roundToDouble()) {
      final newPage = _pageController.page!.round();
      if (newPage > 0) {
        _swipeCount++;
        if (_swipeCount % _adEvery == 0 && _isAdReady) {
          // Her 3 kaydırmada reklam otomatik aç
          Future.delayed(const Duration(milliseconds: 300), _watchAd);
        }
      }
    }
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

  void _watchAd() {
    if (!mounted) return;
    if (_isAdReady) {
      _adMobService.showRewardedAd(
        onEarnedReward: (amount) {
          if (!mounted) return;
          final earned = amount > 0 ? amount : 50;
          setState(() {
            _userPoints += earned;
            _isAdReady = false;
          });
          _loadNextAd(); // Sonraki reklamı hazırla
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: const Color(0xFF1E3A2B),
              content: Text(
                '🎉 Tebrikler! +$earned Puan kazandınız.',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          );
        },
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Yeni reklam yükleniyor, lütfen birkaç saniye bekleyin...')),
      );
      _loadNextAd();
    }
  }

  // Sonsuz kaydırma için tekrarlanan içerik
  final List<Map<String, String>> _feedItems = [
    {
      "title": "Sürdürülebilir Mimarlık Sergisi",
      "advertiser": "Studio Nord",
      "image": "https://images.unsplash.com/photo-1600585154340-be6161a56a0c",
    },
    {
      "title": "Geleceğin Finans Yönetimi",
      "advertiser": "Vanguard Labs",
      "image": "https://images.unsplash.com/photo-1551836022-d5d88e9218df",
    },
    {
      "title": "Doğa Kaçamağı Fırsatları",
      "advertiser": "WildTrails",
      "image": "https://images.unsplash.com/photo-1506905925346-21bda4d32df4",
    },
    {
      "title": "Şehir İçi Ulaşım Devrimi",
      "advertiser": "MoveX",
      "image": "https://images.unsplash.com/photo-1558618666-fcd25c85cd64",
    },
    {
      "title": "Minimalist Yaşam Koleksiyonu",
      "advertiser": "Forma Studio",
      "image": "https://images.unsplash.com/photo-1555041469-a586c61ea9bc",
    },
    {
      "title": "Sağlıklı Beslenme Planları",
      "advertiser": "NutriLife",
      "image": "https://images.unsplash.com/photo-1490645935967-10de6ba17061",
    },
    {
      "title": "Akıllı Ev Teknolojisi",
      "advertiser": "SmartHome TR",
      "image": "https://images.unsplash.com/photo-1558002038-1055e2dae1d7",
    },
    {
      "title": "Fotoğrafçılık Kursu",
      "advertiser": "LensArt",
      "image": "https://images.unsplash.com/photo-1516035069371-29a1b244cc32",
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            scrollDirection: Axis.vertical,
            // Sonsuz kaydırma: itemCount null = sonsuz
            itemBuilder: (context, index) {
              // Listeyi döngüsel kullan
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
                          Colors.black.withOpacity(0.8),
                          Colors.transparent,
                          Colors.black.withOpacity(0.9),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 40,
                    left: 20,
                    right: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            border: Border.all(color: AppTheme.border),
                            color: Colors.black.withOpacity(0.4),
                          ),
                          child: const Text(
                            "Sponsorlu",
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 10,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
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
                              backgroundColor: AppTheme.textPrimary,
                              foregroundColor: AppTheme.background,
                              elevation: 0,
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.zero,
                              ),
                            ),
                            onPressed: _watchAd,
                            icon: Icon(
                              _isAdReady ? Icons.play_arrow : Icons.hourglass_empty,
                              size: 18,
                            ),
                            label: Text(
                              _isAdReady
                                  ? "ÖDÜLLÜ VİDEOYU İZLE (+50 PUAN)"
                                  : "REKLAM YÜKLENİYOR...",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
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

          // Üst puan göstergesi
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Align(
                alignment: Alignment.topRight,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.stars, size: 16, color: AppTheme.textPrimary),
                      const SizedBox(width: 6),
                      Text(
                        "$_userPoints Puan",
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
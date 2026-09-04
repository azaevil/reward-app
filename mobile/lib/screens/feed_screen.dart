import 'package:flutter/material.dart';
import '../theme.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  final PageController _pageController = PageController();

  final List<Map<String, String>> _mockAds = [
    {
      "title": "Sürdürülebilir Mimarlık Sergisi",
      "advertiser": "Studio Nord",
      "image": "https://images.unsplash.com/photo-1600585154340-be6161a56a0c",
    },
    {
      "title": "Geleceğin Finans Yönetimi",
      "advertiser": "Vanguard Labs",
      "image": "https://images.unsplash.com/photo-1551836022-d5d88e9218df",
    }
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            scrollDirection: Axis.vertical,
            itemCount: _mockAds.length,
            itemBuilder: (context, index) {
              final ad = _mockAds[index];
              return Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    ad["image"]!,
                    fit: BoxFit.cover,
                    errorBuilder: (c, e, s) => Container(color: AppTheme.surface),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.black.withOpacity(0.8), Colors.transparent, Colors.black.withOpacity(0.9)],
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
                          child: const Text("Sponsorlu", style: TextStyle(color: AppTheme.textSecondary, fontSize: 10, letterSpacing: 1)),
                        ),
                        const SizedBox(height: 12),
                        Text(ad["title"]!, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 22, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(ad["advertiser"]!, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
                      ],
                    ),
                  )
                ],
              );
            },
          ),
          
          // Üst Bakiye Bilgilendirme Göstergesi
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
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.stars, size: 16, color: AppTheme.textPrimary),
                      SizedBox(width: 6),
                      Text("1,250 Puan", style: TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}
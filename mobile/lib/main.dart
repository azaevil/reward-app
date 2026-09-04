import 'package:flutter/material.dart';
import 'theme.dart';
import 'screens/feed_screen.dart';
import 'screens/wallet_screen.dart';
import 'screens/profile_screen.dart';

void main() {
  runApp(const RewardApp());
}

class RewardApp extends StatelessWidget {
  const RewardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AdRewards',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const MainNavigationHolder(),
    );
  }
}

class MainNavigationHolder extends StatefulWidget {
  const MainNavigationHolder({super.key});

  @override
  State<MainNavigationHolder> createState() => _MainNavigationHolderState();
}

class _MainNavigationHolderState extends State<MainNavigationHolder> {
  int _currentIndex = 0;
  final List<Widget> _screens = [
    const FeedScreen(),
    const WalletScreen(),
    const Center(child: Text("İşlem Geçmişi", style: TextStyle(color: AppTheme.textSecondary))),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppTheme.border, width: 1)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.style), label: 'Keşfet'),
            BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet), label: 'Cüzdan'),
            BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Geçmiş'),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
          ],
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'theme.dart';
import 'screens/auth_screen.dart';
import 'screens/feed_screen.dart';
import 'screens/wallet_screen.dart';
import 'screens/profile_screen.dart';
import 'services/ad_mob_service.dart';
import 'services/api_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AdMobService.initialize();
  runApp(const VidreelApp());
}

class VidreelApp extends StatefulWidget {
  const VidreelApp({super.key});

  @override
  State<VidreelApp> createState() => _VidreelAppState();
}

class _VidreelAppState extends State<VidreelApp> {
  final ApiService _apiService = ApiService();
  bool _isCheckingAuth = true;
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _checkInitialAuth();
  }

  void _checkInitialAuth() async {
    final loggedIn = await _apiService.isLoggedIn();
    if (mounted) {
      setState(() {
        _isLoggedIn = loggedIn;
        _isCheckingAuth = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vidreel - Watch & Earn USDT',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      routes: {
        '/auth': (context) => const AuthScreen(),
        '/home': (context) => const MainNavigationHolder(),
      },
      home: _isCheckingAuth
          ? const Scaffold(
              backgroundColor: AppTheme.background,
              body: Center(
                child: CircularProgressIndicator(color: Colors.purpleAccent),
              ),
            )
          : (_isLoggedIn ? const MainNavigationHolder() : const AuthScreen()),
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
    const Center(child: Text("Transaction History", style: TextStyle(color: AppTheme.textSecondary))),
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
            BottomNavigationBarItem(icon: Icon(Icons.style), label: 'Feed'),
            BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet), label: 'Wallet'),
            BottomNavigationBarItem(icon: Icon(Icons.history), label: 'History'),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          ],
        ),
      ),
    );
  }
}

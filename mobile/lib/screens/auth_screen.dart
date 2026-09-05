import 'package:flutter/material.dart';
import '../theme.dart';
import '../services/api_service.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  late TabController _tabController;

  final _loginEmailController = TextEditingController();
  final _loginPasswordController = TextEditingController();

  final _registerEmailController = TextEditingController();
  final _registerPasswordController = TextEditingController();
  final _registerPasswordConfirmController = TextEditingController();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _loginEmailController.dispose();
    _loginPasswordController.dispose();
    _registerEmailController.dispose();
    _registerPasswordController.dispose();
    _registerPasswordConfirmController.dispose();
    super.dispose();
  }

  void _showServerSettings() async {
    final currentUrl = await _apiService.getBaseUrl();
    final urlController = TextEditingController(text: currentUrl);

    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text("Server Settings", style: TextStyle(color: AppTheme.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Backend Server URL:",
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: urlController,
              style: const TextStyle(color: AppTheme.textPrimary),
              decoration: const InputDecoration(
                hintText: "http://192.168.1.101:8000",
                filled: true,
                fillColor: AppTheme.background,
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel", style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.purpleAccent),
            onPressed: () async {
              await _apiService.setBaseUrl(urlController.text);
              if (mounted) Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Server URL updated successfully.')),
              );
            },
            child: const Text("Save", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _handleLogin() async {
    final email = _loginEmailController.text.trim();
    final password = _loginPasswordController.text;

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields.')),
      );
      return;
    }

    setState(() => _isLoading = true);
    final result = await _apiService.login(email, password);
    setState(() => _isLoading = false);

    if (result['success'] == true && mounted) {
      Navigator.pushReplacementNamed(context, '/home');
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(backgroundColor: Colors.red.shade900, content: Text(result['message'] ?? 'Login failed.')),
      );
    }
  }

  void _handleRegister() async {
    final email = _registerEmailController.text.trim();
    final password = _registerPasswordController.text;
    final confirm = _registerPasswordConfirmController.text;

    if (email.isEmpty || password.isEmpty || confirm.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields.')),
      );
      return;
    }

    if (password.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password must be at least 8 characters.')),
      );
      return;
    }

    if (password != confirm) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match.')),
      );
      return;
    }

    setState(() => _isLoading = true);
    final result = await _apiService.register(email, password);
    setState(() => _isLoading = false);

    if (result['success'] == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(backgroundColor: Colors.green, content: Text('🎉 Account created! Welcome to Vidreel.')),
      );
      Navigator.pushReplacementNamed(context, '/home');
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(backgroundColor: Colors.red.shade900, content: Text(result['message'] ?? 'Registration failed.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text("Vidreel", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.5)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: AppTheme.textSecondary),
            tooltip: "Server Settings",
            onPressed: _showServerSettings,
          )
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.2),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.purpleAccent),
                  ),
                  child: const Icon(Icons.play_arrow, size: 36, color: Colors.purpleAccent),
                ),
              ),
              const SizedBox(height: 16),
              const Center(
                child: Text(
                  "Watch Ads, Earn Real USDT Rewards",
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 13, letterSpacing: 0.5),
                ),
              ),
              const SizedBox(height: 28),

              // Tab Switcher
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.border),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicatorColor: Colors.purpleAccent,
                  indicatorWeight: 3,
                  labelColor: Colors.white,
                  unselectedLabelColor: AppTheme.textSecondary,
                  tabs: const [
                    Tab(text: "Sign In"),
                    Tab(text: "Sign Up"),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              SizedBox(
                height: 360,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildLoginForm(),
                    _buildRegisterForm(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoginForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("EMAIL ADDRESS", style: TextStyle(color: AppTheme.textSecondary, fontSize: 11, letterSpacing: 1)),
        const SizedBox(height: 6),
        TextField(
          controller: _loginEmailController,
          keyboardType: TextInputType.emailAddress,
          style: const TextStyle(color: AppTheme.textPrimary),
          decoration: const InputDecoration(
            hintText: "user@example.com",
            hintStyle: TextStyle(color: Colors.white24),
            filled: true,
            fillColor: AppTheme.surface,
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        const Text("PASSWORD", style: TextStyle(color: AppTheme.textSecondary, fontSize: 11, letterSpacing: 1)),
        const SizedBox(height: 6),
        TextField(
          controller: _loginPasswordController,
          obscureText: true,
          style: const TextStyle(color: AppTheme.textPrimary),
          decoration: const InputDecoration(
            hintText: "••••••••",
            hintStyle: TextStyle(color: Colors.white24),
            filled: true,
            fillColor: AppTheme.surface,
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purpleAccent,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            ),
            onPressed: _isLoading ? null : _handleLogin,
            child: _isLoading
                ? const CircularProgressIndicator(color: Colors.black)
                : const Text("SIGN IN", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
          ),
        ),
      ],
    );
  }

  Widget _buildRegisterForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("EMAIL ADDRESS", style: TextStyle(color: AppTheme.textSecondary, fontSize: 11, letterSpacing: 1)),
        const SizedBox(height: 6),
        TextField(
          controller: _registerEmailController,
          keyboardType: TextInputType.emailAddress,
          style: const TextStyle(color: AppTheme.textPrimary),
          decoration: const InputDecoration(
            hintText: "user@example.com",
            hintStyle: TextStyle(color: Colors.white24),
            filled: true,
            fillColor: AppTheme.surface,
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        const Text("PASSWORD (MIN. 8 CHARACTERS)", style: TextStyle(color: AppTheme.textSecondary, fontSize: 11, letterSpacing: 1)),
        const SizedBox(height: 6),
        TextField(
          controller: _registerPasswordController,
          obscureText: true,
          style: const TextStyle(color: AppTheme.textPrimary),
          decoration: const InputDecoration(
            hintText: "At least 8 characters",
            hintStyle: TextStyle(color: Colors.white24),
            filled: true,
            fillColor: AppTheme.surface,
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        const Text("CONFIRM PASSWORD", style: TextStyle(color: AppTheme.textSecondary, fontSize: 11, letterSpacing: 1)),
        const SizedBox(height: 6),
        TextField(
          controller: _registerPasswordConfirmController,
          obscureText: true,
          style: const TextStyle(color: AppTheme.textPrimary),
          decoration: const InputDecoration(
            hintText: "Re-enter your password",
            hintStyle: TextStyle(color: Colors.white24),
            filled: true,
            fillColor: AppTheme.surface,
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purpleAccent,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            ),
            onPressed: _isLoading ? null : _handleRegister,
            child: _isLoading
                ? const CircularProgressIndicator(color: Colors.black)
                : const Text("CREATE ACCOUNT & START", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
          ),
        ),
      ],
    );
  }
}

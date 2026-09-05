import 'package:flutter/material.dart';
import '../theme.dart';

class LegalScreen extends StatefulWidget {
  final int initialTab; // 0 = Privacy Policy, 1 = Terms of Service
  const LegalScreen({super.key, this.initialTab = 0});

  @override
  State<LegalScreen> createState() => _LegalScreenState();
}

class _LegalScreenState extends State<LegalScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTab,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Legal'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.purpleAccent,
          labelColor: AppTheme.textPrimary,
          unselectedLabelColor: AppTheme.textSecondary,
          tabs: const [
            Tab(text: 'Privacy Policy'),
            Tab(text: 'Terms of Service'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _LegalText(content: _privacyPolicy),
          _LegalText(content: _termsOfService),
        ],
      ),
    );
  }
}

class _LegalText extends StatelessWidget {
  final String content;
  const _LegalText({required this.content});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Text(
        content,
        style: const TextStyle(
          color: AppTheme.textSecondary,
          fontSize: 13,
          height: 1.7,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
// PRIVACY POLICY
// ─────────────────────────────────────────
const String _privacyPolicy = '''
PRIVACY POLICY
Last Updated: September 5, 2026

1. INTRODUCTION
Welcome to Vidreel. We are committed to protecting your personal information. This Privacy Policy explains how we collect, use, and safeguard your information when you use our app.

2. INFORMATION WE COLLECT
• Account Information: Email address and password when you register.
• Payment Information: Binance Pay ID or email when you request a withdrawal.
• Usage Data: Features used, ads watched, time in app.
• Device Information: Device model, OS version, device identifiers.
• Ad Interaction Data: Which ads you viewed and reward status.

3. HOW WE USE YOUR INFORMATION
• To provide rewards and process withdrawals.
• To prevent fraud and detect bot activity.
• To improve app performance and experience.
• To comply with legal obligations.

4. ADVERTISING — GOOGLE ADMOB
We use Google AdMob to display rewarded video ads. AdMob may use your Advertising ID (GAID) to serve relevant ads. You can opt out in: Settings → Google → Ads → Opt out of Ads Personalization.

5. BINANCE PAY WITHDRAWALS
Withdrawal requests require a valid Binance Pay ID or email. We do not store your Binance credentials beyond what is necessary to process your request.

6. DATA SHARING
We do NOT sell your personal information. We may share data only with:
• Google AdMob (ad serving)
• Binance (withdrawal processing)
• Law enforcement (when required by law)

7. DATA RETENTION
• Account data: Retained while your account is active + 90 days after deletion.
• Transaction records: Up to 5 years for financial compliance.
• Log data: Deleted after 30 days.

8. YOUR RIGHTS
Depending on your location, you may request: access, correction, deletion, or portability of your data. GDPR (EU), CCPA (California), and KVKK (Turkey) rights apply.

Contact: Vidreel@proton.me

9. CHILDREN'S PRIVACY
Vidreel is not directed to children under 13 (or 16 in the EEA).

10. CHANGES
We may update this policy. Continued use after changes = acceptance.

Contact: Vidreel@proton.me
''';

// ─────────────────────────────────────────
// TERMS OF SERVICE
// ─────────────────────────────────────────
const String _termsOfService = '''
TERMS OF SERVICE
Last Updated: September 5, 2026

1. AGREEMENT
By using Vidreel, you agree to these Terms. If you disagree, stop using the app.

2. ELIGIBILITY
You must be at least 18 years old and legally allowed to use the app in your country.

3. ACCOUNT
• Provide accurate information during registration.
• You may only create ONE account per person.
• Multiple accounts will be immediately terminated with forfeiture of all rewards.

4. REWARD SYSTEM
• Points are earned only by watching rewarded video ads to completion.
• Partial views, skipped ads, or automated tools do not qualify.
• Points have no monetary value until a withdrawal is successfully processed.
• We may change point values and conversion rates at any time.

5. WITHDRAWALS — BINANCE PAY
• You must have a valid Binance account with KYC completed.
• Provide your Binance Pay ID or registered Binance email.
• Minimum withdrawal threshold applies (shown in the Wallet section).
• Withdrawals are processed within 7–14 business days.
• We may hold or deny withdrawals if fraud is suspected.
• We are not responsible for errors due to incorrect Binance info you provide.

6. PROHIBITED ACTIVITIES
You agree NOT to:
• Use bots, scripts, or automated tools to watch ads.
• Create multiple accounts to exploit rewards.
• Sell, transfer, or trade your account or points.
• Reverse-engineer or modify the app.
• Use the app for any illegal purpose.

Violations result in immediate termination and forfeiture of all rewards.

7. INTELLECTUAL PROPERTY
All app content, design, and code are owned by Vidreel and protected by law.

8. DISCLAIMER
THE APP IS PROVIDED "AS IS." WE DO NOT GUARANTEE UNINTERRUPTED SERVICE OR AD AVAILABILITY.

9. LIMITATION OF LIABILITY
We are not liable for indirect or consequential damages. Our maximum liability is limited to rewards you have successfully withdrawn in the prior 3 months.

10. TERMINATION
We may terminate your account at any time for violations. Unredeemed points are forfeited upon termination.

11. GOVERNING LAW
These Terms are governed by the laws of Turkey. Disputes shall be resolved in Istanbul courts.

Contact: Vidreel@proton.me
''';

import 'package:flutter/material.dart';
import '../theme.dart';
import '../services/api_service.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  final ApiService _apiService = ApiService();
  int _balancePoints = 0;
  int _totalEarnedPoints = 0;
  double _withdrawnUsd = 0.0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchWallet();
  }

  Future<void> _fetchWallet() async {
    setState(() => _isLoading = true);
    try {
      final data = await _apiService.getWallet();
      if (mounted) {
        setState(() {
          final bal = data['balance_points'] ?? 0;
          final total = data['total_earned_points'] ?? 0;
          final withdrawn = data['total_withdrawn_usd'] ?? 0.0;

          _balancePoints = (bal is num) ? bal.toInt() : (double.tryParse(bal.toString())?.toInt() ?? 0);
          _totalEarnedPoints = (total is num) ? total.toInt() : (double.tryParse(total.toString())?.toInt() ?? 0);
          _withdrawnUsd = (withdrawn is num) ? withdrawn.toDouble() : (double.tryParse(withdrawn.toString()) ?? 0.0);
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showWithdrawSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(0)),
      ),
      builder: (_) => _WithdrawBottomSheet(
        currentPoints: _balancePoints,
        onSuccess: _fetchWallet,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double usdValue = _balancePoints * 0.001;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Cüzdan & Hak Ediş"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppTheme.textSecondary),
            onPressed: _fetchWallet,
          )
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchWallet,
        color: Colors.purpleAccent,
        backgroundColor: AppTheme.surface,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Bakiye Kartı
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  border: Border.all(color: AppTheme.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "KULLANILABİLİR BAKİYE (SUNUCU ONAYLI)",
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 11,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _isLoading
                        ? const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(color: Colors.purpleAccent, strokeWidth: 2),
                            ),
                          )
                        : Text(
                            "\$${usdValue.toStringAsFixed(3)} USD",
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 34,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                    const SizedBox(height: 4),
                    Text(
                      "$_balancePoints Puan (Toplam Kazanılan: $_totalEarnedPoints Puan)",
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Divider(color: AppTheme.border),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Text(
                          "Minimum çekim eşiği",
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          "\$5.00 USD (5.000 Puan)",
                          style: TextStyle(
                            color: Colors.purpleAccent,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Binance Pay Bilgi Kutusu
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.purpleAccent.withOpacity(0.4)),
                  color: Colors.purple.withOpacity(0.08),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Icon(Icons.currency_bitcoin, color: Colors.purpleAccent, size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        "Ödemeler Binance Pay (USDT) ile doğrudan sunucu tarafından işlenir. Sıfır komisyon ve anlık aktarım için Binance KYC onayınızın tamamlanmış olması gerekir.",
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Para Çekme Butonu
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.textPrimary,
                    foregroundColor: AppTheme.background,
                    elevation: 0,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.zero,
                    ),
                  ),
                  onPressed: _showWithdrawSheet,
                  icon: const Icon(Icons.send, size: 18),
                  label: const Text(
                    "PARA ÇEKME TALEBİ OLUŞTUR",
                    style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WithdrawBottomSheet extends StatefulWidget {
  final int currentPoints;
  final VoidCallback onSuccess;

  const _WithdrawBottomSheet({required this.currentPoints, required this.onSuccess});

  @override
  State<_WithdrawBottomSheet> createState() => _WithdrawBottomSheetState();
}

class _WithdrawBottomSheetState extends State<_WithdrawBottomSheet> {
  final ApiService _apiService = ApiService();
  final _formKey = GlobalKey<FormState>();
  final _binanceIdController = TextEditingController();
  final _amountController = TextEditingController();
  bool _isSubmitting = false;
  bool _submitted = false;
  String? _errorMessage;

  @override
  void dispose() {
    _binanceIdController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final amount = double.tryParse(_amountController.text.trim()) ?? 0.0;
    final binanceId = _binanceIdController.text.trim();

    try {
      await _apiService.withdraw(
        amountUsd: amount,
        paymentMethod: "BINANCE_PAY",
        payoutDetails: binanceId,
      );

      if (mounted) {
        widget.onSuccess();
        setState(() {
          _isSubmitting = false;
          _submitted = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _errorMessage = e.toString().replaceAll("Exception: ", "");
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 24, 20, 24 + bottomPadding),
      child: _submitted ? _buildSuccess() : _buildForm(),
    );
  }

  Widget _buildSuccess() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.check_circle_outline, color: Colors.greenAccent, size: 56),
        const SizedBox(height: 16),
        const Text(
          "Talep Sunucuya İletildi!",
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          "Para çekme talebiniz kaydedildi. Güvenlik incelemesinin ardından Binance Pay hesabınıza aktarılacaktır.",
          textAlign: TextAlign.center,
          style: TextStyle(color: AppTheme.textSecondary, height: 1.5),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.textPrimary,
              foregroundColor: AppTheme.background,
              shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
            ),
            onPressed: () => Navigator.pop(context),
            child: const Text("KAPAT", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.currency_bitcoin, color: Colors.purpleAccent, size: 22),
              const SizedBox(width: 8),
              const Text(
                "Binance Pay ile Çek",
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close, color: AppTheme.textSecondary),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            "Anlık ve komisyonsuz transfer. KYC tamamlanmış Binance Pay ID veya e-posta giriniz.",
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, height: 1.4),
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              color: Colors.red.shade900.withOpacity(0.3),
              child: Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.redAccent, fontSize: 12),
              ),
            ),
          ],
          const SizedBox(height: 16),

          const Text(
            "BİNANCE PAY ID VEYA E-POSTA",
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 11,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: _binanceIdController,
            style: const TextStyle(color: AppTheme.textPrimary),
            decoration: const InputDecoration(
              hintText: "örn. 123456789 veya ornek@email.com",
              filled: true,
              fillColor: AppTheme.background,
              border: OutlineInputBorder(),
            ),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Binance Pay ID / e-posta zorunludur.' : null,
          ),

          const SizedBox(height: 14),

          const Text(
            "ÇEKMEK İSTEDİĞİNİZ MİKTAR (USD)",
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 11,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(color: AppTheme.textPrimary),
            decoration: const InputDecoration(
              hintText: "Minimum \$5.00",
              prefixText: "\$ ",
              prefixStyle: TextStyle(color: AppTheme.textSecondary),
              filled: true,
              fillColor: AppTheme.background,
              border: OutlineInputBorder(),
            ),
            validator: (v) {
              final val = double.tryParse(v ?? '');
              if (val == null || val < 5.0) {
                return 'Minimum çekim tutarı \$5.00\'dır.';
              }
              final userUsd = widget.currentPoints * 0.001;
              if (val > userUsd) {
                return 'Yetersiz bakiye (Mevcut: \$${userUsd.toStringAsFixed(2)})';
              }
              return null;
            },
          ),

          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purpleAccent,
                foregroundColor: Colors.black,
                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
              ),
              onPressed: _isSubmitting ? null : _submit,
              child: _isSubmitting
                  ? const CircularProgressIndicator(color: Colors.black)
                  : const Text(
                      "TALEBİ GÖNDER",
                      style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

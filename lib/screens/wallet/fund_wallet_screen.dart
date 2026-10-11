import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/api/callit_api.dart';
import '../../core/widgets/app_button.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

class FundWalletScreen extends StatefulWidget {
  const FundWalletScreen({super.key, required this.walletAddress});

  final String walletAddress;

  @override
  State<FundWalletScreen> createState() => _FundWalletScreenState();
}

class _FundWalletScreenState extends State<FundWalletScreen> {
  final _amountController = TextEditingController(text: '10000');
  bool _loading = false;
  String? _errorMessage;

  // Checkout response state
  Map<String, dynamic>? _checkoutData;
  Timer? _pollTimer;
  bool _completed = false;

  static const double _rate = 1550.0; // 1 USDC ≈ 1550 NGN

  double get _amount => double.tryParse(_amountController.text.replaceAll(',', '')) ?? 0;
  double get _estimatedUsdc => _amount > 0 ? _amount / _rate : 0;

  @override
  void dispose() {
    _pollTimer?.cancel();
    _amountController.dispose();
    super.dispose();
  }

  void _selectPreset(int amount) {
    setState(() {
      _amountController.text = amount.toString();
    });
  }

  Future<void> _createCheckout() async {
    if (_amount < 500) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Minimum funding amount is ₦500')),
      );
      return;
    }

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final res = await callitApi.createFundingCheckout(
        amountNgn: _amount,
        walletAddress: widget.walletAddress,
      );

      if (!mounted) return;
      setState(() {
        _checkoutData = res;
        _loading = false;
      });

      _startPolling(res['reference'] as String? ?? '');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  void _startPolling(String reference) {
    if (reference.isEmpty) return;
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 4), (timer) async {
      try {
        final statusRes = await callitApi.getFundingStatus(reference);
        final status = statusRes['status'] as String? ?? '';
        if (status == 'completed') {
          timer.cancel();
          if (!mounted) return;
          setState(() {
            _completed = true;
          });
        }
      } catch (_) {}
    });
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copied to clipboard!'),
        duration: const Duration(seconds: 2),
        backgroundColor: AppColors.ink,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(
        leading: const BackButton(),
        title: Text(_checkoutData == null ? 'Fund Wallet' : 'Payment Instructions', style: AppTextStyles.h3),
      ),
      body: SafeArea(
        child: _completed
            ? _buildSuccessView()
            : (_checkoutData == null ? _buildAmountView() : _buildPaymentView()),
      ),
    );
  }

  Widget _buildAmountView() {
    final shortAddr = widget.walletAddress.length > 8
        ? '${widget.walletAddress.substring(0, 4)}…${widget.walletAddress.substring(widget.walletAddress.length - 4)}'
        : widget.walletAddress;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Deposit NGN', style: AppTextStyles.h1),
          const SizedBox(height: 6),
          Text(
            'Fund your trading balance via instant Nigerian bank transfer powered by FossaPay.',
            style: AppTextStyles.subtitle,
          ),
          const SizedBox(height: 24),

          // Amount card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.white,
              border: Border.all(color: AppColors.mist),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Amount in Naira (NGN)', style: AppTextStyles.body(13, weight: FontWeight.w600, color: AppColors.slate)),
                const SizedBox(height: 8),
                TextField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  style: AppTextStyles.display(32),
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    prefixText: '₦ ',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [5000, 10000, 25000, 50000].map((amt) {
                    final selected = _amountController.text == amt.toString();
                    return ActionChip(
                      label: Text('₦${amt.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}'),
                      backgroundColor: selected ? AppColors.ink : AppColors.mist.withOpacity(0.4),
                      labelStyle: TextStyle(color: selected ? AppColors.paper : AppColors.ink, fontWeight: FontWeight.w600),
                      onPressed: () => _selectPreset(amt),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Estimated receive info
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.white,
              border: Border.all(color: AppColors.mist),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Estimated USDC Credit', style: AppTextStyles.body(14, color: AppColors.slate)),
                    Text('~\$${_estimatedUsdc.toStringAsFixed(2)} USDC', style: AppTextStyles.body(15, weight: FontWeight.w700, color: AppColors.yes)),
                  ],
                ),
                const Divider(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Exchange Rate', style: AppTextStyles.body(13, color: AppColors.slate)),
                    Text('1 USDC ≈ ₦1,550', style: AppTextStyles.tabularNums(13)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Destination Wallet', style: AppTextStyles.body(13, color: AppColors.slate)),
                    Text(shortAddr, style: AppTextStyles.tabularNums(13, weight: FontWeight.w600)),
                  ],
                ),
              ],
            ),
          ),

          if (_errorMessage != null) ...[
            const SizedBox(height: 14),
            Text(_errorMessage!, style: const TextStyle(color: Colors.red, fontSize: 13)),
          ],

          const Spacer(),
          AppButton(
            label: 'Generate Transfer Account',
            loading: _loading,
            onPressed: _amount >= 500 ? _createCheckout : null,
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentView() {
    final d = _checkoutData!;
    final bankName = d['bankName'] as String? ?? 'Bank';
    final accountNumber = d['accountNumber'] as String? ?? '';
    final accountName = d['accountName'] as String? ?? 'Callit / FossaPay';
    final amountPayable = d['amountPayableNgn'] ?? d['amountNgn'];

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.amber.shade50,
            border: Border.all(color: Colors.amber.shade300),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline_rounded, color: Colors.amber.shade900),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Transfer the exact amount below using your bank app (OPay, Kuda, GTBank, etc.). It will be credited automatically.',
                  style: AppTextStyles.body(13, color: Colors.amber.shade900),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Account Details Card
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: AppColors.ink,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('TRANSFER EXACTLY', style: AppTextStyles.body(12, color: AppColors.inkMuted, weight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(
                '₦${amountPayable.toString()}',
                style: AppTextStyles.display(34, color: AppColors.paper),
              ),
              const Divider(color: Colors.white24, height: 32),

              _detailRow('Bank Name', bankName),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Account Number', style: AppTextStyles.body(12, color: AppColors.inkMuted)),
                      const SizedBox(height: 4),
                      Text(accountNumber, style: AppTextStyles.display(22, color: AppColors.paper, weight: FontWeight.w700)),
                    ],
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.highlight,
                      foregroundColor: AppColors.ink,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => _copyToClipboard(accountNumber, 'Account number'),
                    icon: const Icon(Icons.copy_rounded, size: 16),
                    label: const Text('Copy'),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _detailRow('Account Name', accountName),
            ],
          ),
        ),

        const SizedBox(height: 28),

        Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.ink)),
              const SizedBox(width: 12),
              Text('Checking for incoming payment…', style: AppTextStyles.body(14, color: AppColors.slate)),
            ],
          ),
        ),

        const SizedBox(height: 36),
        AppButton(
          label: 'I Have Made The Transfer',
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Payment verification in progress. Funds will appear once confirmed.')),
            );
          },
        ),
      ],
    );
  }

  Widget _detailRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.body(12, color: AppColors.inkMuted)),
        const SizedBox(height: 4),
        Text(value, style: AppTextStyles.body(16, color: AppColors.paper, weight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildSuccessView() {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(color: AppColors.yes, shape: BoxShape.circle),
            child: const Icon(Icons.check_rounded, color: AppColors.white, size: 48),
          ),
          const SizedBox(height: 24),
          Text('Deposit Confirmed!', style: AppTextStyles.h1, textAlign: TextAlign.center),
          const SizedBox(height: 10),
          Text(
            'Your payment was verified by FossaPay. Your wallet trading balance has been updated.',
            style: AppTextStyles.subtitle,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          AppButton(
            label: 'Back to Wallet',
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );
  }
}

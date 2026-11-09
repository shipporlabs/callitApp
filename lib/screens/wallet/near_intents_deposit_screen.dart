import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../core/api/callit_api.dart';
import '../../core/api/token_store.dart';
import '../../core/widgets/app_button.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

class NearIntentsDepositScreen extends StatefulWidget {
  const NearIntentsDepositScreen({super.key, required this.walletAddress});

  final String walletAddress;

  @override
  State<NearIntentsDepositScreen> createState() => _NearIntentsDepositScreenState();
}

class _NearIntentsDepositScreenState extends State<NearIntentsDepositScreen> {
  final _amountController = TextEditingController(text: '1.0');

  String _selectedOrigin = 'wNEAR';
  bool _loadingQuote = false;
  bool _generatingAddress = false;
  Map<String, dynamic>? _activeQuote;
  String? _depositAddress;
  String? _depositStatus;
  Timer? _statusTimer;

  final List<Map<String, String>> _supportedAssets = [
    {'symbol': 'wNEAR', 'name': 'NEAR Protocol', 'blockchain': 'NEAR'},
    {'symbol': 'ETH', 'name': 'Ethereum / Base', 'blockchain': 'EVM'},
    {'symbol': 'SOL', 'name': 'Solana', 'blockchain': 'Solana'},
    {'symbol': 'USDC', 'name': 'USD Coin (Any Chain)', 'blockchain': 'Multi-Chain'},
  ];

  @override
  void dispose() {
    _statusTimer?.cancel();
    _amountController.dispose();
    super.dispose();
  }

  void _getQuote({required bool dry}) async {
    final amount = _amountController.text.trim();
    if (amount.isEmpty || double.tryParse(amount) == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid deposit amount')),
      );
      return;
    }

    setState(() {
      if (dry) {
        _loadingQuote = true;
      } else {
        _generatingAddress = true;
      }
    });

    try {
      final res = await callitApi.createNearIntentQuote(
        originAsset: _selectedOrigin,
        amount: amount,
        recipient: widget.walletAddress.isNotEmpty
            ? widget.walletAddress
            : TokenStore.instance.walletAddress,
        dry: dry,
      );

      final quoteData = (res['data'] as Map?)?.cast<String, dynamic>() ?? res;

      if (!mounted) return;
      setState(() {
        _activeQuote = quoteData;
        _loadingQuote = false;
        _generatingAddress = false;
        if (!dry && quoteData['depositAddress'] != null) {
          _depositAddress = quoteData['depositAddress'] as String;
          _depositStatus = quoteData['status'] as String? ?? 'PENDING_DEPOSIT';
          _startStatusPolling(_depositAddress!);
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingQuote = false;
        _generatingAddress = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Quote error: $e')),
      );
    }
  }

  void _startStatusPolling(String address) {
    _statusTimer?.cancel();
    _statusTimer = Timer.periodic(const Duration(seconds: 4), (timer) async {
      try {
        final res = await callitApi.getNearDepositStatus(address);
        final data = (res['data'] as Map?)?.cast<String, dynamic>() ?? res;
        final status = data['status'] as String?;
        if (status != null && mounted) {
          setState(() => _depositStatus = status);
          if (status == 'COMPLETED' || status == 'SUCCESS') {
            timer.cancel();
            _showSuccessDialog();
          }
        }
      } catch (_) {}
    });
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.paper,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: const [
            Icon(Icons.check_circle_rounded, color: Colors.green, size: 28),
            SizedBox(width: 10),
            Text('Deposit Received!'),
          ],
        ),
        content: const Text(
          'Your funds have been settled via NEAR Intents solvers and credited to your Callit account.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pop(true);
            },
            child: const Text('Back to Trading'),
          ),
        ],
      ),
    );
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Deposit address copied to clipboard')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(
        title: const Text('NEAR Intents 1-Click'),
        leading: const BackButton(),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.ink,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.bolt_rounded, color: Colors.amber, size: 16),
                    SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'Cross-Chain Intent Rail • Zero Bridges',
                        style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Text('Fund with Any Chain', style: AppTextStyles.h1),
              const SizedBox(height: 6),
              Text(
                'Decentralized solvers instantly settle your deposit into Callit with zero bridging friction.',
                style: AppTextStyles.subtitle,
              ),
              const SizedBox(height: 24),

              // Asset Selector
              Text('Select Source Asset', style: AppTextStyles.h3),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _supportedAssets.map((asset) {
                    final selected = _selectedOrigin == asset['symbol'];
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text('${asset['symbol']} (${asset['blockchain']})'),
                        selected: selected,
                        onSelected: (val) {
                          if (val) {
                            setState(() {
                              _selectedOrigin = asset['symbol']!;
                              _activeQuote = null;
                              _depositAddress = null;
                            });
                          }
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 20),

              // Amount input
              Text('Deposit Amount', style: AppTextStyles.h3),
              const SizedBox(height: 10),
              TextField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  hintText: 'e.g. 1.0',
                  suffixText: _selectedOrigin,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  filled: true,
                  fillColor: AppColors.white,
                ),
                onChanged: (_) {
                  setState(() {
                    _activeQuote = null;
                    _depositAddress = null;
                  });
                },
              ),
              const SizedBox(height: 16),

              // Get Quote / Generate Address buttons
              if (_depositAddress == null) ...[
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _loadingQuote ? null : () => _getQuote(dry: true),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: _loadingQuote
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Text('Get Quote', style: TextStyle(fontWeight: FontWeight.w700)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppButton(
                        label: 'Deposit Now',
                        loading: _generatingAddress,
                        onPressed: () => _getQuote(dry: false),
                      ),
                    ),
                  ],
                ),
              ],

              // Quote Preview Card
              if (_activeQuote != null && _depositAddress == null) ...[
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.mist),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Guaranteed Intent Quote', style: AppTextStyles.h3),
                      const SizedBox(height: 12),
                      _row('You Send', '${_activeQuote!['amountInFormatted'] ?? _amountController.text} $_selectedOrigin (~\$${_activeQuote!['amountInUsd'] ?? '--'})'),
                      const Divider(height: 18),
                      _row('You Receive', '${_activeQuote!['amountOutFormatted'] ?? '--'} Destination Asset (~\$${_activeQuote!['amountOutUsd'] ?? '--'})'),
                      const Divider(height: 18),
                      _row('Settlement Time', '~${_activeQuote!['timeEstimateSec'] ?? 19} seconds'),
                      const Divider(height: 18),
                      _row('Settlement Protocol', 'NEAR Intents / Defuse'),
                    ],
                  ),
                ),
              ],

              // Active Deposit Box
              if (_depositAddress != null) ...[
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppColors.ink, width: 1.5),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.amber),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _depositStatus ?? 'AWAITING DEPOSIT',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.5),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: QrImageView(
                          data: _depositAddress!,
                          version: QrVersions.auto,
                          size: 180,
                          backgroundColor: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Send ${_amountController.text} $_selectedOrigin to this 1-click solver address:',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.caption,
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.paper,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.mist),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                _depositAddress!,
                                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.copy_rounded, size: 20),
                              onPressed: () => _copyToClipboard(_depositAddress!),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Once transferred on-chain, decentralized solvers execute the intent and fund your account in ~19s.',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.body(12, color: AppColors.slate),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTextStyles.body(14, color: AppColors.slate)),
        Text(value, style: AppTextStyles.body(14, color: AppColors.ink)),
      ],
    );
  }
}

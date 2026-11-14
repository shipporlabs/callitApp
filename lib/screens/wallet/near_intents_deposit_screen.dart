import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/widgets/app_icon.dart';
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
  final _refundController = TextEditingController();

  String _selectedOrigin = 'wNEAR';
  bool _loadingQuote = false;
  bool _generatingAddress = false;
  Map<String, dynamic>? _activeQuote;
  String? _depositAddress;
  String? _depositStatus;
  Timer? _statusTimer;

  final List<Map<String, String>> _supportedAssets = [
    {'symbol': 'wNEAR', 'name': 'NEAR Protocol', 'blockchain': 'NEAR'},
    {'symbol': 'ETH', 'name': 'Ether on Ethereum', 'blockchain': 'Ethereum'},
    {'symbol': 'SOL', 'name': 'Solana', 'blockchain': 'Solana'},
    {'symbol': 'USDC', 'name': 'USDC on Ethereum', 'blockchain': 'Ethereum'},
  ];

  /// Which chain the selected asset is sent from. The refund address has to
  /// be on that chain, and it has to be the user's own.
  String get _chain => _selectedOrigin == 'wNEAR' ? 'near' : _selectedOrigin == 'SOL' ? 'solana' : 'evm';

  String get _refundLabel => switch (_chain) {
        'near' => 'Your NEAR account (refund address)',
        'solana' => 'Your Solana address (refund address)',
        _ => 'Your Ethereum address (refund address)',
      };

  String get _refundHint => switch (_chain) {
        'near' => 'you.near',
        'solana' => 'Your Solana wallet address',
        _ => '0x…',
      };

  String? _refundError() {
    final v = _refundController.text.trim();
    if (v.isEmpty) return 'Enter your own address so a failed swap is refunded to you.';
    switch (_chain) {
      case 'near':
        final ok = RegExp(r'^[0-9a-f]{64}$').hasMatch(v) ||
            (v.length >= 2 && v.length <= 64 && RegExp(r'^([a-z0-9]+([_-][a-z0-9]+)*\.)*[a-z0-9]+([_-][a-z0-9]+)*$').hasMatch(v));
        return ok ? null : 'That is not a NEAR account. Use something like you.near.';
      case 'solana':
        return RegExp(r'^[1-9A-HJ-NP-Za-km-z]{32,44}$').hasMatch(v) ? null : 'That is not a Solana address.';
      default:
        return RegExp(r'^0x[0-9a-fA-F]{40}$').hasMatch(v) ? null : 'That is not an Ethereum address (0x followed by 40 characters).';
    }
  }

  @override
  void dispose() {
    _statusTimer?.cancel();
    _amountController.dispose();
    _refundController.dispose();
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

    final refundErr = _refundError();
    if (refundErr != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(refundErr)));
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
        refundTo: _refundController.text.trim(),
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
            AppIcon(Ic.check, color: Colors.green, size: 28),
            SizedBox(width: 10),
            Text('Deposit Received!'),
          ],
        ),
        content: const Text(
          'Your swap finished. The SOL or USDC is in your Solana wallet now. Pull down on the wallet screen to refresh your balance.',
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
                    AppIcon(Ic.bolt, color: Colors.amber, size: 16),
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
                              _refundController.clear();
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

              // Refund address: must be the user's own, on the chain they pay from
              Text(_refundLabel, style: AppTextStyles.h3),
              const SizedBox(height: 6),
              Text(
                'If the swap cannot finish, your funds go back here. Use your own address.',
                style: AppTextStyles.body(12, color: AppColors.slate),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _refundController,
                autocorrect: false,
                enableSuggestions: false,
                decoration: InputDecoration(
                  hintText: _refundHint,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  filled: true,
                  fillColor: AppColors.white,
                ),
                onChanged: (_) => setState(() {
                  _activeQuote = null;
                  _depositAddress = null;
                }),
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
                      _row('You Send', '${_activeQuote!['amountInFormatted'] ?? _amountController.text} $_selectedOrigin (~${_usd(_activeQuote!['amountInUsd'])})'),
                      const Divider(height: 18),
                      _row('You Receive', '${_amt(_activeQuote!['amountOutFormatted'])} SOL (~${_usd(_activeQuote!['amountOutUsd'])})'),
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
                    border: Border.all(color: AppColors.mist, width: 1.2),
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
                              icon: const AppIcon(Ic.copy, size: 20),
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

  /// "3.220000000000" -> "$3.22"
  String _usd(dynamic v) {
    final n = double.tryParse('${v ?? ''}');
    return n == null ? '--' : '\$${n.toStringAsFixed(2)}';
  }

  /// "0.043120805" -> "0.0431"
  String _amt(dynamic v) {
    final n = double.tryParse('${v ?? ''}');
    if (n == null) return '--';
    return n >= 1 ? n.toStringAsFixed(2) : n.toStringAsFixed(4);
  }

  Widget _row(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.body(14, color: AppColors.slate)),
        const SizedBox(width: 12),
        Expanded(child: Text(value, textAlign: TextAlign.right, style: AppTextStyles.body(14, color: AppColors.ink))),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import '../../core/widgets/app_button.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

import '../../core/api/solana_service.dart';

/// A simple SOL → USDC (or reverse) convert screen — the everyday "top up
/// my trading balance" step most first-time traders need before backing
/// a side. Wire this to a swap aggregator or Panta-adjacent liquidity.
class ConvertScreen extends StatefulWidget {
  const ConvertScreen({super.key});

  @override
  State<ConvertScreen> createState() => _ConvertScreenState();
}

class _ConvertScreenState extends State<ConvertScreen> {
  bool _solToUsdc = true;
  final _amountController = TextEditingController(text: '1.0');
  bool _converting = false;
  double _rate = 150.0;
  bool _loadingRate = true;

  @override
  void initState() {
    super.initState();
    _fetchRate();
  }

  Future<void> _fetchRate() async {
    final rate = await SolanaService.instance.getSolUsdRate();
    if (!mounted) return;
    setState(() {
      _rate = rate;
      _loadingRate = false;
    });
  }

  double get _amount => double.tryParse(_amountController.text) ?? 0;
  double get _output => _solToUsdc ? _amount * _rate : _amount / _rate;

  void _swap() => setState(() => _solToUsdc = !_solToUsdc);

  void _convert() async {
    setState(() => _converting = true);
    // Hook point: call your swap route, then refresh the wallet balance.
    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;
    setState(() => _converting = false);
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Converted successfully')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fromLabel = _solToUsdc ? 'SOL' : 'USDC';
    final toLabel = _solToUsdc ? 'USDC' : 'SOL';

    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(leading: const BackButton(), title: Text('Convert', style: AppTextStyles.h3)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _AmountCard(
                label: 'You pay',
                asset: fromLabel,
                controller: _amountController,
                editable: true,
              ),
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Material(
                    color: AppColors.ink,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: _swap,
                      child: const Padding(
                        padding: EdgeInsets.all(10),
                        child: Icon(Icons.swap_vert_rounded, color: AppColors.paper, size: 20),
                      ),
                    ),
                  ),
                ),
              ),
              _AmountCard(
                label: 'You receive',
                asset: toLabel,
                value: _output.toStringAsFixed(_solToUsdc ? 2 : 4),
                editable: false,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: AppColors.white, border: Border.all(color: AppColors.mist), borderRadius: BorderRadius.circular(14)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Rate', style: AppTextStyles.body(13, color: AppColors.slate)),
                    Text('1 SOL ≈ $_rate USDC', style: AppTextStyles.tabularNums(13)),
                  ],
                ),
              ),
              const Spacer(),
              AppButton(label: 'Convert', loading: _converting, onPressed: _amount > 0 ? _convert : null),
            ],
          ),
        ),
      ),
    );
  }
}

class _AmountCard extends StatelessWidget {
  const _AmountCard({
    required this.label,
    required this.asset,
    this.controller,
    this.value,
    required this.editable,
  });

  final String label;
  final String asset;
  final TextEditingController? controller;
  final String? value;
  final bool editable;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: AppColors.white, border: Border.all(color: AppColors.mist), borderRadius: BorderRadius.circular(18)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.caption),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: editable
                    ? TextField(
                        controller: controller,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        style: AppTextStyles.h2,
                        decoration: const InputDecoration(border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.zero),
                      )
                    : Text(value ?? '0', style: AppTextStyles.h2),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(color: AppColors.mist, borderRadius: BorderRadius.circular(999)),
                child: Text(asset, style: AppTextStyles.body(13, weight: FontWeight.w700)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

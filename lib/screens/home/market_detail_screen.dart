import 'package:flutter/material.dart';
import '../../core/widgets/app_avatar.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/pill_chip.dart';
import '../../core/widgets/yes_no_bar.dart';
import '../../models/market.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

class MarketDetailScreen extends StatefulWidget {
  const MarketDetailScreen({super.key, required this.market});

  final Market market;

  @override
  State<MarketDetailScreen> createState() => _MarketDetailScreenState();
}

class _MarketDetailScreenState extends State<MarketDetailScreen> {
// true = YES, false = NO
  final _amountController = TextEditingController(text: '10');

  void _openTradeSheet(bool side) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _TradeSheet(
        market: widget.market,
        side: side,
        amountController: _amountController,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final market = widget.market;
    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(
        leading: const BackButton(),
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.ios_share_rounded)),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                PillChip(label: market.category),
                if (market.isGraduated)
                  const PillChip(label: 'GRADUATED', background: AppColors.highlight, foreground: AppColors.ink),
              ],
            ),
            const SizedBox(height: 16),
            Text(market.question, style: AppTextStyles.h1.copyWith(fontSize: 26)),
            const SizedBox(height: 10),
            Row(
              children: [
                AppAvatar(initials: market.creatorInitials, size: 26),
                const SizedBox(width: 8),
                Text(market.creatorHandle, style: AppTextStyles.caption),
                const SizedBox(width: 12),
                const Icon(Icons.circle, size: 4, color: AppColors.slate),
                const SizedBox(width: 12),
                Text(market.resolvesLabel, style: AppTextStyles.caption),
              ],
            ),
            const SizedBox(height: 28),
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
                  Text('Current odds', style: AppTextStyles.body(13, weight: FontWeight.w600, color: AppColors.slate)),
                  const SizedBox(height: 12),
                  YesNoBar(yesPct: market.yesPricePct, height: 14),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: _SideButton(
                          label: 'Back YES',
                          color: AppColors.yes,
                          onTap: () => _openTradeSheet(true),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _SideButton(
                          label: 'Back NO',
                          color: AppColors.no,
                          onTap: () => _openTradeSheet(false),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            Text('Resolution rule', style: AppTextStyles.h3),
            const SizedBox(height: 8),
            Text(
              'Resolves YES or NO based on the official result at close. Disputes are settled against the sources below.',
              style: AppTextStyles.body(14, color: AppColors.slate, height: 1.5),
            ),
            const SizedBox(height: 20),
            Text('Sources of truth', style: AppTextStyles.h3),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.white,
                border: Border.all(color: AppColors.mist),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(Icons.link, size: 18, color: AppColors.slate),
                  const SizedBox(width: 10),
                  Expanded(child: Text('Official result feed', style: AppTextStyles.body(14, weight: FontWeight.w600))),
                  const Icon(Icons.open_in_new, size: 16, color: AppColors.slate),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SideButton extends StatelessWidget {
  const _SideButton({required this.label, required this.color, required this.onTap});

  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Center(
            child: Text(label, style: AppTextStyles.button.copyWith(color: AppColors.white)),
          ),
        ),
      ),
    );
  }
}

/// Mirrors Panta's real flow: quote → build → sign in wallet → broadcast →
/// confirm. Here it's simulated end to end so the interaction is complete;
/// wire the marked steps to the server proxy for the live version.
class _TradeSheet extends StatefulWidget {
  const _TradeSheet({required this.market, required this.side, required this.amountController});

  final Market market;
  final bool side;
  final TextEditingController amountController;

  @override
  State<_TradeSheet> createState() => _TradeSheetState();
}

enum _TradeStep { amount, signing, done }

class _TradeSheetState extends State<_TradeSheet> {
  _TradeStep _step = _TradeStep.amount;

  void _confirm() async {
    setState(() => _step = _TradeStep.signing);
    // Hook point: POST /orders/quote/ → /orders/build/ → wallet sign →
    // broadcast → /orders/submit/ → /orders/verify/.
    await Future.delayed(const Duration(milliseconds: 1400));
    if (!mounted) return;
    setState(() => _step = _TradeStep.done);
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.side ? AppColors.yes : AppColors.no;
    final label = widget.side ? 'YES' : 'NO';

    return Container(
      padding: EdgeInsets.fromLTRB(24, 20, 24, 20 + MediaQuery.of(context).viewInsets.bottom),
      decoration: const BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(color: AppColors.mist, borderRadius: BorderRadius.circular(999)),
            ),
          ),
          if (_step == _TradeStep.amount) ...[
            Row(
              children: [
                PillChip(label: 'Back $label', background: color, foreground: AppColors.white),
              ],
            ),
            const SizedBox(height: 16),
            Text('Amount (USDC)', style: AppTextStyles.body(13, weight: FontWeight.w600, color: AppColors.slate)),
            const SizedBox(height: 8),
            TextField(
              controller: widget.amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: AppTextStyles.h2,
              decoration: const InputDecoration(prefixText: '\$ '),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: ['5', '10', '25', '50'].map((v) {
                return ChoiceChip(
                  label: Text('\$$v'),
                  selected: widget.amountController.text == v,
                  onSelected: (_) => setState(() => widget.amountController.text = v),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            AppButton(label: 'Review and sign', onPressed: _confirm),
          ] else if (_step == _TradeStep.signing) ...[
            const SizedBox(height: 24),
            const Center(child: CircularProgressIndicator(color: AppColors.ink)),
            const SizedBox(height: 20),
            Text('Waiting for your wallet to sign…', style: AppTextStyles.subtitle, textAlign: TextAlign.center),
            const SizedBox(height: 40),
          ] else ...[
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: const BoxDecoration(color: AppColors.yes, shape: BoxShape.circle),
                    child: const Icon(Icons.check_rounded, color: AppColors.white, size: 32),
                  ),
                  const SizedBox(height: 16),
                  Text('Position confirmed', style: AppTextStyles.h2),
                  const SizedBox(height: 8),
                  Text(
                    'You backed $label with \$${widget.amountController.text} USDC.',
                    style: AppTextStyles.subtitle,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  AppButton(label: 'Done', onPressed: () => Navigator.of(context).pop()),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

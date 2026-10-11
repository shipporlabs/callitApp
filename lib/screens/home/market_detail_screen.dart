import 'dart:math';

import 'package:flutter/material.dart';
import '../../core/api/api_exception.dart';
import '../../core/api/callit_api.dart';
import '../../core/api/token_store.dart';
import '../../core/widgets/app_avatar.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/pill_chip.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/yes_no_bar.dart';
import '../../models/market.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../wallet/add_wallet_screen.dart';

class MarketDetailScreen extends StatefulWidget {
  const MarketDetailScreen({super.key, required this.market});

  final Market market;

  @override
  State<MarketDetailScreen> createState() => _MarketDetailScreenState();
}

class _MarketDetailScreenState extends State<MarketDetailScreen> {
  late Market _market = widget.market;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  List<Map<String, dynamic>> _trades = [];
  bool _loadingTrades = true;

  /// Best-effort: refresh with live odds from `GET /markets/{id}` and
  /// recent trade activity from `GET /markets/{id}/trades`.
  Future<void> _refresh() async {
    if (_market.id.isEmpty) return;
    try {
      final jsonFuture = callitApi.getMarket(_market.id);
      final tradesFuture = callitApi.getMarketTrades(_market.id);
      final json = await jsonFuture;
      final trades = await tradesFuture;
      if (!mounted) return;
      setState(() {
        _market = Market.fromApi(json);
        _trades = trades.whereType<Map<String, dynamic>>().toList();
        _loadingTrades = false;
      });
    } catch (_) {
      // Keep showing what we were passed.
      if (mounted) setState(() => _loadingTrades = false);
    }
  }

  bool _sharing = false;

  Future<void> _shareMarket() async {
    if (_sharing) return;
    setState(() => _sharing = true);
    try {
      final card = await callitApi.createShareCard(widget.market.id);
      final shareUrl = card['deepLink'] as String? ?? card['imageUrl'] as String? ?? 'https://callit.my/market/${widget.market.id}';
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Share link ready: $shareUrl')));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Couldn't prepare share card right now.")));
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  void _openTradeSheet(bool side) {
    if (!TokenStore.instance.hasWallet) {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AddWalletScreen())).then((_) {
        if (TokenStore.instance.hasWallet && mounted) _openTradeSheet(side);
      });
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _TradeSheet(market: _market, side: side),
    );
  }

  @override
  Widget build(BuildContext context) {
    final market = _market;
    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(
        leading: const BackButton(),
        actions: [
          IconButton(
            onPressed: _sharing ? null : _shareMarket,
            icon: _sharing
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.ios_share_rounded),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          children: [
            if (market.imagePath != null && market.imagePath!.isNotEmpty) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  market.imagePath!,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
              const SizedBox(height: 16),
            ],
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
                if (market.creatorHandle.isNotEmpty) ...[
                  AppAvatar(initials: market.creatorInitials, size: 26),
                  const SizedBox(width: 8),
                  Text(market.creatorHandle, style: AppTextStyles.caption),
                  const SizedBox(width: 12),
                  const Icon(Icons.circle, size: 4, color: AppColors.slate),
                  const SizedBox(width: 12),
                ],
                Text(market.resolvesLabel, style: AppTextStyles.caption),
              ],
            ),
            const SizedBox(height: 28),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.white,
                border: Border.all(color: AppColors.ink, width: 1.3),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('CURRENT ODDS', style: AppTextStyles.label(12, weight: FontWeight.w700, color: AppColors.slate)),
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
            const SectionHeader(number: 2, title: 'Resolution rule'),
            const SizedBox(height: 8),
            Text(
              'Resolves YES or NO based on the official result at close. Disputes are settled against the sources below.',
              style: AppTextStyles.body(14, color: AppColors.slate, height: 1.5),
            ),
            const SizedBox(height: 20),
            const SectionHeader(number: 3, title: 'Sources of truth'),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.white,
                border: Border.all(color: AppColors.ink, width: 1.3),
                borderRadius: BorderRadius.circular(8),
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
            const SizedBox(height: 28),
            const SectionHeader(number: 4, title: 'Recent activity'),
            const SizedBox(height: 10),
            if (_loadingTrades)
              const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator(color: AppColors.ink)))
            else if (_trades.isEmpty)
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  border: Border.all(color: AppColors.ink, width: 1.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text('No trades yet — be the first to call it!', style: AppTextStyles.caption),
                ),
              )
            else
              Container(
                decoration: BoxDecoration(
                  color: AppColors.white,
                  border: Border.all(color: AppColors.ink, width: 1.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _trades.length > 5 ? 5 : _trades.length,
                  separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.mist),
                  itemBuilder: (context, i) {
                    final t = _trades[i];
                    final isYes = (t['side']?.toString().toLowerCase() == 'yes');
                    final amount = t['amountUsdc']?.toString() ?? t['shares']?.toString() ?? '—';
                    final wallet = t['wallet']?.toString() ?? '';
                    final shortWallet = wallet.length > 8 ? '${wallet.substring(0, 4)}…${wallet.substring(wallet.length - 4)}' : wallet;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isYes ? AppColors.yes.withOpacity(0.12) : AppColors.no.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  isYes ? 'YES' : 'NO',
                                  style: AppTextStyles.tabularNums(12, weight: FontWeight.w700, color: isYes ? AppColors.yes : AppColors.no),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(shortWallet.isNotEmpty ? shortWallet : 'Trader', style: AppTextStyles.body(13, weight: FontWeight.w500)),
                            ],
                          ),
                          Text('\$$amount USDC', style: AppTextStyles.tabularNums(13, weight: FontWeight.w600)),
                        ],
                      ),
                    );
                  },
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
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.ink, width: 1.4),
            borderRadius: BorderRadius.circular(6),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Center(
            child: Text(label.toUpperCase(), style: AppTextStyles.button.copyWith(color: AppColors.white)),
          ),
        ),
      ),
    );
  }
}

/// Panta's real buy flow: quote → build → sign in wallet → broadcast →
/// submit → verify. Every step here except the signature itself hits the
/// live Callit API; the signature is a placeholder until a real Solana
/// Mobile Wallet Adapter session is wired into [AddWalletScreen] (that's
/// the one step a server proxy can never do for you — Panta is
/// non-custodial by design).
class _TradeSheet extends StatefulWidget {
  const _TradeSheet({required this.market, required this.side});

  final Market market;
  final bool side;

  @override
  State<_TradeSheet> createState() => _TradeSheetState();
}

enum _TradeStep { amount, signing, done, error }

class _TradeSheetState extends State<_TradeSheet> {
  _TradeStep _step = _TradeStep.amount;
  final _amountController = TextEditingController(text: '10');
  String? _errorMessage;
  Map<String, dynamic>? _quote;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _confirm() async {
    final wallet = TokenStore.instance.walletAddress!;
    setState(() => _step = _TradeStep.signing);
    try {
      final quote = await callitApi.orderQuote(
        wallet: wallet,
        marketId: widget.market.id,
        side: widget.side,
        amountUsdc: double.parse(_amountController.text).toStringAsFixed(2),
      );
      final build = await callitApi.orderBuild(quoteId: quote['quoteId'] as String, wallet: wallet);

      // Hook point: hand `build['transaction']` (base64) to Solana Mobile
      // Wallet Adapter for the user's real signature. Simulated here.
      await Future.delayed(const Duration(milliseconds: 900));
      final signature = _mockSignature();

      final orderId = build['orderId'] as String;
      await callitApi.orderSubmit(orderId: orderId, signature: signature);
      await callitApi.orderVerify(orderId: orderId, signature: signature);
      await callitApi.reportTrade(signature: signature, wallet: wallet, marketId: widget.market.id, quoteId: quote['quoteId'] as String);
      try {
        await callitApi.tradeStatus(signature);
      } catch (_) {}

      if (!mounted) return;
      setState(() {
        _quote = quote;
        _step = _TradeStep.done;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.message;
        _step = _TradeStep.error;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Something went wrong placing that trade.';
        _step = _TradeStep.error;
      });
    }
  }

  String _mockSignature() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz123456789';
    final rand = Random();
    return List.generate(64, (_) => chars[rand.nextInt(chars.length)]).join();
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
              controller: _amountController,
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
                  selected: _amountController.text == v,
                  onSelected: (_) => setState(() => _amountController.text = v),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            AppButton(
              label: 'Review and sign',
              onPressed: (double.tryParse(_amountController.text) ?? 0) > 0 ? _confirm : null,
            ),
          ] else if (_step == _TradeStep.signing) ...[
            const SizedBox(height: 24),
            const Center(child: CircularProgressIndicator(color: AppColors.ink)),
            const SizedBox(height: 20),
            Text('Waiting for your wallet to sign…', style: AppTextStyles.subtitle, textAlign: TextAlign.center),
            const SizedBox(height: 40),
          ] else if (_step == _TradeStep.error) ...[
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: const BoxDecoration(color: AppColors.no, shape: BoxShape.circle),
                    child: const Icon(Icons.close_rounded, color: AppColors.white, size: 32),
                  ),
                  const SizedBox(height: 16),
                  Text('Trade failed', style: AppTextStyles.h2),
                  const SizedBox(height: 8),
                  Text(_errorMessage ?? 'Please try again.', style: AppTextStyles.subtitle, textAlign: TextAlign.center),
                  const SizedBox(height: 24),
                  AppButton(label: 'Try again', onPressed: () => setState(() => _step = _TradeStep.amount)),
                ],
              ),
            ),
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
                    'You backed $label with \$${_amountController.text} USDC'
                    '${_quote?['shares'] != null ? ' for ${_quote!['shares']} shares' : ''}.',
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

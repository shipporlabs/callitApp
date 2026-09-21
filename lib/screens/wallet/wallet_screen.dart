import 'package:flutter/material.dart';
import '../../core/widgets/market_card.dart';
import '../../core/widgets/section_header.dart';
import '../../data/mock_markets.dart';
import '../../models/wallet_balance.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../home/market_detail_screen.dart';
import 'add_wallet_screen.dart';
import 'convert_screen.dart';

const _mockWallet = WalletBalance(
  address: '7xKXtg2CW87d97TXJSDpbD5jBkheTqA83TZRuJosgAsU',
  solBalance: 2.418,
  usdcBalance: 64.20,
  providerName: 'Phantom',
);

class WalletScreen extends StatelessWidget {
  const WalletScreen({super.key});

  static const bool _connected = true; // toggle to preview the empty state

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(title: Text('Wallet', style: AppTextStyles.h3)),
      body: SafeArea(
        child: _connected ? _ConnectedWallet() : const _DisconnectedWallet(),
      ),
    );
  }
}

class _DisconnectedWallet extends StatelessWidget {
  const _DisconnectedWallet();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.account_balance_wallet_outlined, size: 48, color: AppColors.slate),
            const SizedBox(height: 16),
            Text('No wallet connected', style: AppTextStyles.h3),
            const SizedBox(height: 8),
            Text('Connect a wallet to trade and track positions.', style: AppTextStyles.subtitle, textAlign: TextAlign.center),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AddWalletScreen())),
              child: const Text('Connect wallet'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConnectedWallet extends StatelessWidget {
  const _ConnectedWallet();

  @override
  Widget build(BuildContext context) {
    final positions = mockMarkets.take(2).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      children: [
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(color: AppColors.ink, borderRadius: BorderRadius.circular(24)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(_mockWallet.providerName, style: AppTextStyles.body(13, color: AppColors.inkMuted, weight: FontWeight.w600)),
                  Row(
                    children: [
                      Container(width: 6, height: 6, decoration: const BoxDecoration(color: AppColors.yes, shape: BoxShape.circle)),
                      const SizedBox(width: 6),
                      Text(_mockWallet.shortAddress, style: AppTextStyles.tabularNums(12, color: AppColors.inkMuted2)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 22),
              Text('Total balance', style: AppTextStyles.body(13, color: AppColors.inkMuted)),
              const SizedBox(height: 6),
              Text('\$${_mockWallet.usdcBalance.toStringAsFixed(2)}', style: AppTextStyles.display(36, color: AppColors.paper)),
              const SizedBox(height: 4),
              Text('${_mockWallet.solBalance.toStringAsFixed(3)} SOL also available', style: AppTextStyles.body(13, color: AppColors.inkMuted)),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(child: _WalletAction(icon: Icons.call_received_rounded, label: 'Receive', onTap: () {})),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _WalletAction(
                      icon: Icons.swap_horiz_rounded,
                      label: 'Convert',
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ConvertScreen())),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: _WalletAction(icon: Icons.ios_share_rounded, label: 'Send', onTap: () {})),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        SectionHeader(title: 'Your positions', action: 'See all', onActionTap: () {}),
        const SizedBox(height: 14),
        ...positions.map((m) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: MarketCard(
                market: m,
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => MarketDetailScreen(market: m))),
              ),
            )),
      ],
    );
  }
}

class _WalletAction extends StatelessWidget {
  const _WalletAction({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.inkSurface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Column(
            children: [
              Icon(icon, color: AppColors.highlight, size: 20),
              const SizedBox(height: 6),
              Text(label, style: AppTextStyles.body(12, weight: FontWeight.w600, color: AppColors.paper)),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../core/api/token_store.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import 'add_wallet_screen.dart';
import 'crypto_deposit_screen.dart';
import 'fund_wallet_screen.dart';
import 'near_intents_deposit_screen.dart';

Future<void> showDepositSelectionSheet(
  BuildContext context, {
  required String walletAddress,
  VoidCallback? onFunded,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => DepositSelectionSheet(
      walletAddress: walletAddress,
      onFunded: onFunded,
    ),
  );
}

class DepositSelectionSheet extends StatelessWidget {
  const DepositSelectionSheet({
    super.key,
    required this.walletAddress,
    this.onFunded,
  });

  final String walletAddress;
  final VoidCallback? onFunded;

  void _handleNairaDeposit(BuildContext context) async {
    final nav = Navigator.of(context);
    nav.pop(); // dismiss sheet

    if (!TokenStore.instance.hasWallet) {
      final connected = await nav.push<bool>(
        MaterialPageRoute(builder: (_) => const AddWalletScreen()),
      );
      if (connected != true || !TokenStore.instance.hasWallet) return;
    }

    final address = walletAddress.isNotEmpty
        ? walletAddress
        : (TokenStore.instance.walletAddress ?? '');

    final result = await nav.push<bool>(
      MaterialPageRoute(builder: (_) => FundWalletScreen(walletAddress: address)),
    );
    if (result == true && onFunded != null) {
      onFunded!();
    }
  }

  void _handleCryptoDeposit(BuildContext context) async {
    final nav = Navigator.of(context);
    nav.pop(); // dismiss sheet

    if (!TokenStore.instance.hasWallet) {
      final connected = await nav.push<bool>(
        MaterialPageRoute(builder: (_) => const AddWalletScreen()),
      );
      if (connected != true || !TokenStore.instance.hasWallet) return;
    }

    final address = walletAddress.isNotEmpty
        ? walletAddress
        : (TokenStore.instance.walletAddress ?? '');

    nav.push(
      MaterialPageRoute(builder: (_) => CryptoDepositScreen(walletAddress: address)),
    );
  }

  void _handleNearIntentsDeposit(BuildContext context) async {
    final nav = Navigator.of(context);
    nav.pop(); // dismiss sheet

    if (!TokenStore.instance.hasWallet) {
      final connected = await nav.push<bool>(
        MaterialPageRoute(builder: (_) => const AddWalletScreen()),
      );
      if (connected != true || !TokenStore.instance.hasWallet) return;
    }

    final address = walletAddress.isNotEmpty
        ? walletAddress
        : (TokenStore.instance.walletAddress ?? '');

    nav.push(
      MaterialPageRoute(builder: (_) => NearIntentsDepositScreen(walletAddress: address)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 36),
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
              decoration: BoxDecoration(
                color: AppColors.mist,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          Text('Deposit Funds', style: AppTextStyles.h2),
          const SizedBox(height: 6),
          Text(
            'Select your preferred deposit rail to top up your trading balance.',
            style: AppTextStyles.caption,
          ),
          const SizedBox(height: 20),

          // Option A: Naira Bank Transfer
          _DepositOptionTile(
            title: 'Naira Bank Transfer',
            subtitle: 'Instant transfer via Nigerian banks (OPay, Kuda, GTBank)',
            badge: 'Instant NGN',
            icon: Icons.account_balance_rounded,
            onTap: () => _handleNairaDeposit(context),
          ),
          const SizedBox(height: 12),

          // Option B: Solana Crypto
          _DepositOptionTile(
            title: 'Solana Crypto',
            subtitle: 'Send USDC, USDT, or SOL from Phantom, Binance, or Bybit',
            badge: 'USDC / SOL',
            icon: Icons.qr_code_2_rounded,
            onTap: () => _handleCryptoDeposit(context),
          ),
          const SizedBox(height: 12),

          // Option C: NEAR Intents 1-Click Multi-Chain
          _DepositOptionTile(
            title: 'NEAR Intents',
            subtitle: '1-Click cross-chain swap from NEAR, Base, ETH, Arbitrum',
            badge: '1-Click Swap',
            icon: Icons.bolt_rounded,
            onTap: () => _handleNearIntentsDeposit(context),
          ),
        ],
      ),
    );
  }
}

class _DepositOptionTile extends StatelessWidget {
  const _DepositOptionTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.badge,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final String badge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.ink, width: 1.2),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: badge.contains('1-Click') ? AppColors.highlight : AppColors.mist,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.ink, width: 1.1),
                ),
                child: Icon(icon, size: 22, color: AppColors.ink),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          title,
                          style: AppTextStyles.body(15, weight: FontWeight.w700),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: badge.contains('1-Click') ? AppColors.highlight : AppColors.mist,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: AppColors.ink, width: 0.8),
                          ),
                          child: Text(
                            badge,
                            style: AppTextStyles.label(9, weight: FontWeight.w700, color: AppColors.ink),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: AppTextStyles.caption.copyWith(color: AppColors.slate, height: 1.25),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.ink),
            ],
          ),
        ),
      ),
    );
  }
}

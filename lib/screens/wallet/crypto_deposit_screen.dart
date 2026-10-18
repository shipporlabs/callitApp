import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../core/api/token_store.dart';
import '../../core/widgets/app_button.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

class CryptoDepositScreen extends StatelessWidget {
  const CryptoDepositScreen({super.key, required this.walletAddress});

  final String walletAddress;

  void _copyAddress(BuildContext context, String address) {
    if (address.isEmpty) return;
    Clipboard.setData(ClipboardData(text: address));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Solana address copied to clipboard!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final address = walletAddress.isNotEmpty
        ? walletAddress
        : (TokenStore.instance.walletAddress ?? '');

    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(
        leading: const BackButton(),
        title: Text('Deposit Crypto', style: AppTextStyles.h3),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            // Network warning banner
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.no.withOpacity(0.08),
                border: Border.all(color: AppColors.no.withOpacity(0.25)),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.warning_amber_rounded, color: AppColors.no, size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Only send Solana (SPL) tokens (USDC, USDT, SOL) to this address. Sending assets from other networks (e.g. Ethereum or BSC) may result in permanent loss.',
                      style: AppTextStyles.body(13, color: AppColors.ink, weight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // QR Code Card
            Center(
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.mist),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.ink.withOpacity(0.04),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    if (address.isNotEmpty)
                      QrImageView(
                        data: address,
                        version: QrVersions.auto,
                        size: 210,
                        backgroundColor: Colors.white,
                        eyeStyle: const QrEyeStyle(
                          eyeShape: QrEyeShape.square,
                          color: AppColors.ink,
                        ),
                        dataModuleStyle: const QrDataModuleStyle(
                          dataModuleShape: QrDataModuleShape.square,
                          color: AppColors.ink,
                        ),
                      )
                    else
                      Container(
                        width: 210,
                        height: 210,
                        alignment: Alignment.center,
                        child: Text('No wallet address found', style: AppTextStyles.subtitle),
                      ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.yes,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Solana Mainnet (SPL)',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.slate,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Supported Asset Tags
            Text('Supported Assets', style: AppTextStyles.body(14, weight: FontWeight.w700)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: const [
                _AssetBadge(label: 'USDC (Solana)', isPrimary: true),
                _AssetBadge(label: 'USDT (Solana)'),
                _AssetBadge(label: 'SOL'),
              ],
            ),
            const SizedBox(height: 24),

            // Address display card
            Text('Your Deposit Address', style: AppTextStyles.body(14, weight: FontWeight.w700)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.mist),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SelectableText(
                    address,
                    style: AppTextStyles.tabularNums(13, weight: FontWeight.w600, color: AppColors.ink),
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: () => _copyAddress(context, address),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.mist.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.copy_rounded, size: 16, color: AppColors.ink),
                          const SizedBox(width: 6),
                          Text('Copy Address', style: AppTextStyles.body(13, weight: FontWeight.w700)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            AppButton(
              label: 'Copy Address',
              onPressed: () => _copyAddress(context, address),
            ),
          ],
        ),
      ),
    );
  }
}

class _AssetBadge extends StatelessWidget {
  const _AssetBadge({required this.label, this.isPrimary = false});

  final String label;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isPrimary ? AppColors.ink : AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isPrimary ? AppColors.ink : AppColors.mist),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.check_circle_rounded,
            size: 14,
            color: isPrimary ? AppColors.highlight : AppColors.yes,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: isPrimary ? AppColors.paper : AppColors.ink,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

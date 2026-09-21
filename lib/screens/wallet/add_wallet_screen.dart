import 'package:flutter/material.dart';
import '../../core/app_images.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_image.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../home/home_screen.dart';

/// Wallet connect, using Solana Mobile Wallet Adapter in the real app —
/// this simulates the provider picker and the approval round trip.
/// `fromSignUp` controls whether "Skip for now" is offered.
class AddWalletScreen extends StatefulWidget {
  const AddWalletScreen({super.key, this.fromSignUp = false});

  final bool fromSignUp;

  @override
  State<AddWalletScreen> createState() => _AddWalletScreenState();
}

class _AddWalletScreenState extends State<AddWalletScreen> {
  String? _connecting;

  void _connect(String provider) async {
    setState(() => _connecting = provider);
    // Hook point: launch Solana Mobile Wallet Adapter, request
    // authorization, store the returned public key.
    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;
    if (widget.fromSignUp) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (route) => false,
      );
    } else {
      Navigator.of(context).pop(true);
    }
  }

  void _skip() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(
        leading: widget.fromSignUp ? null : const BackButton(),
        automaticallyImplyLeading: !widget.fromSignUp,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 0, 28, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppImage(
                AppImages.walletConnected,
                width: 140,
                height: 140,
                fallbackIcon: Icons.account_balance_wallet_outlined,
                backgroundColor: AppColors.mist.withOpacity(0.5),
                borderRadius: BorderRadius.circular(24),
              ),
              const SizedBox(height: 24),
              Text('Connect a wallet', style: AppTextStyles.h1),
              const SizedBox(height: 8),
              Text(
                'Callit never holds your keys. Panta builds every transaction, your wallet signs it.',
                style: AppTextStyles.subtitle,
              ),
              const SizedBox(height: 28),
              _WalletOption(
                label: 'Phantom',
                connecting: _connecting == 'Phantom',
                onTap: () => _connect('Phantom'),
              ),
              const SizedBox(height: 12),
              _WalletOption(
                label: 'Solflare',
                connecting: _connecting == 'Solflare',
                onTap: () => _connect('Solflare'),
              ),
              const SizedBox(height: 12),
              _WalletOption(
                label: 'Other Solana wallet',
                icon: Icons.qr_code_rounded,
                connecting: _connecting == 'Other',
                onTap: () => _connect('Other'),
              ),
              const Spacer(),
              if (widget.fromSignUp)
                Center(
                  child: TextButton(onPressed: _skip, child: const Text('Skip for now')),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WalletOption extends StatelessWidget {
  const _WalletOption({required this.label, required this.onTap, required this.connecting, this.icon});

  final String label;
  final VoidCallback onTap;
  final bool connecting;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: connecting ? null : onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(border: Border.all(color: AppColors.mist), borderRadius: BorderRadius.circular(16)),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(color: AppColors.mist, shape: BoxShape.circle),
                child: Icon(icon ?? Icons.account_balance_wallet_rounded, size: 18, color: AppColors.ink),
              ),
              const SizedBox(width: 14),
              Expanded(child: Text(label, style: AppTextStyles.body(15, weight: FontWeight.w700))),
              if (connecting)
                const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.2))
              else
                const Icon(Icons.chevron_right_rounded, color: AppColors.slate),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../core/api/callit_api.dart';
import '../../core/api/token_store.dart';
import '../../core/widgets/app_avatar.dart';
import '../../core/widgets/app_button.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../auth/welcome_screen.dart';
import '../wallet/wallet_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  List<Map<String, dynamic>> _myMarkets = [];
  bool _loading = true;
  bool _claiming = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final result = await callitApi.myMarkets();
      if (!mounted) return;
      setState(() {
        _myMarkets = result.cast<Map<String, dynamic>>();
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  double _sumNumField(String key) {
    var total = 0.0;
    for (final m in _myMarkets) {
      final raw = m[key];
      final parsed = raw is num ? raw.toDouble() : double.tryParse(raw?.toString() ?? '');
      if (parsed != null) total += parsed;
    }
    return total;
  }

  Future<void> _claimAllFees() async {
    final wallet = TokenStore.instance.walletAddress;
    if (wallet == null || _myMarkets.isEmpty) return;
    setState(() => _claiming = true);
    var claimed = 0;
    for (final m in _myMarkets) {
      final marketId = m['marketId'] as String?;
      if (marketId == null) continue;
      try {
        await callitApi.claimCreatorFees(wallet: wallet, marketId: marketId);
        claimed++;
      } catch (_) {
        // Keep going — some markets may have nothing to claim yet.
      }
    }
    if (!mounted) return;
    setState(() => _claiming = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(claimed > 0 ? 'Built $claimed claim(s) — sign them in your wallet to finish.' : "Nothing to claim right now.")),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userName = TokenStore.instance.userName ?? 'Your account';
    final userEmail = TokenStore.instance.userEmail ?? '';
    final initials = userName.trim().isEmpty
        ? '?'
        : userName.trim().split(RegExp(r'\s+')).map((w) => w[0]).take(2).join().toUpperCase();

    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(title: Text('Profile', style: AppTextStyles.h3)),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
            children: [
              Row(
                children: [
                  AppAvatar(initials: initials, size: 56),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(userName, style: AppTextStyles.h3),
                        const SizedBox(height: 2),
                        Text(userEmail, style: AppTextStyles.caption),
                      ],
                    ),
                  ),
                  IconButton(onPressed: () {}, icon: const Icon(Icons.settings_outlined, color: AppColors.ink)),
                ],
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: AppColors.ink, borderRadius: BorderRadius.circular(22)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Creator dashboard', style: AppTextStyles.display(16, weight: FontWeight.w600, color: AppColors.paper)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: AppColors.yes.withOpacity(0.18), borderRadius: BorderRadius.circular(999)),
                          child: Text('LIVE', style: AppTextStyles.body(11, weight: FontWeight.w700, color: AppColors.yes)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(child: _StatTile(label: 'Markets created', value: _loading ? '—' : '${_myMarkets.length}')),
                        const SizedBox(width: 12),
                        Expanded(child: _StatTile(label: 'Trading volume', value: _loading ? '—' : '\$${_sumNumField('volumeUsdc').toStringAsFixed(0)}')),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _StatTile(label: 'Fees to claim', value: _loading ? '—' : '\$${_sumNumField('feesUsdc').toStringAsFixed(2)}')),
                        const SizedBox(width: 12),
                        const Expanded(child: _StatTile(label: 'Wallets traded', value: '—')),
                      ],
                    ),
                    const SizedBox(height: 18),
                    AppButton(
                      label: 'Claim fees',
                      variant: AppButtonVariant.primary,
                      loading: _claiming,
                      onPressed: TokenStore.instance.hasWallet && _myMarkets.isNotEmpty ? _claimAllFees : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _MenuItem(
                icon: Icons.account_balance_wallet_outlined,
                label: 'Portfolio & positions',
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const WalletScreen())),
              ),
              _MenuItem(icon: Icons.groups_outlined, label: 'My communities', onTap: () {}),
              _MenuItem(icon: Icons.notifications_outlined, label: 'Notifications', onTap: () {}),
              _MenuItem(icon: Icons.help_outline_rounded, label: 'Help and support', onTap: () {}),
              _MenuItem(icon: Icons.description_outlined, label: 'Terms of use', onTap: () {}),
              const SizedBox(height: 12),
              _MenuItem(
                icon: Icons.logout_rounded,
                label: 'Log out',
                color: AppColors.no,
                onTap: () async {
                  await TokenStore.instance.clear();
                  if (!context.mounted) return;
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const WelcomeScreen()),
                    (route) => false,
                  );
                },
              ),
              const SizedBox(height: 20),
              Center(
                child: Text('Powered by Panta', style: AppTextStyles.caption),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.inkSurface, borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.body(12, color: AppColors.inkMuted)),
          const SizedBox(height: 6),
          Text(value, style: AppTextStyles.tabularNums(18, color: AppColors.paper)),
        ],
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  const _MenuItem({required this.icon, required this.label, required this.onTap, this.color});

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final tint = color ?? AppColors.ink;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(
            children: [
              Icon(icon, size: 20, color: tint),
              const SizedBox(width: 14),
              Expanded(child: Text(label, style: AppTextStyles.body(15, weight: FontWeight.w600, color: tint))),
              Icon(Icons.chevron_right_rounded, color: AppColors.slate.withOpacity(0.6)),
            ],
          ),
        ),
      ),
    );
  }
}

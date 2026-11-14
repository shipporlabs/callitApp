import 'package:flutter/material.dart';
import '../../core/widgets/app_icon.dart';
import '../../core/api/callit_api.dart';
import '../../core/api/solana_service.dart';
import '../../core/api/token_store.dart';
import '../../core/widgets/app_avatar.dart';
import '../../core/widgets/market_card.dart';
import '../../core/widgets/section_header.dart';
import '../../models/market.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../community/communities_screen.dart';
import '../wallet/convert_screen.dart';
import '../wallet/deposit_selection_sheet.dart';
import '../wallet/wallet_screen.dart';
import 'market_detail_screen.dart';

/// The actual "Home" tab: a balance card for the account's
/// FossaPay-provisioned wallet, a few quick actions, and a short list of
/// markets worth backing right now — in place of a generic feed.
class HomeDashboard extends StatefulWidget {
  const HomeDashboard({super.key, this.onSeeAllMarkets});

  /// Switches the bottom nav over to the Markets tab — wired by
  /// [HomeScreen] since this widget doesn't own the nav state itself.
  final VoidCallback? onSeeAllMarkets;

  @override
  State<HomeDashboard> createState() => _HomeDashboardState();
}

class _HomeDashboardState extends State<HomeDashboard> {
  SolanaBalances? _balances;
  List<Market> _markets = [];
  bool _loadingBalance = true;
  bool _loadingMarkets = true;
  bool _hideBalance = false;

  @override
  void initState() {
    super.initState();
    _loadBalance();
    _loadMarkets();
  }

  void _openDepositSheet() {
    final address = TokenStore.instance.walletAddress ?? '';
    showDepositSelectionSheet(
      context,
      walletAddress: address,
      onFunded: _loadBalance,
    );
  }

  Future<void> _loadBalance() async {
    final wallet = TokenStore.instance.walletAddress;
    if (wallet == null) {
      setState(() => _loadingBalance = false);
      return;
    }
    setState(() => _loadingBalance = true);
    final balances = await SolanaService.instance.getBalances(wallet);
    if (!mounted) return;
    setState(() {
      _balances = balances;
      _loadingBalance = false;
    });
  }

  Future<void> _loadMarkets() async {
    setState(() => _loadingMarkets = true);
    try {
      final result = await callitApi.listMarkets(limit: 5);
      debugPrint('DEBUG LIST MARKETS RESULT: $result');
      final items = (result['items'] as List? ?? []).cast<Map<String, dynamic>>();
      if (!mounted) return;
      setState(() {
        _markets = items.map(Market.fromApi).toList();
        _loadingMarkets = false;
      });
    } catch (e, st) {
      debugPrint('LOAD MARKETS ERROR: $e\n$st');
      if (!mounted) return;
      setState(() {
        _markets = [];
        _loadingMarkets = false;
      });
    }
  }

  Future<void> _refresh() => Future.wait([_loadBalance(), _loadMarkets()]);

  @override
  Widget build(BuildContext context) {
    final userName = TokenStore.instance.userName?.trim();
    final firstName = (userName != null && userName.isNotEmpty) ? userName.split(RegExp(r'\s+')).first : 'there';
    final initials = (userName != null && userName.isNotEmpty)
        ? userName.split(RegExp(r'\s+')).map((w) => w[0]).take(2).join().toUpperCase()
        : '?';

    return Scaffold(
      backgroundColor: AppColors.paper,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            children: [
              Row(
                children: [
                  AppAvatar(initials: initials, size: 46),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('WELCOME BACK', style: AppTextStyles.label(11, color: AppColors.slate)),
                        const SizedBox(height: 2),
                        Text(firstName, style: AppTextStyles.h3),
                      ],
                    ),
                  ),
                  _IconBadgeButton(icon: Icons.notifications_outlined, onTap: () {}),
                ],
              ),
              const SizedBox(height: 20),
              _BalanceCard(
                balances: _balances,
                loading: _loadingBalance,
                hidden: _hideBalance,
                onToggleHidden: () => setState(() => _hideBalance = !_hideBalance),
                onTapDetails: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const WalletScreen())),
                onDeposit: _openDepositSheet,
              ),
              const SizedBox(height: 24),
              Text('QUICK ACTIONS', style: AppTextStyles.label(12, color: AppColors.slate)),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _QuickAction(
                      icon: Icons.add_card_rounded,
                      label: 'Fund',
                      onTap: _openDepositSheet,
                    ),
                  ),
                  Expanded(
                    child: _QuickAction(
                      icon: Icons.swap_horiz_rounded,
                      label: 'Convert',
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ConvertScreen())),
                    ),
                  ),
                  Expanded(
                    child: _QuickAction(
                      icon: Icons.stacked_line_chart_rounded,
                      label: 'Positions',
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const WalletScreen())),
                    ),
                  ),
                  Expanded(
                    child: _QuickAction(
                      icon: Icons.groups_outlined,
                      label: 'Communities',
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CommunitiesScreen())),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              SectionHeader(number: 1, title: 'Markets to back', action: 'See all', onActionTap: widget.onSeeAllMarkets),
              const SizedBox(height: 14),
              if (_loadingMarkets)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: CircularProgressIndicator(color: AppColors.ink)),
                )
              else if (_markets.isEmpty)
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    border: Border.all(color: AppColors.mist, width: 1.2),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Center(child: Text('No markets yet — check back soon.', style: AppTextStyles.caption)),
                )
              else
                ..._markets.map((market) => Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: MarketCard(
                        market: market,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => MarketDetailScreen(market: market)),
                        ),
                      ),
                    )),
            ],
          ),
        ),
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({
    required this.balances,
    required this.loading,
    required this.hidden,
    required this.onToggleHidden,
    required this.onTapDetails,
    this.onDeposit,
  });

  final SolanaBalances? balances;
  final bool loading;
  final bool hidden;
  final VoidCallback onToggleHidden;
  final VoidCallback onTapDetails;
  final VoidCallback? onDeposit;

  @override
  Widget build(BuildContext context) {
    final amountText = hidden
        ? '••••••'
        : (balances != null ? '\$${balances!.totalUsdValue.toStringAsFixed(2)}' : (loading ? '—' : '\$0.00'));

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: AppColors.mist, width: 1.2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(border: Border.all(color: AppColors.mist, width: 1.2), borderRadius: BorderRadius.circular(12)),
                      child: const AppIcon(Ic.wallet, size: 15, color: AppColors.ink),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text('AVAILABLE BALANCE', style: AppTextStyles.label(11, color: AppColors.slate), overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (onDeposit != null) ...[
                    GestureDetector(
                      onTap: onDeposit,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.highlight,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.mist, width: 1.2),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const AppIcon(Ic.add, size: 14, color: AppColors.ink),
                            const SizedBox(width: 4),
                            Text('DEPOSIT', style: AppTextStyles.label(10, color: AppColors.ink, weight: FontWeight.w800)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                  ],
                  _IconBadgeButton(icon: Icons.arrow_outward_rounded, onTap: onTapDetails, filled: true),
                ],
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Text(amountText, style: AppTextStyles.display(32, weight: FontWeight.w700)),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: onToggleHidden,
                child: Icon(hidden ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20, color: AppColors.slate),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            hidden
                ? '•••• SOL  •  •••• USDC'
                : (balances != null
                    ? '${balances!.solBalance.toStringAsFixed(3)} SOL  •  ${balances!.usdcBalance.toStringAsFixed(2)} USDC'
                    : (loading ? 'Fetching on-chain balance…' : '0.000 SOL  •  0.00 USDC')),
            style: AppTextStyles.tabularNums(13, color: AppColors.slate),
          ),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          children: [
            Container(
              width: 50,
              height: 50,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.white,
                border: Border.all(color: AppColors.mist, width: 1.2),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(icon, size: 21, color: AppColors.ink),
            ),
            const SizedBox(height: 8),
            Text(label, style: AppTextStyles.body(11.5, weight: FontWeight.w600), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _IconBadgeButton extends StatelessWidget {
  const _IconBadgeButton({required this.icon, required this.onTap, this.filled = false});

  final IconData icon;
  final VoidCallback onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: filled ? AppColors.highlight : AppColors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(border: Border.all(color: AppColors.mist, width: 1.2), borderRadius: BorderRadius.circular(18)),
          child: Icon(icon, size: 18, color: AppColors.ink),
        ),
      ),
    );
  }
}

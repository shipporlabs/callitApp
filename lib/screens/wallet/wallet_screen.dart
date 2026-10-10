import 'package:flutter/material.dart';
import '../../core/api/callit_api.dart';
import '../../core/api/token_store.dart';
import '../../core/api/solana_service.dart';
import '../../core/widgets/pill_chip.dart';
import '../../core/widgets/section_header.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import 'add_wallet_screen.dart';
import 'convert_screen.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(title: Text('Wallet', style: AppTextStyles.h3)),
      body: SafeArea(
        child: TokenStore.instance.hasWallet
            ? _ConnectedWallet(onDisconnected: () => setState(() {}))
            : _DisconnectedWallet(onConnected: () => setState(() {})),
      ),
    );
  }
}

class _DisconnectedWallet extends StatelessWidget {
  const _DisconnectedWallet({required this.onConnected});

  final VoidCallback onConnected;

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
              onPressed: () async {
                await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AddWalletScreen()));
                onConnected();
              },
              child: const Text('Connect wallet'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConnectedWallet extends StatefulWidget {
  const _ConnectedWallet({required this.onDisconnected});

  final VoidCallback onDisconnected;

  @override
  State<_ConnectedWallet> createState() => _ConnectedWalletState();
}

class _ConnectedWalletState extends State<_ConnectedWallet> {
  List<Map<String, dynamic>> _positions = [];
  List<Map<String, dynamic>> _tradeHistory = [];
  SolanaBalances? _balances;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPositions();
  }

  Future<void> _loadPositions() async {
    final wallet = TokenStore.instance.walletAddress;
    if (wallet == null) return;
    setState(() => _loading = true);
    try {
      final posFuture = callitApi.positions(wallet);
      final tradesFuture = callitApi.getWalletTrades(wallet);
      final balFuture = SolanaService.instance.getBalances(wallet);
      final posResult = await posFuture;
      final tradesResult = await tradesFuture;
      final balResult = await balFuture;
      if (!mounted) return;
      setState(() {
        _positions = posResult.cast<Map<String, dynamic>>();
        _tradeHistory = tradesResult.whereType<Map<String, dynamic>>().toList();
        _balances = balResult;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final address = TokenStore.instance.walletAddress ?? '';
    final shortAddress = address.length > 8 ? '${address.substring(0, 4)}…${address.substring(address.length - 4)}' : address;
    final provider = TokenStore.instance.walletProvider ?? 'Wallet';

    return RefreshIndicator(
      onRefresh: _loadPositions,
      child: ListView(
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
                    Text(provider, style: AppTextStyles.body(13, color: AppColors.inkMuted, weight: FontWeight.w600)),
                    Row(
                      children: [
                        Container(width: 6, height: 6, decoration: const BoxDecoration(color: AppColors.yes, shape: BoxShape.circle)),
                        const SizedBox(width: 6),
                        Text(shortAddress, style: AppTextStyles.tabularNums(12, color: AppColors.inkMuted2)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                Text('Total balance', style: AppTextStyles.body(13, color: AppColors.inkMuted)),
                const SizedBox(height: 6),
                Text(
                  _balances != null ? '\$${_balances!.totalUsdValue.toStringAsFixed(2)}' : '—',
                  style: AppTextStyles.display(36, color: AppColors.paper),
                ),
                const SizedBox(height: 4),
                Text(
                  _balances != null
                      ? '${_balances!.solBalance.toStringAsFixed(3)} SOL  •  ${_balances!.usdcBalance.toStringAsFixed(2)} USDC'
                      : (_loading ? 'Fetching on-chain balance…' : '0.00 SOL  •  0.00 USDC'),
                  style: AppTextStyles.body(13, color: AppColors.inkMuted),
                ),
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
          SectionHeader(title: 'Your positions', action: 'Refresh', onActionTap: _loadPositions),
          const SizedBox(height: 14),
          if (_loading)
            const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator(color: AppColors.ink)))
          else if (_positions.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text('No open positions yet — back a market to see it here.', style: AppTextStyles.subtitle),
            )
          else
            ..._positions.map((p) => Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: _PositionTile(position: p),
                )),
          const SizedBox(height: 28),
          SectionHeader(title: 'Recent trades', action: 'Refresh', onActionTap: _loadPositions),
          const SizedBox(height: 14),
          if (_tradeHistory.isEmpty)
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.white,
                border: Border.all(color: AppColors.mist),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Center(
                child: Text('No trades recorded for this wallet yet.', style: AppTextStyles.caption),
              ),
            )
          else
            ..._tradeHistory.map((t) {
              final isYes = (t['side']?.toString().toLowerCase() == 'yes');
              final marketId = t['marketId']?.toString() ?? 'Market';
              final amount = t['amountUsdc']?.toString() ?? t['shares']?.toString() ?? '—';
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    border: Border.all(color: AppColors.mist),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          PillChip(
                            label: isYes ? 'YES' : 'NO',
                            background: isYes ? AppColors.yes : AppColors.no,
                            foreground: AppColors.white,
                            dense: true,
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(marketId, style: AppTextStyles.body(13, weight: FontWeight.w600)),
                              const SizedBox(height: 2),
                              Text('Completed trade', style: AppTextStyles.caption),
                            ],
                          ),
                        ],
                      ),
                      Text('\$$amount USDC', style: AppTextStyles.tabularNums(13, weight: FontWeight.w700)),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _PositionTile extends StatelessWidget {
  const _PositionTile({required this.position});

  final Map<String, dynamic> position;

  @override
  Widget build(BuildContext context) {
    final side = position['side'] as String? ?? 'yes';
    final isYes = side == 'yes';
    final shares = position['shares']?.toString() ?? '0';
    final phase = position['phase'] as String? ?? 'primary';
    final claimable = position['claimable'] as bool? ?? false;
    final claimed = position['claimed'] as bool? ?? false;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.white, border: Border.all(color: AppColors.mist), borderRadius: BorderRadius.circular(18)),
      child: Row(
        children: [
          PillChip(
            label: side.toUpperCase(),
            background: isYes ? AppColors.yes : AppColors.no,
            foreground: AppColors.white,
            dense: true,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${position['marketId'] ?? ''}', style: AppTextStyles.body(13, weight: FontWeight.w700), overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text('$shares shares · $phase', style: AppTextStyles.caption),
              ],
            ),
          ),
          if (claimed)
            Text('Claimed', style: AppTextStyles.caption)
          else if (claimable)
            TextButton(
              onPressed: () async {
                final wallet = TokenStore.instance.walletAddress;
                final marketId = position['marketId'] as String?;
                if (wallet == null || marketId == null) return;
                try {
                  await callitApi.claimWin(wallet: wallet, marketId: marketId);
                  // Hook point: sign+broadcast the returned instructions
                  // with the connected wallet, same as the buy flow.
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Claim built — sign it in your wallet to finish.')));
                  }
                } catch (_) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Couldn't build that claim right now.")));
                  }
                }
              },
              child: const Text('Claim'),
            )
          else
            const SizedBox.shrink(),
        ],
      ),
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

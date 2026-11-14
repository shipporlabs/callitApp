import 'package:callit_app/screens/wallet/add_wallet_screen.dart';
import 'package:flutter/material.dart';
import '../../core/widgets/app_icon.dart';
import '../../core/api/callit_api.dart';
import '../../core/api/token_store.dart';
import '../../core/api/solana_service.dart';
import '../../core/widgets/pill_chip.dart';
import '../../core/widgets/section_header.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import 'convert_screen.dart';
import 'deposit_selection_sheet.dart';

/// The portfolio screen: balance, open positions, and trade history for
/// the account's FossaPay-provisioned wallet. Reached from a "Positions"
/// quick action on the home screen — there's no "connect a wallet" step
/// here, every account already has one.
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
      appBar: AppBar(title: Text('Portfolio', style: AppTextStyles.h3)),
      body: SafeArea(
        child: TokenStore.instance.hasWallet
            ? _ConnectedWallet(onDisconnected: () => setState(() {}))
            : _WalletNotReady(onRetry: () => setState(() {})),
      ),
    );
  }
}

/// Edge case only — a wallet that hasn't synced locally yet (first cold
/// start before `fetchWalletAddress` resolves). There's nothing for the
/// person to connect; this just offers to check again.
class _WalletNotReady extends StatefulWidget {
  const _WalletNotReady({required this.onRetry});

  final VoidCallback onRetry;

  @override
  State<_WalletNotReady> createState() => _WalletNotReadyState();
}

class _WalletNotReadyState extends State<_WalletNotReady> {
  bool _checking = false;

  Future<void> _retry() async {
    setState(() => _checking = true);
    try {
      final address = await callitApi.fetchWalletAddress();
      if (address != null) {
        await TokenStore.instance.saveWallet(address: address, provider: 'FossaPay');
      }
    } catch (_) {}
    if (!mounted) return;
    setState(() => _checking = false);
    widget.onRetry();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AppIcon(Ic.wallet, size: 48, color: AppColors.slate),
            const SizedBox(height: 16),
            Text('Setting up your wallet', style: AppTextStyles.h3),
            const SizedBox(height: 8),
            Text(
              'FossaPay provisions a wallet for every account — this usually only takes a moment.',
              style: AppTextStyles.subtitle,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            _checking
                ? const CircularProgressIndicator(color: AppColors.ink)
                : Column(
                    children: [
                      TextButton(onPressed: _retry, child: const Text('Try again')),
                      const SizedBox(height: 8),
                      OutlinedButton(
                        onPressed: () async {
                          final connected = await Navigator.of(context).push<bool>(
                            MaterialPageRoute(builder: (_) => const AddWalletScreen()),
                          );
                          if (connected == true) {
                            widget.onRetry();
                          }
                        },
                        child: const Text('Connect or Import Solana Wallet'),
                      ),
                    ],
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
          _TicketCard(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(provider.toUpperCase(), style: AppTextStyles.label(12, color: AppColors.inkMuted, weight: FontWeight.w600)),
                  Row(
                    children: [
                      Container(width: 6, height: 6, decoration: const BoxDecoration(color: AppColors.yes, shape: BoxShape.circle)),
                      const SizedBox(width: 6),
                      Text(shortAddress, style: AppTextStyles.tabularNums(12, color: AppColors.inkMuted2)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _TicketDivider(),
              const SizedBox(height: 18),
              Text('TOTAL BALANCE', style: AppTextStyles.label(12, color: AppColors.inkMuted)),
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
                style: AppTextStyles.tabularNums(13, color: AppColors.inkMuted),
              ),
              const SizedBox(height: 18),
              _TicketDivider(),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: _WalletAction(
                      icon: Icons.add_card_rounded,
                      label: 'Fund',
                      onTap: () => showDepositSelectionSheet(
                        context,
                        walletAddress: address,
                        onFunded: _loadPositions,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _WalletAction(
                      icon: Icons.call_received_rounded,
                      label: 'Receive',
                      onTap: () => showDepositSelectionSheet(
                        context,
                        walletAddress: address,
                        onFunded: _loadPositions,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _WalletAction(
                      icon: Icons.swap_horiz_rounded,
                      label: 'Convert',
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ConvertScreen())),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: _WalletAction(icon: Icons.ios_share_rounded, label: 'Send', onTap: () {})),
                ],
              ),
            ],
          ),
          const SizedBox(height: 28),
          SectionHeader(number: 1, title: 'Your positions', action: 'Refresh', onActionTap: _loadPositions),
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
          SectionHeader(number: 2, title: 'Recent trades', action: 'Refresh', onActionTap: _loadPositions),
          const SizedBox(height: 14),
          if (_tradeHistory.isEmpty)
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.white,
                border: Border.all(color: AppColors.mist, width: 1.2),
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
                    border: Border.all(color: AppColors.mist, width: 1.2),
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

/// The balance card drawn as a ticket stub: a solid Ink rectangle with
/// circular notches punched into its left/right edges at each dashed
/// divider, like a torn raffle ticket.
class _TicketCard extends StatelessWidget {
  const _TicketCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.ink,
        border: Border.all(color: AppColors.mist, width: 1.2),
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.all(22),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }
}

/// A dashed line with a small punched-out circle at each end — the
/// "ticket stub" perforation, drawn in the page background color so it
/// reads as a cutout against the card's Ink fill.
class _TicketDivider extends StatelessWidget {
  const _TicketDivider();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 10,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(double.infinity, 1),
            painter: _DashedLinePainter(color: AppColors.inkBorder),
          ),
          const Positioned(left: -22, child: _Notch()),
          const Positioned(right: -22, child: _Notch()),
        ],
      ),
    );
  }
}

class _Notch extends StatelessWidget {
  const _Notch();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 14,
      height: 14,
      decoration: const BoxDecoration(color: AppColors.paper, shape: BoxShape.circle),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  _DashedLinePainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.3;
    const dashWidth = 5.0;
    const dashSpace = 4.0;
    double x = 0;
    while (x < size.width) {
      canvas.drawLine(Offset(x, 0), Offset(x + dashWidth, 0), paint);
      x += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant _DashedLinePainter oldDelegate) => oldDelegate.color != color;
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
      decoration: BoxDecoration(color: AppColors.white, border: Border.all(color: AppColors.mist, width: 1.2), borderRadius: BorderRadius.circular(18)),
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
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
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

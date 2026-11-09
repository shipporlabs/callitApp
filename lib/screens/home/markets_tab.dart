import 'package:flutter/material.dart';
import '../../core/api/callit_api.dart';
import '../../core/widgets/app_logo.dart';
import '../../core/widgets/market_card.dart';
import '../../core/widgets/pill_chip.dart';
import '../../models/market.dart';
import '../../core/widgets/section_header.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import 'market_detail_screen.dart';
import '../community/communities_screen.dart';
import '../../core/api/solana_service.dart';
import '../../core/api/token_store.dart';
import '../wallet/deposit_selection_sheet.dart';

class MarketsTab extends StatefulWidget {
  const MarketsTab({super.key, this.searchMode = false});

  final bool searchMode;

  @override
  State<MarketsTab> createState() => _MarketsTabState();
}

class _MarketsTabState extends State<MarketsTab> {
  String? _category; // null = All; otherwise the API's lowercase enum value
  final _searchController = TextEditingController();
  final List<String> _categories = List.of(CallitApi.fallbackCategories);

  List<Market> _markets = [];
  bool _loading = true;
  SolanaBalances? _balances;

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _loadMarkets();
    _loadBalance();
  }

  Future<void> _loadBalance() async {
    final wallet = TokenStore.instance.walletAddress;
    if (wallet == null) return;
    try {
      final bal = await SolanaService.instance.getBalances(wallet);
      if (mounted) setState(() => _balances = bal);
    } catch (_) {}
  }

  Future<void> _loadCategories() async {
    try {
      final cats = await callitApi.categories();
      if (!mounted || cats.isEmpty) return;
      setState(() {
        _categories
          ..clear()
          ..addAll(cats);
      });
    } catch (_) {
      // Keep the fallback list — the filter chips still work either way.
    }
  }

  Future<void> _loadMarkets() async {
    setState(() => _loading = true);
    try {
      final result = await callitApi.listMarkets(category: _category, limit: 50);
      final items = (result['items'] as List? ?? []).cast<Map<String, dynamic>>();
      if (!mounted) return;
      setState(() {
        _markets = items.map(Market.fromApi).toList();
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _markets = [];
        _loading = false;
      });
    }
  }

  void _selectCategory(String? cat) {
    setState(() => _category = cat);
    _loadMarkets();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _label(String apiValue) => apiValue.isEmpty ? apiValue : apiValue[0].toUpperCase() + apiValue.substring(1);

  @override
  Widget build(BuildContext context) {
    final filtered = _markets.where((m) {
      final matchesSearch = _searchController.text.isEmpty ||
          m.question.toLowerCase().contains(_searchController.text.toLowerCase());
      final matchesCategory = _category == null || m.categoryApiValue == _category;
      return matchesSearch && matchesCategory;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.paper,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await Future.wait([
              _loadMarkets(),
              _loadBalance(),
            ]);
          },
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const AppLogo(size: 26),
                          const SizedBox(width: 8),
                          Text('Callit', style: AppTextStyles.display(20, weight: FontWeight.w700)),
                        ],
                      ),
                      Row(
                        children: [
                          IconButton(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const CommunitiesScreen()),
                              );
                            },
                            icon: const Icon(Icons.groups_outlined, color: AppColors.ink),
                            tooltip: 'Communities & Leaderboard',
                          ),
                          IconButton(
                            onPressed: () {},
                            icon: const Icon(Icons.notifications_outlined, color: AppColors.ink),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              if (!widget.searchMode)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.ink,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Wallet Balance',
                                style: AppTextStyles.body(12, color: AppColors.inkMuted, weight: FontWeight.w600),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _balances != null
                                    ? '\$${_balances!.totalUsdValue.toStringAsFixed(2)}'
                                    : (TokenStore.instance.hasWallet ? 'Fetching…' : '\$0.00'),
                                style: AppTextStyles.display(22, color: AppColors.paper),
                              ),
                            ],
                          ),
                          ElevatedButton.icon(
                            onPressed: () {
                              final wallet = TokenStore.instance.walletAddress ?? '';
                              showDepositSelectionSheet(
                                context,
                                walletAddress: wallet,
                                onFunded: _loadBalance,
                              );
                            },
                            icon: const Icon(Icons.add_card_rounded, size: 16),
                            label: const Text('Fund / Deposit'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.highlight,
                              foregroundColor: AppColors.ink,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              textStyle: AppTextStyles.body(13, weight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              if (widget.searchMode)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (_) => setState(() {}),
                      style: AppTextStyles.body(14),
                      decoration: const InputDecoration(
                        hintText: 'SEARCH MARKETS',
                        prefixIcon: Icon(Icons.search, color: AppColors.ink),
                      ),
                    ),
                  ),
                ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 44,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    itemCount: _categories.length + 1,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, i) {
                      final cat = i == 0 ? null : _categories[i - 1];
                      final label = cat == null ? 'All' : _label(cat);
                      final selected = cat == _category;
                      return GestureDetector(
                        onTap: () => _selectCategory(cat),
                        child: PillChip(
                          label: label,
                          background: selected ? AppColors.ink : AppColors.mist,
                          foreground: selected ? AppColors.paper : AppColors.ink,
                        ),
                      );
                    },
                  ),
                ),
              ),
              if (_loading)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: CircularProgressIndicator(color: AppColors.ink)),
                )
              else if (filtered.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.search_off_rounded, size: 48, color: AppColors.slate),
                          const SizedBox(height: 12),
                          Text('No markets match that search yet.', style: AppTextStyles.subtitle, textAlign: TextAlign.center),
                        ],
                      ),
                    ),
                  ),
                )
              else ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 2),
                    child: SectionHeader(
                      number: 1,
                      title: _category == null ? 'Trending Markets' : _label(_category!),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                  sliver: SliverList.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 14),
                    itemBuilder: (context, i) {
                      final market = filtered[i];
                      return MarketCard(
                        market: market,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => MarketDetailScreen(market: market)),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

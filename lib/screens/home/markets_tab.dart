import 'package:flutter/material.dart';
import '../../core/widgets/app_logo.dart';
import '../../core/widgets/market_card.dart';
import '../../core/widgets/pill_chip.dart';
import '../../data/mock_markets.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import 'market_detail_screen.dart';

const _categories = ['All', 'Sports', 'Crypto', 'Entertainment', 'Politics', 'Finance'];

class MarketsTab extends StatefulWidget {
  const MarketsTab({super.key, this.searchMode = false});

  final bool searchMode;

  @override
  State<MarketsTab> createState() => _MarketsTabState();
}

class _MarketsTabState extends State<MarketsTab> {
  String _category = 'All';
  final _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final filtered = mockMarkets.where((m) {
      final matchesCategory = _category == 'All' || m.category == _category;
      final matchesSearch = _searchController.text.isEmpty ||
          m.question.toLowerCase().contains(_searchController.text.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.paper,
      body: SafeArea(
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
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(Icons.notifications_outlined, color: AppColors.ink),
                    ),
                  ],
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
                    decoration: const InputDecoration(
                      hintText: 'Search markets',
                      prefixIcon: Icon(Icons.search, color: AppColors.slate),
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
                  itemCount: _categories.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, i) {
                    final cat = _categories[i];
                    final selected = cat == _category;
                    return GestureDetector(
                      onTap: () => setState(() => _category = cat),
                      child: PillChip(
                        label: cat,
                        background: selected ? AppColors.ink : AppColors.mist,
                        foreground: selected ? AppColors.paper : AppColors.ink,
                      ),
                    );
                  },
                ),
              ),
            ),
            if (filtered.isEmpty)
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
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
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
        ),
      ),
    );
  }
}

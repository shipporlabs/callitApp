import 'package:flutter/material.dart';
import '../../core/widgets/app_icon.dart';
import '../../core/api/api_exception.dart';
import '../../core/api/callit_api.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/market_card.dart';
import '../../core/widgets/pill_chip.dart';
import '../../core/widgets/section_header.dart';
import '../../models/community.dart';
import '../../models/market.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../create/paste_screen.dart';
import '../home/market_detail_screen.dart';

class CommunityDetailScreen extends StatefulWidget {
  const CommunityDetailScreen({super.key, required this.community});

  final Community community;

  @override
  State<CommunityDetailScreen> createState() => _CommunityDetailScreenState();
}

class _CommunityDetailScreenState extends State<CommunityDetailScreen> {
  late Community _community;
  List<Market> _markets = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _community = widget.community;
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await callitApi.community(_community.id);
      final rawComm = (res['community'] as Map?)?.cast<String, dynamic>();
      if (rawComm != null) {
        _community = Community.fromJson(rawComm);
      }
      final rawMarkets = (res['markets'] as List? ?? []).cast<Map<String, dynamic>>();

      // Fetch market details for each market meta
      final List<Market> loadedMarkets = [];
      for (final mMeta in rawMarkets) {
        final mId = mMeta['marketId']?.toString();
        if (mId != null && mId.isNotEmpty) {
          try {
            final mJson = await callitApi.getMarket(mId);
            loadedMarkets.add(Market.fromApi(mJson));
          } catch (_) {
            // If individual market fetch fails, construct a minimal item
            final rawCategory = mMeta['category']?.toString() ?? 'other';
            loadedMarkets.add(Market(
              id: mId,
              question: 'Market #$mId',
              category: rawCategory.isEmpty ? 'Other' : rawCategory[0].toUpperCase() + rawCategory.substring(1),
              yesPricePct: 50.0,
              resolvesLabel: 'Active',
            ));
          }
        }
      }

      if (!mounted) return;
      setState(() {
        _markets = loadedMarkets;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not load community details.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(
        leading: const BackButton(),
        title: Text(_community.name, style: AppTextStyles.h3),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  border: Border.all(color: AppColors.mist, width: 1.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            _community.name,
                            style: AppTextStyles.h1.copyWith(fontSize: 24),
                          ),
                        ),
                        PillChip(
                          label: 'c/${_community.slug}',
                          background: AppColors.highlight,
                          foreground: AppColors.ink,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _statBox(
                            'Trading Volume',
                            _community.volumeLabel,
                            Icons.trending_up_rounded,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _statBox(
                            'Markets',
                            '${_community.marketCount}',
                            Icons.pie_chart_outline_rounded,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'ATTRIBUTION ID: ${_community.attributionId}',
                      style: AppTextStyles.label(11, color: AppColors.slate),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              AppButton(
                label: 'Create market in this community',
                icon: Icons.add_circle_outline_rounded,
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => PasteScreen(initialCommunity: _community),
                    ),
                  );
                },
              ),
              const SizedBox(height: 28),
              const SectionHeader(number: 1, title: 'Community markets'),
              const SizedBox(height: 14),
              if (_loading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: CircularProgressIndicator(color: AppColors.ink),
                  ),
                )
              else if (_error != null)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: Column(
                      children: [
                        Text(_error!, style: AppTextStyles.body(14, color: AppColors.slate)),
                        const SizedBox(height: 12),
                        OutlinedButton(onPressed: _load, child: const Text('Retry')),
                      ],
                    ),
                  ),
                )
              else if (_markets.isEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    border: Border.all(color: AppColors.mist, width: 1.2),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Center(
                    child: Column(
                      children: [
                        const AppIcon(Ic.group, size: 40, color: AppColors.slate),
                        const SizedBox(height: 12),
                        Text('No markets created here yet', style: AppTextStyles.h3),
                        const SizedBox(height: 6),
                        Text(
                          'Be the first to create a prediction market in this community!',
                          style: AppTextStyles.caption,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              else
                ..._markets.map(
                  (m) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: MarketCard(
                      market: m,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => MarketDetailScreen(market: m)),
                        );
                      },
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statBox(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.mist, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: AppColors.slate),
              const SizedBox(width: 6),
              Text(title, style: AppTextStyles.caption),
            ],
          ),
          const SizedBox(height: 6),
          Text(value, style: AppTextStyles.tabularNums(16, weight: FontWeight.w700)),
        ],
      ),
    );
  }
}

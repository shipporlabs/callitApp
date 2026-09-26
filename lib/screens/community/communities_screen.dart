import 'package:flutter/material.dart';
import '../../core/api/api_exception.dart';
import '../../core/api/callit_api.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/pill_chip.dart';
import '../../models/community.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import 'community_detail_screen.dart';

class CommunitiesScreen extends StatefulWidget {
  const CommunitiesScreen({super.key});

  @override
  State<CommunitiesScreen> createState() => _CommunitiesScreenState();
}

class _CommunitiesScreenState extends State<CommunitiesScreen> {
  List<Community> _communities = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await callitApi.communities();
      if (!mounted) return;
      final parsed = items.map((e) => Community.fromJson((e as Map).cast<String, dynamic>())).toList();
      // Sort by volume descending, then marketCount descending
      parsed.sort((a, b) {
        final volComp = b.volumeUsdc.compareTo(a.volumeUsdc);
        if (volComp != 0) return volComp;
        return b.marketCount.compareTo(a.marketCount);
      });
      setState(() {
        _communities = parsed;
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
        _error = 'Could not load communities.';
        _loading = false;
      });
    }
  }

  void _showCreateCommunityDialog() {
    final controller = TextEditingController();
    bool creating = false;
    String? dialogError;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
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
                      decoration: BoxDecoration(color: AppColors.mist, borderRadius: BorderRadius.circular(999)),
                    ),
                  ),
                  Text('Create a Community', style: AppTextStyles.h2),
                  const SizedBox(height: 8),
                  Text(
                    'Communities aggregate prediction markets and track volume on the leaderboard.',
                    style: AppTextStyles.subtitle,
                  ),
                  const SizedBox(height: 20),
                  AppTextField(
                    label: 'Community Name',
                    controller: controller,
                    hint: 'e.g. Super Eagles Fan Club',
                  ),
                  if (dialogError != null) ...[
                    const SizedBox(height: 12),
                    Text(dialogError!, style: AppTextStyles.body(13, color: AppColors.no, weight: FontWeight.w600)),
                  ],
                  const SizedBox(height: 24),
                  AppButton(
                    label: 'Create Community',
                    loading: creating,
                    onPressed: creating
                        ? null
                        : () async {
                            final name = controller.text.trim();
                            if (name.length < 2) {
                              setModalState(() => dialogError = 'Name must be at least 2 characters.');
                              return;
                            }
                            setModalState(() {
                              creating = true;
                              dialogError = null;
                            });
                            try {
                              final created = await callitApi.createCommunity(name);
                              if (!mounted) return;
                              Navigator.of(ctx).pop();
                              final comm = Community.fromJson(created);
                              _load();
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => CommunityDetailScreen(community: comm),
                                ),
                              );
                            } on ApiException catch (e) {
                              setModalState(() {
                                creating = false;
                                dialogError = e.message;
                              });
                            } catch (_) {
                              setModalState(() {
                                creating = false;
                                dialogError = 'Failed to create community.';
                              });
                            }
                          },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(
        leading: const BackButton(),
        title: Text('Communities', style: AppTextStyles.h3),
        actions: [
          IconButton(
            onPressed: _showCreateCommunityDialog,
            icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.ink),
            tooltip: 'Create Community',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Leaderboard', style: AppTextStyles.h1.copyWith(fontSize: 26)),
                      const SizedBox(height: 4),
                      Text('Top communities ranked by trading volume', style: AppTextStyles.subtitle),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (_loading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 60),
                    child: CircularProgressIndicator(color: AppColors.ink),
                  ),
                )
              else if (_error != null)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Column(
                      children: [
                        Text(_error!, style: AppTextStyles.body(14, color: AppColors.slate)),
                        const SizedBox(height: 12),
                        OutlinedButton(onPressed: _load, child: const Text('Retry')),
                      ],
                    ),
                  ),
                )
              else if (_communities.isEmpty)
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    border: Border.all(color: AppColors.mist),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Center(
                    child: Column(
                      children: [
                        const Icon(Icons.groups_outlined, size: 48, color: AppColors.slate),
                        const SizedBox(height: 16),
                        Text('No communities yet', style: AppTextStyles.h3),
                        const SizedBox(height: 8),
                        Text(
                          'Create the first community to start tracking volume and attribution!',
                          style: AppTextStyles.caption,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        AppButton(
                          label: 'Create Community',
                          onPressed: _showCreateCommunityDialog,
                        ),
                      ],
                    ),
                  ),
                )
              else
                ...List.generate(_communities.length, (index) {
                  final comm = _communities[index];
                  final rank = index + 1;
                  return _CommunityLeaderboardCard(
                    community: comm,
                    rank: rank,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => CommunityDetailScreen(community: comm),
                        ),
                      );
                    },
                  );
                }),
            ],
          ),
        ),
      ),
    );
  }
}

class _CommunityLeaderboardCard extends StatelessWidget {
  const _CommunityLeaderboardCard({
    required this.community,
    required this.rank,
    required this.onTap,
  });

  final Community community;
  final int rank;
  final VoidCallback onTap;

  Color get _rankColor {
    if (rank == 1) return const Color(0xFFFFD700);
    if (rank == 2) return const Color(0xFFC0C0C0);
    if (rank == 3) return const Color(0xFFCD7F32);
    return AppColors.mist;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.mist),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: _rankColor.withOpacity(rank <= 3 ? 0.35 : 0.5),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '#$rank',
                    style: AppTextStyles.tabularNums(
                      13,
                      weight: FontWeight.w800,
                      color: rank <= 3 ? AppColors.ink : AppColors.slate,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        community.name,
                        style: AppTextStyles.body(15, weight: FontWeight.w700),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          PillChip(
                            label: 'c/${community.slug}',
                            dense: true,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${community.marketCount} ${community.marketCount == 1 ? 'market' : 'markets'}',
                            style: AppTextStyles.caption,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      community.volumeLabel,
                      style: AppTextStyles.tabularNums(14, weight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text('Volume', style: AppTextStyles.caption),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

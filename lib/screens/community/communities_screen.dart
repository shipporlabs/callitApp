import 'package:flutter/material.dart';
import '../../core/api/callit_api.dart';
import '../../core/widgets/app_avatar.dart';
import '../../core/widgets/pill_chip.dart';
import '../../core/widgets/section_header.dart';
import '../../models/community.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../create/paste_screen.dart';
import 'community_detail_screen.dart';

/// Communities & leaderboard — lists the communities a user can trade
/// under (from `GET /communities`) with a simple rank-by-volume
/// leaderboard view. The response shape isn't pinned down by a spec, so
/// every field read here tolerates being missing.
class CommunitiesScreen extends StatefulWidget {
  const CommunitiesScreen({super.key});

  @override
  State<CommunitiesScreen> createState() => _CommunitiesScreenState();
}

class _CommunitiesScreenState extends State<CommunitiesScreen> {
  List<Community> _communities = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final items = await callitApi.communities();
      if (!mounted) return;
      setState(() {
        _communities = items.whereType<Map<String, dynamic>>().map(Community.fromJson).toList()
          ..sort((a, b) => b.volumeUsdc.compareTo(a.volumeUsdc));
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _communities = [];
        _loading = false;
      });
    }
  }

  Future<void> _createCommunity() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New community'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Community name'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
            child: const Text('Create'),
          ),
        ],
      ),
    );
    if (name == null || name.isEmpty) return;
    try {
      await callitApi.createCommunity(name);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('"$name" created.')));
      _load();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Couldn't create that community right now.")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(
        leading: const BackButton(),
        title: Text('Communities', style: AppTextStyles.h3),
        actions: [
          IconButton(onPressed: _createCommunity, icon: const Icon(Icons.add_rounded)),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: AppColors.ink))
              : _communities.isEmpty
                  ? ListView(
                      padding: const EdgeInsets.fromLTRB(20, 40, 20, 24),
                      children: [
                        Center(
                          child: Column(
                            children: [
                              const Icon(Icons.groups_outlined, size: 48, color: AppColors.slate),
                              const SizedBox(height: 16),
                              Text('No communities yet', style: AppTextStyles.h3),
                              const SizedBox(height: 8),
                              Text(
                                'Create one to run a private leaderboard with friends.',
                                style: AppTextStyles.subtitle,
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                      children: [
                        const SectionHeader(title: 'Leaderboard'),
                        const SizedBox(height: 14),
                        ..._communities.asMap().entries.map((entry) {
                          final rank = entry.key + 1;
                          final c = entry.value;
                          if (c == null) return const SizedBox.shrink();
                          final initials = c.name.isNotEmpty ? c.name.substring(0, c.name.length >= 2 ? 2 : 1).toUpperCase() : '?';
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Material(
                              color: AppColors.white,
                              borderRadius: BorderRadius.circular(18),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(18),
                                onTap: () => Navigator.of(context).push(
                                  MaterialPageRoute(builder: (_) => CommunityDetailScreen(community: c)),
                                ),
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: AppColors.mist),
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                  child: Row(
                                    children: [
                                      SizedBox(
                                        width: 28,
                                        child: Text(
                                          '#$rank',
                                          style: AppTextStyles.tabularNums(14, color: AppColors.slate),
                                        ),
                                      ),
                                      AppAvatar(initials: initials, size: 36),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(c.name, style: AppTextStyles.body(15, weight: FontWeight.w700)),
                                            if (c.memberCount != null) ...[
                                              const SizedBox(height: 2),
                                              Text('${c.memberCount} members', style: AppTextStyles.caption),
                                            ],
                                          ],
                                        ),
                                      ),
                                      if (c.volumeUsdc > 0) ...[
                                        PillChip(label: c.volumeLabel, background: AppColors.mist, dense: true),
                                        const SizedBox(width: 8),
                                      ],
                                      IconButton(
                                        tooltip: 'New market in ${c.name}',
                                        onPressed: () => Navigator.of(context).push(
                                          MaterialPageRoute(builder: (_) => PasteScreen(initialCommunity: c)),
                                        ),
                                        icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.ink, size: 22),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
        ),
      ),
    );
  }
}

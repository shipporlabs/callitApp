import 'package:flutter/material.dart';
import '../../core/api/callit_api.dart';
import '../../core/widgets/app_avatar.dart';
import '../../core/widgets/pill_chip.dart';
import '../../core/widgets/section_header.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../create/paste_screen.dart';

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
  List<Map<String, dynamic>> _communities = [];
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
        _communities = items.whereType<Map<String, dynamic>>().toList()
          ..sort((a, b) => (_volume(b)).compareTo(_volume(a)));
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

  double _volume(Map<String, dynamic> c) {
    final v = c['volumeUsdc'] ?? c['volume'] ?? c['totalVolume'];
    return v is num ? v.toDouble() : 0;
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
                          final id = c['id']?.toString() ?? c['communityId']?.toString();
                          final name = c['name']?.toString() ?? 'Community';
                          final members = c['memberCount'] ?? c['members'];
                          final volume = _volume(c);
                          final initials = name.isNotEmpty ? name.substring(0, name.length >= 2 ? 2 : 1).toUpperCase() : '?';
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppColors.white,
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
                                        Text(name, style: AppTextStyles.body(15, weight: FontWeight.w700)),
                                        if (members != null) ...[
                                          const SizedBox(height: 2),
                                          Text('$members members', style: AppTextStyles.caption),
                                        ],
                                      ],
                                    ),
                                  ),
                                  if (volume > 0) ...[
                                    PillChip(
                                      label: '\$${volume.toStringAsFixed(0)}',
                                      background: AppColors.mist,
                                      dense: true,
                                    ),
                                    const SizedBox(width: 8),
                                  ],
                                  if (id != null)
                                    IconButton(
                                      tooltip: 'New market in $name',
                                      onPressed: () => Navigator.of(context).push(
                                        MaterialPageRoute(builder: (_) => PasteScreen(initialCommunity: id)),
                                      ),
                                      icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.ink, size: 22),
                                    ),
                                ],
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

import 'package:flutter/material.dart';
import '../../core/widgets/app_icon.dart';
import 'package:flutter/services.dart';
import '../../core/api/api_exception.dart';
import '../../core/api/callit_api.dart';
import '../../core/widgets/app_button.dart';
import '../../models/community.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import 'review_market_screen.dart';

/// Step 1 of Callit's core flow: paste a headline, a tweet, or a raw
/// question. The next screen is where the AI-compiled draft is reviewed
/// before anything is quoted against Panta.
///
/// [initialCommunity] is set when this is opened from a specific
/// community (e.g. "New market" inside [CommunitiesScreen] or
/// [CommunityDetailScreen]) — the resulting market is then scoped to
/// that community's own leaderboard rather than the public catalog.
/// Null for the ordinary bottom-nav "Create" tab.
class PasteScreen extends StatefulWidget {
  const PasteScreen({super.key, this.initialCommunity});

  final Community? initialCommunity;

  @override
  State<PasteScreen> createState() => _PasteScreenState();
}

class _PasteScreenState extends State<PasteScreen> {
  final _controller = TextEditingController();
  bool _compiling = false;

  static const _examples = [
    'Will the Super Eagles qualify for the 2027 World Cup?',
    'https://x.com/someone/status/123456789',
    'Will SOL flip \$300 before March?',
  ];

  void _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null && data!.text!.isNotEmpty) {
      setState(() => _controller.text = data.text!);
    }
  }

  void _compile() async {
    setState(() => _compiling = true);
    try {
      final result = await callitApi.compile(_controller.text.trim());
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ReviewMarketScreen(rawInput: _controller.text, compiled: result, communityId: widget.initialCommunity?.id),
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      // Fall through so a slow/offline compiler doesn't block the demo —
      // the review screen has its own local fallback draft.
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => ReviewMarketScreen(rawInput: _controller.text, communityId: widget.initialCommunity?.id)),
      );
    } finally {
      if (mounted) setState(() => _compiling = false);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(
        leading: const CloseButton(),
        title: Text('New market', style: AppTextStyles.h3),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: (constraints.maxHeight - 28).clamp(0, double.infinity)),
              child: IntrinsicHeight(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Paste any take', style: AppTextStyles.h1.copyWith(fontSize: 28)),
                    const SizedBox(height: 8),
                    Text(
                      'A headline, a tweet link, or your own question. Callit turns it into a live market.',
                      style: AppTextStyles.subtitle,
                    ),
                    if (widget.initialCommunity != null) ...[
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.mist, width: 1.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const AppIcon(Ic.group, size: 14, color: AppColors.ink),
                              const SizedBox(width: 6),
                              Text('Posting to ${widget.initialCommunity!.name}', style: AppTextStyles.body(12, weight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        border: Border.all(color: AppColors.mist),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: TextField(
                        controller: _controller,
                        maxLines: 4,
                        onChanged: (_) => setState(() {}),
                        style: AppTextStyles.body(16, weight: FontWeight.w500),
                        decoration: const InputDecoration(
                          hintText: 'Paste a headline, tweet link, or type a question…',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.all(16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: _pasteFromClipboard,
                        icon: const AppIcon(Ic.paste, size: 16),
                        label: const Text('Paste from clipboard'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('Try one of these', style: AppTextStyles.caption),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _examples.map((e) {
                        return ActionChip(
                          label: Text(e, overflow: TextOverflow.ellipsis),
                          onPressed: () => setState(() => _controller.text = e),
                        );
                      }).toList(),
                    ),
                    const Spacer(),
                    const SizedBox(height: 16),
                    AppButton(
                      label: 'Compile market',
                      icon: Icons.auto_awesome_rounded,
                      loading: _compiling,
                      onPressed: _controller.text.trim().isEmpty ? null : _compile,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

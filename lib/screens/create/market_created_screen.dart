import 'package:flutter/material.dart';
import '../../core/api/callit_api.dart';
import '../../core/app_images.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_image.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

class MarketCreatedScreen extends StatefulWidget {
  const MarketCreatedScreen({super.key, required this.question, this.marketId});

  final String question;
  final String? marketId;

  @override
  State<MarketCreatedScreen> createState() => _MarketCreatedScreenState();
}

class _MarketCreatedScreenState extends State<MarketCreatedScreen> {
  String? _shareUrl;
  bool _preparingShare = false;

  Future<void> _share() async {
    final marketId = widget.marketId;
    if (marketId == null || marketId.isEmpty) return;
    setState(() => _preparingShare = true);
    try {
      final card = await callitApi.createShareCard(marketId);
      if (!mounted) return;
      setState(() => _shareUrl = card['deepLink'] as String? ?? card['imageUrl'] as String?);
      // Hook point: hand `_shareUrl` to the platform share sheet
      // (share_plus or similar) instead of just displaying it.
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Share link ready: $_shareUrl')));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Couldn't prepare a share card right now.")));
    } finally {
      if (mounted) setState(() => _preparingShare = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 20, 28, 28),
          child: Column(
            children: [
              const Spacer(),
              AppImage(
                AppImages.successCheck,
                width: 180,
                height: 180,
                fallbackIcon: Icons.celebration_outlined,
                backgroundColor: AppColors.highlight.withOpacity(0.35),
                borderRadius: BorderRadius.circular(90),
              ),
              const SizedBox(height: 32),
              Text('Your market is live', style: AppTextStyles.h1, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              Text(
                widget.question,
                style: AppTextStyles.subtitle,
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Text(
                'Share it now to get the first trades in — you earn a share of the fees for as long as people trade it.',
                style: AppTextStyles.caption,
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              AppButton(label: 'Share market', icon: Icons.ios_share_rounded, loading: _preparingShare, onPressed: _share),
              const SizedBox(height: 12),
              AppButton(
                label: 'View market',
                variant: AppButtonVariant.outline,
                onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

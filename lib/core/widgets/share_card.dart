import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../models/market.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import 'app_logo.dart';
import 'pill_chip.dart';
import 'yes_no_bar.dart';

/// Opens a bottom sheet with a PnL-style share card for [market] and
/// lets the user share it as an image through the system share sheet.
/// [shareUrl] (from `POST /share-card`, if that call succeeded) is
/// printed on the card and passed along as the share text; pass null to
/// fall back to a generic market link.
Future<void> showMarketShareSheet(BuildContext context, {required Market market, String? shareUrl}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _ShareCardSheet(market: market, shareUrl: shareUrl),
  );
}

class _ShareCardSheet extends StatefulWidget {
  const _ShareCardSheet({required this.market, this.shareUrl});

  final Market market;
  final String? shareUrl;

  @override
  State<_ShareCardSheet> createState() => _ShareCardSheetState();
}

class _ShareCardSheetState extends State<_ShareCardSheet> {
  final _boundaryKey = GlobalKey();
  bool _sharing = false;

  String get _link => widget.shareUrl ?? 'callit.my/m/${widget.market.id}';

  Future<void> _share() async {
    if (_sharing) return;
    setState(() => _sharing = true);
    try {
      final boundary = _boundaryKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final bytes = byteData!.buffer.asUint8List();

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/callit-${widget.market.id.isEmpty ? 'market' : widget.market.id}.png');
      await file.writeAsBytes(bytes, flush: true);

      if (!mounted) return;
   await Share.shareXFiles(
  [XFile(file.path)],
  text: 'Called it on Callit — $_link',
);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Couldn't generate the share image right now.")));
      }
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(24, 20, 24, 24 + MediaQuery.of(context).viewInsets.bottom),
      decoration: const BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(color: AppColors.mist, borderRadius: BorderRadius.circular(999)),
          ),
          Text('SHARE THIS CALL', style: AppTextStyles.label(12, color: AppColors.slate)),
          const SizedBox(height: 16),
          RepaintBoundary(
            key: _boundaryKey,
            child: _MarketShareCard(market: widget.market, link: _link),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.ink,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: AppColors.ink, width: 1.4),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(4),
                  onTap: _sharing ? null : _share,
                  child: Center(
                    child: _sharing
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.2, color: AppColors.paper))
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.ios_share_rounded, size: 18, color: AppColors.paper),
                              const SizedBox(width: 8),
                              Text('Share image', style: AppTextStyles.button.copyWith(color: AppColors.paper)),
                            ],
                          ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The card itself — what actually gets captured to PNG. Styled like a
/// trading PnL screenshot: dark card, a big headline number, the
/// YES/NO split as the "chart", Callit branding in the corner.
class _MarketShareCard extends StatelessWidget {
  const _MarketShareCard({required this.market, required this.link});

  final Market market;
  final String link;

  @override
  Widget build(BuildContext context) {
    final yes = market.yesPricePct.clamp(0, 100);
    final leadingYes = yes >= 50;
    final leadingPct = leadingYes ? yes : 100 - yes;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.ink,
        border: Border.all(color: AppColors.ink, width: 1.4),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const AppLogo(size: 20, color: AppColors.paper),
                  const SizedBox(width: 6),
                  Text('CALLIT', style: AppTextStyles.label(12, color: AppColors.paper, weight: FontWeight.w700)),
                ],
              ),
              PillChip(label: market.category, background: AppColors.inkSurface, foreground: AppColors.paper),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            market.question,
            style: AppTextStyles.display(19, color: AppColors.paper, weight: FontWeight.w700, height: 1.3),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 22),
          Text(
            leadingYes ? 'LEANING YES' : 'LEANING NO',
            style: AppTextStyles.label(12, color: leadingYes ? AppColors.yes : AppColors.no, weight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            '${leadingPct.toStringAsFixed(0)}%',
            style: AppTextStyles.display(56, color: AppColors.paper, weight: FontWeight.w700),
          ),
          const SizedBox(height: 18),
          YesNoBar(yesPct: market.yesPricePct, height: 10),
          const SizedBox(height: 22),
          Container(height: 1, color: AppColors.inkBorder),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(market.resolvesLabel, style: AppTextStyles.tabularNums(11, color: AppColors.inkMuted)),
              Text(link, style: AppTextStyles.tabularNums(11, color: AppColors.inkMuted2)),
            ],
          ),
        ],
      ),
    );
  }
}

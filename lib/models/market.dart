import 'package:intl/intl.dart';

/// A single Panta prediction market, as Callit displays it.
///
/// Field names track the Panta API's create/catalog schema (question,
/// category, resolutionRule, sourcesOfTruth, startTime/endTime/
/// resolutionTime) so this model maps cleanly onto real API responses.
/// [fromApi] does that mapping for `GET /markets` and `GET /markets/{id}`
/// — see the Callit OpenAPI spec's `Markets` tag. The catalog and detail
/// responses don't carry creator info, so `creatorHandle`/`creatorInitials`
/// come back empty from the API and screens should hide that row rather
/// than print blank text (see `MarketDetailScreen`'s `if` around it).
class Market {
  const Market({
    required this.id,
    required this.question,
    required this.category,
    required this.yesPricePct,
    required this.resolvesLabel,
    this.creatorHandle = '',
    this.creatorInitials = '',
    this.volumeLabel,
    this.imagePath,
    this.isGraduated = false,
  });

  final String id;
  final String question;
  final String category; // Sports | Crypto | Politics | Entertainment | Finance | Science | World | Other
  final double yesPricePct;
  final String resolvesLabel;
  final String creatorHandle;
  final String creatorInitials;
  final String? volumeLabel;
  final String? imagePath;
  final bool isGraduated;

  /// The API's lowercase enum value for this market's category, for
  /// sending back as a `?category=` query param.
  String get categoryApiValue => category.toLowerCase();

  /// Builds a [Market] from a `GET /markets` (catalog) or
  /// `GET /markets/{id}` (detail) JSON object. Both share the same core
  /// fields; detail responses just carry fewer of the optional ones.
  factory Market.fromApi(Map<String, dynamic> json) {
    final rawCategory = (json['category'] as String?) ?? 'other';
    final category = rawCategory.isEmpty ? 'Other' : rawCategory[0].toUpperCase() + rawCategory.substring(1);

    final yesPriceStr = json['yesPrice'] as String?;
    final yesPrice = yesPriceStr != null ? double.tryParse(yesPriceStr) : null;
    final yesPricePct = yesPrice != null ? (yesPrice * 100).clamp(0, 100).toDouble() : 50.0;

    final endTime = json['endTime'] as int?;
    final resolvesLabel = endTime != null
        ? 'Resolves ${DateFormat('MMM d, yyyy').format(DateTime.fromMillisecondsSinceEpoch(endTime * 1000))}'
        : 'Resolution date pending';

    final volumeRaw = json['volumeUsdc'];
    final volume = volumeRaw is String ? double.tryParse(volumeRaw) : (volumeRaw as num?)?.toDouble();
    final volumeLabel = (volume != null && volume > 0) ? '${volume.toStringAsFixed(volume >= 1000 ? 0 : 2)} USDC volume' : null;

    // The catalog schema doesn't expose a "graduated" flag directly —
    // Panta's own phase enum (primary → secondary once a market's bonding
    // curve is done) is the closest signal until the API adds one.
    final phase = json['phase'] as String?;
    final images = json['images'] as List?;
    final imagePath = (images != null && images.isNotEmpty)
        ? images.first?.toString()
        : (json['imageUrl'] as String?);

    final titleStr = (json['title'] as String?)?.trim();
    final questionStr = (json['question'] as String?)?.trim();
    final resolvedQuestion = (titleStr != null && titleStr.isNotEmpty)
        ? titleStr
        : ((questionStr != null && questionStr.isNotEmpty) ? questionStr : 'Untitled market');

    return Market(
      id: (json['marketId'] as String?) ?? '',
      question: resolvedQuestion,
      category: category,
      yesPricePct: yesPricePct,
      resolvesLabel: resolvesLabel,
      volumeLabel: volumeLabel,
      imagePath: imagePath,
      isGraduated: phase == 'secondary',
    );
  }
}

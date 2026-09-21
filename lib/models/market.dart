/// A single Panta prediction market, as Callit displays it.
///
/// Field names track the Panta API's create/catalog schema (question,
/// category, resolutionRule, sourcesOfTruth, startTime/endTime/
/// resolutionTime) so this model maps cleanly onto real API responses
/// once the server proxy is wired in. `yesPricePct`/`volumeLabel` are
/// display-ready values — the real app derives them from the market's
/// live yesPrice/noPrice per the Panta docs.
class Market {
  const Market({
    required this.id,
    required this.question,
    required this.category,
    required this.yesPricePct,
    required this.resolvesLabel,
    required this.creatorHandle,
    required this.creatorInitials,
    this.volumeLabel,
    this.imagePath,
    this.isGraduated = false,
  });

  final String id;
  final String question;
  final String category; // sports | crypto | politics | entertainment | finance | science | world | other
  final double yesPricePct;
  final String resolvesLabel;
  final String creatorHandle;
  final String creatorInitials;
  final String? volumeLabel;
  final String? imagePath;
  final bool isGraduated;
}

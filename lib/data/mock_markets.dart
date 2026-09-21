import '../models/market.dart';

/// Placeholder markets so every screen has real-looking content to render
/// without a live Panta connection. Swap this out for a repository that
/// calls `GET /markets/` once the server proxy is wired up (see the
/// Callit PRD's Technical architecture section).
const mockMarkets = <Market>[
  Market(
    id: 'm1',
    question: 'Will the Super Eagles win AFCON 2027?',
    category: 'Sports',
    yesPricePct: 61,
    resolvesLabel: 'Resolves Feb 2027',
    creatorHandle: '@naijafootball',
    creatorInitials: 'NG',
    volumeLabel: '1.2k USDC volume',
    isGraduated: true,
  ),
  Market(
    id: 'm2',
    question: 'Will SOL close above \$300 before March 2027?',
    category: 'Crypto',
    yesPricePct: 47,
    resolvesLabel: 'Resolves Mar 1, 2027',
    creatorHandle: '@solcalls',
    creatorInitials: 'SC',
    volumeLabel: '860 USDC volume',
  ),
  Market(
    id: 'm3',
    question: 'Will BBNaija All Stars 2 have a female winner?',
    category: 'Entertainment',
    yesPricePct: 55,
    resolvesLabel: 'Resolves when the season ends',
    creatorHandle: '@gistbeta',
    creatorInitials: 'GB',
    volumeLabel: '410 USDC volume',
  ),
  Market(
    id: 'm4',
    question: 'Will ETH trade above \$5,000 before Jan 2027?',
    category: 'Crypto',
    yesPricePct: 38,
    resolvesLabel: 'Resolves Jan 1, 2027',
    creatorHandle: '@ethwatch',
    creatorInitials: 'EW',
    volumeLabel: '2.4k USDC volume',
    isGraduated: true,
  ),
  Market(
    id: 'm5',
    question: 'Will UniUyo win the NACOS Games this year?',
    category: 'Sports',
    yesPricePct: 72,
    resolvesLabel: 'Resolves this weekend',
    creatorHandle: '@gdgcampus',
    creatorInitials: 'GC',
    volumeLabel: '95 USDC volume',
  ),
];

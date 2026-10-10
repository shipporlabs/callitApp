import 'dart:convert';
import 'package:http/http.dart' as http;

class SolanaBalances {
  const SolanaBalances({
    required this.solBalance,
    required this.usdcBalance,
    required this.totalUsdValue,
  });

  final double solBalance;
  final double usdcBalance;
  final double totalUsdValue;
}

class SolanaService {
  SolanaService._();
  static final SolanaService instance = SolanaService._();

  static const String rpcUrl = 'https://api.mainnet-beta.solana.com';
  static const String usdcMint = 'EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v';

  final http.Client _client = http.Client();

  /// Fetches real on-chain SOL and USDC balance for [walletAddress].
  Future<SolanaBalances> getBalances(String walletAddress) async {
    final futures = await Future.wait([
      _getSolBalance(walletAddress),
      _getUsdcBalance(walletAddress),
      getSolUsdRate(),
    ]);

    final sol = futures[0];
    final usdc = futures[1];
    final solRate = futures[2];

    final totalUsd = (sol * solRate) + usdc;
    return SolanaBalances(
      solBalance: sol,
      usdcBalance: usdc,
      totalUsdValue: totalUsd,
    );
  }

  Future<double> _getSolBalance(String walletAddress) async {
    try {
      final res = await _client.post(
        Uri.parse(rpcUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'jsonrpc': '2.0',
          'id': 1,
          'method': 'getBalance',
          'params': [walletAddress],
        }),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final lamports = (data['result']?['value'] as num?)?.toDouble() ?? 0.0;
        return lamports / 1e9;
      }
    } catch (_) {}
    return 0.0;
  }

  Future<double> _getUsdcBalance(String walletAddress) async {
    try {
      final res = await _client.post(
        Uri.parse(rpcUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'jsonrpc': '2.0',
          'id': 2,
          'method': 'getTokenAccountsByOwner',
          'params': [
            walletAddress,
            {'mint': usdcMint},
            {'encoding': 'jsonParsed'},
          ],
        }),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final accounts = (data['result']?['value'] as List?) ?? [];
        if (accounts.isNotEmpty) {
          final info = accounts.first['account']?['data']?['parsed']?['info'];
          final uiAmount = (info?['tokenAmount']?['uiAmount'] as num?)?.toDouble();
          if (uiAmount != null) return uiAmount;
        }
      }
    } catch (_) {}
    return 0.0;
  }

  /// Live market price for SOL/USD from CoinGecko.
  Future<double> getSolUsdRate() async {
    try {
      final res = await _client.get(
        Uri.parse('https://api.coingecko.com/api/v3/simple/price?ids=solana&vs_currencies=usd'),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final rate = (data['solana']?['usd'] as num?)?.toDouble();
        if (rate != null && rate > 0) return rate;
      }
    } catch (_) {}
    return 150.0; // fallback if CoinGecko is throttled
  }
}

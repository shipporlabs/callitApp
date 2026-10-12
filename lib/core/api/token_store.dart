import 'package:shared_preferences/shared_preferences.dart';

/// Everything the app persists about the signed-in session: the bearer
/// JWT from `/auth/verify` or `/auth/login`, a little user info to paint
/// the profile screen without a round trip, and the account's wallet
/// public key. There's no user-facing "connect a wallet" step — FossaPay
/// provisions a wallet automatically for every account, and the app just
/// fetches it off the user's profile right after sign-up/login (see
/// `CallitApi.fetchWalletAddress`).
///
/// A single in-memory singleton backed by SharedPreferences, so every
/// screen reads the same values and a cold start restores them via
/// [load] before the first frame that needs them.
class TokenStore {
  TokenStore._();
  static final TokenStore instance = TokenStore._();

  static const _kToken = 'callit.token';
  static const _kUserId = 'callit.userId';
  static const _kUserName = 'callit.userName';
  static const _kUserEmail = 'callit.userEmail';
  static const _kWallet = 'callit.wallet';
  static const _kWalletProvider = 'callit.walletProvider';

  String? token;
  String? userId;
  String? userName;
  String? userEmail;
  String? walletAddress;
  String? walletProvider;

  bool _loaded = false;

  bool get isAuthenticated => token != null && token!.isNotEmpty;
  bool get hasWallet => walletAddress != null && walletAddress!.isNotEmpty;

  /// Call once at startup (see `main.dart`) so [isAuthenticated] is
  /// accurate before the splash screen decides where to route.
  Future<void> load() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    token = prefs.getString(_kToken);
    userId = prefs.getString(_kUserId);
    userName = prefs.getString(_kUserName);
    userEmail = prefs.getString(_kUserEmail);
    walletAddress = prefs.getString(_kWallet);
    walletProvider = prefs.getString(_kWalletProvider);
    _loaded = true;
  }

  Future<void> saveSession({required String token, String? userId, String? userName, String? userEmail}) async {
    this.token = token;
    this.userId = userId;
    this.userName = userName;
    this.userEmail = userEmail;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kToken, token);
    if (userId != null) await prefs.setString(_kUserId, userId);
    if (userName != null) await prefs.setString(_kUserName, userName);
    if (userEmail != null) await prefs.setString(_kUserEmail, userEmail);
  }

  Future<void> saveWallet({required String address, required String provider}) async {
    walletAddress = address;
    walletProvider = provider;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kWallet, address);
    await prefs.setString(_kWalletProvider, provider);
  }

  /// Log out: clears the session but keeps nothing behind.
  Future<void> clear() async {
    token = null;
    userId = null;
    userName = null;
    userEmail = null;
    walletAddress = null;
    walletProvider = null;
    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.remove(_kToken),
      prefs.remove(_kUserId),
      prefs.remove(_kUserName),
      prefs.remove(_kUserEmail),
      prefs.remove(_kWallet),
      prefs.remove(_kWalletProvider),
    ]);
  }
}

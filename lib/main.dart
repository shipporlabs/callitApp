import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'app.dart';
import 'core/api/token_store.dart';

/// Optional developer auto-login for debug builds. Pass these at run time:
///   flutter run --dart-define=DEV_TOKEN=... --dart-define=DEV_USER_ID=... \
///     --dart-define=DEV_WALLET=...
/// Nothing is stored in the source, and release builds ignore it entirely.
const String _devToken = String.fromEnvironment('DEV_TOKEN');
const String _devUserId = String.fromEnvironment('DEV_USER_ID');
const String _devWallet = String.fromEnvironment('DEV_WALLET');

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Restore the saved session (JWT + wallet) before the first frame, so
  // the splash screen can route straight to Home for a returning user.
  await TokenStore.instance.load();
  if (kDebugMode && _devToken.isNotEmpty && !TokenStore.instance.isAuthenticated) {
    await TokenStore.instance.saveSession(
      token: _devToken,
      userId: _devUserId,
      userName: 'Developer',
      userEmail: '',
    );
    if (_devWallet.isNotEmpty) {
      await TokenStore.instance.saveWallet(address: _devWallet, provider: 'Solana');
    }
  }
  runApp(const CallitApp());
}

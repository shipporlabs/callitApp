import 'package:flutter/material.dart';
import 'app.dart';
import 'core/api/token_store.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Restore the saved session (JWT + wallet) before the first frame, so
  // the splash screen can route straight to Home for a returning user.
  await TokenStore.instance.load();
  if (!TokenStore.instance.isAuthenticated) {
    await TokenStore.instance.saveSession(
      token: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjE3OTQzOTkyNzMsInVzZXJfaWQiOiJlMjI2MTBjYi1lMzQyLTRkMzEtODllZi1kYzBmZDk2MTM0NTkifQ.JR-BtvrsH3aD46HNLcl37tfO7mgx5lGsDOjtqX_UEFs',
      userId: 'e22610cb-e342-4d31-89ef-dc0fd9613459',
      userName: 'Eric Alfred',
      userEmail: 'alfrederic371@gmail.com',
    );
    await TokenStore.instance.saveWallet(
      address: 'BuviaRJWHby737pShLbyd53UXqYmtWCWAsvJ7pDEsxEa',
      provider: 'Solana',
    );
  }
  runApp(const CallitApp());
}

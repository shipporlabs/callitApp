import 'package:flutter/material.dart';
import 'app.dart';
import 'core/api/token_store.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Restore the saved session (JWT + wallet) before the first frame, so
  // the splash screen can route straight to Home for a returning user.
  await TokenStore.instance.load();
  runApp(const CallitApp());
}

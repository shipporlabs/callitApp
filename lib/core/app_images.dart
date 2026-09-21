/// Central list of every local asset the app looks for.
///
/// Drop files with these exact names into the folders below and they show
/// up automatically — nothing else to wire up. Until then, every screen
/// falls back to a clean drawn placeholder (see `AppImage` in
/// core/widgets/app_image.dart), so the app looks intentional and runs
/// fine with zero images added.
///
/// assets/images/  — photos and illustrations
/// assets/icons/   — small monochrome or brand icons (24–48px)
///
/// See ASSETS_GUIDE.md at the project root for recommended sizes.
class AppImages {
  AppImages._();

  // Onboarding illustrations (recommended 800x800, square, transparent bg)
  static const onboarding1 = 'assets/images/onboarding_1.png';
  static const onboarding2 = 'assets/images/onboarding_2.png';
  static const onboarding3 = 'assets/images/onboarding_3.png';

  // Auth screen art
  static const authArt = 'assets/images/auth_art.png';

  // Empty / success states
  static const emptyMarkets = 'assets/images/empty_markets.png';
  static const successCheck = 'assets/images/success_check.png';
  static const walletConnected = 'assets/images/wallet_connected.png';

  // Wordmark / app icon, if you want a raster version instead of the
  // drawn logomark used by default (see AppLogo widget)
  static const logo = 'assets/icons/logo.png';

  // Wallet provider marks — drop official marks here if you have them
  static const walletPhantom = 'assets/icons/wallet_phantom.png';
  static const walletSolflare = 'assets/icons/wallet_solflare.png';

  // Per-market cover image, when a creator adds one (see Market.imageUrl
  // for the remote case — this is only for local/demo markets)
  static const marketPlaceholder = 'assets/images/market_placeholder.png';
}

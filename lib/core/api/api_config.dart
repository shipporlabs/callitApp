/// Where the Callit server lives. The server holds the Panta API key and
/// the Anthropic key — the app never talks to Panta or Claude directly,
/// only to this proxy (see the Callit PRD's Technical architecture).
///
/// Swap [baseUrl] for wherever you're running `callit-api`:
/// - Android emulator talking to a server on your own machine: use
///   `http://10.0.2.2:8095/v1` (10.0.2.2 is the emulator's alias for
///   the host's localhost).
/// - A real device on the same Wi-Fi as your dev machine: use your
///   machine's LAN IP, e.g. `http://192.168.1.23:8095/v1`.
/// - The shared dev VPS from the OpenAPI spec: already set below. It has
///   no TLS yet, so cleartext HTTP must stay allowed for it —
///   `android:usesCleartextTraffic="true"` in AndroidManifest.xml (or a
///   `<domain-config>` scoped to just this host), and an
///   `NSAppTransportSecurity` exception domain in Info.plist on iOS.
class ApiConfig {
  ApiConfig._();

  /// Default: the live public HTTPS Cloudflare tunnel pointing to the dev VPS.
  static String baseUrl = 'https://ads-headset-kilometers-finite.trycloudflare.com/v1';

  static const Duration timeout = Duration(seconds: 20);
}

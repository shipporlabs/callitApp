# Callit — Flutter app

Turn any take into a market. A native iOS + Android UI for Callit, the app
that drafts and shares Panta prediction markets. This is a design-complete,
fully navigable UI skeleton — see "What's real vs. mocked" before demoing
or shipping it.

## Run it

```bash
flutter pub get
flutter run
```

Requires Flutter 3.22+ (Dart 3.3+). No API keys or backend needed to run —
everything is mocked so you can see and click through the whole app today.

## Screens included

- **Splash → Onboarding** (3 slides) → **Welcome**
- **Auth:** sign up, log in, 6-digit email verification
- **Wallet connect:** Phantom / Solflare / other, skippable after sign-up
- **Home:** market feed with category filters and search, bottom nav with a
  raised centre "Create" action
- **Market detail:** odds, resolution rule, sources, a bottom-sheet buy flow
  (amount → sign → confirmed)
- **Create market:** paste a headline/tweet → AI-compiled review (editable
  question, category, resolution rule, source) → sign → success + share
- **Wallet:** balance card, receive/convert/send, positions list; **Convert**
  screen (SOL ⇄ USDC)
- **Profile:** creator dashboard (markets created, volume, fees to claim),
  settings list, log out

## Project layout

```
lib/
  theme/          Colors, type (Space Grotesk + IBM Plex Sans), ThemeData
  core/
    app_images.dart      Every local asset path the app looks for
    widgets/              Shared UI: buttons, fields, market card, nav, etc.
  models/          Market, WalletBalance
  data/            Mock market list (swap for a real repository)
  screens/         One folder per flow — splash, onboarding, auth, home,
                   create, wallet, profile
assets/
  images/          Drop illustrations here — see assets/images/README.md
  icons/           Drop small marks here — see assets/icons/README.md
```

## Adding your own images

Every illustration slot (onboarding, welcome art, success screens, wallet
connect) already renders a clean drawn placeholder — an icon on a soft
tile — so the app looks intentional with zero images added. Drop a file
with the exact name listed in `assets/images/README.md` or
`assets/icons/README.md` into the matching folder and it swaps in
automatically; no code changes needed. `lib/core/widgets/app_image.dart`
is what makes that fallback work (`Image.asset` with an `errorBuilder`).

## Wired to the Callit API

The app talks to the `callit-api` server (the Callit OpenAPI spec) through
`lib/core/api/`:

- `api_config.dart` — the base URL. Defaults to the shared dev VPS from the
  spec (`http://quirky-comet.62-171-156-198.sslip.io:8095/v1`). Point it at
  `http://10.0.2.2:8095/v1` for an Android emulator hitting your own
  machine, or your LAN IP for a real device.
- `api_client.dart` — the envelope-aware HTTP layer (`{"data":...}` /
  `{"error":...}`), adds the bearer JWT automatically.
- `callit_api.dart` — one method per endpoint, grouped by the spec's tags.
- `token_store.dart` — persists the session JWT and the connected wallet
  address across app restarts (`SharedPreferences`); `main.dart` loads it
  before the first frame so `SplashScreen` can skip onboarding for a
  returning, signed-in user.

**Both dev servers in the spec are plain HTTP, no TLS yet.** Once you run
`flutter create .` to add the `android/` and `ios/` folders, you'll need:
- Android: `android:usesCleartextTraffic="true"` on `<application>` in
  `android/app/src/main/AndroidManifest.xml` (or a `<network-security-config>`
  scoped to just that host).
- iOS: an `NSAppTransportSecurity` → `NSExceptionDomains` entry for the host
  in `ios/Runner/Info.plist`.

| Screen | Calls |
| --- | --- |
| Sign up → verify | `POST /auth/register` → `POST /auth/verify` (saves the JWT) |
| Log in | `POST /auth/login` |
| Add wallet | Still simulated — generates a placeholder pubkey and saves it via `TokenStore.saveWallet`. Swap in Solana Mobile Wallet Adapter and save the *real* returned public key the same way; everything downstream already reads it from there. |
| Markets feed | `GET /markets`, `GET /categories` — falls back to `lib/data/mock_markets.dart` if the server's unreachable |
| Market detail | `GET /markets/{id}` on open; buy sheet runs `POST /orders/quote` → `/build` → (simulated signature) → `/submit` → `/verify` → `POST /trades/report` |
| Paste → Review | `POST /ai/compile`, then `POST /markets/create/quote` → `/build` → (simulated signature) → `/register` |
| Market created | `POST /share-card` when you tap "Share market" |
| Wallet tab | `GET /positions` for the wallet address in `TokenStore`; USDC/SOL balance display is still a placeholder — that's a Solana RPC call, not a Panta one |
| Claim (wallet + profile) | `POST /claims/win`, `POST /claims/creator-fees` — both return *unsigned* instructions, so the wallet still needs to sign and broadcast them |
| Profile | `GET /me/markets` for the creator dashboard stats |

The one step no server proxy can do for you: **the wallet signature**.
Every flow above builds the real unsigned transaction from the live API
and then simulates the sign step with a random string — search for
"Hook point" in `market_detail_screen.dart`, `review_market_screen.dart`,
and `add_wallet_screen.dart` for exactly where Mobile Wallet Adapter goes.

Mock data in `lib/data/mock_markets.dart` is now only a fallback for when
the server can't be reached, not the primary source.

## Brand

Colors, type and voice match the Callit landing page and PRD exactly —
Ink `#111426`, Paper `#FBF8F1`, Highlight `#FFD23F`, Yes `#0B7F76`,
No `#D63645`, Slate `#5B6478`, Mist `#E7E4DA`. Add "Powered by Panta"
wherever a screen shows Panta-powered functionality, per Panta's API Terms.

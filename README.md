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

## What's real vs. mocked — read before demoing

This is the UI and interaction design, built to the Callit PRD and brand.
It is **not** wired to the live Panta API yet. Every screen that would call
Panta has a comment marking the hook point, matching the PRD's architecture
(a server holds the API key; the app never talks to Panta directly):

| Screen | Hook point |
| --- | --- |
| Sign up / log in | Your auth backend (`/auth/register/`, `/auth/token/`) |
| Add wallet | Solana Mobile Wallet Adapter |
| Paste → Review | Your AI compiler, then `POST /markets/create/quote/` → `build/` → `register/` |
| Market detail buy sheet | `POST /orders/quote/` → `build/` → wallet sign → `submit/` → `verify/` |
| Wallet screen | `GET /positions/` + a Solana RPC balance check |
| Convert screen | A swap route of your choosing |
| Profile dashboard | `GET /account/metrics/`, `POST /claim/creator-fees/build/` |

Mock data lives in `lib/data/mock_markets.dart` — replace it with a
repository that calls your server proxy once that's built.

## Brand

Colors, type and voice match the Callit landing page and PRD exactly —
Ink `#111426`, Paper `#FBF8F1`, Highlight `#FFD23F`, Yes `#0B7F76`,
No `#D63645`, Slate `#5B6478`, Mist `#E7E4DA`. Add "Powered by Panta"
wherever a screen shows Panta-powered functionality, per Panta's API Terms.

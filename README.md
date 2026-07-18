# Zomato Sync Table

“Two locations. Two carts. One shared meal.”

Sync Table is an offline-first iOS hackathon prototype for couples, friends, and families who want to order locally in different cities and experience one meal together. Aniket in Mumbai and Aisha in Bengaluru find compatible restaurants, build separately owned carts while seeing each other’s activity, authorize separate mock payments, follow two honest delivery journeys, and begin the first bite together.

## What is implemented

- Complete home → invite → match → shared menu → dual cart → checkout → tracking → first bite → dining → memory flow
- Deterministic restaurant Sync Score based on menu similarity, price, preparation time, delivery time, ratings, and predicted arrival difference
- Menu Twin using Apple Foundation Models with structured `@Generable` output, runtime availability checks, and a deterministic tag/keyword fallback
- Real `GroupActivity`, `GroupSessionMessenger`, and typed SharePlay messages plus a one-device `LocalSyncSession`
- Two independent carts and orders with readiness and payment gating
- Divergent individual order states; shared milestones derive from the slower order
- MapKit courier routes and honest shared delivery windows
- ActivityKit updates, a WidgetKit Live Activity, Dynamic Island layouts, and an App Intent ready-to-eat action
- Accessibility labels, Dynamic Type-friendly layouts, semantic colors, haptics, and an offline demo catalogue
- Discreet demo controls under the ellipsis button on every screen

## Architecture

`SyncTableStore` is the main-actor, observable client state. Views read the store and send explicit user intentions. `DemoBackendService` is the transport boundary: the demo uses `HTTPDemoBackendService`, while a production API client can replace it without changing feature views. Navigation is deliberately local to each device; only shared domain state is sent to the backend. Cart and confirmation mutations are server-authoritative operations, avoiding cross-device last-write-wins data loss. Each `LinkedOrder` owns its own status and estimate; `SharedMilestone` is derived from both orders rather than copied into them.

Key folders:

- `Prototype_1_movie/Models`: domain values
- `Prototype_1_movie/Services`: protocol-backed mock services and deterministic logic
- `Prototype_1_movie/SyncSession`: observable store, SharePlay model, local fallback
- `Prototype_1_movie/FoundationModel`: Foundation Models guided generation
- `Prototype_1_movie/LiveActivity`: app-side ActivityKit attributes and updates
- `Prototype_1_movie/Features`: polished SwiftUI flow
- `SyncTableWidget`: WidgetKit, Dynamic Island, and App Intent extension
- `Prototype_1_movieTests`: Swift Testing coverage for core invariants

## Platform APIs

Built with Xcode 26.0, Swift 6.2, and the installed iOS 26 SDK (iOS 27 was not installed). It uses SwiftUI, Observation, structured concurrency, NavigationStack, Foundation Models, GroupActivities, ActivityKit, WidgetKit, App Intents, and MapKit. The Foundation Models implementation only classifies catalogue-supplied menu text and never controls logistics.

## Setup and run

1. Open `Prototype_1_movie.xcodeproj` in Xcode 26 or newer.
2. Choose the `Prototype_1_movie` scheme and an iOS 26 simulator.
3. Run. No API keys or payment credentials are needed.

From Terminal:

```sh
./script/build_and_run.sh
```

Override the default simulator with `SYNC_TABLE_DEVICE_ID=<UDID>`. Run tests with:

```sh
xcodebuild test \
  -project Prototype_1_movie.xcodeproj \
  -scheme Prototype_1_movie \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

## Two-simulator live demo

Run the complete demo setup with:

```sh
./script/run_two_simulators.sh
```

This starts the local backend, clears the previous `ST-7N4K` session, builds once, and launches:

- Aniket as host on iPhone 17 Pro
- Aisha as partner on iPhone 17 Pro Max

Both apps start on the same entry screen. Create a table on either device, then enter its four-character code on the other device. Both apps poll the server-authoritative revision stream four times per second. Session membership, ordering mode, restaurant selection, independently owned cart changes, readiness, payment decisions and confirmations, linked orders, delivery status, first-bite state, reactions, notification events, and the final Table Memory are shared. Screen navigation is never synchronized. The green dot in the navigation bar confirms backend connectivity.

The ordering-mode screen supports:

- Blend
- The nearest branch of the same chain
- Independently selected local restaurants

Before checkout, both people choose and confirm one payment arrangement: equal split, own orders, or one volunteer paying the combined total. The final memory persists in SQLite and includes both users, locations, dishes, restaurants, ordering mode, and payment summary.

Override either device or the backend without changing app code:

```sh
SYNC_TABLE_HOST_DEVICE=<UDID> \
SYNC_TABLE_PARTNER_DEVICE=<UDID> \
SYNC_TABLE_BACKEND_URL=http://localhost:8787 \
./script/run_two_simulators.sh
```

For a hosted demo server, run `script/demo_server.sh` on the host and pass its URL. The backend is an intentionally small Python standard-library service backed by `.build/sync-table-demo.sqlite3`, with no package installation. Set `SYNC_TABLE_DB` to move the SQLite database.

## Demo Mode

The two-simulator flow uses real independent host/partner actions. The ellipsis button retains judge-friendly manual controls to join Aisha, trigger cart activity, set both ready, advance delivery, inject a delay, complete both deliveries, trigger first bite, or reset.

Automatic delivery uses seven 15-second beats and completes in about 105 seconds. Use “Complete both deliveries” for a two-minute stage demo.

## Capabilities and real-device testing

- SharePlay requires the Group Activities capability, a signed build, FaceTime, and multiple participants. The local session is always available for one-simulator demos.
- Live Activities require “Supports Live Activities” and the embedded widget extension. Start one by submitting linked orders. On a supported device, inspect the Lock Screen and Dynamic Island. The tracking screen contains an in-app preview for simulators where system presentation is unreliable.
- Foundation Models requires an available on-device system model and supported locale. Unsupported simulators automatically use the deterministic fallback.
- Production signing may require selecting your own development team and adding the Group Activities entitlement in Xcode.

## Prototype limitations

- Catalogue, inventory, payments, kitchen timing, couriers, and routes are deterministic mocks. Presence, carts, orders, status, and notification events use the shared demo backend.
- The App Intent demonstrates the Live Activity action surface but does not persist readiness to a production server.
- SharePlay transport is implemented behind the same message model as local demo mode; sensitive payment details are never sent.
- No operational claim is hidden or guaranteed. The prototype coordinates planned kitchen start and courier assignment; it never claims food or riders are intentionally held.

## Future production architecture

A production system would use server-authoritative session state, per-owner cart authorization, inventory reservations, idempotent linked-order orchestration, encrypted presence channels, event-sourced delivery estimates, observability, fraud controls, and fallbacks that cleanly unpair orders when one side fails. Matching would pre-filter only serviceable catalogue inventory and keep deterministic logistics scoring separate from culinary model classification.

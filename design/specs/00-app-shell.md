# Screen type: app shell

## Orientation
This is the fiddliest part of the native build. Settled: **the shell is portrait, activities are
landscape-only.**

SwiftUI has no first-class per-screen orientation lock. Implement it as:
1. `UIViewControllerRepresentable` wrapper exposing `supportedInterfaceOrientations`.
2. An `OrientationLock` environment value the activity runner sets on appear and clears on disappear.
3. On iOS 16+, drive it through `UIWindowScene.requestGeometryUpdate(_:)` and update
   `AppDelegate.application(_:supportedInterfaceOrientationsFor:)` from the same source of truth.
4. Info.plist declares all orientations; the lock narrows them at runtime.

Entering an activity: rotate to landscape and show a one-time "turn your device" hint if the
device is held portrait and rotation lock is on. Leaving: restore portrait.

**iPad exception.** Do not force-rotate on iPad — it is jarring and Slide Over / Stage Manager make
it unreliable. On iPad the activity runner renders landscape-proportioned content inside whatever
size class it gets, letterboxed. Design the runner layout to be aspect-driven, not orientation-driven.

## Navigation
A single `NavigationStack` with a typed `Route` enum. Modals (Settings, Switch Child, Paywall)
are sheets, not stack pushes. The activity runner is a **full-screen cover**, not a push — it owns
the whole surface, has no nav bar, and its own close affordance.

Route enum, at minimum: `.home`, `.umbrella(key)`, `.activity(id)`, `.progress`, `.rewards`, `.tips`.

## Chrome
No system navigation bar anywhere. Every screen draws its own header. Back is a 44pt circular
white button, `0 3px 9px rgba(22,48,91,.12)` shadow, navy chevron, top-left of the header block.

## Startup
1. Restore session → if none, auth (`specs/05`, auth section).
2. Fetch `/v1/catalog` → umbrellas + activities.
3. Fetch entitlement state.
4. Render home. Do not block home on activity config — that loads when an activity is opened.

## Delete from the template
`Item.swift`, the `Schema`/`ModelContainer` in `BeemooArticulationApp.swift`, and the
SwiftData list in `ContentView.swift`. `ContentView` becomes the route host. The macOS
`NavigationViewWrapper` branch is dead code — remove it, this is iOS/iPadOS only.

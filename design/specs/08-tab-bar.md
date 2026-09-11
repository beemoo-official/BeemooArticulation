# Screen type: tab bar

## Why this changes the navigation model
The app was specced as a hub-and-spoke `NavigationStack`: Home is the centre, everything else is a
push, and adult tools (Settings, Switch Child) are sheets off the Home header. A tab bar replaces
that with persistent top-level destinations.

This is a real restructure, not an added component. Read this whole doc before changing routing.

## Tabs
Four. More than four crowds the bar at phone widths and none of the candidates earn a fifth.

| Tab | Icon | Contents |
|---|---|---|
| **Home** | house | The existing home screen, minus what the other tabs now own |
| **Progress** | chart | `specs/04` Progress screen, promoted from a push |
| **Rewards** | star | `specs/04` Rewards screen, promoted from a push |
| **Parents** | adult figure | Tips for Parents, Settings, and Switch Child — all adult-facing, one tab |

**Parents** is a list screen, not a direct view: rows for Tips for Parents, Settings, Switch Child,
and Subscription, each pushing within that tab's own stack.

Each tab owns an independent `NavigationStack`. Switching tabs preserves each stack's position.

## What moves off Home
- The Progress card **stays** but becomes a glanceable summary: tapping it *switches to the Progress
  tab* rather than pushing. Same for the Daily Challenge card → Rewards tab.
- The Settings gear and Switch Child pill **leave the Home header**. They live in Parents now.
  Removing them from the header is the point — Home becomes the child's screen, and adult controls
  are one deliberate tap away rather than sitting next to a four-year-old's thumb.
- The subscription banner stays on Home.

## The runner
The activity runner is a landscape `fullScreenCover` and **must cover the tab bar completely**.
Presenting it from inside a tab is correct — a cover sits above the `TabView` — but verify it, and
never render the runner as a tab's content. A tab bar visible mid-trial is a child's exit route.

## Visual spec
- Height 56pt plus the bottom safe area. Background `#FFFDF6`, not translucent — the app's grounds
  are cream and a blurred tab bar over cream reads as a smudge.
- Hairline top border `rgba(22,48,91,.09)`.
- Selected: icon and label `#16305B`; a 4pt `#FFD100` dot centred 3pt above the icon.
- Unselected: icon and label `rgba(22,48,91,.50)`. This clears 4.5:1 on cream.
- Labels: Nunito 700, 10pt, always visible — never icon-only. Pre-readers aren't the ones using it,
  and adults navigating a child's app want words.
- Icons 24pt, consistent weight across the set. Use one icon family; don't mix SF Symbols with
  custom art in the same bar.
- Full 44pt hit target per tab regardless of the 56pt bar height — extend the tappable area into the
  safe-area inset.
- No badges. Nothing in this app is urgent enough to dot a tab, and a badge on Rewards teaches a
  child to chase it.

## Accessibility
Each tab is a button with an accessibility label matching its visible label and a
`.isSelected` trait on the active one. Respect Dynamic Type up to XL on labels; past that, let the
label truncate rather than growing the bar.

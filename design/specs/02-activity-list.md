# Screen type: umbrella activity list

Portrait. Surface `#F4F8FE`.

## Header
Gradient `linear-gradient(180deg,#DCEBFB,#F4F8FE)`, padding `44 16 16`.
Back button (44pt white circle) · title in the umbrella's ink colour, Baloo 2 800 21pt ·
subtitle Nunito 600 12pt navy-60 showing progress across the umbrella.

## Rows
One card per activity, vertical stack. Each row:
- Left: 44pt+ rounded square in the activity's `tint`, initials in white Baloo 2 800
- Title Baloo 2 800 14.5pt navy
- Badges inline after the title, gap 7:
  - `NEW` — `#FFD100` fill, navy text, Nunito 800 8.5pt, radius 999, padding `4 6`, letter-spacing .4
  - `SOON` — `rgba(22,48,91,.09)` fill, navy-60 text, same metrics
- Description Nunito 600, navy-62
- Right: progress percentage or chevron

Row states from `activities.json`: `status: "live"` navigates; `status: "stub"` shows SOON and is
non-interactive (but still readable — do not dim below 4.5:1).

Locked-by-subscription rows are a *different* state from SOON: they navigate to the paywall.
Only How Much is live today.

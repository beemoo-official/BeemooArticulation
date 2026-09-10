# Screen type: home

Portrait. Surface `#FFFDF6`. Scrolls as one column.

## 1. Hero block
Gradient `linear-gradient(180deg,#FFF6DA,#FFEFB8 46%,#FFE07A)`, padding `44 18 0`.

**Header row** (44pt tall controls, gap 11):
- Child avatar — 46pt circle, 3pt white border, `0 3px 10px rgba(0,0,0,.14)`
- Name block — "Hi, {childName}!" Baloo 2 800 17pt navy; "Let's practice!" Nunito 600 12.5pt navy-62
- "Switch Child" pill — white, 44pt tall, radius 999, Nunito 800 12.5pt navy, leading 15pt navy dot
- Settings — 44pt white circle

**Brand block** (min-height 214):
- Logo, 192pt wide, `drop-shadow(0 4px 8px rgba(0,0,0,.13))`
- Tagline: "Speech & Language Practice / Made Simple. Made Fun." Nunito 800 13pt navy, max-width 190
- BeeMoo character, 168pt, offset right −30 / top 14, `bmFloat` animation
- Speech bubble — white, radius 18, padding 12/14, width 214, with a rotated 16pt square tail at
  left −7 / bottom 20. Title "Hi! I'm BeeMoo!" Baloo 2 800 13.5pt; body Nunito 600 12.5pt navy-78

The hero closes with a 26pt cream cap, radius `26 26 0 0`, bleeding to the gradient's edges.

## 2. Umbrella grid
2 × 2, gap 11, padding `0 16 18`. Each card: umbrella `tint` background, umbrella `ink` for the
title, icon, description Nunito 600. Tap → `.umbrella(key)`. Cards for umbrellas with no live
activities still navigate — the list shows SOON badges.

## 3. Today's Progress card
White, radius 20, border navy-09, shadow `0 4px 14px rgba(22,48,91,.05)`, padding `13 13 14`.
Title "Today's Progress" Baloo 2 800 13.5pt + chevron button → `.progress`.
Ring: conic progress, 52pt white centre, "{done}/5" Baloo 2 800 15pt over "Activities Completed"
Nunito 700 6.5pt centred.

## 4. Daily Challenge card
Star art 66pt with `bmBob`. Title Baloo 2 800 13.5pt. Body "Complete 5 activities to earn your
badge." Nunito 600 11pt navy-60. Progress line in `#F2801F` Baloo 2 800 13pt. Chevron → `.rewards`.

## 5. Subscription banner
Gradient `120deg #16305B → #264A85`, radius 20, padding `13 15`.
"BeeMoo Everything" Baloo 2 800 13pt in `#FFD100`; body Nunito 600 11pt white-78.
CTA pill: `#FFD100` fill, 40pt tall, navy Nunito 800 12pt, "See plans" → paywall sheet.
Hide this entire card for subscribed accounts — do not show a "you're subscribed" variant.

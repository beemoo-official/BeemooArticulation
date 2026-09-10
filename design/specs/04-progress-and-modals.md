# Screen types: progress and modals

## Progress (portrait, pushed route)
Surface `#FFFDF6`. Header gradient `linear-gradient(180deg,#FFF3CE,#FFFDF6)`, padding `46 16 14`.
Title "Progress" Baloo 2 800 22pt navy; subtitle "{childName} · this week" Nunito 600 12pt navy-60.

**Accuracy card** — conic ring, 56pt white centre with the percentage in Baloo 2 800 16pt.
Title "HOW MUCH accuracy" Baloo 2 800 14pt; below it the trial count line Nunito 600 11.5pt navy-62.

**By concept card** — title "By concept" Baloo 2 800 14pt, caption "First-try accuracy on receptive
trials" Nunito 600 10.5pt navy-50. Then one row per concept (nine rows), each a label plus a
horizontal bar. Concepts with no trials render at zero with a muted bar — do not hide them; the
gaps are clinically meaningful.

Everything here derives from logged trials. No invented numbers, no placeholder charts.

## Rewards (portrait, pushed route)
Badge grid, earned vs. unearned. Daily challenge state. Earned badges use `bmBob`.

## Tips for Parents (portrait, pushed route)
Card list. Each tip: an uppercase category tag (AT HOME, PROMPTING, …) Nunito 800 with
letter-spacing, a Baloo 2 800 title, and a Nunito 600 body. Long-form reading — generous line
height, max ~70 characters per line.

## Switch Child (sheet)
Row per child: avatar, name Baloo 2 800, meta line "Age 5 · 4 goals · 12 sessions" Nunito 600
navy-62, and a selected state. Plus an "Add child" row. Switching resets the session and refetches
progress. Number of children is entitlement-gated — see `05`.

## Settings (sheet)
Grouped list. Four groups: **Child** (name, avatar), **Activity** (wrong-answer response, advance
gating), **Audio** (narration on/off, voice), **Account** (subscription, sign out).
The activity settings are the ones that change runner behaviour — label them in adult language,
not child-facing copy.

# Screen type: activity runner

Landscape. This is the heart of the app. Driven entirely by `config/how-much.json` — the runner
must contain no activity-specific logic. Adding an activity means adding a config document.

## Data model
```
Activity { activityId, version, title, umbrella, orientation, concepts[], screens[] }
Screen   { n, type, concept, ...type-specific fields, audio?, note? }
```
Six `type` values: `intro`, `teaching`, `comparison`, `receptive`, `transition`, `celebration`.

## Marker syntax
Prompt strings mark the target concept word with asterisks: `This is *one* apple.`
Render the marked run in `#1F8A48` at the same weight as the surrounding text. Parse once into an
`AttributedString`; never ship the asterisks to screen. This is the single most important visual
rule in the activity — the green word is the teaching signal.

## Scene geometry — read before building any screen
Scenes are illustrations with meaningful composition, so they are **`scaledToFit`, centred, and
letterboxed on cream (`#FFFDF6`)** in the area above the prompt plate. Never `scaledToFill`: cropping
a 4:3 illustration onto a 19.5:9 phone cuts the subject unpredictably.

Every `ringXPercent`, `ringYPercent`, `cuesXPercent` and `cueTopPercent` is a percentage of the
**rendered image frame**, not of the screen. Compute the image's actual laid-out rect and position
cues inside it. Positioning against the viewport misaligns every cue on every device.

## Prompt treatment
Prompt text sits on a **solid cream plate** (`#FFFDF6`) running the full width along the bottom of
the screen — not a gradient scrim over the art. Ink is navy `#16305B`; the marked concept word is
`#1F8A48` at the same weight. The plate is sized to its text, minimum 96pt tall.

Do **not** put white text over the illustration: `#1F8A48` on a dark scrim is ~3.6:1, which makes the
concept word — the teaching signal — the least legible thing on screen. Light ground is also what the
rest of the app looks like.

Prompt type is the largest in the app: Nunito 700 at 34–40pt landscape, wrapping to at most two lines.

## Screen types

### intro
Full-bleed `scene`. Prompt text overlaid. Advances on narration end or tap.

### teaching
Full-bleed `scene` with the prompt. Optional `ringXPercent` / `ringYPercent` — a highlight ring centred at that
point of the **rendered image frame**. The ring is a stroked circle in `#F2801F`, 4pt, sized to about
22% of the image's shorter side — never a fixed pixel size, and never a fill. It marks the object; it
must not cover it.

### comparison
Full-bleed `scene` showing 2–3 quantities side by side. `lines[]` are read in order, each paired
with `cuesXPercent[i]` — a pointer at that x-percentage of the rendered image. Optional
`labels[]` render as captions under each region. Optional `cueTopPercent` overrides cue vertical
position (default 50).
Each line plays in sequence with its cue active; the child is not asked to respond.

### receptive
The trial screen. `prompt` + `choices[]`, each choice `{asset, meaning}`.
**Correctness is semantic, not positional** — compare `choice.meaning` to `screen.correct`.
`shuffleChoices: true` means randomise presentation order every time the screen is entered,
including on retry. Never hard-code panel positions.

Choice panels are equal-width, full-height cards in a horizontal row, gap 16, radius 20. Minimum
touch target far exceeds 44pt here — these are the primary interaction and should be large.

### transition
A concept-pair interstitial. Flat ground in a palette colour selected by `variant`:
0 → `#2A7BD4`, 1 → `#8B57C4`, 2 → `#3E9B4F`. Flat, not a gradient, and no colours outside the palette.

The only content is the concept pair from `concept` (e.g. "MORE / LESS"), Baloo 2 800 at 56pt in
white, centred, with the slash rendered at 40% opacity. **No other copy** — no "Next up", no
instructions. This is a breath between blocks, not a screen to read.

Auto-advances after 1.2s; a tap skips it.

### celebration
End of activity. Ground is the home hero gradient (`#FFF6DA → #FFEFB8 → #FFE07A`). `star.png` at
160pt with `bmBob`. One line of copy, Baloo 2 800 44pt navy: **"You did it!"**

`audio` is a **narration string, not display copy** — speak it, never render it as text. No
"Tap to finish" hint; the screen advances on tap or after the narration ends.

## Trial flow (spec-exact — do not simplify)
1. Model says the target word.
2. Pause for the child to repeat it.
3. The stressed word plays.
4. For `receptive` screens, choices become tappable.
5. Tap → evaluate semantically → feedback → log the trial.

## Trial logging
On every answer: `{screenId, concept, firstTry: Bool, attempts: Int, timestamp}`.
Only the **first** attempt counts toward accuracy; subsequent attempts increment `attempts` and
leave `firstTry` untouched. Progress views read first-try accuracy by concept.
POST to `/v1/children/:id/trials` — batch per session, queue on failure, retry on next launch.

## Settings that change runner behaviour
| Setting | Effect |
|---|---|
| Wrong-answer response | Retry same screen / advance anyway / re-teach then retry |
| Advance gating | Auto-advance on correct vs. adult taps to continue |
| Narration | On / off — off still shows text and still logs trials |
| Child name | Interpolated into narration and copy |

These are read at screen-entry time, not cached for the session — an adult may change them mid-activity.

## Exit
A deliberately adult-targeted close control in the top trailing corner: small relative to the choice
panels, and requiring a **press-and-hold** so a child cannot exit mid-trial by tapping.

The hold must be discoverable. On first tap, show a ring that fills over the hold duration plus the
label "Hold to exit" — a control whose tap silently does nothing reads as broken to the adult
holding the phone.

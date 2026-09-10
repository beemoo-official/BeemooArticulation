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

## Screen types

### intro
Full-bleed `scene`. Prompt text overlaid. Advances on narration end or tap.

### teaching
Full-bleed `scene` with the prompt. Optional `ringXPercent` — a highlight ring centred at that
percentage of the scene's width, vertically centred unless `cueTopPx` says otherwise. The ring is
a stroked circle, not a fill; it must not obscure the object it marks.

### comparison
Full-bleed `scene` showing 2–3 quantities side by side. `lines[]` are read in order, each paired
with `cuesXPercent[i]` — a pointer/highlight at that x-percentage of the scene. Optional
`labels[]` render as captions under each region. Optional `cueTopPx` overrides cue vertical position.
Each line plays in sequence with its cue active; the child is not asked to respond.

### receptive
The trial screen. `prompt` + `choices[]`, each choice `{asset, meaning}`.
**Correctness is semantic, not positional** — compare `choice.meaning` to `screen.correct`.
`shuffleChoices: true` means randomise presentation order every time the screen is entered,
including on retry. Never hard-code panel positions.

Choice panels are equal-width, full-height cards in a horizontal row, gap 16, radius 20. Minimum
touch target far exceeds 44pt here — these are the primary interaction and should be large.

### transition
A concept-pair interstitial (`variant` 0/1/2 selects the visual treatment). No interaction beyond
advancing. Short — this is a breath between blocks, not a screen to read.

### celebration
End of activity. Plays `audio`, shows the reward, returns to the activity list.

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
A small, deliberately adult-targeted close control (top corner, small hit area relative to the
choice panels, ideally a press-and-hold) so a child does not exit accidentally mid-trial.

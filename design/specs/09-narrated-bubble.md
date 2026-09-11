# Screen type: activity chrome and the narrated speech bubble

Supersedes the chrome described at the end of `03-activity-runner.md`. Applies to every screen type
that speaks — `intro`, `teaching`, `comparison`, `receptive`.

## Why this replaces the prompt plate
`03` specced prompt text on a static cream plate along the bottom. That was right for a fixed
string. It is wrong for narrated text, because the point of narration is that the child hears and
sees the same word at the same moment — a fully-rendered sentence gives the eye somewhere else to be
while the voice is still on word two.

The bubble replaces the plate on speaking screens. The plate stays for any screen with text but no
narration.

## Chrome layout

| Control | Position | Size |
|---|---|---|
| **Home** | top leading, inset 14 | 44pt circle, `#1E88E5`, white 3pt ring |
| **Bee + bubble** | top, bee at leading, bubble extending trailing | see below |
| **Progress readout** | bottom trailing, inset 14 | pill, auto width |
| **Next** | bottom **centre** | 52pt circle |

**Next moves to bottom-centre.** It was bottom-trailing, which is where the progress readout now
goes. Centre is better anyway: it is equidistant from both hands on a held phone, and it stops the
advance control from sitting in the same corner a child's palm rests on.

Keep the answer-panel row clear of all four — inset the row's trailing edge past the progress pill,
not just past the frame.

### Progress readout
Replaces the 36-dot HUD. At phone-landscape size the dots were 2pt wide and unreadable.

Pill, `rgba(255,255,255,.82)`, radius 999, padding 5/10. Content: `12 / 36` in Baloo 2 800 13pt navy,
preceded by a 4pt `#FFD100` dot. No screen-type label — that was debug affordance, not product.
Tapping it does nothing; it is a readout, not a button.

## The narrated bubble

### Behaviour
Words appear one at a time, in sync with narration, and the bubble grows to contain them.

1. Screen enters. Bubble is present but collapsed to its minimum (a 44 × 36 rounded rect with the
   tail) — it must exist before the first word so it does not pop into being.
2. Narration starts. Each word-boundary event reveals the next word.
3. The bubble animates to the bounding box of the revealed text after each word.
4. The **marked concept word** (`*word*`) appears in `#1F8A48` and lands with a scale pop
   (1 → 1.14 → 1, 260ms) — it is the stressed word in the audio and should be the stressed word on
   screen.
5. When narration ends, the bubble holds at full size. On `receptive` screens the choice panels
   become tappable only now.

### The reflow trap — this is the whole implementation
Appending words to a wrapping text container rewraps every line, so already-visible words jump
sideways as new ones arrive. It looks broken and it breaks the read.

Lay out the **full sentence** first, invisibly, at the bubble's maximum width. That fixes every
word's final position and the final line count. Then reveal words in place. A word never moves after
it appears; only the bubble's frame animates.

In SwiftUI: render the full attributed string in a hidden measuring pass to get per-word frames
(or lay the words out yourself in a wrapping `HStack`/`FlowLayout` and drive each word's opacity),
then animate the bubble's `frame` toward the union of revealed word frames. Do **not** rebuild the
text from a growing substring each tick.

### Sizing
- Max width 60% of the frame. Wider and the bubble crowds the illustration; narrower and long
  prompts run to four lines.
- Min height 36pt. Grow height in whole line increments — never a partial line.
- Growth animation: 220ms `easeOut`, interruptible. Words arrive faster than that at speaking pace,
  so the animation must be additive, not queued.
- Text: Baloo 2 700, 22pt at phone landscape. Ink navy `#16305B`.
- Bubble: white, 4pt `#FFD100` border, radius 20, tail at leading pointing to the bee.

### Narration source
Build against a protocol, not a concrete engine:

```swift
protocol NarrationTrack {
    func speak(_ text: String,
               onWord: @escaping (Range<String.Index>) -> Void,
               onFinish: @escaping () -> Void)
    func stop()
}
```

Implement `SystemNarrationTrack` with `AVSpeechSynthesizer` now —
`speechSynthesizer(_:willSpeakRangeOfSpeechString:utterance:)` gives exact character ranges as
spoken, offline and free. The chosen third-party TTS swaps in behind the same protocol later; verify
it returns word or character timestamps before committing to a vendor, because one that returns only
an audio blob cannot drive this.

The asterisk markers are stripped before the text reaches the synthesizer. Keep a map from the
stripped string's ranges back to the marked run so the green word can be identified by range.

### Narration off
Reveal the whole sentence at once, bubble at full size, no animation. Trials still log. The setting
must not change what the child can do — only the pacing.

### Reduce Motion
Respect `.accessibilityReduceMotion`: words still appear in time with the audio (that is
information, not decoration), but the bubble jumps to its final size immediately rather than
animating, and the concept word's pop becomes a colour change with no scale.

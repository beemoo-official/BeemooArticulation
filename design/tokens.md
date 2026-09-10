# Design tokens

## Colour
| Token | Hex | Use |
|---|---|---|
| navy | `#16305B` | Primary ink, headings, most body text |
| navy-62 | `rgba(22,48,91,.62)` | Secondary text |
| navy-50 | `rgba(22,48,91,.50)` | Tertiary text, captions |
| navy-09 | `rgba(22,48,91,.09)` | Hairline borders on cards |
| concept-green | `#1F8A48` | The target concept word inside prompt text. Never used for anything else |
| blue | `#1E88E5` | Links, interactive accent |
| blue-dark | `#0F6FC4` | Link hover/pressed |
| wc-blue | `#1E5FA8` | Words & Concepts umbrella heading |
| yellow | `#FFD100` | Primary CTA fill, NEW badge |
| yellow-hover | `#FFE066` | CTA pressed |
| orange | `#F2801F` | Daily-challenge progress line |
| cream | `#FFFDF6` | App surface |
| sand | `#EDE9E0` | Workspace backdrop (prototype chrome only — not in the app) |
| ice | `#F4F8FE` | Activity-list surface |
| device-ink | `#14161C` | Prototype device bezel only — not in the app |

### Umbrella tints
| Umbrella | Tint | Ink |
|---|---|---|
| Clear Speech | `#EEF7EA` | `#3E9B4F` |
| Words & Concepts | `#EAF2FD` | `#2A7BD4` |
| Putting It Together | `#F6EEFB` | `#8B57C4` |
| Social Communication | `#FDF0E6` | `#EE7B22` |

### Gradients
- Home hero: `linear-gradient(180deg, #FFF6DA 0%, #FFEFB8 46%, #FFE07A 100%)`
- Activity-list header: `linear-gradient(180deg, #DCEBFB, #F4F8FE)`
- Progress header: `linear-gradient(180deg, #FFF3CE, #FFFDF6)`
- Subscription banner: `linear-gradient(120deg, #16305B, #264A85)`

## Type
Two families. **Baloo 2** for anything titular or numeric; **Nunito** for body and UI labels.
Both need bundling — do not substitute system fonts.

| Role | Family / weight / size / leading |
|---|---|
| Screen title | Baloo 2 800 · 21–22pt · 1.1 |
| Card title | Baloo 2 800 · 13.5–14.5pt · 1.2 |
| Numeric readout | Baloo 2 800 · 15–16pt · 1 |
| Body | Nunito 600 · 12.5pt · 1.45 |
| Secondary body | Nunito 600 · 11–12pt · 1.35 |
| Caption | Nunito 700 · 10.5pt · 1.3 |
| Badge | Nunito 800 · 8.5pt · letter-spacing .4 |
| Button label | Nunito 800 · 12–12.5pt · 1 |

Sizes above are the **portrait shell** scale. Landscape activity screens scale up
substantially — prompt text is the largest type in the app. See `specs/03-activity-runner.md`.

## Geometry
- Radii: card `20`, inner card `18`, pill `999`, sheet top `26`
- Card border: `1.5px solid rgba(22,48,91,.09)`
- Card shadow: `0 4px 14px rgba(22,48,91,.05)`
- Raised shadow: `0 6px 18px rgba(0,0,0,.12)`
- Floating control shadow: `0 3px 10px rgba(0,0,0,.10)`
- Grid gap: `11`; section padding: `16` horizontal
- Minimum hit target: **44 × 44** everywhere, no exceptions

## Motion
- `bmFloat` — BeeMoo idle: 5.5s ease-in-out infinite, translateY 0 → −14 with rotate −2° → 2°
- `bmBob` — badge/star idle: 3.4s ease-in-out infinite, translateY 0 → −8
- Screen transitions: 260ms ease-out
- Correct-answer feedback: scale 1 → 1.06 → 1, 320ms spring
Respect `.accessibilityReduceMotion` — drop the idle loops, keep the feedback.

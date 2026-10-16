# Calm Ledger — design tokens

The redesign direction picked on 2026-10-16. The reference screens are in this folder:

| Screen | File |
|---|---|
| Expenses list | `01-expenses.png` |
| Add expense sheet | `02-add-expense.png` |
| AI Consultant | `03-consultant.png` |

The code version of these tokens is `lib/core/theme/tokens.dart`, and `lib/core/theme/app_theme.dart` maps them onto Material 3. When a value changes, update both this file and `tokens.dart`.

## Principles
- A quiet warm-grey canvas with **white cards that float above it**.
- **One accent (blue) is reserved for actions**: add, save, send, the active tab and your own chat messages.
- Category colors are the only other hue, and every category gets an icon on a tinted tile.
- Every amount uses **Geist Mono** so the digits line up in columns.
- Three levels of elevation, with soft layered shadows.

## Color
| Token | Hex | Use |
|---|---|---|
| `primary` | `#1F4DD8` | Primary actions, active tab, user chat bubble |
| `primaryDark` | `#163BA8` | Pressed / hover |
| `primaryLight` | `#E8EEFC` | Active-tab pill, selected date chip |
| `primarySubtle` | `#EEF2FD` | Badges |
| `background` | `#F3F3F0` | Screen canvas |
| `surface` | `#FFFFFF` | Cards, sheets, nav bar |
| `surfaceSubtle` | `#F6F6F3` | Keypad keys, amount field |
| `surfaceSunken` | `#F8F8F6` | Tables inside cards |
| `scrim` | `#6E6E6A` | Behind modal sheets |
| `ink` / `textPrimary` | `#111111` | Text, selected category chip |
| `textSecondary` | `#5F5F5B` | Labels, section headers |
| `textMuted` | `#6B6B66` | Timestamps, inactive tabs |
| `divider` | `#F0F0ED` | Rows inside a card |
| `borderLight` | `#ECECE8` | Unselected chips |
| `borderStrong` | `#E2E2DE` | Prompt chips |
| `borderDashed` | `#C4C4BF` | "+ New" affordances |
| `expense` | `#C8372D` | Destructive actions, errors |
| `income` / `incomeContainer` / `tipText` | `#157F55` / `#EEF7F2` / `#14553A` | Consultant tips |

### Category palette
| Category | Swatch | Tile background | Icon color |
|---|---|---|---|
| Food | `#E0712B` | `#FCEBDD` | `#C2571B` |
| Transport | `#2F7FD1` | `#E1EEFA` | `#1F6BBF` |
| Utilities | `#7A5AD6` | `#ECE6FA` | `#6343C4` |
| Coffee | `#8A6B3F` | `#F1EAE0` | `#7A5A30` |
| Health | `#1E9E6A` | `#DDF3E9` | `#157F55` |
| Other (bar) | `#D3D3CE` | — | — |

In code, `CategoryPalette.tint(c)` and `CategoryPalette.onTint(c)` work out the tile background and icon color from any category color, so custom categories follow the same rule.

## Typography
Fonts are bundled from `assets/fonts` (SIL OFL), so the app never needs the network for them.

| Style | Font | Size / weight |
|---|---|---|
| Hero amount | Geist Mono | 46 / 500, tracking −2 |
| Entry amount (add sheet) | Geist Mono | 56 / 500, tracking −2.5 |
| Row amount | Geist Mono | 16 / 500 |
| Section total | Geist Mono | 13 / 500 |
| Screen / sheet title | Geist | 18 / 600 |
| Row title | Geist | 16 / 600 |
| Body (chat) | Geist | 15 / 400, line-height 1.55 |
| Label | Geist | 14 / 500 |
| Section header | Geist | 13 / 600 |
| Caption | Geist | 13 / 400 |
| Nav label | Geist | 12 / 500 (600 when active) |

## Spacing
`2 · 4 · 8 · 12 · 16 · 20 · 24`. The page gutter is 16. List rows are at least 64 tall, and touch targets are at least 44.

## Radius
| Token | px | Use |
|---|---|---|
| `xs` | 8 | Small icon tiles |
| `sm` | 12 | Row icon tiles, tip boxes |
| `md` | 14 | Chips, keypad keys |
| `lg` | 20 | List cards, amount field |
| `xl` | 24 | Hero card, nav-bar top corners |
| `sheet` | 28 | Bottom sheets |
| `pill` | 999 | Pills, round buttons |

## Elevation
| Level | Shadow | Use |
|---|---|---|
| 1 `raised` | `0 1 2 rgba(17,17,17,.06)`, `0 4 12 rgba(17,17,17,.05)` | Chips, month pill |
| 2 `card` | `0 1 2 rgba(17,17,17,.05)`, `0 6 18 rgba(17,17,17,.05)` | List cards, chat bubbles |
| 3 `heroCard` | `0 1 2 rgba(17,17,17,.05)`, `0 10 30 rgba(17,17,17,.08)` | Month summary card, composer |
| Accent `fab` | `0 2 4 rgba(31,77,216,.25)`, `0 12 28 rgba(31,77,216,.35)` | Add, Save, Send |
| `navBar` | `0 −1 0 rgba(17,17,17,.04)`, `0 −8 24 rgba(17,17,17,.06)` | Bottom nav (casts upward) |
| `sheet` | `0 −12 40 rgba(0,0,0,.25)` | Modal sheets |

## Components
- **Bottom nav**: four tabs (Expenses, Categories, Consultant, Settings). The centre slot holds a raised 60px blue **Add** button with a 5px white ring, sitting 26px above the bar. The active tab shows a 56×30 `primaryLight` pill behind its icon.
- **Expense row**: a 40px tinted category tile, the category name with the time underneath, and the amount in mono on the right. Tap a row to edit it; swipe left to delete.
- **Add sheet**: a sunken amount field, a 3-column grid of category chips (the selected one is solid ink), Today / Yesterday / Pick-date chips, an on-screen keypad and a full-width Save button that shows the live amount.
- **Consultant**: an elevated header with a blue sparkle tile, the user's messages in blue bubbles, the assistant's answers in white elevated cards, grey prompt chips and an elevated pill composer.

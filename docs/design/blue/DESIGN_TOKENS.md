# Blue — design tokens

This is the current design, adopted on 2026-10-16. It replaces Calm Ledger, whose files are kept in `docs/design/calm-ledger/` for history. It's built from the user's reference screens with **solid colors only, no gradients**.

The reference screens in this folder are rendered from the app itself:

| File | What it shows |
|---|---|
| `1_home.png` … `5_profile.png` | Each screen in light mode |
| `screens-light.png`, `screens-dark.png` | All five screens side by side |

The code version of these tokens is `lib/core/theme/tokens.dart`, and `lib/core/theme/app_theme.dart` maps them onto Material 3. Shared widgets (header, square buttons, menu rows, primary button) are in `lib/core/theme/widgets.dart`.

## Color
| Token | Light | Dark | Use |
|---|---|---|---|
| `primary` | `#042895` | `#3358D4` | Hero card, add button, selected chip/day, primary buttons, your chat bubbles |
| `primaryLight` | `#E6EBF8` | `#1A2A5C` | Tinted icon backgrounds, first prompt chip |
| `onPrimaryMuted` | `#D6DEF7` | — | Secondary text on the blue card |
| `background` / `surface` | `#FFFFFF` | `#0B1020` / `#141A2E` | Screens |
| `surfaceSubtle` | `#F3F5FA` | `#1E2640` | Square header buttons, chips, calendar strip, assistant bubbles |
| `ink` | `#141A2E` | `#F4F6FB` | Text |
| `textSecondary` | `#667085` | `#A3ABC2` | Captions, timestamps |
| `navInactive` | `#A9B0C2` | `#A3ABC2` | Inactive nav icons |
| `divider` | `#EEF1F6` | `#273049` | Lines between menu rows |
| `expense` | `#D9411F` | same | Expense amounts (`−450`), delete |
| `danger` | `#E5484D` | same | Sign-out tile |

### Category colors
Category colors are used solid with a white icon in menus, and as a soft tint with a colored icon in the transaction list.

| Category | Color |
|---|---|
| Food | `#E97A1F` |
| Transport | `#3B82F6` |
| Utilities | `#0F766E` |
| Coffee | `#92603A` |
| Health | `#E5484D` |
| Shopping | `#DB2777` |
| Entertainment | `#4F46E5` |

## Typography
The app uses **Plus Jakarta Sans**, bundled in `assets/fonts` (SIL OFL). Amounts use tabular figures so the digits line up.

| Style | Size / weight |
|---|---|
| Hero amount | 34 / 800 |
| Screen title | 19 / 600 |
| Section title ("Transactions") | 18 / 700 |
| Field label | 16 / 600 |
| Row title | 16 / 600 (menus 500) |
| Row amount | 16 / 700, red |
| Body (chat) | 15 / 400 |
| Caption | 12–13 / 400 |

## Shape and spacing
- Page gutter 24.
- Square header buttons 44×44, radius 12.
- Chips and day cells: radius 12; the selected day is a 40px circle.
- List tiles 46px with radius 14; solid menu squares 36px with radius 10.
- Fields and the primary button: radius 14. The primary button is 58px tall.
- Hero card radius 22; sheets radius 28.

## Elevation
| Name | Shadow | Use |
|---|---|---|
| `heroCard` | `0 14 30` `#042895` at 28% | Spent card |
| `fab` | `0 10 24` `#042895` at 40% | Add button, send button |
| `button` | `0 12 26` `#042895` at 32% | Primary buttons |
| `navBar` | `0 −6 24` ink at 6% | Bottom nav |

In dark mode, shadows are dropped and thin borders are used instead.

## Components
- **Bottom nav**: icon-only. Home, Consultant, a raised 60px blue **+** with a white ring, Categories, Profile. The active tab is blue with a 5px dot under it.
- **Home**: header (grid button → Categories, sun/moon toggle), the blue "Spent in ‹month›" card with Today / This week totals, and the transaction list. Tap a transaction to edit it; swipe left to delete.
- **Add / edit expense**: a full-screen page with a week strip (← → change week; tap the month for a full date picker; future days disabled), the amount field with an MRU prefix, category chips (the selected one is filled blue), and an "Add Expense" button. When editing there's a delete button in the header.
- **Categories**: solid squares, this month's expense count, a "⋯" menu with Edit/Delete, thin lines between rows and an "Add category" row.
- **Consultant**: blue user bubbles, grey assistant bubbles, prompt chips, a bordered input and a square send button.
- **Profile**: an avatar with the username and sync status, then account rows (Create account / Sign in, or Switch account / Sign out), Dark mode, Currency and Sync now.

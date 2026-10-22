---
name: expense-advisor
description: A pocket ledger on white, with one deep ink-blue for everything you do.
colors:
  deep-ink-blue: "#042895"
  deep-ink-blue-pressed: "#031E70"
  deep-ink-blue-tint: "#E6EBF8"
  on-blue-muted: "#D6DEF7"
  deep-ink-blue-dark-mode: "#3358D4"
  blue-text-dark-mode: "#9DB2F7"
  blue-tint-dark-mode: "#1A2A5C"
  paper-white: "#FFFFFF"
  mist: "#F6F7F9"
  sunken-mist: "#F3F5FA"
  ink: "#141A2E"
  slate: "#667085"
  chevron-grey: "#98A2B3"
  hairline: "#EEF1F6"
  border: "#E3E7EF"
  dashed-border: "#C9CFDB"
  outflow-red: "#D9411F"
  outflow-red-tint: "#FDECE8"
  danger-red: "#E5484D"
  inflow-green: "#16A34A"
  inflow-green-tint: "#EAF7EF"
  tip-green: "#14532D"
  night: "#0B1020"
  night-surface: "#141A2E"
  night-raised: "#1E2640"
  night-text: "#F4F6FB"
  night-slate: "#A3ABC2"
  night-border: "#273049"
  category-food: "#E97A1F"
  category-transport: "#3B82F6"
  category-utilities: "#0F766E"
  category-coffee: "#92603A"
  category-health: "#E5484D"
  category-shopping: "#DB2777"
  category-entertainment: "#4F46E5"
  category-other: "#D0D5DD"
typography:
  display:
    fontFamily: "Plus Jakarta Sans"
    fontSize: "34px"
    fontWeight: 800
    lineHeight: 1.1
    letterSpacing: "-0.5px"
    fontFeature: "tnum"
  headline:
    fontFamily: "Plus Jakarta Sans"
    fontSize: "24px"
    fontWeight: 700
    fontFeature: "tnum"
  title:
    fontFamily: "Plus Jakarta Sans"
    fontSize: "19px"
    fontWeight: 600
  title-section:
    fontFamily: "Plus Jakarta Sans"
    fontSize: "18px"
    fontWeight: 700
  body-strong:
    fontFamily: "Plus Jakarta Sans"
    fontSize: "16px"
    fontWeight: 600
  amount:
    fontFamily: "Plus Jakarta Sans"
    fontSize: "16px"
    fontWeight: 700
    fontFeature: "tnum"
  body:
    fontFamily: "Plus Jakarta Sans"
    fontSize: "15px"
    fontWeight: 400
    lineHeight: 1.5
  label:
    fontFamily: "Plus Jakarta Sans"
    fontSize: "14px"
    fontWeight: 500
  caption:
    fontFamily: "Plus Jakarta Sans"
    fontSize: "13px"
    fontWeight: 400
  nav-label:
    fontFamily: "Plus Jakarta Sans"
    fontSize: "12px"
    fontWeight: 500
rounded:
  xs: "8px"
  sm: "10px"
  md: "12px"
  lg: "14px"
  dialog: "20px"
  xl: "22px"
  sheet: "28px"
  pill: "999px"
spacing:
  xxs: "2px"
  xs: "4px"
  sm: "8px"
  md: "12px"
  lg: "16px"
  xl: "20px"
  xxl: "24px"
  gutter: "24px"
components:
  button-primary:
    backgroundColor: "{colors.deep-ink-blue}"
    textColor: "{colors.paper-white}"
    typography: "{typography.body-strong}"
    rounded: "{rounded.lg}"
    padding: "16px 24px"
    height: "58px"
  button-primary-pressed:
    backgroundColor: "{colors.deep-ink-blue-pressed}"
  button-outlined:
    backgroundColor: "{colors.paper-white}"
    textColor: "{colors.ink}"
    typography: "{typography.body-strong}"
    rounded: "{rounded.lg}"
    height: "50px"
  button-text:
    textColor: "{colors.deep-ink-blue}"
    typography: "{typography.body-strong}"
  input:
    backgroundColor: "{colors.paper-white}"
    textColor: "{colors.ink}"
    rounded: "{rounded.lg}"
    padding: "16px"
  chip:
    backgroundColor: "{colors.paper-white}"
    textColor: "{colors.ink}"
    typography: "{typography.label}"
    rounded: "{rounded.md}"
  chip-selected:
    backgroundColor: "{colors.deep-ink-blue}"
    textColor: "{colors.paper-white}"
    rounded: "{rounded.md}"
  hero-card:
    backgroundColor: "{colors.deep-ink-blue}"
    textColor: "{colors.paper-white}"
    typography: "{typography.display}"
    rounded: "{rounded.xl}"
  square-icon-button:
    backgroundColor: "{colors.paper-white}"
    textColor: "{colors.ink}"
    rounded: "{rounded.md}"
    size: "44px"
  category-tile:
    backgroundColor: "{colors.category-food}"
    textColor: "{colors.paper-white}"
    rounded: "{rounded.sm}"
    size: "36px"
  menu-row:
    textColor: "{colors.ink}"
    typography: "{typography.label}"
    padding: "10px 8px"
    height: "62px"
  nav-bar:
    backgroundColor: "{colors.paper-white}"
    textColor: "{colors.slate}"
    typography: "{typography.nav-label}"
    height: "72px"
  nav-tab-active:
    backgroundColor: "{colors.deep-ink-blue-tint}"
    textColor: "{colors.deep-ink-blue}"
  sheet:
    backgroundColor: "{colors.paper-white}"
    rounded: "{rounded.sheet}"
---

> **Superseded (2026-10-22).** This records the earlier "deep ink blue, solid colours" direction. The app now follows the Monex Figma UI kit: brand `#0E33F3` running to sky `#2BB0ED` as a gradient, a `#F5F6F7` canvas with floating white cards, Inter at 90%, centered titles and amounts in ink. `lib/core/theme/tokens.dart` is the source of truth until this file is regenerated (`/impeccable document`).


# Design System: expense-advisor

## Overview

**Creative North Star: "The Pocket Ledger"**

The app is a clean white page of your own records. Entries sit on paper-white in ink, and one deep ink-blue marks what you can act on: the add button, the save button, the selected day or Category, your own chat messages, and the card that holds this month's total. Everything else steps back, so the eye goes to the amount and the next action.

The mood is calm and trustworthy. Money is a stressful subject, so nothing on screen raises its voice. Red appears only on Expense amounts and destructive actions, never as a warning, and green appears only on Income. Density is relaxed: a 24px page gutter, rows at least 62px tall and 44px touch targets. A one-handed log after paying at a till should never need precision tapping.

Depth is flat by default. Surfaces separate by tone and a 1px hairline, never by a drop shadow: white panels carry a light outline, header buttons are soft mist squares, and dark mode lifts surfaces with the night tones. The one shadow left on a screen is a soft glow under its single primary action.

The look is shared across iOS and Android, but behavior follows each OS. Navigation, back gestures, sheets, pickers, dialogs, haptics and scroll physics follow the platform, while color, type, shape and the components below stay the same.

**Key Characteristics:**
- White page, ink text, one deep ink-blue for actions and the month's total.
- Amounts in tabular figures; Outflow Red for Expenses, Inflow Green for Income.
- Solid-colored Category squares with white icons are the only multicolor element.
- Generous rounding (12–14px on controls, 22px on the hero card, 28px on sheets).
- Flat by default: tone and hairlines separate surfaces; a soft glow marks only the primary action.

## Colors

One deep ink-blue on paper-white, neutral cool greys, two money hues and a fixed Category palette.

### Primary
- **Deep Ink Blue** (`deep-ink-blue`): the only accent. Used on the month-total hero card, the add button, filled primary buttons, selected chips and days, the active nav tab, text buttons, focused field borders and the user's chat bubbles. It is pressed to `deep-ink-blue-pressed`, tinted to `deep-ink-blue-tint` for selected backgrounds and icon wells, and softened to `on-blue-muted` for secondary text on the blue card.
- **Deep Ink Blue, dark mode** (`deep-ink-blue-dark-mode`): replaces the accent on dark backgrounds, where the light-mode blue would disappear. Text links and the active nav icon use `blue-text-dark-mode`; tinted wells use `blue-tint-dark-mode`.

### Neutral
- **Paper White** (`paper-white`): the page, cards, sheets and fields. Background and surface are the same white; panels separate with a 1px Border outline, not grey fills or shadows.
- **Mist** (`mist`) / **Sunken Mist** (`sunken-mist`): Sunken Mist fills header icon buttons and the empty-state icon tile; Mist is the off-switch track.
- **Ink** (`ink`): all primary text.
- **Slate** (`slate`): captions, timestamps, section labels, hints, subtitles.
- **Chevron Grey** (`chevron-grey`): row chevrons.
- **Hairline** (`hairline`): dividers between menu rows. **Border** (`border`): 1.5px outlines on fields and outlined buttons. **Dashed Border** (`dashed-border`): "add" placeholders.
- **Night** (`night`, `night-surface`, `night-raised`, `night-text`, `night-slate`, `night-border`): the dark theme's page, surfaces, raised controls, text, secondary text and borders.

### Money and status
- **Outflow Red** (`outflow-red`): Expense amounts (shown as "−450") and destructive actions such as delete. `outflow-red-tint` is its soft background.
- **Inflow Green** (`inflow-green`): Income amounts. `inflow-green-tint` is its soft background, and `tip-green` is text on that tint.
- **Danger Red** (`danger-red`): the sign-out tile only.

### Category palette
Category hues (`category-food` through `category-other`) appear in two forms. In menus they are **solid squares with a white icon**. In entry lists they are a **12% tint of the hue on white**, with the icon in the hue darkened by 8% lightness. User-created Categories pick from this set.

### Named Rules
**The One Voice Rule.** Deep Ink Blue is the only accent and it means "you can act here" (or "this month's total"). Never use it for decoration, illustration or a second information channel.

**The Money Hues Rule.** Red belongs to Expenses and green to Income. Neither is used to warn, judge or grade spending. There are no budgets to be over. Net is neither, so it is set in Ink and carries only its sign (+ or −), with no arrow.

## Typography

**Font:** Plus Jakarta Sans (bundled, SIL OFL), weights 400–800. It is the only family in use.

**Character:** a warm, open geometric sans. Bold weights carry the amounts, and medium weights carry everything else. Every amount uses tabular figures so columns of digits line up.

### Hierarchy
- **Display** (800, 34px, 1.1, −0.5px tracking, tabular): the month total on the hero card. One per screen.
- **Headline** (700, 24px, tabular): the amount being typed into the add/edit form.
- **Title** (600, 19px): centered screen titles in the header.
- **Section title** (700, 18px): list section headings.
- **Body strong** (600, 16px): row titles, field labels and button labels. Menu titles use 500.
- **Amount** (700, 16px, tabular): row amounts, colored Outflow Red or Inflow Green.
- **Body** (400, 15px, 1.5): Consultant chat text and explanations.
- **Label** (500, 14px, Slate): secondary labels and chip text.
- **Caption** (400–600, 13px, Slate): timestamps, counts and per-section totals (600 with tabular figures).
- **Nav label** (500, 12px; 700 when selected): the label under every tab on Android. iOS uses 10px, as the system tab bar does.

### Named Rules
**The Tabular Money Rule.** Any number that is money is set in tabular figures and formatted through `Money.format`. A proportional digit in an amount is a bug.

## Layout

Single-column phone layout with a **24px page gutter** (`spacing.gutter`). The spacing scale is 2, 4, 8, 12, 16, 20 and 24px; vertical rhythm between blocks is mostly 16–24px.

- **Header:** a 44px row 20px below the safe area, with a centered Title between two 44px slots that hold square icon buttons or nothing.
- **Bottom navigation:** five labeled tabs (Home, Income, Expenses, Consultant, Profile), 72px tall on Android and 50pt on iOS, plus the bottom inset. Content scrolls behind it (`extendBody`), so the last item needs bottom padding.
- **Rows:** at least 62px tall, with the leading tile, a 14px gap, title and subtitle, then trailing content.
- **Sheets:** they rise from the bottom with a 28px top radius over a 45% Ink scrim.
- **Wide windows:** every page is a centered column at most 640px wide (`AppLayout.readableWidth`, `ReadablePage`), so rows and cards never stretch across a tablet or desktop. From 840px (Material's expanded class) Android and desktop swap the bottom bar for a labeled navigation rail headed by an icon-only add button. iPad keeps its tab bar at any width, and its add button lines up with the column's right edge.
- **Large text:** everything follows the system text size except two fixed grids: the five tab labels stay at their base size (as iOS tab bar labels do; long-press shows the label on Android) and the week strip's day digits stop at 1.4×. The hero card's Today and This week stack above 1.2×, and screen headers grow taller rather than clip.

## Elevation & Depth

The system is flat. In light mode, panels are white with a 1px Border outline and icon buttons are Sunken Mist squares; in dark mode surfaces step up through tone (`night` → `night-surface` → `night-raised`) with 1px `night-border` lines. Shadows exist only where something genuinely floats: the primary action and sheets.

### Shadow Vocabulary (current code; see the sidecar for exact values)
- **Action glow** (`fab`, `button`): a soft blue glow (0 6px 16px, 18%) under the add button, the send button and the full-width primary button. Light mode only.
- **Sheet** (`sheet`): bottom sheets.

### Named Rules
**The One Glow Rule.** A glow marks the screen's single primary action. New work does not add glows to secondary controls or cards, and two glowing elements may not compete on one screen.

**The Tone Before Shadow Rule.** Surfaces separate through tone, hairlines and spacing. No component gets a drop shadow to stand off the page; use `panelDecoration` / `panelShape` (white with a 1px outline) or the mist fill.

## Shapes

The shape language is soft and consistent. Radius grows with the size of the element:

- **8px** (`xs`): small tiles inside chat answers and small Category squares (under 32px).
- **10px** (`sm`): solid Category squares in menus (36px).
- **12px** (`md`): square icon buttons, chips, day cells, snackbars and ink ripples.
- **14px** (`lg`): fields, list tiles and every button.
- **20px** (`dialog`): dialogs.
- **22px** (`xl`): the hero card.
- **28px** (`sheet`): the top corners of bottom sheets.
- **Circles:** the selected day (40px) and the profile avatar.

Borders are 1.5px on interactive outlines (fields, outlined buttons) and 1px on dividers. There are no gradients anywhere.

## Components

**Soft and sure:** generous corners, tall touch targets, and one filled blue action per screen.

### Buttons
- **Shape:** gently rounded (14px).
- **Primary:** a full-width filled Deep Ink Blue button, 58px tall, with a 17px label in weight 600 and the action glow beneath. While busy, it shows a white 22px spinner in place of the label and drops the glow.
- **Pressed:** `deep-ink-blue-pressed`, with the Material ripple.
- **Outlined:** white with a 1.5px Border and Ink text, 50px tall. Used for the secondary choice next to a primary action.
- **Text:** Deep Ink Blue (`blue-text-dark-mode` in dark), weight 600, for inline actions.
- **Add button:** the main "log it" action. An extended floating button ("Add Expense" on Home and the Expenses tab, "Add Income" on the Income tab): Deep Ink Blue, 56px tall, 14px radius, a + icon and a 16px weight-600 label, with the action glow in light mode. It floats bottom right above the tab bar, in thumb reach, and is the only add action on its screen: headers and empty states carry no add button of their own. The form it opens covers the tab bar.

### Chips
- **Unselected:** white with a 1px Border outline (a `night-raised` fill in dark mode), Ink label, 12px radius.
- **Selected:** filled Deep Ink Blue with a white label. Category chips show the Category icon before the name.

### Cards / Containers
- **Hero card:** flat Deep Ink Blue with a 22px radius; the color is its emphasis, no glow. It shows "Spent in ‹month›" in `on-blue-muted`, the Display total, then Today and This week sub-totals with small icon wells.
- **Panels** (total cards, Net, week strip, prompt cards): white with a 1px Border outline and a 14–22px radius.
- **Material cards:** flat white, no elevation, 14px radius.

### Switches
- **On:** a white thumb on a Deep Ink Blue track. **Off:** a Slate thumb and Slate outline on the mist track, so an off switch still reads as a switch on white.

### Inputs / Fields
- **Style:** a filled white field with a 1.5px Border outline, 14px radius and 16px padding. The hint is in Slate at 15px. The amount field leads with the Currency code in Deep Ink Blue.
- **Focus:** the outline turns Deep Ink Blue, still 1.5px.
- **Error:** the outline turns Outflow Red.

### Navigation
- **Bottom bar:** five labeled tabs, shaped by each OS. The bar is flat surface with a hairline on top, never a shadow. Inactive tabs show an outlined icon and label in Slate (4.5:1 or better); the active tab switches to the filled icon.
  - **Android:** the Material 3 navigation bar. The active icon sits in Deep Ink Blue on a `deep-ink-blue-tint` pill, with the label in Ink at weight 700.
  - **iOS:** the system tab bar's metrics: a 25pt icon over a 10pt label, with the active tab's icon and label in Deep Ink Blue and no pill.
- **Header:** a centered Title between 44px square icon buttons: Sunken Mist fill, 12px radius, no shadow, a 21px icon. Back is always this square, with the OS's own glyph (`Icons.adaptive.arrow_back_rounded`: an arrow on Android, a chevron on iOS). A button that can't act yet (Clear chat on an empty chat) dims its icon and ignores taps.
- **Dark mode** has one control, the switch in Profile. Headers carry no theme toggle.

### Menu rows
A Category square (a solid hue, 36px, 10px radius, white icon at 52%), a 14px gap, a title (16px, weight 500) with an optional 12px Slate subtitle, and trailing content (a chevron, switch or value). A hairline sits underneath. Destructive rows set the title in Outflow Red.

### Entry rows
An entry list tile (46px, 14px radius) holds the Category tint with its colored icon, then the title and time, then the amount right-aligned in the Amount style (Outflow Red or Inflow Green). Tap a row to edit it; swipe to delete. New entries animate in over 220ms with an ease-out-cubic curve.

### Consultant chat
User messages are Deep Ink Blue bubbles with white text, and assistant messages are neutral bubbles in Body type. Prompt cards are white panels with a tinted blue icon well and a chevron. Below them sit a bordered input and a square blue send button with the action glow.

## Do's and Don'ts

### Do:
- **Do** reserve Deep Ink Blue for the one primary action on a screen, selected states, the active tab, the user's own messages and the month-total card.
- **Do** set every amount in Plus Jakarta Sans with tabular figures, through `Money.format`.
- **Do** color Expense amounts Outflow Red and Income amounts Inflow Green, and nothing else in those hues.
- **Do** label every tab, and keep touch targets at least 44px and rows at least 62px, with the 24px page gutter.
- **Do** separate new surfaces with tone and hairlines first; in dark mode, always use borders instead of shadows.
- **Do** show a list that fails to load with the shared load-error state ("Couldn't load your Expenses", Try again), never the raw exception.
- **Do** follow each OS for behavior (navigation, back gestures, sheets, date and option pickers, dialogs, haptics, scroll physics) while keeping the visual tokens identical.
- **Do** change `lib/core/theme/tokens.dart` and this file together when a token changes.

### Don't:
- **Don't** add a second accent color, or use Deep Ink Blue for decoration.
- **Don't** use red or green to warn, judge or show progress toward a limit. The product has no budgets.
- **Don't** add gradients. The system is solid colors only.
- **Don't** add glows to secondary controls, or put two glowing elements on one screen.
- **Don't** give a card, chip or button a drop shadow to lift it off the page. Outline it, or fill it with mist.
- **Don't** use grey filled panels where a white surface with a hairline will do.
- **Don't** introduce another typeface. Geist and Geist Mono are bundled in `assets/fonts/` but are not part of the system.

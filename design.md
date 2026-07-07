# Sehatiku — Design System (Color Palette & UI)

Reference doc for aligning the web design with the existing mobile app. Source: `lib/core/theme/app_colors.dart` and `lib/shared/widgets/*.dart`.

## 1. Color Palette

### 1.1 Surface / Text (flips light ↔ dark)

| Token | Light | Dark |
|---|---|---|
| `background` | `#F4F9FF` | `#0B0F1A` |
| `surface` | `#FFFFFF` | `#131B2E` |
| `elevated` | `#EEF3FA` | `#1C2640` |
| `text` | `#1A2540` | `#E8EFF8` |
| `muted` | `#6B7A94` | `#8899B4` |
| `line` (border/divider) | `#DDE7F5` | `#243354` |

### 1.2 Accent colors (static — same in both modes)

| Name | Hex | Typical use |
|---|---|---|
| `primary` | `#4F8EFF` | Brand blue — primary actions, active states, links |
| `primary2` | `#60A5FA` | Gradient partner for `primary` |
| `green` | `#10D9A0` | Success / good health status / "aman" |
| `lime` | `#84CC16` | Positive checkmarks / recommendations |
| `violet` | `#A78BFA` | AI features, secondary accent |
| `cyan` | `#22D3EE` | Data viz accent |
| `amber` | `#FBBF24` | Warning / stress-neutral |
| `orange` | `#FB923C` | Caution (e.g. smoking/alcohol flags) |
| `red` | `#F87171` | Danger / missed medication / high risk |
| `pink` | `#F472B6` | Data viz accent |
| `whatsapp` | `#25D366` | WhatsApp contact link only |

Tint helper: `color.withValues(alpha: 0.12–0.18)` is used to create soft icon-badge backgrounds from any accent color (e.g. `primary` at 12% for an icon chip background).

### 1.3 Usage rules

- Surface/text tokens **must** flip with theme; accents **never** flip.
- Gradients: `primary → primary2` (buttons, active pills), `green → primary` (hero/risk card), `primary → violet` (AI/FAB elements).
- Status colors follow health semantics: green = good/normal, amber = borderline, red = high risk/missed, orange = lifestyle caution.

## 2. Typography

- No custom font family — system default (sans-serif).
- Weight-driven hierarchy, not size-driven: `w600` (labels/muted), `w700` (body emphasis), `w800` (headings/values — used almost everywhere important).
- Common sizes: page title `24px/w800`, section title `16px/w800`, card title `14.5px/w800`, big metric value `20–26px/w800`, label/caption `11–12.5px/w600–700`, body/description `13px` with `height: 1.4–1.5` line spacing.

## 3. Shape & Spacing

| Element | Corner radius |
|---|---|
| Small chip / dot badge | 10–14px |
| Buttons, inputs, icon tiles | 14–18px |
| Cards (`AppCard`) | 22px |
| Large panels / hero cards / detail sheets | 24px |
| Bottom nav bar (notched) | 26px |

- Page padding: `EdgeInsets.fromLTRB(20, 16, 20, 108)` (extra bottom to clear the floating nav).
- Card padding: 18px default, 12–20px depending on density.
- Consistent 8–14px gaps between stacked elements.

## 4. Elevation & Shadows

- Cards: soft ambient shadow `Color(0x18000000)`, blur 24, offset (0,12), spread -4 — very subtle, relies on `border: Border.all(color: line)` for definition more than shadow.
- Colored/gradient panels (risk card, big actions): shadow tinted with the panel's own gradient color at ~30–50% alpha, larger blur (20–36px), for a "glow" effect.
- Bottom nav: glassmorphic — `BackdropFilter` blur (14px) + translucent gradient fill (`surface` 90% → `background` 80%) + hairline gradient border, plus a wide soft `primary`-tinted glow shadow. This is the signature "floating glass" element of the app.

## 5. Core Components

- **AppCard** — the base surface: `surface` bg, `line` border, 22px radius, soft shadow. Nearly every list item/tile wraps this.
- **PrimaryButton** — full-width, 58px tall, 20px radius, `primary → #2A8FE0` gradient with glow shadow when enabled; flat muted-gray gradient when disabled. Icon + w800 16px label, white text.
- **MetricCard / SummaryCard / StatBox** — icon-badge (tinted accent bg, 12-15px radius) + label (muted, small) + big value (w800) + unit/status line. Used across dashboard for health metrics.
- **RiskCard** — hero gradient (`green → primary`) card with circular progress ring showing a score (0-100), status pill, and message. Highest-visual-weight component on the dashboard.
- **SegmentedPills / SegmentedMini / PillTab** — pill-style tab switchers; selected segment gets an animated sliding `primary → primary2` gradient fill, unselected is `elevated`/transparent with `muted` text.
- **SelectChip / TwoChoice / YesNoCard** — form choice chips; selected state = accent-tinted background + accent border + accent text (pattern reused for yes/no health questions, red=yes/risk, green=no/safe).
- **NumberField / LabeledNumberField** — large (22-26px, w800) numeric inputs with `elevated` fill, 16px radius, `line` border, focus border switches to the field's accent color.
- **FloatingNav** — custom-painted notched glass bottom bar, 5 destinations with a raised center "AI" FAB (breathing glow, rotating sweep-gradient aura, `primary → violet` gradient body) nested in the notch.
- **Tiles** (`InsightTile`, `DoctorTile`, `TimelineTile`, `ArticleTile`, `ProfileRow`, `NotifCard`, `HistoryNode`) — consistent row layout: leading icon badge (tinted accent bg) → title/description column → trailing chevron/value. `NotifCard` and `HistoryNode` add left accent stripe / timeline dot for state.
- **PageHeading / SectionTitle / DetailScaffold** — page-level heading (24px w800 title + muted subtitle) and back-button + title header for detail/modal screens.

## 6. Theming Mechanics

- Material 3, seeded from `primary` (`#4F8EFF`).
- Theme (light/dark) is a user preference persisted locally; status bar brightness follows it.
- All components read colors via `AppColors.of(context)` rather than `Theme.of(context).colorScheme`, so the web port should mirror the token table in §1.1 rather than relying on Material defaults.

## 7. Notes for Web Alignment

- Recreate the **surface/text token pairs** (§1.1) as CSS variables that swap on a `dark` class/media query; keep the **11 accent colors** as fixed values in both modes.
- Reuse the **gradient pairs** (`primary→primary2`, `green→primary`, `primary→violet`) for CTAs, hero/status cards, and any AI-branded UI.
- Corner radius scale: 12–14px (small controls) / 18–22px (cards) / 24–26px (hero panels, nav) — keep this 3-tier scale on web instead of introducing new values.
- Status semantics (green=good, amber=caution, red=risk/danger, orange=lifestyle flag) should carry over 1:1 for any health-data visualization on the web dashboard.

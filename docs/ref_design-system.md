# PaintHoarder design system

The UI follows the "C · Bold" direction from the redesign canvas (https://claude.ai/code/artifact/54575dd0-982b-4ab9-8830-4d7a29387328): bone-on-ink, condensed caps for titles and actions, orange only for the next action.

## Where it lives

| What | Where |
|---|---|
| Themes (`painthoarder` dark default, `painthoarder-light`) | `app/assets/stylesheets/application.tailwind.css` (`@plugin "daisyui/theme"`) |
| Extra tokens and components | `app/assets/stylesheets/components/painthoarder.css` |
| Helpers: `status_tag`, `ph_icon`, `brand_mark`, `match_quality`, `match_meter`, `nav_current` | `app/helpers/design_helper.rb` |
| Theme switch (account menu, guest footer) | `theme_controller.js`, `ThemesHelper#themes` |
| Header, phone tab bar, flash | `app/views/layouts/application.html.erb` |

## Tokens

DaisyUI slots: `base-100` = surface, `base-200` = surface-2, `base-300` = border, `primary` = orange, `neutral` = bone (inverse), `warning` = wanted, `error` = avoid. Extra Tailwind colours: `page` (page background), `line`, `line-strong`, `soft`, `muted`, `accent-text` (orange text that passes 4.5:1 in light), `wanted`, `avoid`. Fonts: Archivo (`font-sans`, `cond` utility for condensed caps) and JetBrains Mono (`font-mono`).

## Rules

- Statuses always pair word, icon and colour: Owned = filled bone, Wanted = yellow outline, Avoid = coral outline, Add = dashed. Use `status_tag`, never ad-hoc badges. The stored value for Wanted is still `wishlist`.
- Match quality from ΔE: < 1 near-identical, 1–3 very close, 3–6 close, > 6 noticeable (`match_quality`).
- One `btn-primary` per view; buttons are 48px tall; focus ring is 3px bone with 3px offset.
- Paint names wrap to two lines (`paint-card-name`), never truncate. Text in condensed caps is uppercased by CSS, so system tests match it case-insensitively.
- DaisyUI nests its components in the utilities layer; overrides of DaisyUI properties go in the `@layer utilities` block of `painthoarder.css`.
- Pages render inside `.wrap`; set `content_for :bare` to opt out (landing).

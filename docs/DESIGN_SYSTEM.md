# Design System

> Approved design. **Do not change the visual design without the owner's permission**.

All styles live in one file, `client/app/static/css/main.css` (≈1,320 lines). There is no preprocessor and no build step.

## Tokens (`:root`)

| Group | Tokens |
|---|---|
| Night palette | `--night #120612`, `--night-2`, `--plum`, `--purple`, `--violet`, `--lilac` |
| Warm palette | `--burgundy #6b1d2c`, `--wine`, `--orange`, `--ember` |
| Gold | `--gold #c99a3e`, `--gold-light`, `--gold-pale`, `--gold-text` (gradient) |
| Paper and ink | `--parchment #f3e6c8`, `--parchment-2`, `--ink #2a1810`, `--ink-soft`, `--ink-purple` |
| States | `--success #3f6b2a`, `--danger #9e2a3a`, `--line` |
| Type | `--f-display` Fraunces, `--f-text` IM Fell English, `--f-hand` Caveat (all self-hosted, SIL OFL) |
| Layout | `--gutter clamp(1rem, 4vw, 3rem)`, `--max 1240px` |
| Motion | `--ease-spring`, `--ease-out` |
| Textures | `--img-parchment`, `--img-leather`, `--img-niche`, `--img-smoke`, `--img-feather`, `--grain` (inline SVG noise), `--paper` |

White-label theming (P4-38) should start here: a theme is a file that overrides these tokens.

## Components

| Component | Notes |
|---|---|
| Buttons | `.btn`, `--magic`, `--ghost`, `--large`; `data-sparks` adds a particle burst |
| Product card | `.card` with a product `.stage` (darkened display niche) and an `.art` layer per effect. Built by the `art`/`photo` macros in `templates/partials/macros.html` |
| Stage | `.stage`: square, `--img-niche` background with vignette; the product photo sits at 88% base, scaled to .94 |
| Basket drawer | `<dialog class="basket">` from the right; `.basket-line`, small quantity control |
| Toasts | `.toasts`; they move inside an open dialog |
| Game | `<dialog class="game">` with HUD, arena, intro and result cards |
| Ledger | parchment book layout with status seals |
| Icons | SVG sprite `templates/partials/defs.svg`; logo seal `seal.svg`; animated `clock.svg` |

## Imagery

- Product photos are cut-outs on transparent 1600×1600 canvases, with the base of the object at 88% of the height. There are 640 px copies in `products/640/`.
- Multi-state products use extra frames (`--open`, `--extended`) or layers (`pocket-fluffs--box/--violet/--pink`).
- Scenes live in `img/scenes/` (storefront, shop interior, workshop). The door and sign hotspots are positioned in % over the storefront photo.

## Motion and accessibility rules

- All movement switches off under `prefers-reduced-motion`.
- Idle cards pause their animations, except the Pocket Fluffs, which keep hopping by design.
- Interactive hotspots are real buttons, reachable with Tab and activated with Enter or Space.

## Static asset delivery

- `asset()` adds a content hash to every static URL, and static files are cached for 1 year.
- CSP forbids inline scripts. Inline `style` attributes are allowed.

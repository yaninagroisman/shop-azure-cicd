# Dev tools (not part of the site)

Scripts used during development. Nothing in `client/` imports them, and the shop runs without them.

## `images/`: image pipeline

These scripts need Python with `pillow` and `numpy`, plus `rembg` (BiRefNet and SAM models, downloaded on first use). Install them in a **separate** virtual environment. They are not project dependencies.

| Script | What it does | Example |
|---|---|---|
| `rb.py` | Background removal with a rembg model | `python rb.py birefnet-general <src_dir> <out_dir> bottled-bog queasy-drops` |
| `fillholes.py` | Makes small enclosed holes (eyes, glass) opaque. Holes of 3,000 px or more are kept | `python fillholes.py cut/*.png` |
| `frame.py` | Places each cut-out on a 1600×1600 canvas, centred, base at 88% (env `BASE`, `TOP`), and writes 640 px copies. Image pairs share one scale | `python frame.py cut/ framed/` |
| `sam_pair.py`, `sam_pair_v.py` | SAM masks for the pink and violet Pocket Fluffs | see the script headers |
| `split_pair.py` | Splits the fluff pair into two layers. Each fringe pixel goes to the nearer fluff. The hidden side of the violet fluff is rebuilt from its own mirrored fur, with soft edges | `python split_pair.py <work_dir>` (expects `pf/src/fluffs.png` and `pf/sam-*.png`) |
| `compose_fluffs.py` | Builds `pocket-fluffs--box/--violet/--pink.webp` and the composite | `VIO_DY=74 python compose_fluffs.py <work_dir> .55 .80 .05 .64 .33 .895` |

The source PNG masters are in `../source-png/`, which is excluded from git.

## `netlify/`: static preview

`freeze.py` renders the whole shop (mock mode) into `dist/` at the project root for Netlify Drop. See `docs/DEPLOYMENT.md`.

## `checks/`: old ad-hoc browser checks

These Playwright scripts were used for manual checks before the test suite existed.

- They expect the preview at `http://localhost:8000`.
- `final.py` also needs an `API_MODE=http` instance on port 8001.
- Each script takes an output folder as its first argument.

The maintained tests are in `client/tests/`.

"""Place each cut-out on a 1600x1600 transparent canvas: base on the niche ledge (88%),
centred, fitting inside x 8-92%, y 16-88%. Pairs share one scale/offset."""
import sys, os
from PIL import Image
src, out = sys.argv[1], sys.argv[2]
import os as _o
N, BASE, TOP, SIDE = 1600, float(_o.environ.get("BASE", .88)), float(_o.environ.get("TOP", .16)), .08
groups = [["long-reach-listeners", "long-reach-listeners--extended"], ["truants-tuckbox", "truants-tuckbox--open"]]
names = [f[:-4] for f in sorted(os.listdir(src)) if f.endswith(".png")]
singles = [[n] for n in names if not any(n in g for g in groups)]
os.makedirs(out + "/640", exist_ok=True)
groups = [g for g in groups if all(n in names for n in g)]
for g in groups + singles:
    ims = {n: Image.open(f"{src}/{n}.png").convert("RGBA") for n in g}
    boxes = [im.getchannel("A").point(lambda v: 255 if v > 24 else 0).getbbox() for im in ims.values()]
    l, t, r, b = min(x[0] for x in boxes), min(x[1] for x in boxes), max(x[2] for x in boxes), max(x[3] for x in boxes)
    k = min(N * (1 - 2 * SIDE) / (r - l), N * (BASE - TOP) / (b - t))
    for n, im in ims.items():
        s = im.resize((round(im.width * k), round(im.height * k)), Image.LANCZOS)
        canvas = Image.new("RGBA", (N, N), (0, 0, 0, 0))
        x = round(N / 2 - (l + r) / 2 * k); y = round(N * BASE - b * k)
        canvas.alpha_composite(s, (x, y)) if x >= 0 and y >= 0 else canvas.paste(s, (x, y), s)
        canvas.save(f"{out}/{n}.webp", quality=90, method=6)
        canvas.resize((640, 640), Image.LANCZOS).save(f"{out}/640/{n}.webp", quality=88, method=6)
        print(n, "scale %.2f" % k)

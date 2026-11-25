import sys, os
from PIL import Image
S = sys.argv[1]; BOX_H, BOX_BASE, BOX_X, PAIR_W, PAIR_X, PAIR_BASE = map(float, sys.argv[2:8])
N = 1600
box = Image.open(f"{S}/pf/src/box.png").convert("RGBA"); pink = Image.open(f"{S}/pf/pink.png"); vio = Image.open(f"{S}/pf/violet.png")
bb = box.getchannel("A").point(lambda v: 255 if v > 24 else 0).getbbox()
pb = Image.alpha_composite(vio, pink).getchannel("A").point(lambda v: 255 if v > 24 else 0).getbbox()
def place(img, b, k, xl, yb):
    s = img.resize((round(img.width * k), round(img.height * k)), Image.LANCZOS)
    c = Image.new("RGBA", (N, N)); x = round(xl - b[0] * k); y = round(yb - b[3] * k); c.paste(s, (x, y), s); return c, (x, y)
kb = N * BOX_H / (bb[3] - bb[1]); boxL, _ = place(box, bb, kb, N * BOX_X, N * BOX_BASE)
kp = N * PAIR_W / (pb[2] - pb[0])
pinkL, off = place(pink, pb, kp, N * PAIR_X, N * PAIR_BASE); vioL, _ = place(vio, pb, kp, N * PAIR_X, N * PAIR_BASE + float(os.environ.get('VIO_DY', 0)))  # VIO_DY: px down, to stand it on the floor
print("box x %.1f-%.1f top %.1f | pair top %.1f right %.1f" % (100 * BOX_X, 100 * (BOX_X + (bb[2] - bb[0]) * kb / N), 100 * (BOX_BASE - BOX_H), 100 * (PAIR_BASE - (pb[3] - pb[1]) * kp / N), 100 * (PAIR_X + PAIR_W)))
comp = Image.alpha_composite(Image.alpha_composite(boxL, vioL), pinkL)
os.makedirs(f"{S}/pf/out/640", exist_ok=True)
for n, im in [("pocket-fluffs", comp), ("pocket-fluffs--box", boxL), ("pocket-fluffs--violet", vioL), ("pocket-fluffs--pink", pinkL)]:
    im.save(f"{S}/pf/out/{n}.webp", quality=90, method=6); im.resize((640, 640), Image.LANCZOS).save(f"{S}/pf/out/640/{n}.webp", quality=88, method=6)
open(f"{S}/pf/out/xform.txt", "w").write(f"{kp} {off[0]} {off[1]}")
n = Image.open(os.path.join(os.path.dirname(os.path.abspath(__file__)), "../../../client/app/static/img/textures/display-niche.webp")).convert("RGBA"); n.alpha_composite(comp); n.convert("RGB").resize((700, 700)).save(f"{S}/pfcomp.jpg")

import sys, numpy as np
from PIL import Image, ImageFilter
S = sys.argv[1]
im = Image.open(f"{S}/pf/src/fluffs.png").convert("RGBA"); a = np.array(im).astype(np.float32)
H, W = a.shape[:2]; alpha = a[..., 3]
from PIL import ImageDraw, ImageOps
pm = Image.open(f"{S}/pf/sam-pink.png").convert("L").point(lambda v: 255 if v > 127 else 0)
holes = ImageOps.invert(pm); ImageDraw.floodfill(holes, (0, 0), 0)      # close holes (the eye) in the pink mask
pink = (np.array(pm) > 0) | (np.array(holes) > 0)
solid = alpha > 127
violet = (np.array(Image.open(f"{S}/pf/sam-violet.png").convert("L")) > 127) & ~pink
# grow both labels outward over the fur fringe: each fringe pixel goes to the nearer fluff
lab = np.zeros((H, W), np.uint8); lab[pink] = 1; lab[violet] = 2
present = alpha > 4
for _ in range(60):
    if not ((lab == 0) & present).any(): break
    for v in (1, 2):
        g = np.array(Image.fromarray(((lab == v) * 255).astype(np.uint8)).filter(ImageFilter.MaxFilter(3))) > 0
        lab[(lab == 0) & present & g] = v
def soft(mask): return np.array(Image.fromarray((mask * 255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(1.2))) / 255
pk = a.copy(); pk[..., 3] = alpha * soft(lab == 1)
vi = a.copy(); vi[..., 3] = alpha * soft(lab == 2)
# fill the violet fluff's left side (hidden behind pink) with its own mirrored right side
# the violet fluff's outline, from its eyes (x 1010/1220, y 446) and its right edge (x 1560)
cx, cy, rx, ry = 1115, 470, 445, 385
mx = np.clip((2 * cx - np.arange(W)).astype(int), 0, W - 1)
mir = vi[:, mx]
yy, xx = np.mgrid[0:H, 0:W]
d = np.sqrt(((xx - cx) / rx) ** 2 + ((yy - cy) / ry) ** 2)
# behind the pink one (and its fringe), and on the left where violet has nothing of its own
# only where the violet fluff has (almost) no fur of its own, i.e. behind the pink one; soft edges, no seam
behind = np.array(Image.fromarray((((lab != 2) | (vi[..., 3] < 60)) * 255).astype(np.uint8)).filter(ImageFilter.MaxFilter(71))) > 0  # + the shadow pink casts
hidden = behind & (d < 1.18) & (d > .42) & (xx < cx) & (mir[..., 3] > 0)
w = np.array(Image.fromarray((hidden * 255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(14))) / 255
w = np.where((mir[..., 3] > vi[..., 3]) | (d < 1.05), w, 0)[..., None]
vi = vi * (1 - w) + mir * w
# stray pink hairs lying over the violet fur: recolour them violet, keep their brightness
own = (lab == 2) & (alpha > 200)
ref = vi[own][:, :3]; ref_mean = ref.mean(0); ref_lum = (.3 * ref[:, 0] + .59 * ref[:, 1] + .11 * ref[:, 2]).mean()
lum = .3 * vi[..., 0] + .59 * vi[..., 1] + .11 * vi[..., 2]
pinkish = ((vi[..., 0] - vi[..., 2]) > 28) & (vi[..., 3] > 0) & (xx < cx + 60)
tint = ref_mean[None, None, :] * (lum / ref_lum)[..., None]
k = np.array(Image.fromarray((pinkish * 255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(2))) / 255
vi[..., :3] = vi[..., :3] * (1 - k[..., None]) + tint * k[..., None]
lum = .3 * vi[..., 0] + .59 * vi[..., 1] + .11 * vi[..., 2]
vi[(lum < 70) & (vi[..., 3] < 230) & (d > .5)] = 0                       # dark specks at the mirrored edge
fill = hidden
for name, arr in (("pink", pk), ("violet", vi)):
    Image.fromarray(arr.clip(0, 255).astype(np.uint8)).save(f"{S}/pf/{name}.png")
print("cx", round(cx), "filled", int(fill.sum()))

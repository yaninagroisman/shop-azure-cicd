"""Make every pixel enclosed by the object opaque (holes the cut-out left in eyes, glass…)."""
import sys, glob
import numpy as np
from PIL import Image
from collections import deque
for f in sys.argv[1:]:
    im = Image.open(f).convert("RGBA"); a = np.array(im.getchannel("A"))
    H, W = a.shape; solid = a > 200
    outside = np.zeros_like(solid); q = deque()
    for x in range(W):
        for y in (0, H - 1):
            if not solid[y, x] and not outside[y, x]: outside[y, x] = True; q.append((y, x))
    for y in range(H):
        for x in (0, W - 1):
            if not solid[y, x] and not outside[y, x]: outside[y, x] = True; q.append((y, x))
    while q:
        y, x = q.popleft()
        for dy, dx in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            ny, nx = y + dy, x + dx
            if 0 <= ny < H and 0 <= nx < W and not outside[ny, nx] and not solid[ny, nx]:
                outside[ny, nx] = True; q.append((ny, nx))
    holes = ~outside & ~solid
    # fill only small holes (an eye, a glint); big ones (inside the ear headband) are real gaps
    seen = np.zeros_like(holes); n = 0
    for y0, x0 in zip(*np.nonzero(holes)):
        if seen[y0, x0]: continue
        comp = [(y0, x0)]; seen[y0, x0] = True; i = 0
        while i < len(comp):
            y, x = comp[i]; i += 1
            for dy, dx in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                ny, nx = y + dy, x + dx
                if 0 <= ny < H and 0 <= nx < W and holes[ny, nx] and not seen[ny, nx]:
                    seen[ny, nx] = True; comp.append((ny, nx))
        if len(comp) < 3000:
            ys, xs = zip(*comp); a[list(ys), list(xs)] = 255; n += len(comp)
    Image.fromarray(a).save(f + ".a.png"); im.putalpha(Image.fromarray(a)); im.save(f)
    print(f.split("/")[-1], "filled px:", n)

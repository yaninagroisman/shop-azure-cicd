import sys
from PIL import Image
from rembg import new_session, remove
src, out = sys.argv[1], sys.argv[2]
im = Image.open(src).convert("RGBA"); W, H = im.size
rgb = Image.new("RGB", im.size, (40, 200, 40)); rgb.paste(im, mask=im.getchannel("A"))
side = max(W, H); sq = Image.new("RGB", (side, side), (40, 200, 40)); sq.paste(rgb, (0, 0))
small = sq.resize((1024, 1024), Image.LANCZOS); f = 1024 / side
P = lambda x, y, l: {"type": "point", "data": [int(x * W * f), int(y * H * f)], "label": l}
sess = new_session("sam")
m = remove(small, session=sess, only_mask=True, sam_prompt=[P(.34, .60, 1), P(.28, .45, 1), P(.40, .75, 1), P(.76, .38, 0), P(.82, .55, 0)])
m.resize((side, side), Image.LANCZOS).crop((0, 0, W, H)).save(out)
print("ok")

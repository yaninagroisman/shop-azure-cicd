import sys, glob, os, time
from rembg import new_session, remove
from PIL import Image
model, src, dst = sys.argv[1], sys.argv[2], sys.argv[3]
names = sys.argv[4:]
sess = new_session(model)
os.makedirs(dst, exist_ok=True)
for n in names:
    t = time.time()
    im = Image.open(os.path.join(src, n + ".png")).convert("RGB")
    out = remove(im, session=sess, post_process_mask=True)
    out.save(os.path.join(dst, n + ".png"))
    print(n, "%.1fs" % (time.time() - t), flush=True)

import glob
from playwright.sync_api import sync_playwright
from PIL import Image
exe = None  # Playwright's bundled Chromium (run: playwright install chromium)
O="./v4"; errs=[]
with sync_playwright() as p:
    b=p.chromium.launch(executable_path=exe); pg=b.new_page(viewport={"width":1440,"height":900})
    pg.on("pageerror", lambda e: errs.append(str(e))); pg.on("console", lambda m: m.type=="error" and errs.append(m.text))
    pg.goto("http://localhost:8000/product/pocket-fluffs"); pg.wait_for_timeout(2500)
    st=pg.locator(".stage--big"); pg.mouse.move(5,890)
    pg.evaluate("document.querySelectorAll('.fluff,.fluff-shadow').forEach(e=>e.style.animationPlayState='paused')")
    frames=[]
    for t in [0,.08,.18,.27,.38,.46]:
        pg.evaluate(f"document.querySelectorAll('.fluff,.fluff-shadow').forEach(e=>{{const a=e.getAnimations()[0]; if(a) a.currentTime = {t} * a.effect.getTiming().duration + (e.className.includes('violet')? 1500:0)}})")
        pg.wait_for_timeout(120); st.screenshot(path=f"{O}/hop{t}.png"); frames.append(f"{O}/hop{t}.png")
    pg.goto("http://localhost:8000/catalogue"); pg.wait_for_timeout(1500); c=pg.locator("[data-effect='puffs']").first; c.scroll_into_view_if_needed(); pg.wait_for_timeout(700); c.screenshot(path=O+"/pfcard.png")
    b.close()
ims=[Image.open(f).convert("RGB").resize((400,400)) for f in frames]
s=Image.new("RGB",(1200,800))
for i,im in enumerate(ims): s.paste(im,((i%3)*400,(i//3)*400))
s.save(O+"/hops.png"); print("errors",errs)

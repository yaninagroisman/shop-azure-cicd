import glob
from playwright.sync_api import sync_playwright
exe = None  # Playwright's bundled Chromium (run: playwright install chromium)
O="./v4"; errs=[]
with sync_playwright() as p:
    b=p.chromium.launch(executable_path=exe)
    for w in (1440, 1024, 768, 390, 360):
        pg=b.new_page(viewport={"width":w,"height":900}); pg.on("pageerror", lambda e: errs.append(str(e)))
        pg.goto("http://localhost:8000/product/bumble-fizzies"); pg.wait_for_timeout(1200)
        h=pg.locator("#related-title")
        r=pg.evaluate("() => { const e=document.querySelector('#related-title'); const range=document.createRange(); range.selectNodeContents(e); return {lines: [...new Set([...range.getClientRects()].map(r=>Math.round(r.top)))].length, w: Math.round(e.scrollWidth), cw: e.clientWidth, overflow: document.documentElement.scrollWidth > innerWidth} }")
        print(w, r)
        if w in (1440,390): h.scroll_into_view_if_needed(); pg.wait_for_timeout(500); pg.screenshot(path=f"{O}/rel{w}.png")
        pg.close()
    pg=b.new_page(viewport={"width":1440,"height":900}); pg.goto("http://localhost:8000/product/bumble-fizzies"); pg.wait_for_timeout(1800); pg.locator(".stage--big").screenshot(path=O+"/bf-stage.png")
    print("title:", pg.title(), "| old slug:", pg.goto("http://localhost:8000/product/old-renamed-slug").status)
    b.close()
print("errors", errs)

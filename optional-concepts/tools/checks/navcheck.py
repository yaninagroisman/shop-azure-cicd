import glob, time
from playwright.sync_api import sync_playwright
exe = None  # Playwright's bundled Chromium (run: playwright install chromium)
with sync_playwright() as p:
    b=p.chromium.launch(executable_path=exe); pg=b.new_page(viewport={"width":1280,"height":800}); errs=[]
    pg.on("pageerror", lambda e: errs.append(str(e)))
    pg.goto("http://localhost:8000/"); pg.wait_for_timeout(1500)
    for sel,pat in [(".nav__links a >> nth=1","**/catalogue"),(".card__title a >> nth=0","**/product/**"),(".breadcrumb a >> nth=0","http://localhost:8000/"),(".nav__links a >> nth=0","http://localhost:8000/"),("[data-ledger-link]","**/orders")]:
        t=time.time(); pg.click(sel); pg.wait_for_url(pat); pg.wait_for_timeout(1300)
        print(pg.url, "%.2fs"%(time.time()-t), pg.evaluate("document.documentElement.className"))
    pg.go_back(); pg.wait_for_timeout(800); print("back:", pg.url, pg.evaluate("document.documentElement.className"))
    print("errors", errs); b.close()

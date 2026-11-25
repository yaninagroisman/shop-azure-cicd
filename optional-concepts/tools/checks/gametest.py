import glob, sys
from playwright.sync_api import sync_playwright
exe = None  # Playwright's bundled Chromium (run: playwright install chromium)
O=sys.argv[1]
with sync_playwright() as p:
    b=p.chromium.launch(executable_path=exe)
    for name, vp, mobile in [("desk",{"width":1440,"height":900},False),("mob",{"width":390,"height":844},True)]:
        pg=b.new_page(viewport=vp, is_mobile=mobile, has_touch=mobile); errs=[]
        pg.on("pageerror", lambda e: errs.append(str(e))); pg.on("console", lambda m: errs.append(m.text) if m.type=="error" else None)
        pg.goto("http://localhost:8000/"); pg.wait_for_timeout(2600)
        (pg.tap if mobile else pg.click)(".shop-door"); pg.wait_for_timeout(1200)
        print(name, "dialog open:", pg.evaluate("document.querySelector('[data-game]').open"), "focus:", pg.evaluate("document.activeElement.textContent.trim()"))
        pg.screenshot(path=f"{O}/{name}-intro.png")
        pg.click("[data-game-intro] [data-game-start]"); pg.wait_for_timeout(2500)
        pg.screenshot(path=f"{O}/{name}-play.png")
        caught={}
        for k in range(40):
            its=pg.locator(".game__item:not(.is-caught)")
            if its.count():
                it=its.first; cls=it.get_attribute("class")
                try:
                    if mobile: it.tap(timeout=500, force=True)
                    else: it.click(timeout=500, force=True)
                    eff=cls.split("--")[-1]; caught[eff]=caught.get(eff,0)+1
                except Exception as e: pass
            pg.wait_for_timeout(150)
        print(name, "caught by type:", caught, "score:", pg.inner_text("[data-game-score]"), "time left:", pg.inner_text("[data-game-time]"))
        if not mobile:
            pg.keyboard.press("Tab"); pg.wait_for_timeout(50)
            f=pg.evaluate("document.activeElement.className")
            before=pg.inner_text("[data-game-score]")
            if "game__item" in f: pg.keyboard.press("Enter"); pg.wait_for_timeout(100)
            print("keyboard focus:", f, "score", before, "->", pg.inner_text("[data-game-score]"))
        pg.wait_for_timeout(25000)
        print(name, "result visible:", pg.is_visible("[data-game-result]"), "final:", pg.inner_text("[data-game-final]"), "best:", pg.inner_text("[data-game-best]"), "verdict:", pg.inner_text("[data-game-verdict]"))
        pg.screenshot(path=f"{O}/{name}-result.png")
        pg.keyboard.press("Escape"); pg.wait_for_timeout(400)
        print(name, "closed:", not pg.evaluate("document.querySelector('[data-game]').open"), "door closed:", not pg.evaluate("document.querySelector('[data-storefront]').classList.contains('is-open')"), "canvas back:", pg.evaluate("document.querySelector('[data-magic-canvas]').parentNode.tagName"), "overflow:", pg.evaluate("document.documentElement.scrollWidth>innerWidth"))
        print(name, "errors:", errs)
        pg.close()
    b.close()

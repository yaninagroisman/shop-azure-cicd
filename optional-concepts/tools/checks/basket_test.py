import glob, sys
from playwright.sync_api import sync_playwright
exe = None  # Playwright's bundled Chromium (run: playwright install chromium)
O=sys.argv[1]; errs=[]
with sync_playwright() as p:
    b=p.chromium.launch(executable_path=exe)
    for name,vp in [("d",{"width":1440,"height":900}),("m",{"width":390,"height":844})]:
        pg=b.new_page(viewport=vp, has_touch=name=="m")
        pg.on("pageerror", lambda e: errs.append(str(e))); pg.on("console", lambda m: m.type=="error" and errs.append(m.text))
        pg.goto("http://localhost:8000/"); pg.evaluate("localStorage.clear(); sessionStorage.clear()"); pg.reload(); pg.wait_for_timeout(2600)
        pg.screenshot(path=f"{O}/{name}-home.png")
        assert pg.locator(".nav__links a[href='/orders']").count()==0, "ledger still in nav"
        assert pg.locator("[data-ledger-link]").count()==1
        pg.goto("http://localhost:8000/catalogue"); pg.wait_for_timeout(1500)
        pg.screenshot(path=f"{O}/{name}-cat.png")
        btns=pg.locator("[data-add]")
        btns.nth(0).click(); btns.nth(4).click(); btns.nth(4).click(); pg.wait_for_timeout(300)
        print(name,"count",pg.locator("[data-basket-count]").inner_text())
        pg.goto("http://localhost:8000/product/bottled-bog"); pg.wait_for_timeout(1500)
        pg.click("[data-qty-step='1']"); pg.click("[data-qty-step='1']"); pg.click(".btn--buy")
        pg.wait_for_timeout(300); pg.screenshot(path=f"{O}/{name}-prod.png")
        pg.click("[data-basket-open]"); pg.wait_for_timeout(700)
        print(name,"lines",pg.locator(".basket-line").count(), pg.locator("[data-basket-total]").inner_text().replace("\n"," "))
        pg.screenshot(path=f"{O}/{name}-basket.png")
        pg.locator(".basket-line").nth(0).locator("[data-line-remove]").click(); pg.wait_for_timeout(200)
        print(name,"after remove",pg.locator(".basket-line").count())
        pg.evaluate("sessionStorage.setItem('mmc-mock-mode','ok')")
        pg.click("[data-checkout]"); pg.wait_for_timeout(1500)
        print(name,"status:",pg.locator("[data-basket-status] .order-status__title").inner_text(), "lines left", pg.locator(".basket-line").count())
        pg.screenshot(path=f"{O}/{name}-checkout.png")
        pg.wait_for_timeout(9000)
        print(name,"later:",pg.locator("[data-basket-status] .order-status__title").inner_text())
        pg.screenshot(path=f"{O}/{name}-done.png")
        pg.keyboard.press("Escape"); pg.wait_for_timeout(400)
        pg.goto("http://localhost:8000/orders"); pg.wait_for_timeout(1500)
        print(name,"ledger entries", pg.locator(".entry").count())
        pg.close()
    b.close()
print("ERRORS",errs)

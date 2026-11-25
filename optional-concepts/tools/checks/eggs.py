import glob, sys
from playwright.sync_api import sync_playwright
exe = None  # Playwright's bundled Chromium (run: playwright install chromium)
B = "http://localhost:8000"; O = sys.argv[1]
with sync_playwright() as p:
    b = p.chromium.launch(executable_path=exe)
    pg = b.new_page(viewport={"width": 1440, "height": 900}); errs = []
    pg.on("pageerror", lambda e: errs.append(str(e)))
    pg.on("console", lambda m: errs.append(m.text) if m.type == "error" else None)
    pg.goto(B + "/"); pg.wait_for_timeout(1500)
    # storefront door + sign hotspots
    pg.click(".shop-door"); pg.wait_for_timeout(900); print("door opens game:", pg.evaluate("document.querySelector('[data-game]').open"))
    pg.keyboard.press("Escape"); pg.wait_for_timeout(300)
    for i in range(3): pg.click(".hanging-sign")
    pg.wait_for_selector(".secret-poster"); print("poster ok"); pg.wait_for_timeout(700); pg.screenshot(path=f"{O}/poster.png")
    pg.click(".secret-poster button")
    # keyboard access to hotspots
    pg.focus(".shop-door"); pg.keyboard.press("Enter"); pg.wait_for_timeout(900); print("door via keyboard opens game:", pg.evaluate("document.querySelector('[data-game]').open")); pg.keyboard.press("Escape"); pg.wait_for_timeout(300)
    # snackbox toggle via keyboard
    pg.focus("[data-toggle-stage]"); pg.keyboard.press("Enter"); pg.wait_for_timeout(900)
    print("snackbox toggle:", pg.get_attribute("[data-toggle-stage]", "aria-pressed"))
    pg.locator("[data-toggle-stage]").screenshot(path=f"{O}/snack-open.png")
    # parallax
    pg.mouse.move(1300, 300); pg.wait_for_timeout(200)
    print("parallax vars:", pg.evaluate("getComputedStyle(document.querySelector('.storefront')).getPropertyValue('--px')"))
    # spells
    pg.mouse.click(700, 120)
    pg.keyboard.type("lucerna"); pg.wait_for_timeout(900); print("lucerna:", pg.evaluate("document.documentElement.classList.contains('wandlight')"))
    pg.mouse.move(400, 400); pg.wait_for_timeout(300); pg.screenshot(path=f"{O}/lumos.png")
    pg.keyboard.type("umbra"); print("nox:", not pg.evaluate("document.documentElement.classList.contains('wandlight')"))
    pg.keyboard.type("reserare"); print("reserare toast ok:", pg.locator(".toast__title", has_text="Reserare").count() > 0)
    pg.keyboard.type("nothingupmysleeve"); pg.wait_for_timeout(3500)
    print("map open:", pg.is_visible("[data-chart]"), "walkers:", pg.locator(".chart__walkers .footprint").count())
    pg.screenshot(path=f"{O}/map.png")
    pg.keyboard.press("Escape"); print("map closed:", not pg.is_visible("[data-chart]"))
    # clock
    for i in range(3): pg.click("[data-clock]")
    print("peril:", pg.evaluate("document.documentElement.classList.contains('peril')"))
    # footprint trigger
    pg.click("[data-chart-trigger]"); pg.wait_for_timeout(500); print("map via footprints:", pg.is_visible("[data-chart]")); pg.click("[data-chart-close]")
    # wandering footprints
    pg.evaluate("Magic.walk(document.querySelector('[data-footprints]'))"); pg.wait_for_timeout(1500); print("wander prints:", pg.locator(".footprints-layer .footprint").count())
    # page transition
    pg.click(".hero .btn--magic"); pg.wait_for_timeout(250); print("leaving class:", pg.evaluate("document.documentElement.className"))
    pg.wait_for_url("**/catalogue"); pg.wait_for_timeout(1200)
    # filters
    pg.fill("[data-filter-search]", "swamp"); print("search:", pg.inner_text("[data-results-count]"))
    pg.fill("[data-filter-search]", "zzzz"); print("empty:", pg.is_visible("[data-empty]"))
    pg.click("[data-filter-reset]"); pg.click("[data-filter-category='creatures']"); print("shelf:", pg.inner_text("[data-results-count]"))
    pg.click("[data-filter-category='all']"); pg.select_option("[data-filter-sort]", "price-desc"); pg.wait_for_timeout(300)
    print("sorted first:", pg.locator(".card__title").first.inner_text())
    pg.select_option("[data-filter-sort]", "shelf"); pg.wait_for_timeout(500)
    # darkness card hover
    pg.hover('[data-effect="darkness"] .card__label'); pg.wait_for_timeout(500); print("darkness hover:", pg.locator('[data-effect="darkness"] .stage.is-dark').count())
    # puffs tickle on product page
    pg.goto(B + "/product/pocket-fluffs"); pg.wait_for_timeout(1200)
    pg.click(".stage--big"); print("tickled:", pg.locator(".stage.is-tickled").count())
    pg.click("[data-demo]"); print("demo pressed:", pg.get_attribute("[data-demo]", "aria-pressed"))
    for slug in ["skyroarer-rockets","songbird-creams","bottled-bog","reverie-charms","diversion-crackers","hot-brow-fudge","queasy-drops","crimson-nose-nougat","long-reach-listeners","truants-tuckbox","instant-midnight"]:
        pg.goto(B + "/product/" + slug); pg.wait_for_timeout(700); pg.click("[data-demo]"); pg.wait_for_timeout(500)
        st = pg.get_attribute(".stage--big", "class")
        print(slug, "demo ->", "is-demo" in st or "is-dark" in st)
    # images: all loaded and with alpha intact
    pg.goto(B + "/catalogue"); h = pg.evaluate("document.body.scrollHeight")
    for y in range(0, h, 500): pg.evaluate(f"scrollTo(0,{y})"); pg.wait_for_timeout(80)
    pg.wait_for_timeout(800)
    print("broken imgs:", pg.evaluate("[...document.images].filter(i=>!i.complete||!i.naturalWidth).map(i=>i.src)"))
    # mobile menu + reduced motion
    mp = b.new_page(viewport={"width": 390, "height": 844}, is_mobile=True, has_touch=True)
    mp.goto(B + "/"); mp.wait_for_timeout(1200)
    mp.click("[data-nav-toggle]"); mp.wait_for_timeout(800); print("menu open:", mp.is_visible("[data-nav-menu] a")); mp.screenshot(path=f"{O}/m-menu.png")
    mp.keyboard.press("Escape")
    print("mobile overflow:", [ (u, mp.goto(B+u) and mp.evaluate("document.documentElement.scrollWidth > innerWidth")) for u in ["/","/catalogue","/product/pocket-fluffs","/orders"]])
    mp.tap("[data-toggle-stage]") if mp.goto(B+"/") else None; mp.wait_for_timeout(600); print("tap snackbox:", mp.get_attribute("[data-toggle-stage]", "aria-pressed"))
    rp = b.new_page(viewport={"width": 1440, "height": 900}, reduced_motion="reduce")
    rp.goto(B + "/"); rp.wait_for_timeout(500)
    print("reduced: curtain", rp.evaluate("getComputedStyle(document.querySelector('.curtain')).display"), "motes", rp.evaluate("getComputedStyle(document.querySelector('.motes')).display"), "hero visible", rp.evaluate("getComputedStyle(document.querySelector('.hero__line')).opacity"))
    rp.screenshot(path=f"{O}/reduced.png")
    print("errors:", errs)
    b.close()

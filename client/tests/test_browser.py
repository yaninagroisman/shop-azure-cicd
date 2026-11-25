"""End-to-end smoke tests in headless Chromium against the mock API."""
import pytest

pytestmark = pytest.mark.browser

PAGES = ["/", "/catalogue", "/orders", "/product/pocket-fluffs", "/product/truants-tuckbox"]


@pytest.mark.parametrize("url", PAGES)
def test_page_has_no_js_errors_or_broken_images(make_page, url):
    page = make_page()  # strict CSP: a CSP violation would show up as a console error
    page.goto(page.base + url)
    page.wait_for_load_state("networkidle")
    broken = page.evaluate("[...document.images].filter(i => i.complete && i.naturalWidth === 0 && i.loading !== 'lazy').map(i => i.src)")
    assert broken == []
    assert page.js_errors == []


@pytest.mark.parametrize("url", ["/", "/catalogue", "/product/pocket-fluffs", "/orders"])
def test_no_horizontal_scroll_on_phones(browser, live_server, url):
    ctx = browser.new_context(viewport={"width": 390, "height": 844}, is_mobile=True, has_touch=True)
    pg = ctx.new_page()
    pg.goto(live_server + url)
    pg.wait_for_load_state("networkidle")
    assert pg.evaluate("document.documentElement.scrollWidth <= innerWidth")
    ctx.close()


def test_basket_checkout_reaches_the_ledger(make_page):
    page = make_page(bypass_csp=True)
    page.goto(page.base + "/catalogue?mock=ok&mock=reset")
    page.evaluate("localStorage.clear(); sessionStorage.setItem('mmc-mock-mode', 'ok')")
    page.reload()
    adds = page.locator("[data-add]")
    adds.nth(0).click()
    adds.nth(4).click()
    adds.nth(4).click()
    assert page.locator("[data-basket-count]").inner_text().strip() == "3"

    page.click("[data-basket-open]")
    assert page.locator(".basket-line").count() == 2
    page.locator(".basket-line").nth(0).locator("[data-line-remove]").click()
    assert page.locator(".basket-line").count() == 1

    page.click("[data-checkout]")
    status = page.locator("[data-basket-status] .order-status__title")
    page.wait_for_function("document.querySelectorAll('.basket-line').length === 0", timeout=5000)
    status.filter(has_text="delivered").wait_for(timeout=15000)  # mock processes in 3-7 s

    page.keyboard.press("Escape")
    page.goto(page.base + "/orders")
    page.locator(".entry").first.wait_for(timeout=5000)
    assert page.locator(".entry").count() == 1
    assert page.js_errors == []


def test_door_game_starts_scores_and_closes(make_page):
    page = make_page(bypass_csp=True)
    page.goto(page.base + "/")
    page.wait_for_load_state("networkidle")
    page.click(".shop-door")
    page.wait_for_function("document.querySelector('[data-game]').open", timeout=5000)
    page.click("[data-game-intro] [data-game-start]")
    item = page.locator(".game__item:not(.is-caught)").first
    item.wait_for(timeout=5000)
    item.click(force=True)
    page.wait_for_timeout(300)
    assert page.locator(".game__item.is-caught").count() + int(page.inner_text("[data-game-score]")) > 0
    page.keyboard.press("Escape")
    page.wait_for_function("!document.querySelector('[data-game]').open", timeout=3000)
    assert not page.evaluate("document.querySelector('[data-storefront]').classList.contains('is-open')")
    assert page.js_errors == []


def test_catalogue_search_filter_and_sort(make_page):
    from app.catalog import PRODUCTS

    page = make_page()
    page.goto(page.base + "/catalogue")
    page.wait_for_load_state("networkidle")
    visible = page.locator("[data-product-card]:not(.is-hidden)")
    assert visible.count() == len(PRODUCTS)

    page.fill("[data-filter-search]", "bog")
    assert visible.count() == 1 and "Bottled Bog" in visible.first.inner_text()

    page.fill("[data-filter-search]", "zzzz-nothing")
    assert visible.count() == 0 and page.is_visible("[data-empty]")
    page.click("[data-empty] [data-filter-reset]")
    assert visible.count() == len(PRODUCTS)

    page.click("[data-filter-category='mayhem']")
    expected = sum(p["category"] == "mayhem" for p in PRODUCTS)
    assert visible.count() == expected

    page.click("[data-filter-category='all']")
    page.select_option("[data-filter-sort]", "price-asc")
    prices = [int(x) for x in page.eval_on_selector_all("[data-product-card]:not(.is-hidden)", "els => els.map(e => e.dataset.price)")]
    assert prices == sorted(prices)
    assert page.js_errors == []

/* ledger.js: "The Mischief Ledger" (purchase history, /orders).
   Loads every purchase through ShopAPI.getAllBoughtItems(), keeps
   re-reading while any order is still pending, inks in new entries and
   re-stamps the seals of orders whose status changed. */
(function () {
  "use strict";
  var list = document.querySelector("[data-entries]");
  if (!list || !window.Shop || !window.ShopAPI) return;

  var POLL_MS = parseInt(document.body.getAttribute("data-poll-interval"), 10) || 1500;
  var emptyBox = document.querySelector("[data-ledger-empty]");
  var errorBox = document.querySelector("[data-ledger-error]");
  var syncEl = document.querySelector("[data-sync-status]");
  var loadingBox = document.querySelector("[data-ledger-loading]");
  var firstLoad = true;
  var timer = null;
  var failures = 0;
  var LABELS = { pending: "Owl in flight", completed: "Delivered", failed: "Confiscated" };

  function fmtDate(iso) {
    var d = new Date(iso);
    if (isNaN(d)) return iso;
    return d.toLocaleString("en-GB", { day: "numeric", month: "short", year: "numeric", hour: "2-digit", minute: "2-digit" });
  }

  function statusOf(li) { return (li.className.match(/entry--(\w+)/) || [])[1]; }

  function buildEntry(p, number) {
    var li = document.createElement("li");
    li.className = "entry entry--" + p.status;
    li.setAttribute("data-id", p.id);
    li.innerHTML =
      '<span class="entry__num"></span>' +
      '<div class="entry__main"><a class="entry__name"></a><span class="entry__qty"></span><span class="entry__when"></span></div>' +
      '<span class="entry__price"></span>' +
      '<span class="entry__status"><span class="seal" aria-hidden="true"></span><span class="entry__label"></span></span>';
    li.querySelector(".entry__num").textContent = number + ".";
    var name = li.querySelector(".entry__name");
    name.textContent = p.product_name;
    name.href = "/product/" + encodeURIComponent(p.product_slug);
    li.querySelector(".entry__qty").textContent = "× " + p.quantity;
    li.querySelector(".entry__when").textContent = fmtDate(p.created_at);
    li.querySelector(".entry__price").appendChild(Shop.coinsElement(p.total_price));
    setStatus(li, p);
    return li;
  }

  function setStatus(li, p) {
    li.className = li.className.replace(/entry--\w+/, "entry--" + p.status);
    var seal = li.querySelector(".seal");
    seal.className = "seal seal--" + p.status;
    var status = li.querySelector(".entry__status");
    // Replace the text node / label after the seal.
    Array.prototype.slice.call(status.childNodes).forEach(function (n) { if (n !== seal) n.remove(); });
    status.appendChild(document.createTextNode(LABELS[p.status] || p.status));
    var reason = li.querySelector(".entry__reason");
    if (p.status === "failed" && p.failure_reason && !reason) {
      reason = document.createElement("span");
      reason.className = "entry__reason";
      reason.textContent = p.failure_reason;
      li.querySelector(".entry__main").appendChild(reason);
    }
  }

  function render(purchases) {
    var existing = {};
    list.querySelectorAll("[data-id]").forEach(function (li) { existing[li.getAttribute("data-id")] = li; });

    purchases.forEach(function (p, i) {
      var number = purchases.length - i;
      var li = existing[p.id];
      if (!li) {
        li = buildEntry(p, number);
        if (!firstLoad) li.classList.add("is-new"); // ink in entries that arrive while watching
      } else if (statusOf(li) !== p.status) {
        setStatus(li, p);
        li.classList.remove("is-updated"); void li.offsetWidth; li.classList.add("is-updated");
        if (p.status === "completed") Magic.burstAt(li.querySelector(".seal"), { count: 22 });
      }
      li.querySelector(".entry__num").textContent = number + ".";
      list.appendChild(li); // keeps server order (newest first)
      delete existing[p.id];
    });
    Object.keys(existing).forEach(function (id) { existing[id].remove(); });

    firstLoad = false;
    loadingBox.hidden = true;
    emptyBox.hidden = purchases.length > 0;
    renderSummary(purchases);
    return purchases.some(function (p) { return p.status === "pending"; });
  }

  function renderSummary(purchases) {
    var done = purchases.filter(function (p) { return p.status === "completed"; });
    var count = function (status) { return purchases.filter(function (p) { return p.status === status; }).length; };
    document.querySelector("[data-sum-count]").textContent = done.reduce(function (n, p) { return n + p.quantity; }, 0);
    document.querySelector("[data-sum-pending]").textContent = count("pending");
    document.querySelector("[data-sum-failed]").textContent = count("failed");
    var spent = document.querySelector("[data-sum-spent]");
    spent.innerHTML = "";
    spent.appendChild(Shop.coinsElement(done.reduce(function (n, p) { return n + p.total_price; }, 0)));
  }

  function setLive(live) {
    syncEl.classList.toggle("is-live", live);
    syncEl.textContent = live ? "Owls in flight: the ink is still moving…" : "All owls have landed. The ink is dry.";
  }

  function refresh() {
    clearTimeout(timer);
    ShopAPI.getAllBoughtItems().then(function (purchases) {
      failures = 0;
      errorBox.hidden = true;
      var stillPending = render(purchases);
      setLive(stillPending);
      if (stillPending) timer = setTimeout(refresh, POLL_MS);
    }).catch(function () {
      failures++;
      errorBox.hidden = false;
      loadingBox.hidden = true;
      timer = setTimeout(refresh, Math.min(POLL_MS * Math.pow(2, failures), 20000));
    });
  }

  document.querySelector("[data-ledger-retry]").addEventListener("click", refresh);
  // Purchases made from this page's toasts or other tabs: stay in sync with the tracker.
  document.addEventListener("shop:purchases", function (e) { setLive(render(e.detail)); });

  refresh();
})();

/* ==========================================================================
   shop.js: money and order tracking (uses window.ShopAPI from api.js)
     * Coins: Pips -> Griffins / Shards / Pips, same markup as the Jinja macro.
     * Order tracker: remembers orders still "pending" (accepted, not yet
       processed), polls until they are "completed" or "failed", and
       announces the result on any page.
   Putting things in the basket and checking out lives in basket.js.
   ========================================================================== */
(function () {
  "use strict";

  var POLL_MS = parseInt(document.body.getAttribute("data-poll-interval"), 10) || 1500;
  var STORE_KEY = "mmc-pending-orders";

  /* ---------------------------------------------------------- money in JS */
  // 1 gold Griffin = 12 silver Shards = 240 copper Pips (same as money.py)
  var PIPS_PER_SHARD = 20, PIPS_PER_GRIFFIN = 240;
  function splitPips(total) {
    var g = Math.floor(total / PIPS_PER_GRIFFIN);
    var rest = total % PIPS_PER_GRIFFIN;
    return { gold: g, silver: Math.floor(rest / PIPS_PER_SHARD), copper: rest % PIPS_PER_SHARD };
  }
  // Builds the same markup as the Jinja `coins` macro.
  function coinsElement(total) {
    var c = splitPips(total);
    var wrap = document.createElement("span");
    wrap.className = "coins";
    [["g", c.gold, "Griffin", "G"], ["s", c.silver, "Shard", "S"], ["c", c.copper, "Pip", "P"]].forEach(function (row, i) {
      var show = row[1] > 0 || (i === 2 && !c.gold && !c.silver);
      if (!show) return;
      var coin = document.createElement("span");
      coin.className = "coin coin--" + row[0];
      coin.innerHTML = '<span class="coin__disc" aria-hidden="true">' + row[3] + "</span><b></b><span class=\"coin__unit\"></span>";
      coin.querySelector("b").textContent = row[1];
      coin.querySelector(".coin__unit").textContent = " " + row[2] + (row[1] === 1 ? "" : "s");
      wrap.appendChild(coin);
    });
    return wrap;
  }

  /* ------------------------------------------------------- order tracker */
  function loadPending() {
    try { return JSON.parse(sessionStorage.getItem(STORE_KEY)) || []; } catch (e) { return []; }
  }
  function savePending(list) {
    try { sessionStorage.setItem(STORE_KEY, JSON.stringify(list)); } catch (e) { /* private mode: fine */ }
  }

  var pending = loadPending();
  var pollTimer = null;
  var failures = 0;
  var listeners = []; // basket.js listens to hear when its orders land

  function onUpdate(fn) { listeners.push(fn); }
  function emit(purchase) { listeners.forEach(function (fn) { fn(purchase); }); }

  function updateBadge() {
    var badge = document.querySelector("[data-owl-badge]");
    var count = document.querySelector("[data-owl-count]");
    if (badge && count) {
      count.textContent = pending.length;
      badge.hidden = pending.length === 0;
    }
    // The family clock knows when you have orders in flight.
    document.documentElement.classList.toggle("peril", pending.length > 0);
  }

  function track(purchase) {
    pending.push({ id: purchase.id, name: purchase.product_name, quantity: purchase.quantity });
    savePending(pending);
    updateBadge();
    schedulePoll(POLL_MS);
  }

  function schedulePoll(delay) {
    clearTimeout(pollTimer);
    if (!pending.length) return;
    pollTimer = setTimeout(poll, delay);
  }

  function poll() {
    ShopAPI.getAllBoughtItems().then(function (purchases) {
      failures = 0;
      var byId = {};
      purchases.forEach(function (p) { byId[p.id] = p; });
      pending = pending.filter(function (entry) {
        var p = byId[entry.id];
        if (!p) return false; // forgotten by the server (e.g. a restart): stop tracking
        if (p.status === "pending") return true;
        announce(p);
        emit(p);
        return false;
      });
      savePending(pending);
      updateBadge();
      document.dispatchEvent(new CustomEvent("shop:purchases", { detail: purchases }));
      schedulePoll(POLL_MS);
    }).catch(function () {
      failures++;
      schedulePoll(Math.min(POLL_MS * Math.pow(2, failures), 20000)); // back off gently
    });
  }

  var DONE_LINES = [
    "Delivered by a slightly singed owl.",
    "Wrapped, tested and only mildly exploded.",
    "Reynard says thanks. Rufus says spend more.",
    "It's in your ledger. The ledger is pleased.",
  ];

  function announce(p) {
    if (p.status === "completed") {
      Magic.fireworks(7);
      Magic.toast({
        type: "success",
        title: "Mischief delivered: " + p.product_name + (p.quantity > 1 ? " × " + p.quantity : ""),
        text: DONE_LINES[Math.floor(Math.random() * DONE_LINES.length)],
      });
    } else if (p.status === "failed") {
      Magic.toast({
        type: "error",
        title: "Order confiscated: " + p.product_name,
        text: p.failure_reason || "Something went wrong on the way.",
        duration: 9000,
      });
    }
  }

  /* ------------------------------------------------------------- start */
  updateBadge();
  if (pending.length) schedulePoll(300);

  window.Shop = {
    coinsElement: coinsElement,
    track: track,
    onUpdate: onUpdate,
    splitPips: splitPips,
    hasPending: function () { return pending.length > 0; },
  };
})();

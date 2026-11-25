/* ==========================================================================
   mock-api.js: a pretend backend that lives in the browser.

   It imitates the future asynchronous (Kafka) purchase flow:
     buy()               resolves quickly with status "pending" (order ACCEPTED)
     getAllBoughtItems() later reports "completed" or "failed" (order PROCESSED)

   Purchases are kept in localStorage, so they survive page reloads.
   Delete this file (and its <script> tag) once the real backend exists.

   Demo helpers (in the address bar):
     ?mock=fail    every new order fails
     ?mock=ok      no order fails
     ?mock=reset   wipe the mock purchase history
   ========================================================================== */
(function () {
  "use strict";

  var STORE_KEY = "mmc-mock-purchases";
  var MODE_KEY = "mmc-mock-mode";
  var MIN_PROCESSING_MS = 3000;
  var MAX_PROCESSING_MS = 7000;
  var FAILURE_RATE = 0.1;

  var FAILURE_REASONS = [
    "Intercepted by a school inspector. Order confiscated.",
    "Your owl flew into a very grumpy oak. It's fine. The parcel isn't.",
    "The caretaker found the parcel and filed it under 'Forbidden'.",
    "A magpie got into the stockroom. Your Griffins are gone; so is the magpie.",
    "The order got befuddled in transit. Please try again.",
  ];

  // Handle the ?mock=... demo switches.
  var flag = new URLSearchParams(location.search).get("mock");
  try {
    if (flag === "reset") localStorage.removeItem(STORE_KEY);
    if (flag === "fail" || flag === "ok") sessionStorage.setItem(MODE_KEY, flag);
  } catch (e) { /* storage blocked: the mock still works for this page */ }

  var memory = []; // fallback when localStorage is unavailable

  function load() {
    try { return JSON.parse(localStorage.getItem(STORE_KEY)) || []; } catch (e) { return memory; }
  }
  function save(list) {
    memory = list;
    try { localStorage.setItem(STORE_KEY, JSON.stringify(list)); } catch (e) { /* keep in memory */ }
  }
  function failureRate() {
    try {
      var mode = sessionStorage.getItem(MODE_KEY);
      if (mode === "fail") return 1;
      if (mode === "ok") return 0;
    } catch (e) { /* ignore */ }
    return FAILURE_RATE;
  }
  function randomId() {
    var bytes = new Uint8Array(16);
    crypto.getRandomValues(bytes);
    return Array.prototype.map.call(bytes, function (b) { return b.toString(16).padStart(2, "0"); }).join("");
  }
  // Simulated network latency.
  function later(value, ms) {
    return new Promise(function (resolve) { setTimeout(function () { resolve(value); }, ms); });
  }

  // What callers see: the stored record with its status worked out "now".
  function publicView(r, now) {
    var done = now >= r.readyAt;
    var status = done ? r.outcome : "pending";
    return {
      id: r.id,
      product_slug: r.product_slug,
      product_name: r.product_name,
      quantity: r.quantity,
      unit_price: r.unit_price,
      total_price: r.unit_price * r.quantity,
      status: status,
      failure_reason: status === "failed" ? r.reason : null,
      created_at: new Date(r.createdAt).toISOString(),
      updated_at: new Date(done ? r.readyAt : r.createdAt).toISOString(),
    };
  }

  window.MockShopAPI = {
    buy: function (product, quantity) {
      var now = Date.now();
      var fails = Math.random() < failureRate();
      var record = {
        id: randomId(),
        product_slug: product.slug,
        product_name: product.name,
        quantity: quantity,
        unit_price: product.price,
        createdAt: now,
        readyAt: now + MIN_PROCESSING_MS + Math.random() * (MAX_PROCESSING_MS - MIN_PROCESSING_MS),
        outcome: fails ? "failed" : "completed",
        reason: fails ? FAILURE_REASONS[Math.floor(Math.random() * FAILURE_REASONS.length)] : null,
      };
      var list = load();
      list.unshift(record);
      save(list.slice(0, 100));
      return later(publicView(record, now), 500 + Math.random() * 500);
    },

    getAllBoughtItems: function () {
      var now = Date.now();
      return later(load().map(function (r) { return publicView(r, now); }), 250);
    },
  };
})();

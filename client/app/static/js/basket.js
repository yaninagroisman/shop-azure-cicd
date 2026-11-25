/* ==========================================================================
   basket.js: the shopping basket (a drawer opened from the header)
     * "Add" buttons on product cards and the product page's form put things
       in the basket; nothing is bought until you check out.
     * Checking out sends one ShopAPI.buy(product, quantity) per line, the
       same API call as before, and hands each accepted order to the order
       tracker in shop.js, which announces it once it is delivered.
   The basket itself is a per-browser convenience kept in localStorage.
   ========================================================================== */
(function () {
  "use strict";
  var dialog = document.querySelector("[data-basket]");
  if (!dialog || !window.Shop || !window.ShopAPI) return;

  var KEY = "mmc-basket";
  var MAX_QTY = 10;
  var el = function (sel) { return dialog.querySelector(sel); };
  var linesBox = el("[data-basket-lines]"), emptyBox = el("[data-basket-empty]"), foot = el("[data-basket-foot]");
  var totalBox = el("[data-basket-total]"), checkoutBtn = el("[data-checkout]"), statusBox = el("[data-basket-status]");
  var openers = document.querySelectorAll("[data-basket-open]");

  /* ------------------------------------------------------------- storage */
  function load() {
    try { return JSON.parse(localStorage.getItem(KEY)) || []; } catch (e) { return []; }
  }
  function save() {
    try { localStorage.setItem(KEY, JSON.stringify(lines)); } catch (e) { /* private mode: the basket lasts this page only */ }
  }
  var lines = load(); // [{ slug, name, price (Pips), qty, img }]

  function clamp(n) { return Math.max(1, Math.min(MAX_QTY, n)); }
  function find(slug) { return lines.filter(function (l) { return l.slug === slug; })[0]; }
  function count() { return lines.reduce(function (n, l) { return n + l.qty; }, 0); }
  function total() { return lines.reduce(function (n, l) { return n + l.price * l.qty; }, 0); }

  function add(item, qty) {
    var line = find(item.slug);
    if (line) line.qty = clamp(line.qty + qty);
    else lines.push({ slug: item.slug, name: item.name, price: item.price, qty: clamp(qty), img: item.img });
    save();
    render();
  }

  /* -------------------------------------------------------------- render */
  function renderCount() {
    var n = count();
    Array.prototype.forEach.call(openers, function (b) {
      var c = b.querySelector("[data-basket-count]");
      if (c) { c.textContent = n; c.hidden = n === 0; }
      b.setAttribute("aria-label", "Basket, " + (n === 1 ? "1 item" : n + " items"));
    });
  }

  function buildLine(l) {
    var li = document.createElement("li");
    li.className = "basket-line";
    li.setAttribute("data-slug", l.slug);
    li.innerHTML =
      '<img class="basket-line__img" alt="" width="640" height="640" loading="lazy">' +
      '<div class="basket-line__main"><a class="basket-line__name"></a><span class="basket-line__each"></span></div>' +
      '<div class="qty__control qty__control--small">' +
        '<button type="button" class="qty__btn" data-line-step="-1">−</button>' +
        '<output class="basket-line__qty"></output>' +
        '<button type="button" class="qty__btn" data-line-step="1">+</button>' +
      "</div>" +
      '<span class="basket-line__price"></span>' +
      '<button type="button" class="basket-line__remove" data-line-remove>×</button>';
    if (l.img) li.querySelector("img").src = l.img;
    var a = li.querySelector(".basket-line__name");
    a.textContent = l.name;
    a.href = "/product/" + encodeURIComponent(l.slug);
    var each = li.querySelector(".basket-line__each");
    each.appendChild(Shop.coinsElement(l.price));
    each.appendChild(document.createTextNode(" each"));
    li.querySelector(".basket-line__qty").textContent = l.qty;
    li.querySelector(".basket-line__price").appendChild(Shop.coinsElement(l.price * l.qty));
    var minus = li.querySelector('[data-line-step="-1"]');
    minus.setAttribute("aria-label", "One fewer " + l.name);
    minus.disabled = l.qty <= 1;
    var plus = li.querySelector('[data-line-step="1"]');
    plus.setAttribute("aria-label", "One more " + l.name);
    plus.disabled = l.qty >= MAX_QTY;
    li.querySelector("[data-line-remove]").setAttribute("aria-label", "Remove " + l.name + " from the basket");
    return li;
  }

  function render() {
    linesBox.innerHTML = "";
    lines.forEach(function (l) { linesBox.appendChild(buildLine(l)); });
    var empty = lines.length === 0;
    emptyBox.hidden = !empty || !statusBox.hidden;
    foot.hidden = empty;
    totalBox.innerHTML = "";
    totalBox.appendChild(Shop.coinsElement(total()));
    renderCount();
  }

  linesBox.addEventListener("click", function (e) {
    var li = e.target.closest(".basket-line");
    if (!li) return;
    var line = find(li.getAttribute("data-slug"));
    var step = e.target.closest("[data-line-step]");
    if (step && line) {
      line.qty = clamp(line.qty + parseInt(step.getAttribute("data-line-step"), 10));
      save(); render();
      var again = linesBox.querySelector('[data-slug="' + line.slug + '"] [data-line-step="' + step.getAttribute("data-line-step") + '"]');
      if (again && !again.disabled) again.focus(); else el("[data-basket-close]").focus();
    }
    if (e.target.closest("[data-line-remove]") && line) {
      lines.splice(lines.indexOf(line), 1);
      save(); render();
      var next = linesBox.querySelector("[data-line-remove]") || el("[data-basket-close]");
      next.focus();
    }
  });

  /* --------------------------------------------------- open and close */
  // A modal <dialog> sits above everything, so it borrows the sparks canvas
  // and the toasts while it is open (the door game does the same).
  var borrowed = ["[data-magic-canvas]", "[data-toasts]"].map(function (sel) {
    var node = document.querySelector(sel);
    return node && { node: node, home: node.parentNode };
  }).filter(Boolean);

  function open() {
    if (dialog.open) return;
    borrowed.forEach(function (b) { dialog.appendChild(b.node); });
    Array.prototype.forEach.call(document.querySelectorAll(".toast--info"), function (t) { t.remove(); }); // "added to the basket" notes are done
    render();
    dialog.showModal();
    el("[data-basket-close]").focus();
  }
  function close() { if (dialog.open) dialog.close(); }

  dialog.addEventListener("close", function () {
    borrowed.forEach(function (b) { b.home.appendChild(b.node); });
    if (!checkingOut && statusBox.classList.contains("order-status--done")) { statusBox.hidden = true; render(); }
  });
  dialog.addEventListener("click", function (e) {
    if (e.target === dialog || e.target.closest("[data-basket-close]")) close(); // backdrop or ×
  });
  document.addEventListener("click", function (e) {
    var opener = e.target.closest('[data-basket-open], a[href="#basket"]');
    if (!opener) return;
    e.preventDefault();
    var menu = document.querySelector("[data-nav-menu].is-open"), toggle = document.querySelector("[data-nav-toggle]");
    if (menu && toggle) toggle.click(); // close the mobile menu first
    open();
  });

  /* ------------------------------------------------------ adding things */
  function added(name, qty, from) {
    Magic.burstAt(from, { count: 18 });
    Array.prototype.forEach.call(openers, function (b) {
      b.classList.remove("is-bumped"); void b.offsetWidth; b.classList.add("is-bumped");
    });
    Magic.toast({
      title: "In the basket: " + name + (qty > 1 ? " × " + qty : ""),
      text: "Nothing is bought until you check out.",
      link: { href: "#basket", text: "Open the basket" },
    });
  }

  // Quick "Add" buttons on product cards
  document.addEventListener("click", function (e) {
    var btn = e.target.closest("[data-add]");
    if (!btn) return;
    var item = { slug: btn.getAttribute("data-add"), name: btn.getAttribute("data-name"), price: parseInt(btn.getAttribute("data-price"), 10), img: btn.getAttribute("data-img") };
    add(item, 1);
    added(item.name, 1, btn);
  });

  // The product page form: quantity, running total, "Add to basket"
  var form = document.querySelector("[data-add-form]");
  if (form) {
    var item = { slug: form.getAttribute("data-slug"), name: form.getAttribute("data-name"), price: parseInt(form.getAttribute("data-price"), 10), img: form.getAttribute("data-img") };
    var qtyInput = form.querySelector("[data-qty]");
    var formTotal = form.querySelector("[data-total]");
    var qty = function () { var n = parseInt(qtyInput.value, 10); return clamp(isNaN(n) ? 1 : n); };
    var refresh = function () { formTotal.innerHTML = ""; formTotal.appendChild(Shop.coinsElement(item.price * qty())); };
    form.addEventListener("click", function (e) {
      var step = e.target.closest("[data-qty-step]");
      if (!step) return;
      qtyInput.value = clamp(qty() + parseInt(step.getAttribute("data-qty-step"), 10));
      refresh();
    });
    qtyInput.addEventListener("input", refresh);
    qtyInput.addEventListener("change", function () { qtyInput.value = qty(); refresh(); });
    form.addEventListener("submit", function (e) {
      e.preventDefault();
      add(item, qty());
      added(item.name, qty(), form.querySelector("[type=submit]"));
    });
    refresh();
  }

  /* ----------------------------------------------------------- checkout */
  var OWL = '<svg viewBox="0 0 24 24"><use href="#i-owl"/></svg>';
  var STAR = '<svg viewBox="0 0 20 20"><use href="#i-star"/></svg>';
  var checkingOut = false;
  var watching = {}; // purchase id -> "pending" | "completed" | "failed", for the last checkout

  function showStatus(state, title, text, step) {
    statusBox.hidden = false;
    statusBox.className = "order-status order-status--" + state;
    statusBox.innerHTML = '<span class="order-status__icon" aria-hidden="true">' + (state === "completed" ? STAR : OWL) + "</span>" +
      '<p class="order-status__title"></p><p class="order-status__text"></p>';
    statusBox.querySelector(".order-status__title").textContent = title;
    statusBox.querySelector(".order-status__text").textContent = text;
    if (step >= 0) {
      var steps = document.createElement("ol");
      steps.className = "order-status__steps";
      steps.setAttribute("aria-label", "Order progress");
      ["Owl sent", "Accepted", "Delivered"].forEach(function (label, i) {
        var li = document.createElement("li");
        li.textContent = label;
        if (i < step || step === 3) li.className = "is-done";
        else if (i === step) { li.className = "is-current"; li.setAttribute("aria-current", "step"); }
        steps.appendChild(li);
      });
      statusBox.appendChild(steps);
    }
    if (state === "completed" || state === "pending") statusBox.classList.add("order-status--done");
    emptyBox.hidden = true;
  }

  function summarise() {
    var ids = Object.keys(watching);
    if (!ids.length) return;
    var left = ids.filter(function (id) { return watching[id] === "pending"; }).length;
    var failed = ids.filter(function (id) { return watching[id] === "failed"; }).length;
    if (left) {
      showStatus("pending", "Order accepted!",
        (ids.length === 1 ? "The shop received your owl." : "The shop received all " + ids.length + " parcels.") +
        " Rufus and Reynard are wrapping it now (and testing it first, sorry). You'll find it in the Ledger in the shop window.", 1);
    } else if (failed === ids.length) {
      showStatus("failed", "Order confiscated", "None of it survived the journey. The toasts have the details.", -1);
    } else {
      showStatus("completed", "Mischief delivered!",
        failed ? (ids.length - failed) + " of " + ids.length + " parcels arrived; the rest were confiscated on the way." : "Processed and delivered. Enjoy responsibly, or at least quietly.", 3);
    }
  }

  Shop.onUpdate(function (p) {
    if (!(p.id in watching)) return;
    watching[p.id] = p.status;
    summarise();
  });

  function checkout() {
    if (checkingOut || !lines.length) return;
    checkingOut = true;
    checkoutBtn.disabled = true;
    checkoutBtn.classList.add("is-busy");
    watching = {};
    showStatus("sending", "Sending your owl…", "Rolling up the order and tying it to a very determined owl.", 0);
    foot.hidden = true;

    var errors = [];
    // One order per basket line, one after another, like posting several letters.
    lines.slice().reduce(function (chain, line) {
      return chain.then(function () {
        return ShopAPI.buy({ slug: line.slug, name: line.name, price: line.price }, line.qty).then(function (purchase) {
          Shop.track(purchase);
          watching[purchase.id] = "pending";
          lines.splice(lines.indexOf(line), 1);
          save();
        }, function (err) {
          errors.push(line.name + ": " + err.message);
        });
      });
    }, Promise.resolve()).then(function () {
      checkingOut = false;
      checkoutBtn.disabled = false;
      checkoutBtn.classList.remove("is-busy");
      render();
      if (errors.length) {
        showStatus("error", "The owl never arrived", errors.join(" ") + " Those items are still in your basket; try again in a moment.", -1);
      } else {
        summarise();
      }
      statusBox.focus();
    });
  }
  checkoutBtn.addEventListener("click", checkout);

  render();
  window.Basket = { open: open, close: close, add: add, lines: function () { return lines.slice(); } };
})();

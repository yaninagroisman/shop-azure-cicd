/* ==========================================================================
   magic.js: shared enchantments for every page
     * Magic.burst() / Magic.fireworks(): canvas sparks & fireworks
     * Magic.toast(): little parchment notices
     * mobile navigation
     * the Prowler's Chart footprints and the hidden spells
   ========================================================================== */
(function () {
  "use strict";

  var html = document.documentElement;
  var motionQuery = window.matchMedia("(prefers-reduced-motion: reduce)");
  function reduced() { return motionQuery.matches; }

  var PALETTES = {
    gold: ["#fff4d6", "#f0cf7a", "#f2b84b", "#f28c3a"],
    mischief: ["#f28c3a", "#d4612a", "#f0cf7a", "#c9a8e0", "#e46fb4", "#fff4d6"],
    pink: ["#ff8fc6", "#ffd2ec", "#e46fb4"],
    green: ["#c9e08a", "#9cc25a", "#5d7a3a"],
  };

  /* ---------------------------------------------------------------- canvas */
  var canvas = document.querySelector("[data-magic-canvas]");
  var ctx = canvas ? canvas.getContext("2d") : null;
  var particles = [];
  var rockets = [];
  var running = false;
  var dpr = 1;

  function resize() {
    if (!canvas) return;
    dpr = Math.min(window.devicePixelRatio || 1, 2);
    canvas.width = Math.floor(window.innerWidth * dpr);
    canvas.height = Math.floor(window.innerHeight * dpr);
    ctx.setTransform(dpr, 0, 0, dpr, 0, 0);
  }
  resize();
  window.addEventListener("resize", resize, { passive: true });

  function pick(list) { return list[Math.floor(Math.random() * list.length)]; }

  function spawn(x, y, opts) {
    var angle = opts.angle != null ? opts.angle : Math.random() * Math.PI * 2;
    var speed = (opts.speed || 4) * (0.35 + Math.random() * 0.75);
    var life = (opts.life || 50) * (0.7 + Math.random() * 0.6);
    particles.push({
      x: x, y: y,
      vx: Math.cos(angle) * speed, vy: Math.sin(angle) * speed,
      life: life, max: life,
      size: (opts.size || 2.2) * (0.6 + Math.random() * 0.8),
      color: pick(opts.colors || PALETTES.gold),
      gravity: opts.gravity != null ? opts.gravity : 0.08,
      drag: opts.drag || 0.96,
      star: Math.random() < (opts.stars || 0.25),
    });
  }

  function burst(x, y, opts) {
    if (!ctx || reduced()) return;
    opts = opts || {};
    var count = opts.count || 26;
    for (var i = 0; i < count; i++) spawn(x, y, opts);
    start();
  }

  function burstAt(el, opts) {
    var r = el.getBoundingClientRect();
    burst(r.left + r.width / 2, r.top + r.height / 2, opts);
  }

  /* Fireworks: rockets climb, then burst. Optionally from inside a box (an element rect). */
  function fireworks(count, box) {
    if (!ctx || reduced()) return;
    count = count || 6;
    var area = box || { left: 0, top: 0, width: window.innerWidth, height: window.innerHeight };
    for (var i = 0; i < count; i++) {
      (function (delay) {
        setTimeout(function () {
          var x = area.left + area.width * (0.15 + Math.random() * 0.7);
          rockets.push({
            x: x, y: area.top + area.height,
            vx: (Math.random() - 0.5) * 1.5,
            vy: -(area.height / 60) * (0.85 + Math.random() * 0.3) - 3,
            targetY: area.top + area.height * (0.15 + Math.random() * 0.3),
            colors: pick([PALETTES.mischief, PALETTES.gold, ["#e46fb4", "#c9a8e0", "#fff4d6"], ["#f28c3a", "#fff4d6"]]),
          });
          start();
        }, delay);
      })(i * 260 + Math.random() * 180);
    }
  }

  function start() {
    if (!running) { running = true; requestAnimationFrame(frame); }
  }

  function drawStar(x, y, r) {
    ctx.beginPath();
    ctx.moveTo(x, y - r * 2);
    ctx.quadraticCurveTo(x, y, x + r * 2, y);
    ctx.quadraticCurveTo(x, y, x, y + r * 2);
    ctx.quadraticCurveTo(x, y, x - r * 2, y);
    ctx.quadraticCurveTo(x, y, x, y - r * 2);
    ctx.fill();
  }

  function frame() {
    ctx.clearRect(0, 0, canvas.width / dpr, canvas.height / dpr);
    ctx.globalCompositeOperation = "lighter";

    for (var r = rockets.length - 1; r >= 0; r--) {
      var k = rockets[r];
      k.x += k.vx; k.y += k.vy; k.vy *= 0.985;
      ctx.fillStyle = "#fff4d6";
      ctx.beginPath(); ctx.arc(k.x, k.y, 2.2, 0, Math.PI * 2); ctx.fill();
      spawn(k.x, k.y + 4, { speed: 0.6, life: 18, size: 1.4, gravity: 0.02, colors: PALETTES.gold, stars: 0 });
      if (k.y <= k.targetY || k.vy > -1) {
        rockets.splice(r, 1);
        var n = 60 + Math.floor(Math.random() * 30);
        for (var i = 0; i < n; i++) {
          spawn(k.x, k.y, { speed: 5.5, life: 70, size: 2.4, gravity: 0.05, drag: 0.965, colors: k.colors, stars: 0.3 });
        }
      }
    }

    for (var p = particles.length - 1; p >= 0; p--) {
      var q = particles[p];
      q.vx *= q.drag; q.vy = q.vy * q.drag + q.gravity;
      q.x += q.vx; q.y += q.vy;
      q.life -= 1;
      if (q.life <= 0) { particles.splice(p, 1); continue; }
      var a = q.life / q.max;
      ctx.globalAlpha = a;
      ctx.fillStyle = q.color;
      if (q.star) { drawStar(q.x, q.y, q.size * 0.9); }
      else { ctx.beginPath(); ctx.arc(q.x, q.y, q.size * (0.5 + a * 0.5), 0, Math.PI * 2); ctx.fill(); }
    }
    ctx.globalAlpha = 1;

    if (particles.length || rockets.length) { requestAnimationFrame(frame); }
    else { running = false; ctx.clearRect(0, 0, canvas.width, canvas.height); }
  }

  // Sparks on chosen interactions.
  document.addEventListener("click", function (e) {
    var el = e.target.closest("[data-sparks], .chip, .btn--demo, .qty__btn");
    if (!el) return;
    burst(e.clientX || 0, e.clientY || 0, { count: el.matches(".chip, .qty__btn") ? 10 : 26, speed: 4 });
  });

  // A gentle glitter trail while the pointer moves over magic buttons and big stages.
  var lastTrail = 0;
  document.addEventListener("pointermove", function (e) {
    if (e.pointerType !== "mouse" || reduced()) return;
    var now = performance.now();
    if (now - lastTrail < 40) return;
    if (!e.target.closest || !e.target.closest(".btn--magic, .stage--big")) return;
    lastTrail = now;
    spawn(e.clientX, e.clientY, { speed: 1.2, life: 32, size: 1.8, gravity: -0.02, colors: PALETTES.gold, stars: 0.5 });
    start();
  }, { passive: true });

  /* ---------------------------------------------------------------- toasts */
  var toastBox = document.querySelector("[data-toasts]");
  function toast(opts) {
    if (!toastBox) return;
    var el = document.createElement("div");
    el.className = "toast toast--" + (opts.type || "info");
    var title = document.createElement("p");
    title.className = "toast__title";
    title.textContent = opts.title || "";
    el.appendChild(title);
    if (opts.text || opts.link) {
      var text = document.createElement("p");
      text.className = "toast__text";
      if (opts.text) text.appendChild(document.createTextNode(opts.text + (opts.link ? " " : "")));
      if (opts.link) {
        var a = document.createElement("a");
        a.href = opts.link.href; a.textContent = opts.link.text;
        text.appendChild(a);
      }
      el.appendChild(text);
    }
    var close = document.createElement("button");
    close.type = "button"; close.className = "toast__close"; close.setAttribute("aria-label", "Dismiss");
    close.textContent = "×";
    el.appendChild(close);

    function dismiss() {
      if (el.classList.contains("is-leaving")) return;
      el.classList.add("is-leaving");
      setTimeout(function () { el.remove(); }, reduced() ? 0 : 350);
    }
    close.addEventListener("click", dismiss);
    toastBox.appendChild(el);
    while (toastBox.children.length > 4) toastBox.firstElementChild.remove();
    setTimeout(dismiss, opts.duration || 6500);
    return el;
  }

  /* Page transitions live in CSS (@view-transition) and boot.js: the browser
     animates from the old page to the new one, and the home page then arrives
     in purple smoke. There is no JS exit animation on purpose: it froze
     half-way while the next page loaded. */

  /* -------------------------------------------------------- mobile nav menu */
  var toggle = document.querySelector("[data-nav-toggle]");
  var menu = document.querySelector("[data-nav-menu]");
  if (toggle && menu) {
    var setOpen = function (open) {
      toggle.setAttribute("aria-expanded", String(open));
      menu.classList.toggle("is-open", open);
      document.body.classList.toggle("menu-open", open);
      if (open) { var first = menu.querySelector("a"); if (first) setTimeout(function () { first.focus(); }, 50); }
    };
    toggle.addEventListener("click", function () { setOpen(toggle.getAttribute("aria-expanded") !== "true"); });
    document.addEventListener("keydown", function (e) {
      if (toggle.getAttribute("aria-expanded") !== "true") return;
      if (e.key === "Escape") { setOpen(false); toggle.focus(); }
      if (e.key === "Tab") { // keep focus inside the open menu
        var links = Array.prototype.slice.call(menu.querySelectorAll("a"));
        var last = links[links.length - 1];
        if (!e.shiftKey && document.activeElement === last) { e.preventDefault(); toggle.focus(); }
        else if (e.shiftKey && document.activeElement === toggle) { e.preventDefault(); last.focus(); }
      }
    });
    window.addEventListener("resize", function () { if (window.innerWidth > 920) setOpen(false); });
  }

  /* ------------------------------------------------------------- footprints */
  var footLayer = document.querySelector("[data-footprints]");

  // One walk = a trail of alternating footprints crossing part of the screen.
  function walk(layer, opts) {
    if (!layer || reduced()) return;
    opts = opts || {};
    var w = layer.clientWidth || window.innerWidth, h = layer.clientHeight || window.innerHeight;
    var x = opts.x != null ? opts.x : Math.random() * w;
    var y = opts.y != null ? opts.y : h + 20;
    var angle = opts.angle != null ? opts.angle : -Math.PI / 2 + (Math.random() - 0.5) * 1.6;
    var steps = opts.steps || 16;
    var stride = 34;
    for (var i = 0; i < steps; i++) {
      angle += (Math.random() - 0.5) * 0.25; // a slightly wandering, sneaky gait
      x += Math.cos(angle) * stride;
      y += Math.sin(angle) * stride;
      var side = i % 2 ? 1 : -1;
      var px = x + Math.cos(angle + Math.PI / 2) * 9 * side;
      var py = y + Math.sin(angle + Math.PI / 2) * 9 * side;
      var deg = angle * 180 / Math.PI + 90;
      var f = document.createElement("div");
      f.className = "footprint";
      f.style.left = px + "px";
      f.style.top = py + "px";
      f.style.transform = "rotate(" + deg + "deg)" + (side > 0 ? " scaleX(-1)" : "");
      f.style.animationDelay = (i * 0.3) + "s";
      f.innerHTML = '<svg viewBox="0 0 20 34"><use href="#i-foot"/></svg>';
      if (opts.name && i === Math.floor(steps / 2)) {
        var label = document.createElement("span");
        label.className = "footprint__name";
        label.textContent = opts.name;
        label.style.setProperty("--unrot", (-deg) + "deg");
        if (side > 0) label.style.transform = "scaleX(-1) rotate(" + (-deg) + "deg)";
        f.appendChild(label);
      }
      layer.appendChild(f);
      (function (node, delay) { setTimeout(function () { node.remove(); }, delay); })(f, i * 300 + 3600);
    }
  }

  // Occasionally, mysterious footprints sneak across the shop.
  function scheduleWander(first) {
    var delay = first ? 9000 + Math.random() * 10000 : 28000 + Math.random() * 30000;
    setTimeout(function () {
      if (!document.hidden) walk(footLayer);
      scheduleWander(false);
    }, delay);
  }
  scheduleWander(true);

  /* ---------------------------------------------------- the Prowler's Chart */
  var chart = document.querySelector("[data-chart]");
  var walkersLayer = document.querySelector("[data-chart-walkers]");
  var walkerTimer = null;
  var lastFocus = null;
  var NAMES = ["Rufus", "Reynard", "Barnaby", "Mr. Grimsby", "The caretaker's cat", "The school poltergeist", "Mabel (on her lunch break)", "You"];

  function openMap() {
    if (!chart || !chart.hidden) return;
    lastFocus = document.activeElement;
    chart.hidden = false;
    var btn = chart.querySelector("[data-chart-close]");
    if (btn) btn.focus();
    var n = 0;
    var go = function () {
      var w = walkersLayer.clientWidth, h = walkersLayer.clientHeight; // footprints walk across the map itself
      var edge = n % 4;
      var opts = { name: NAMES[n % NAMES.length], steps: 14 };
      if (edge === 0) { opts.x = -20; opts.y = Math.random() * h; opts.angle = (Math.random() - 0.5) * 0.8; }
      if (edge === 1) { opts.x = w + 20; opts.y = Math.random() * h; opts.angle = Math.PI + (Math.random() - 0.5) * 0.8; }
      if (edge === 2) { opts.x = Math.random() * w; opts.y = h + 20; opts.angle = -Math.PI / 2 + (Math.random() - 0.5) * 0.8; }
      if (edge === 3) { opts.x = Math.random() * w; opts.y = -20; opts.angle = Math.PI / 2 + (Math.random() - 0.5) * 0.8; }
      walk(walkersLayer, opts);
      n++;
    };
    go();
    walkerTimer = setInterval(go, 1400);
  }

  function closeMap() {
    if (!chart || chart.hidden) return;
    chart.hidden = true;
    clearInterval(walkerTimer);
    if (walkersLayer) walkersLayer.innerHTML = "";
    toast({ title: "All clear.", text: "The chart is just a blank piece of parchment again. Nothing to see here, Mr. Grimsby." });
    if (lastFocus && lastFocus.focus) lastFocus.focus();
  }

  document.addEventListener("click", function (e) {
    if (e.target.closest("[data-chart-trigger]")) openMap();
    if (e.target.closest("[data-chart-close]")) closeMap();
  });

  /* ---------------------------------------------------------- typed spells */
  var typed = "";
  var SPELLS = {
    nothingupmysleeve: openMap,
    allclear: closeMap,
    lucerna: function () {
      html.classList.add("wandlight");
      toast({ title: "Lucerna!", text: "Your wand lights the way. Type “umbra” to put it out." });
    },
    umbra: function () {
      if (!html.classList.contains("wandlight")) return;
      html.classList.remove("wandlight");
      toast({ title: "Umbra.", text: "Lights back on. Mind the Bottled Bog." });
    },
    reserare: function () {
      var shop = document.querySelector("[data-storefront]");
      if (shop) { shop.classList.add("is-open"); burstAt(shop, { count: 40, colors: PALETTES.mischief }); }
      toast({ title: "Reserare!", text: "Unlocked. Though, for the record, the shop door is never locked. We want your money." });
    },
    advenio: function () {
      toast({ title: "Advenio Griffins!", text: "Nice try. The Griffins are staying in your pocket until you hit “Buy”." });
    },
  };

  document.addEventListener("keydown", function (e) {
    if (e.key === "Escape" && chart && !chart.hidden) { closeMap(); return; }
    var t = e.target;
    if (t && (t.isContentEditable || /^(INPUT|TEXTAREA|SELECT)$/.test(t.tagName))) return;
    if (!e.key || e.key.length !== 1 || e.ctrlKey || e.metaKey || e.altKey) return;
    var ch = e.key.toLowerCase();
    if (ch < "a" || ch > "z") return; // spaces & punctuation are ignored
    typed = (typed + ch).slice(-40);
    for (var spell in SPELLS) {
      if (typed.slice(-spell.length) === spell) { SPELLS[spell](); typed = ""; break; }
    }
  });

  document.addEventListener("pointermove", function (e) {
    if (!html.classList.contains("wandlight")) return;
    html.style.setProperty("--mx", e.clientX + "px");
    html.style.setProperty("--my", e.clientY + "px");
  }, { passive: true });

  /* ------------------------------------------------- storefront & the clock */
  var shopFront = document.querySelector("[data-storefront]");
  if (shopFront) {
    var signClicks = 0, signTimer = null;
    shopFront.addEventListener("click", function (e) {
      var spot = e.target.closest(".hotspot");
      var x = e.clientX, y = e.clientY;
      if (spot && !x && !y) { var r = spot.getBoundingClientRect(); x = r.left + r.width / 2; y = r.top + r.height / 2; } // keyboard
      if (e.target.closest(".shop-door")) {
        // The door swings open, light floods out... and the stock makes a run for it (game.js).
        shopFront.classList.add("is-open");
        burst(x, y, { count: 30, colors: PALETTES.mischief });
        document.dispatchEvent(new CustomEvent("shop:door-opened"));
      }
      if (e.target.closest(".hanging-sign")) {
        spot.classList.remove("is-knocked"); void spot.offsetWidth; spot.classList.add("is-knocked");
        signClicks++;
        clearTimeout(signTimer);
        signTimer = setTimeout(function () { signClicks = 0; }, 1500);
        burst(x, y, { count: 8 });
        if (signClicks >= 3) { signClicks = 0; showPoster(); }
      }
    });
  }

  function showPoster() {
    if (document.querySelector(".secret-poster")) return;
    var p = document.createElement("div");
    p.className = "secret-poster";
    p.setAttribute("role", "dialog");
    p.setAttribute("aria-label", "A poster from the shop window");
    p.innerHTML =
      '<p class="eyebrow" style="color:#3f1650">From the back of the shop window</p>' +
      "<p>Afraid of the dark?</p>" +
      '<p class="secret-poster__big">Be the dark.</p>' +
      "<p>Instant Midnight Powder. Now in pocket size. Results not guaranteed, giggling is.</p>" +
      '<button class="btn btn--ink btn--small" type="button">Roll it back up</button>';
    document.body.appendChild(p);
    var btn = p.querySelector("button");
    btn.focus();
    btn.addEventListener("click", function () { p.remove(); });
    burstAt(p, { count: 50, colors: PALETTES.mischief });
  }

  var clock = document.querySelector("[data-clock]");
  if (clock) {
    var clockClicks = 0;
    clock.addEventListener("click", function () {
      clockClicks++;
      if (clockClicks === 3) {
        clockClicks = 0;
        html.classList.add("peril");
        toast({ title: "Grave Danger!", text: "Rufus and Reynard are in grave danger. As usual. They're fine. Probably testing something." });
        setTimeout(function () { if (!window.Shop || !Shop.hasPending()) html.classList.remove("peril"); }, 4000);
      }
    });
  }

  // Say hello to anyone who opens the developer console.
  if (window.console) {
    console.log("%cMarvellous Mischief Co.", "font: 900 22px Fraunces, serif; color: #f28c3a");
    console.log("%cPoking around the back of the shop? Try typing: nothing up my sleeve...", "font-style: italic; color: #c9a8e0");
  }

  window.Magic = {
    reduced: reduced, burst: burst, burstAt: burstAt, fireworks: fireworks, toast: toast, walk: walk,
    palettes: PALETTES,
  };
})();

/* ==========================================================================
   game.js: "Mischief on the Loose", the door mini-game on the home page.
   Push the shop door and the stock makes a run for it: product photos float
   up out of the doorway. Catch as many as you can in 30 seconds.
     * stock             1–2 Griffins (Pocket Fluffs 3, a runaway gold Griffin 5)
     * Diversion Cracker −3 and a bang
     * Instant Midnight  +1, then the lights go out for a moment
   Every item is a real <button>, so it can be caught with the keyboard too.
   The best score is a per-browser convenience in localStorage.
   ========================================================================== */
(function () {
  "use strict";
  var dialog = document.querySelector("[data-game]");
  if (!dialog || typeof dialog.showModal !== "function") return;

  var arena = dialog.querySelector("[data-game-arena]");
  var stock = Array.prototype.slice.call(dialog.querySelector("[data-game-stock]").content.querySelectorAll("img"));
  var el = function (sel) { return dialog.querySelector(sel); };
  var scoreEl = el("[data-game-score]"), timeEl = el("[data-game-time]"), bestEl = el("[data-game-best]");
  var intro = el("[data-game-intro]"), result = el("[data-game-result]"), live = el("[data-game-live]");

  var ROUND = 30;                       // seconds
  var BEST_KEY = "mmc-door-game-best";
  var POINTS = { coin: 5, puffs: 3, decoy: -3, darkness: 1 };
  var QUIPS = { coin: "Ka-ching!", puffs: "Squeak!", decoy: "BANG!", darkness: "Lights out!" };
  var VALUABLE = ["snackbox", "whizbang", "dream", "ears"]; // the pricier stock: 2 Griffins

  var items = [], score = 0, timeLeft = ROUND, running = false, last = 0, spawnIn = 0, elapsed = 0, raf = 0;
  var reduced = function () { return window.Magic && Magic.reduced(); };

  function readBest() { try { return parseInt(localStorage.getItem(BEST_KEY), 10) || 0; } catch (e) { return 0; } }
  function saveBest(v) { try { localStorage.setItem(BEST_KEY, String(v)); } catch (e) { /* private mode: fine */ } }

  function pointsFor(effect) {
    if (effect in POINTS) return POINTS[effect];
    return VALUABLE.indexOf(effect) !== -1 ? 2 : 1;
  }

  /* ------------------------------------------------------------- spawning */
  function pick() {
    var r = Math.random();
    var find = function (fx) { return stock.filter(function (i) { return i.dataset.effect === fx; })[0]; };
    if (r < 0.08) return find("coin");
    if (r < 0.24) return find("decoy");          // hazards get more common as you go
    if (r < 0.31) return find("darkness");
    var plain = stock.filter(function (i) { return ["coin", "decoy", "darkness"].indexOf(i.dataset.effect) === -1; });
    return plain[Math.floor(Math.random() * plain.length)];
  }

  function spawn() {
    var W = arena.clientWidth, H = arena.clientHeight;
    var src = pick(), effect = src.dataset.effect;
    var base = Math.min(W, H);   // big enough for a fingertip on phones
    var size = Math.round(effect === "coin" ? Math.max(56, base * 0.09) : Math.max(84, base * 0.17));
    var btn = document.createElement("button");
    btn.type = "button";
    btn.className = "game__item game__item--" + effect;
    btn.setAttribute("aria-label", "Catch " + src.alt);
    btn.appendChild(src.cloneNode(true)).alt = "";
    btn.style.width = btn.style.height = size + "px";
    arena.appendChild(btn);

    var level = elapsed / ROUND;                 // 0 → 1 over the round: things get faster
    var speed = (H * (0.16 + Math.random() * 0.12)) * (1 + level * 0.9) * (effect === "coin" ? 1.5 : 1) * (reduced() ? 0.6 : 1);
    var item = {
      el: btn, effect: effect, size: size,
      x0: W / 2 - size / 2 + (Math.random() - 0.5) * W * 0.25,   // out of the doorway…
      drift: (Math.random() - 0.5) * W * 0.5,                     // …then away to either side
      y: H + size * 0.2, vy: -speed,
      sway: 10 + Math.random() * 26, phase: Math.random() * 6.28, spin: (Math.random() - 0.5) * 30,
      age: 0, caught: false,
    };
    btn.addEventListener("click", function (e) { catchItem(item, e); });
    items.push(item);
  }

  /* -------------------------------------------------------------- catching */
  function catchItem(item, e) {
    if (!running || item.caught) return;
    item.caught = true;
    var pts = pointsFor(item.effect);
    score = Math.max(0, score + pts);
    scoreEl.textContent = score;
    live.textContent = (pts > 0 ? "+" : "") + pts + ". Total " + score + " Griffins.";

    var r = item.el.getBoundingClientRect();
    var cx = e && e.clientX ? e.clientX : r.left + r.width / 2, cy = e && e.clientY ? e.clientY : r.top + r.height / 2;
    floatLabel(cx, cy, (pts > 0 ? "+" : "") + pts + (QUIPS[item.effect] ? " " + QUIPS[item.effect] : ""), pts < 0);

    if (window.Magic) {
      var palette = item.effect === "decoy" ? Magic.palettes.mischief : item.effect === "puffs" ? Magic.palettes.pink : Magic.palettes.gold;
      Magic.burst(cx, cy, { count: item.effect === "decoy" ? 46 : 22, colors: palette, speed: item.effect === "decoy" ? 7 : 4 });
    }
    if (item.effect === "decoy" && !reduced()) { dialog.classList.remove("is-shaking"); void dialog.offsetWidth; dialog.classList.add("is-shaking"); }
    if (item.effect === "darkness") {
      dialog.classList.add("is-dark");
      clearTimeout(dialog._dark);
      dialog._dark = setTimeout(function () { dialog.classList.remove("is-dark"); }, 1800);
    }
    var hadFocus = document.activeElement === item.el;
    item.el.classList.add("is-caught");
    item.el.disabled = true;
    if (hadFocus) arena.focus(); // keyboard players: the next Tab goes to the next escaping item
    setTimeout(function () { remove(item); }, 450);
  }

  function floatLabel(x, y, text, bad) {
    var box = dialog.getBoundingClientRect();
    var s = document.createElement("span");
    s.className = "game__pop" + (bad ? " game__pop--bad" : "");
    s.textContent = text;
    s.style.left = (x - box.left) + "px";
    s.style.top = (y - box.top) + "px";
    dialog.appendChild(s);
    setTimeout(function () { s.remove(); }, 900);
  }

  function remove(item) {
    var i = items.indexOf(item);
    if (i !== -1) items.splice(i, 1);
    item.el.remove();
  }

  /* ------------------------------------------------------------------ loop */
  function frame(now) {
    if (!running) return;
    var dt = Math.min((now - last) / 1000, 0.05); // a hidden tab or a slow frame never teleports things
    last = now;
    elapsed += dt;
    timeLeft = Math.max(0, ROUND - elapsed);
    timeEl.textContent = Math.ceil(timeLeft);
    dialog.classList.toggle("is-hurry", timeLeft <= 5);

    spawnIn -= dt;
    if (spawnIn <= 0) {
      spawn();
      spawnIn = Math.max(0.32, 0.95 - (elapsed / ROUND) * 0.6) * (0.7 + Math.random() * 0.6);
    }

    for (var i = items.length - 1; i >= 0; i--) {
      var it = items[i];
      if (it.caught) continue;
      it.age += dt;
      it.y += it.vy * dt;
      var x = it.x0 + it.drift * Math.min(it.age / 3, 1) + Math.sin(it.phase + it.age * 2.2) * it.sway;
      it.el.style.transform = "translate3d(" + x.toFixed(1) + "px," + it.y.toFixed(1) + "px,0) rotate(" + (Math.sin(it.phase + it.age * 1.6) * it.spin).toFixed(1) + "deg)";
      if (it.y < -it.size * 1.2) remove(it); // it got away
    }

    if (timeLeft <= 0) return finish();
    raf = requestAnimationFrame(frame);
  }

  /* ------------------------------------------------------------ the round */
  function start() {
    items.slice().forEach(remove);
    score = 0; elapsed = 0; timeLeft = ROUND; spawnIn = 0.2;
    scoreEl.textContent = "0"; timeEl.textContent = String(ROUND);
    intro.hidden = true; result.hidden = true;
    dialog.classList.add("is-playing");
    dialog.classList.remove("is-dark", "is-hurry");
    running = true;
    last = performance.now();
    raf = requestAnimationFrame(frame);
    arena.focus();
  }

  function finish() {
    running = false;
    cancelAnimationFrame(raf);
    dialog.classList.remove("is-playing", "is-hurry", "is-dark");
    items.slice().forEach(function (it) { it.el.classList.add("is-gone"); setTimeout(function () { remove(it); }, 400); });

    var best = readBest(), record = score > best;
    if (record) { saveBest(score); best = score; }
    bestEl.textContent = best;
    el("[data-game-final]").textContent = score;
    el("[data-game-record]").hidden = !record || score === 0;
    el("[data-game-verdict]").textContent =
      score < 10 ? "Even the caretaker could have done better." :
      score < 25 ? "Not bad for a first-year." :
      score < 45 ? "Rufus and Reynard are genuinely impressed." :
                   "You're hired. Start Monday, bring a helmet.";
    result.hidden = false;
    var again = result.querySelector("[data-game-start]");
    if (again) again.focus();
    if (record && score > 0 && window.Magic) Magic.fireworks(5);
  }

  // A modal <dialog> sits above everything, so borrow the sparks canvas while it is open.
  var canvas = document.querySelector("[data-magic-canvas]"), canvasHome = canvas && canvas.parentNode;

  function open() {
    if (dialog.open) return;
    if (canvas) dialog.appendChild(canvas);
    bestEl.textContent = readBest();
    intro.hidden = false; result.hidden = true;
    dialog.showModal();
    var go = intro.querySelector("[data-game-start]");
    if (go) go.focus();
  }

  function close() {
    running = false;
    cancelAnimationFrame(raf);
    items.slice().forEach(remove);
    dialog.classList.remove("is-playing", "is-dark", "is-hurry");
    if (dialog.open) dialog.close();
  }

  /* --------------------------------------------------------------- wiring */
  // magic.js fires this when the storefront door is pushed; give the light a moment to spill out.
  document.addEventListener("shop:door-opened", function () { setTimeout(open, reduced() ? 0 : 550); });
  dialog.addEventListener("click", function (e) {
    if (e.target.closest("[data-game-start]")) start();
    if (e.target.closest("[data-game-close]")) close();
  });
  dialog.addEventListener("close", function () {   // Escape or close(): stop the round, shut the door
    running = false;
    cancelAnimationFrame(raf);
    items.slice().forEach(remove);
    if (canvas && canvasHome) canvasHome.appendChild(canvas);
    var shop = document.querySelector("[data-storefront]");
    if (shop) shop.classList.remove("is-open");
  });

  window.DoorGame = { open: open, close: close }; // handy from the console
})();

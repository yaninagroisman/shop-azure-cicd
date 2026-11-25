/* ==========================================================================
   effects.js: product-specific magic
     * Pocket Fluffs hop about, lean towards the cursor, hop faster when it
       comes close and bounce like mad when tickled
     * Instant Midnight Powder briefly blacks out its own display
     * "Demonstrate" buttons on product pages (touch-friendly hover)
     * Tap-to-open stages (the Tuckbox on the home page)
   ========================================================================== */
(function () {
  "use strict";
  var reduced = function () { return window.Magic ? Magic.reduced() : false; };

  /* ---------------------------------------------------------- Pocket Fluffs */
  var puffStages = Array.prototype.slice.call(document.querySelectorAll(".stage--puffs"));
  var visible = new Set();
  var pointer = null;
  var ticking = false;

  if ("IntersectionObserver" in window) {
    var io = new IntersectionObserver(function (entries) {
      entries.forEach(function (en) { if (en.isIntersecting) visible.add(en.target); else visible.delete(en.target); });
    });
    puffStages.forEach(function (s) { io.observe(s); });
  } else {
    puffStages.forEach(function (s) { visible.add(s); });
  }

  function watchPointer() {
    ticking = false;
    if (!pointer || reduced()) return;
    visible.forEach(function (stage) {
      var r = stage.getBoundingClientRect();
      var cx = r.left + r.width * 0.64, cy = r.top + r.height * 0.7; // where the fluffs sit in the photo
      var dx = pointer.x - cx, dy = pointer.y - cy;
      var lean = Math.max(-1, Math.min(1, dx / (r.width * 1.5))) * 6; // degrees: they lean towards the cursor
      stage.style.setProperty("--lean", lean.toFixed(2) + "deg");
      stage.classList.toggle("is-near", Math.hypot(dx, dy) < r.width * 0.4); // and hop faster when it's close
    });
  }

  if (puffStages.length) {
    document.addEventListener("pointermove", function (e) {
      pointer = { x: e.clientX, y: e.clientY };
      if (!ticking) { ticking = true; requestAnimationFrame(watchPointer); }
    }, { passive: true });
    document.addEventListener("pointerleave", function () {
      puffStages.forEach(function (s) { s.classList.remove("is-near"); s.style.removeProperty("--lean"); });
    });
  }

  // Tickling a puff (click/tap on its stage) makes it giggle.
  function tickle(stage, x, y) {
    stage.classList.add("is-tickled");
    if (window.Magic) Magic.burst(x, y, { count: 16, colors: Magic.palettes.pink, speed: 3, gravity: -0.03 });
    clearTimeout(stage._tickle);
    stage._tickle = setTimeout(function () { stage.classList.remove("is-tickled"); }, 1600);
  }

  /* ------------------------------------------------------ Instant Midnight */
  function darken(stage, ms) {
    if (stage.classList.contains("is-dark")) return;
    stage.classList.add("is-dark");
    setTimeout(function () { stage.classList.remove("is-dark"); }, ms || 2200);
  }

  // In the catalogue: hovering the Instant Midnight card throws a pinch (with a cooldown).
  document.querySelectorAll('[data-product-card][data-effect="darkness"]').forEach(function (card) {
    var stage = card.querySelector("[data-stage]");
    var cooling = false;
    card.addEventListener("mouseenter", function () {
      if (cooling || !stage) return;
      cooling = true;
      darken(stage, 1500);
      setTimeout(function () { cooling = false; }, 4000);
    });
  });

  /* ------------------------------------------------ tap-to-toggle stages */
  function toggleStage(stage) {
    var on = !stage.classList.contains("is-demo");
    stage.classList.toggle("is-demo", on);
    stage.setAttribute("aria-pressed", String(on));
    if (on && window.Magic) Magic.burstAt(stage, { count: 24, colors: Magic.palettes.gold, speed: 3 });
  }
  document.querySelectorAll("[data-toggle-stage]").forEach(function (stage) {
    stage.addEventListener("click", function () { toggleStage(stage); });
    stage.addEventListener("keydown", function (e) {
      if (e.key === "Enter" || e.key === " ") { e.preventDefault(); toggleStage(stage); }
    });
  });

  /* -------------------------------------------------- stages & demo button */
  document.addEventListener("click", function (e) {
    var stage = e.target.closest(".stage--puffs");
    if (stage && !stage.closest("a")) tickle(stage, e.clientX, e.clientY);
  });

  var demoBtn = document.querySelector("[data-demo]");
  var bigStage = document.querySelector(".stage--big[data-stage]");
  if (demoBtn && bigStage) {
    var effect = bigStage.getAttribute("data-effect");

    bigStage.addEventListener("click", function () {
      var box = bigStage.getBoundingClientRect();
      if (effect === "darkness") darken(bigStage);
      if (effect === "whizbang" && window.Magic) Magic.fireworks(3, box);
    });

    demoBtn.addEventListener("click", function () {
      var box = bigStage.getBoundingClientRect();
      if (effect === "darkness") { // momentary, not a toggle
        darken(bigStage, 2400);
        return;
      }
      var on = !bigStage.classList.contains("is-demo");
      bigStage.classList.toggle("is-demo", on);
      demoBtn.setAttribute("aria-pressed", String(on));
      if (!on || !window.Magic) return;
      var at = function (fx, fy) { return [box.left + box.width * fx, box.top + box.height * fy]; };
      var p;
      if (effect === "whizbang") Magic.fireworks(4, box);
      if (effect === "canary") { p = at(0.5, 0.4); Magic.burst(p[0], p[1], { count: 30, colors: ["#f2c94c", "#ffe08a", "#fff4d6"], speed: 3, gravity: 0.03 }); }
      if (effect === "swamp") { p = at(0.5, 0.45); Magic.burst(p[0], p[1], { count: 24, colors: Magic.palettes.gold, speed: 2.5, gravity: -0.04 }); }
      if (effect === "dream") { p = at(0.6, 0.55); Magic.burst(p[0], p[1], { count: 24, colors: ["#efe1ff", "#c9a8e0", "#fff4d6"], speed: 2, gravity: -0.03 }); }
      if (effect === "decoy") setTimeout(function () { p = at(0.8, 0.5); Magic.burst(p[0], p[1], { count: 36, colors: Magic.palettes.mischief, speed: 6 }); }, 900);
      if (effect === "puffs") { p = at(0.64, 0.7); tickle(bigStage, p[0], p[1]); }
    });
  }

})();

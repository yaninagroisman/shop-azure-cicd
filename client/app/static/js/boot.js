/* Runs in <head> before the page paints: flags JS support and, on the home
   page, starts the "puff of smoke" entrance. Kept tiny and dependency-free.

   Order of events on a new page:
     1. the browser cross-fades the old page into this page's first frame,
        which is the purple smoke (CSS @view-transition, .is-entering);
     2. when that cross-fade has finished, the smoke slowly thins away (.is-entered).
   Browsers without view transitions go straight to step 2. */
(function () {
  var html = document.documentElement;
  html.classList.remove("no-js");
  html.classList.add("js");
  var reduced = window.matchMedia && window.matchMedia("(prefers-reduced-motion: reduce)").matches;
  // Only the shop window arrives in smoke; other pages use the simple fade in main.css.
  if (reduced || html.getAttribute("data-entrance") !== "smoke") return;
  html.classList.add("is-entering");

  var done = false;
  function reveal() {
    if (done) return;
    done = true;
    requestAnimationFrame(function () {
      requestAnimationFrame(function () {
        html.classList.remove("is-entering");
        html.classList.add("is-entered");
      });
    });
  }
  function whenReady(fn) {
    if (document.readyState === "loading") document.addEventListener("DOMContentLoaded", fn);
    else fn();
  }

  if ("onpagereveal" in window) {
    window.addEventListener("pagereveal", function (e) {
      if (e.viewTransition) {
        e.viewTransition.finished.then(reveal, reveal);
        setTimeout(reveal, 900); // the cross-fade lasts .6 s; don't wait on a slow one
      }
      else whenReady(reveal);
    }, { once: true });
  } else {
    whenReady(reveal);
  }
  // Safety net: never leave the curtain down.
  setTimeout(reveal, 2000);
  // Coming back via the browser's back button restores a frozen page; lift the curtain.
  window.addEventListener("pageshow", function (e) {
    if (e.persisted) { html.classList.remove("is-entering"); html.classList.add("is-entered"); }
  });
})();

/* catalogue.js: search, shelf filters and sorting (all in the browser). */
(function () {
  "use strict";
  var form = document.querySelector("[data-filters]");
  var shelf = document.querySelector("[data-shelf]");
  if (!form || !shelf) return;

  var search = form.querySelector("[data-filter-search]");
  var sort = form.querySelector("[data-filter-sort]");
  var chips = Array.prototype.slice.call(form.querySelectorAll("[data-filter-category]"));
  var cards = Array.prototype.slice.call(shelf.querySelectorAll("[data-product-card]"));
  var original = cards.slice();
  var countEl = document.querySelector("[data-results-count]");
  var empty = document.querySelector("[data-empty]");
  var category = "all";

  // Let people link straight to a shelf or search: /catalogue?shelf=mayhem&q=bog
  var params = new URLSearchParams(location.search);
  if (params.get("q")) search.value = params.get("q");
  if (params.get("shelf")) category = params.get("shelf");

  function apply() {
    var q = search.value.trim().toLowerCase();
    var shown = 0;
    cards.forEach(function (card) {
      var ok = (category === "all" || card.dataset.category === category) &&
               (!q || card.dataset.name.indexOf(q) !== -1 || card.dataset.category.replace("-", " ").indexOf(q) !== -1);
      var wasHidden = card.classList.contains("is-hidden");
      card.classList.toggle("is-hidden", !ok);
      if (ok && wasHidden) { card.classList.remove("is-revealed"); void card.offsetWidth; card.classList.add("is-revealed"); }
      if (ok) shown++;
    });
    // Wide feature cards only make sense on the full, unfiltered shelf.
    shelf.classList.toggle("is-filtered", shown !== cards.length || sort.value !== "shelf");
    original.forEach(function (c, i) { if (i === 0 || i === 8) c.classList.toggle("card--wide", !shelf.classList.contains("is-filtered")); });

    chips.forEach(function (c) { c.setAttribute("aria-pressed", String(c.dataset.filterCategory === category)); });
    empty.hidden = shown !== 0;
    countEl.textContent = shown === cards.length ? "Showing all " + shown + " products"
      : shown === 0 ? "No products found"
      : "Showing " + shown + " of " + cards.length + " products";
  }

  function reorder() {
    var list = original.slice();
    var by = sort.value;
    if (by === "price-asc") list.sort(function (a, b) { return a.dataset.price - b.dataset.price; });
    if (by === "price-desc") list.sort(function (a, b) { return b.dataset.price - a.dataset.price; });
    if (by === "name") list.sort(function (a, b) { return a.querySelector(".card__title").textContent.localeCompare(b.querySelector(".card__title").textContent); });
    list.forEach(function (c) { shelf.appendChild(c); });
    cards = list;
    apply();
  }

  form.addEventListener("submit", function (e) { e.preventDefault(); });
  search.addEventListener("input", apply);
  sort.addEventListener("change", reorder);
  chips.forEach(function (chip) {
    chip.addEventListener("click", function () { category = chip.dataset.filterCategory; apply(); });
  });
  document.addEventListener("click", function (e) {
    if (!e.target.closest("[data-filter-reset]")) return;
    search.value = ""; category = "all"; sort.value = "shelf"; reorder(); search.focus();
  });

  apply();
})();

/* ==========================================================================
   api.js: the ONE place the shop talks to a backend.

   window.ShopAPI offers the two business operations:
     ShopAPI.buy(product, quantity)  -> Promise<Purchase>     (status "pending")
     ShopAPI.getAllBoughtItems()     -> Promise<Purchase[]>   (newest first)

   product = { slug, name, price }  (price in Pips)

   Purchase = {
     id, product_slug, product_name, quantity,
     unit_price, total_price,          // Pips (1 Griffin = 12 Shards = 240 Pips)
     status: "pending" | "completed" | "failed",
     failure_reason,                   // text when failed, otherwise null
     created_at, updated_at            // ISO 8601
   }

   The mode comes from <body data-api-mode>, set by Flask from the API_MODE
   environment variable:
     "mock" -> MockShopAPI (static/js/mock-api.js), no backend needed
     "http" -> same-origin requests:
                 POST /api/buy        body {"product_slug", "quantity"}
                                      reply 202 {"purchase": Purchase} or Purchase
                 GET  /api/purchases  reply {"purchases": Purchase[]} or Purchase[]
   ========================================================================== */
(function () {
  "use strict";

  function request(method, url, body) {
    return fetch(url, {
      method: method,
      headers: body ? { "Content-Type": "application/json", Accept: "application/json" } : { Accept: "application/json" },
      body: body ? JSON.stringify(body) : undefined,
      credentials: "same-origin",
    }).then(function (res) {
      return res.json().catch(function () { return {}; }).then(function (data) {
        if (!res.ok) {
          throw new Error((data && data.error) || "The owl came back with a strange look (HTTP " + res.status + ").");
        }
        return data;
      });
    }, function () {
      throw new Error("Our owl couldn't find the shop. Check your connection and try again.");
    });
  }

  var HttpShopAPI = {
    buy: function (product, quantity) {
      return request("POST", "/api/buy", { product_slug: product.slug, quantity: quantity })
        .then(function (data) { return data.purchase || data; });
    },
    getAllBoughtItems: function () {
      return request("GET", "/api/purchases")
        .then(function (data) { return Array.isArray(data) ? data : (data.purchases || []); });
    },
  };

  var mode = document.body.getAttribute("data-api-mode") || "mock";
  window.ShopAPI = mode === "http" || !window.MockShopAPI ? HttpShopAPI : window.MockShopAPI;
})();

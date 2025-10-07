var PRODUCTS;
var COMPANY;
var SITE;
var BASKET = [];

var IS_M = window.innerWidth < 777;
var IS_HOME = window.location.pathname == "/" || window.location.pathname.includes("/index.html");
var IS_MOBILE = (function () {
  var dataString = [navigator.userAgent, navigator.vendor, navigator.platform, window.opera, ''].join(' ');
  var mobileRegex = /Android|webOS|iPhone|iPad|iPod|BlackBerry|IEMobile|Opera Mini|Mobile|Mobi|iOS|CriOS|FxiOS|CFNetwork|UCBrowser|Silk|Kindle|Tablet|Mac.*Mobile|MacIntel|Phone|samsung|SAMSUNG/i;
  var isMobileDevice = mobileRegex.test(dataString);
  var hasTouchPoints = navigator.maxTouchPoints > 0;
  var hasTouchEvents = 'ontouchstart' in window || 'ontouchend' in document;
  return isMobileDevice || hasTouchPoints || hasTouchEvents;
})();

document.addEventListener("DOMContentLoaded", function () {
  COMPANY = getData("company");
  PRODUCTS = getData("products").products;
  SITE = getData("site");

  let $body = document.body;
  doHeader($body);

  let $m = document.createElement("main");
  if (IS_HOME) {
    let part = imgWithBtn("/static/img/pages/header.jpg", SITE.headSloganBtn, SITE.headSloganLnk, [SITE.headImgSloganStart, SITE.headImgSloganEnd]);
    if (IS_M) { part.style.marginTop = "-128px"; }
    else { part.style.marginTop = "-48px"; }
    $body.append(part);
  }
  else { $m.append(h3(COMPANY.slogan)); }

  $body.append($m);
  doBasket($body, doFooter($body));

  if (window.location.href.includes("/products/")) {
    let pun = window.location.href.split("/").pop().split(".")[0];
    let product = PRODUCTS.find(p => p.url === pun);
    if (product) {
      let a = article();
      a.className = "prd";
      a.append(doProduct(product, false), p(product.longDesc.join(" "), true));
      $m.append(a);
    } else { console.error("Product not found: " + pun); }
  }

  if (window.location.href.includes("/urunlerimiz.html")) { doProducts($m, false); }
  else {
    if (SITE.pages) {
      for (let [key, pd] of Object.entries(SITE.pages)) {
        if (window.location.href.includes(`/${key}.html`)) {

          if (key === "index") { break; }
          if (key === "iletisim") { doIletisim($m); break; }
          if (key === "site-haritasi") { doSiteHaritasi($m); break; }
          if (key === "404") { do404($m); break; }

          let a = article();
          let i = img(`/static/img/pages/${key}.jpg`, pd.title);
          i.style.objectPosition = "center";
          a.append(h2(pd.title.split("|")[0].trim()), i);

          (async function () {
            let d = getData("pages/" + key);
            if (d && d.parts) {
              d.parts.forEach(i => {
                a.append(h2(i.title), p2(Array.isArray(i.content) ? i.content.join(" ") : i.content.replace(/\n/g, "<br/>"), true));
                if (i.list) {
                  let ul = document.createElement("ul");
                  ul.className = "list";
                  i.list.forEach(il => { ul.append(li(il)); });
                  a.append(ul);
                }
              });
            }
          })();
          $m.append(a);
          break;
        }
      }
    }
    else { do404($m); }

    doProducts($m);
  }

  setTimeout(function () {
    let prms = new URLSearchParams(window.location.search);
    for (let [key, value] of prms.entries()) {
      let product = PRODUCTS.find(p => p.id === key);
      if (product) { addToBasket(key, parseInt(value)); }
    }
  }, 987);
});

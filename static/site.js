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
function getLogo() {
    let l = img("/logo.jpg", COMPANY.slogan);
    l.className = "logo";
    return l;
}

function getData(p) {
    let xhr = new XMLHttpRequest();
    xhr.open("GET", "/data/" + p + ".json", false);
    xhr.send();
    if (xhr.status === 200) {
        let r = JSON.parse(xhr.responseText);
        return r;
    } else {
        console.error("Error fetching " + p + ".json : ", xhr.statusText);
        return null;
    }
}

function lnk(h, t, b = false) {
    let x = document.createElement("a");
    x.href = h;
    x.textContent = t;
    if (b) { x.target = "_blank"; }
    return x;
}

function img(s, t) {
    let x = document.createElement("img");
    x.src = s;
    x.alt = x.title = t;
    return x;
}

function lnkimg(h, s, t) {
    let x = document.createElement("a");
    x.href = h;
    x.target = "_blank";
    let i = img(s, t);
    x.append(i);
    return x;
}

function imgWithBtn(s, t, u, l) {
    let i = img(s, COMPANY.slogan);
    let ld = div();
    let b = btn(t);
    b.addEventListener("click", function () { window.location.href = u + window.location.search; });
    ld.append(em(l[0]), em(l[1]), b);
    let d = div();
    d.className = "bigImg";
    d.append(i, ld);
    return d;
}

function em(t) {
    let x = document.createElement("em");
    x.textContent = t;
    return x;
}

function div() { return document.createElement("div"); }

function li(t) {
    let x = document.createElement("li");
    x.textContent = t;
    return x;
}

function h2(t) {
    let x = document.createElement("h2");
    x.textContent = t;
    return x;
}

function h3(t) {
    let x = document.createElement("h3");
    x.textContent = t;
    return x;
}

function p(t, j = false) {
    let x = document.createElement("p");
    x.textContent = t;
    if (j) { x.style.textAlign = "justify"; }
    return x;
}

function p2(t) {
    let x = document.createElement("p");
    x.innerHTML = t;
    return x;
}

function article() { return document.createElement("article"); }

function address(ls) {
    let x = document.createElement("address");
    ls.forEach(l => { x.innerHTML += l + "<br/>"; });
    return x;
}

function br() { return document.createElement("br"); }

function btn(t) {
    let x = document.createElement("button");
    x.textContent = t;
    return x;
}

function btni(s, t) {
    let x = document.createElement("button");
    x.append(img(s, t));
    return x;
}

function rmv(i) { rmv2(document.querySelector(i)); }
function rmv2(e) { if (e) { e.remove(); } }
function rmAfter(e) {
    if (!e) { return; }
    let rem = [];
    let sib = e.nextSibling;
    while (sib) {
        rem.push(sib);
        sib = sib.nextSibling;
    }
    rem.forEach(el => el.remove());
}

function insertAfter(r, n) { r.insertAdjacentElement("afterend", n); }
function changeBtnAddToBasket(parent, display) {
  let btn = parent.querySelector(".btnAddToBasket");
  if (btn) {
    btn.style.display = display;
    rmAfter(btn);
  }
  return btn;
}

function basketAdder(prevElem, prdId) {
  let exi = BASKET.find(p => p.id == prdId);

  let $q = em(exi.quantity + " Adet");

  let mbs = exi.quantity > 1 || true ? "minus" : "delete";
  let mbs2 = exi.quantity > 1 ? "çıkart" : "sil";
  let $mb = img("/static/img/" + mbs + ".png", mbs2);
  $mb.addEventListener("click", function () {
    if (exi.quantity > 1) { decreaseBasket(prdId, exi.quantity); }
    else {
      changeBtnAddToBasket($mb.parentElement, "inline-block");
      removeFromBasket(prdId);
    }
  });

  let $pb = img("/static/img/plus.png", "ekle");
  $mb.className = $pb.className = "bskbtn";
  $pb.addEventListener("click", function () { addToBasket(prdId); });

  insertAfter(prevElem, $pb);
  insertAfter(prevElem, $q);
  insertAfter(prevElem, $mb);
}

function fnAddToBasket() {
  this.style.display = "none";
  let x = p("Sepete Eklendi");
  x.style.marginBottom = "5px";
  insertAfter(this, x);

  let prdId = this.parentElement.dataset.id;
  addToBasket(prdId);
  basketAdder(x, prdId);
}

function addToBasket(prdId, quantity) {
  let db = PRODUCTS.find(p => p.id == prdId);
  if (quantity == undefined) { quantity = 1; }

  let existing = BASKET.find(p => p.id == db.id);
  if (existing) { BASKET = BASKET.map(p => p.id === existing.id ? { ...p, quantity: existing.quantity + 1 } : p); }
  else { BASKET.push({ id: db.id, name: db.name, url: db.url, price: db.price, quantity: quantity }); }

  refreshBasket();
}

function decreaseBasket(prdId, quantity) {
  BASKET = BASKET.map(p => p.id === prdId ? { ...p, quantity: quantity - 1 } : p);
  refreshBasket();
}

function emptyBasket() {
  BASKET.forEach(function (p) {
    cPrd("#products", p.id);
    cPrd(".prd", p.id);
  });
  BASKET = [];
  refreshBasket();
}

function removeFromBasket(prdId) {
  BASKET = BASKET.filter(p => p.id !== prdId);
  refreshBasket();
  cPrd("#products", prdId);
  cPrd(".prd", prdId);
}

function cPrd(sel, prdId) {
  let p = document.querySelector(sel + " > li[data-id='" + prdId + "']");
  if (p) { changeBtnAddToBasket(p, "inline-block"); }
}

function cPrdAdd(sel, p) {
  let pp = document.querySelector(sel + " > li[data-id='" + p.id + "']");
  if (pp) { basketAdder(changeBtnAddToBasket(pp, "none"), p.id); }
}

function calcShip(w) {
  if (w <= 5) { return 167; }
  else if (w <= 10) { return 195; }
  else if (w < 15) { return 249; }
  else { return 0; }
}

function getTotals() {
  let total = 0;
  let qp = [];
  let w = 0;
  BASKET.forEach(function (p) {
    qp.push(`${p.id}=${p.quantity}`);
    total += p.quantity * p.price;
    let numPart = parseInt(p.id.replace(/\D/g, ""), 10);
    w += (numPart / 1000) * p.quantity;
  });
  return { total, qp, w };
}

function refreshBasket() {
  let { total, qp, w } = getTotals();
  history.replaceState(null, "", `?${qp.join("&")}`);

  let $bi = document.getElementById("basketInfo");
  if (BASKET.length > 0) {
    $bi.querySelector("div").textContent = BASKET.reduce((sum, item) => sum + item.quantity, 0);
    $bi.style.visibility = "visible";
  } else {
    $bi.querySelector("div").textContent = "";
    $bi.style.visibility = "hidden";
  }

  let $ul = document.querySelector("#basket ul");
  $ul.innerHTML = "";
  rmAfter($ul);

  let $be = document.querySelector("#btnEmptyBasket");
  if ($be) { $be.style.display = "none"; }

  if (BASKET.length > 0) {
    let frag = document.createDocumentFragment();
    let $b = document.querySelector("#basket");

    if ($be) { $be.style.display = "inline-block"; }

    let $pTotal = p("");
    $pTotal.id = "pTotal";
    $pTotal.textContent = "Ürün Tutarı : " + formatPrice(total) + " (KDV Dahil)";
    frag.append($pTotal);

    let $e = em("15 kg ve üzeri siparişlerde kargo ücretsizdir.");
    $e.style.fontSize = "13px";
    $e.style.color = "#333";
    $e.style.paddingBottom = "8px";
    $e.style.display = "block";
    $e.style.marginTop = "-5px";
    let ship = calcShip(w);
    if (w < 15) {
      let $c = p("Kargo Ücreti: " + ship + " TL (Vergiler Dahil)");
      frag.append($c);
      frag.append($e);
    }
    else {
      $e.textContent = "Kargonuz ücretsiz.";
      frag.append($e);
    }

    let $total = p("");
    $total.id = "total";
    $total.textContent = "Genel Toplam : " + formatPrice(total + ship);
    frag.append($total);

    $bi.querySelector("em").textContent = formatPrice(total);

    let $bw = btn("Whatsapp'dan Siparişini İlet");
    $bw.id = "btnOrderFromWhatsapp";
    $bw.addEventListener("click", function () {
      let phone = COMPANY.phone.replace(/\D/g, "");
      let message = "Merhaba,\n\n";
      BASKET.forEach(function (p) { message += `${p.quantity} ${p.name} (${p.price} x ${p.quantity})\n`; });

      let { total, qp, w } = getTotals();
      let ship = calcShip(w);
      message += "\nÜrün Tutarı : " + formatPrice(total);
      message += "\nKargo Ücreti :" + formatPrice(ship);
      message += "\nGenel Toplam :" + formatPrice(total + ship);
      message += "\n\nSatın almak istiyorum.";

      let encoded = encodeURIComponent(message);

      if (IS_MOBILE) { window.open(`https://wa.me/${phone}?text=${encoded}`, "_blank"); }
      else { window.open(`https://web.whatsapp.com/send?phone=${phone}&text=${encoded}`, "_blank"); }
    });
    frag.append($bw);

    let no_wa = p2("WhatsApp kullanmıyorsanız,<br/>sipariş ve sorularınız için bize <a target='_blank' href='mailto:info@ozumgida.com'>info@ozumgida.com</a> adresimizden ulaşabilirsiniz.") ;
    no_wa.id = "no_wa";
    frag.append(no_wa);

    $b.append(frag);

    frag = document.createDocumentFragment();

    BASKET.forEach(function (p) {
      let $li = li();
      let $db = img("/static/img/delete.png", "sil");
      $db.className = "btnDelete";
      $db.addEventListener("click", function () { removeFromBasket(p.id); });
      $li.append($db);

      doProductInner($li, p, true);
      basketAdder($li.lastElementChild, p.id);

      frag.append($li);
      cPrdAdd("#products", p);
      cPrdAdd(".prd", p);
    });

    $ul.append(frag);
  }

  showBasket();
}

function doBasket($body, $f) {
  let bi = div();
  bi.id = "basketInfo";
  bi.append(div(), img("/static/img/basket.png", "Sepet"), em(""));
  bi.addEventListener("click", function () {
    window.location.href = "#basket";
    showBasket();
  });
  $body.append(bi);

  let $b = div();
  $b.id = "basket";
  $b.append(p2(SITE.basketWarning));

  let $bs = btn("Sepeti Göster");
  $bs.id = "btnShowBasket";
  $bs.addEventListener("click", function () {
    if ($bs.dataset.active === "true") { hideBasket(); }
    else { showBasket(); }
  });

  let $be = btn("Sepeti Boşalt");
  $be.id = "btnEmptyBasket";
  $be.addEventListener("click", emptyBasket);
  $be.style.display = "none";

  $b.append($bs, $be);
  $b.append(document.createElement("ul"));

  $body.insertBefore($b, $f);
  hideBasket();
}

function showBasket() {
  let p = document.getElementById("basket");
  let b = document.getElementById("btnShowBasket");
  b.dataset.active = "true";
  b.innerHTML = "Sepeti Gizle";
  p.style.height = "fit-content";
}

function hideBasket() {
  let p = document.getElementById("basket");
  let b = document.getElementById("btnShowBasket");
  b.dataset.active = "false";
  b.innerHTML = "Sepeti Göster";
  p.style.height = IS_M ? "260px" : "220px";
}

function formatPrice(price) { return price.toLocaleString("tr-TR") + " TL"; }
function do404($m) {
  let a = article();
  let i = img("/static/img/pages/404.jpg", "Sayfa Bulunamadı");
  i.style.objectPosition = "center";
  a.append(h2("Sayfa Bulunamadı"), i, p("Aradığınız sayfa bulunamadı. Lütfen menüden başka bir sayfayı seçin."), br());
  $m.append(a);
  return a;
}

function doIletisim($m) {
  let a = article();
  let i = img("/static/img/pages/iletisim.jpg", COMPANY.name);
  i.style.objectPosition = "center";
  a.append(h2("İletişim"), i, em(COMPANY.legalName), br());

  let $d = div();
  $d.className = "contact";
  $d.append(
    img("/static/img/address.png", "adres"), address(COMPANY.address), br(),
    img("/static/img/map.png", "harita"), lnk("https://maps.app.goo.gl/hVNeyU35MEWc8sGp8", "Haritada Gör", true), br(),
    img("/static/img/phone.png", "telefon"), lnk("tel:" + COMPANY.phone.replace(/ /g, ""), COMPANY.phone), br(),
    img("/static/img/email.png", "e-posta"), lnk("mailto:" + COMPANY.email, COMPANY.email));
  a.append($d);
  $m.append(a);
  return a;
}

function doSiteHaritasi($m) {
  let a = article();
  let i = img("/static/img/pages/site-haritasi.jpg", "Site Haritası");
  i.style.objectPosition = "bottom";
  a.append(h2("Site Haritası"), i, br(),
    lnk("/index.html", "Anasayfa"),
    lnk("/urunlerimiz.html", "Ürünlerimiz"),
    lnk("/hakkimizda.html", "Hakkımızda"),
    lnk("/lezzetimizin-hikayesi.html", "Lezzetimizin Hikayesi"),
    lnk("/satis-sozlesmesi.html", "Mesafeli Satış Sözleşmesi"),
    lnk("/gizlilik-politikasi.html", "Gizlilik Politikası"),
    lnk("/kvkk.html", "KVKK Aydınlatma Metni"),
    lnk("/iletisim.html", "İletişim"), br());
  $m.append(a);
  return a;
}

function mi(t, u) {
  let x = li(t);
  x.dataset.url = u;
  x.addEventListener("click", function () { window.location.href = x.dataset.url + window.location.search; });
  if (window.location.href.includes(x.dataset.url)) {
    x.style.textDecoration = "underline";
    x.style.fontWeight = "bold";
  }
  return x;
}

function doHeader($body) {
  let $header = document.createElement("header");
  let $logo = getLogo();
  $logo.addEventListener("click", function () { window.location.href = "/" + window.location.search; });
  $header.append($logo);
  $body.insertBefore($header, $body.firstChild);

  rmv('#loading');

  let $nav = document.createElement("nav");
  let $menu = document.createElement("menu");
  let m = li("");
  m.append(img("/static/img/menu.png", "Menü"));
  m.dataset.open = "false";
  m.style.cursor = "pointer";
  m.style.paddingBottom = 0;
  m.addEventListener("click", function () {
    let items = this.parentElement.querySelectorAll("li");
    if (this.dataset.open == "true") {
      this.dataset.open = "false";
      this.firstElementChild.src = "/static/img/menu.png";
      items.forEach(function (i) { i.className = "close" });
    }
    else {
      this.dataset.open = "true";
      this.firstElementChild.src = "/static/img/close.png";
      items.forEach(function (i) { i.className = "" });
    }
    this.className = "";
  });

  let m1 = mi("Hakımızda", "/hakkimizda.html");
  let m2 = mi("Ürünlerimiz", "/urunlerimiz.html");
  let m3 = mi("Lezzetimizin Hikayesi", "/lezzetimizin-hikayesi.html");
  let m4 = mi("İletişim", "/iletisim.html");
  if (IS_M) {
    $menu.append(m);
    m1.className = m2.className = m3.className = m4.className = "close";

    if (IS_HOME) { $nav.style.height = "133px"; }
  }

  $menu.append(m1, m2, m3, m4);
  $nav.append($menu);
  $body.append($nav);
  return $header;
}

function doFooter($body) {
  let $f = document.createElement("footer");
  $f.append(imgWithBtn("/static/img/pages/footer.jpg", SITE.footSloganBtn, SITE.footSloganLnk, [SITE.footImgSloganStart, SITE.footImgSloganEnd]));

  let $w = lnkimg("tel:" + COMPANY.phone, "/static/img/whatsapp.png", "whatsapp");
  $w.addEventListener("click", function () {
    let phone = COMPANY.phone;
    let message = "Merhaba";
    if (IS_MOBILE) { window.open(`https://wa.me/${phone}?text=${message}`, "_blank"); }
    else { window.open(`https://web.whatsapp.com/send?phone=${phone}&text=${message}`, "_blank"); }
  });

  let $social = div();
  $social.className = "social";
  $social.append(lnkimg(COMPANY.instagram, "/static/img/instagram.png", "instagram"), $w);

  $f.append(
    br(), br(), $social, br(), br(),
    lnk("mailto:" + COMPANY.email, COMPANY.email), p(COMPANY.name + " © " + new Date().getFullYear()), br(),
    lnk("/satis-sozlesmesi.html", "Uzaktan Satış Sözleşmesi"),
    lnk("/kvkk.html", "KVKK Aydınlatma Metni"),
    lnk("/gizlilik-politikasi.html", "Gizlilik Politikası"),
    lnk("/site-haritasi.html", "Site Haritası"), getLogo());

  $body.append($f);
  return $f;
}
function doProductInner($p, prd, isLinked) {
    let $img = img("", prd.name);
    $img.src = "/products/" + prd.url + ".jpg";
    $p.append($img);

    let $n = h2(prd.name);
    $img.dataset.url = $n.dataset.url = prd.url;
    $p.append($n);

    let $pr = document.createElement("strong");
    $pr.innerHTML = `${prd.price} TL <em>(KDV Dahil)</em>`;
    $p.append($pr);

    if (isLinked) {
        $img.addEventListener("click", fpc);
        $n.addEventListener("click", fpc);
        $p.append(p(prd.shortDesc));
    }
    else { rmv("main h3"); }
}

function doProduct(product, isLinked = true) {
    let $p = document.createElement("li");
    $p.dataset.id = product.id;

    doProductInner($p, product, isLinked);

    let $btn = btn("Sepete Ekle");
    $btn.className = "btnAddToBasket";
    $btn.addEventListener("click", fnAddToBasket);
    $p.append($btn, br());
    return $p;
}

function doProducts($body, rand = true) {
    let $p = document.createElement("ul");
    $p.id = "products";
    let items = PRODUCTS.slice(0, 4);
    items.forEach(product => { $p.append(doProduct(product)); });
    $body.append($p);
}

function fpc() { window.location.href = "/products/" + this.dataset.url + ".html" + window.location.search; };

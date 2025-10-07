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

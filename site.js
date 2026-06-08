function calculateShippingPrice(items) {
let weight = 0;
for (let i = 0; i < items.length; i++) {
weight += items[i].weight * items[i].quantity;
}
weight = weight / 1000;
if (weight <= 5) { return 195; }
if (weight <= 10) { return 230; }
return 290;
}
(function() {
let imgs = document.querySelectorAll("img[data-src]");
if (!imgs.length) { return; }
let observer = new IntersectionObserver(function(entries) {
for (let i = 0; i < entries.length; i++) {
if (entries[i].isIntersecting) {
let img = entries[i].target;
let fullSrc = img.dataset.src;
observer.unobserve(img);
(window.caches
? caches.match(fullSrc)
: Promise.resolve(null)
).then(function(cached) {
if (cached) {
img.src = fullSrc;
img.removeAttribute("data-src");
} else {
let real = new Image();
real.onload = function() {
img.src = fullSrc;
img.removeAttribute("data-src");
};
real.src = fullSrc;
}
});
}
}
});
for (let i = 0; i < imgs.length; i++) { observer.observe(imgs[i]); }
})();
if ("serviceWorker" in navigator) {
navigator.serviceWorker.register("/sw.js");
navigator.serviceWorker.ready.then(function(reg) {
setTimeout(function() {
if (reg.active) { reg.active.postMessage("cache-all"); }
}, 60000);
});
}
window.addEventListener("offline", function() {
document.querySelectorAll(".off").forEach(function(el) {
el.style.visibility = "visible";
});
});
window.addEventListener("online", function() {
document.querySelectorAll(".off").forEach(function(el) {
el.style.visibility = "hidden";
});
});
let _nav = document.querySelector("nav");
if (_nav) { _nav.addEventListener("click", function(e) { if (e.target === this) { this.classList.toggle("open"); } }); }
var IS_MOBILE = (function () {
var dataString = [navigator.userAgent, navigator.vendor, navigator.platform, window.opera, ''].join(' ');
var mobileRegex = /Android|webOS|iPhone|iPad|iPod|BlackBerry|IEMobile|Opera Mini|Mobile|Mobi|iOS|CriOS|FxiOS|CFNetwork|UCBrowser|Silk|Kindle|Tablet|Mac.*Mobile|MacIntel|Phone|samsung|SAMSUNG/i;
var isMobileDevice = mobileRegex.test(dataString);
var hasTouchPoints = navigator.maxTouchPoints > 0;
var hasTouchEvents = 'ontouchstart' in window || 'ontouchend' in document;
return isMobileDevice || hasTouchPoints || hasTouchEvents;
})();
function _el(tag, cls) {
let e = document.createElement(tag);
if (cls) { e.className = cls; }
return e;
}
function div(cls) { return _el("div", cls); }
function span(cls) { return _el("span", cls); }
function b(cls) { return _el("b", cls); }
function i(cls) { return _el("i", cls); }
function em(cls) { return _el("em", cls); }
function p(cls) { return _el("p", cls); }
function a(cls) { return _el("a", cls); }
function h5(cls) { return _el("h5", cls); }
function h6(cls) { return _el("h6", cls); }
function small(cls) { return _el("small", cls); }
function button(cls) { return _el("button", cls); }
function img(src, title, cls) {
let e = _el("img", cls);
if (src) { e.src = src; }
if (title) { e.alt = title; e.title = title; }
return e;
}
function txt(fn, text, cls) {
let e = fn(cls);
e.textContent = text;
return e;
}
function show(e) { e.classList.remove("hidden"); }
function hide(e) { e.classList.add("hidden"); }
function makeRow(label, value, cls) {
let row = div(cls);
row.append(txt(span, label), txt(b, value));
return row;
}
function parseBr(text, parent) {
let parts = text.split(/<br\s*\/?>/i);
for (let i = 0; i < parts.length; i++) {
if (i > 0) { parent.append(document.createElement("br")); }
parent.append(parts[i]);
}
}
function fmt(n) { return n.toString().replace(/\B(?=(\d{3})+(?!\d))/g, "."); }
function empty(el) { while (el.firstChild) { el.removeChild(el.firstChild); } }
function actionImg(src, title, action, id, cls) {
let e = img(src, title, cls);
e.setAttribute("data-action", action);
e.setAttribute("data-id", id);
return e;
}
let PRODUCTS={"p1000":{"name":"Erzincan Tulum Peyniri 1 kg","price":630,"weight":1000,"img":"erzincan-tulum-peyniri-1000gr.webp"},"p500":{"name":"Erzincan Tulum Peyniri 500 gr","price":315,"weight":500,"img":"erzincan-tulum-peyniri-500gr.webp"},"yt900":{"name":"Tuzlu Tereyağı 900 gr","price":640,"weight":900,"img":"tuzlu-tereyagi-900gr.webp"},"y500":{"name":"Tuzsuz Tereyağı 500 gr","price":320,"weight":500,"img":"tuzsuz-tereyagi-500gr.webp"}};
let BASKET_CONFIG={"warning":"Ürünlerinizi sepete ekledikten sonra,<br/>'WhatsApp'tan Siparişini İlet' butonuna tıklayarak<br/>siparişinizi ve kargo bilgilerinizi tarafımıza hızlıca iletebilir,<br/>alışverişinizi kolayca tamamlayabilirsiniz.","waWarning":"WhatsApp kullanmıyorsanız,<br/>sipariş ve sorularınız için info@ozumgida.com adresine ulaşabilirsiniz.","shippingWarning":"15 kg ve üzeri siparişlerde kargo ücretsizdir.","isBasketDesc":false,"paymentOptions":["Ödeme Linki"],"currency":"₺","waNumber":"905409063518","productsPage":"/pages/urunlerimiz.html","timezone":"Europe/Istanbul","labels":{"addToBasket":"Sepete Ekle","basket":"Sepet","myBasket":"Sepetim","itemSuffix":"ürün","for":"toplam","openBasket":"Sepeti Aç","closeBasket":"Sepeti Kapat","subtotal":"Ara Toplam","shipping":"Kargo","freeShipping":"Ücretsiz","total":"Toplam","delete":"Sil","unit":"Adet","whatsAppOrder":"WhatsApp'tan Siparişini İlet","whatsAppGreeting":"Merhaba, sipariş vermek istiyorum:","telegramOrder":"Telegram'dan Siparişini İlet","telegramGreeting":"Merhaba, sipariş vermek istiyorum:","emptyBasket":"Sepetiniz boş","productsLinkText":"Ürünlerimiz","emptyBasketDesc":"sayfasından beğendiğiniz ürünleri ekleyebilirsiniz.","waiterLabel":"Garson","tableLabel":"Masa","basketDescPlaceholder":"Not ekleyin (isteğe bağlı)","basketDescTooltip":"Belirtmek istediğiniz bir şey varsa, WhatsApp üzerinden de doğrudan mesaj atabilirsiniz.","paymentLabel":"Ödeme Yöntemi","noteLabel":"Not","happyHourTimezoneWarning":"Bu indirim restoran saatine göredir. Cihaz saatiniz farklı olabilir.","discountProgressPrefix":"daha alışverişle","discountProgressSuffix":"indirim kazan","notForOnlineOrder":"Online siparişe uygun değil"}};
let CAMPAIGN_CONFIG=[{"type": "free_shipping", "label": "15 kg ve üzeri siparişlerde kargo bedava!", "messageLine": "Bedava Kargo Kampanyası", "img": "15kg-uzeri-kargo-bedava.png", "addProducts": [{"id": "p1000", "qty": 6}, {"id": "p500", "qty": 6}, {"id": "yt900", "qty": 4}, {"id": "y500", "qty": 5}], "conditions": [{"minWeight": 15, "hintTemplate": "{remaining} kg daha ekle, kargo bedava!"}]}];
window.TABLE_NO = (new URLSearchParams(location.search)).get('t') || '';
window.WAITER_NAME = localStorage.getItem('waiter') || '';
(function() {
let basketSection = document.getElementById("basket");
if (!basketSection) { return; }
let C = BASKET_CONFIG;
let warningText = C.warning || "";
let waWarningText = C.waWarning || "";
let currencySymbol = C.currency || "\u20BA";
let waNumber = C.waNumber || "";
let tgUsername = C.tgUsername || "";
let labels = C.labels || {};
let L = function(k) { return labels[k]; };
let addToBasketText = L("addToBasket");
let badge;
let basketOpen = false;
let lastQty = 0;
let navEl;
let emptyEl, descEl, wrapEl, toggleBtnEl, toggleInfoEl, contentEl, itemsEl, totalsEl, descInputEl;
function getCart() {
let params = new URLSearchParams(location.search);
let cart = {};
params.forEach(function(val, key) {
if (PRODUCTS[key]) {
let qty = parseInt(val, 10);
if (qty > 0) { cart[key] = qty; }
}
});
return cart;
}
function setCart(cart) {
let params = new URLSearchParams(location.search);
let toRemove = [];
params.forEach(function(val, key) {
if (PRODUCTS[key]) { toRemove.push(key); }
});
for (let r = 0; r < toRemove.length; r++) params.delete(toRemove[r]);
for (let id in cart) {
if (cart[id] > 0) { params.set(id, cart[id]); }
}
let qs = params.toString();
let url = location.pathname + (qs ? "?" + qs : "") + location.hash;
history.replaceState(null, "", url);
render();
}
function getItems(cart) {
if (!cart) { cart = getCart(); }
let items = [];
for (let id in cart) {
let prod = PRODUCTS[id];
if (prod) {
items.push({
id: id, name: prod.name, price: prod.price,
weight: prod.weight, img: prod.img, quantity: cart[id],
ord: prod.ord
});
}
}
return items;
}
function addToBasket(id) {
let cart = getCart();
cart[id] = (cart[id] || 0) + 1;
basketOpen = true;
setCart(cart);
}
function updateQty(id, delta) {
let cart = getCart();
let qty = (cart[id] || 0) + delta;
if (qty <= 0) { delete cart[id]; }
else { cart[id] = qty; }
setCart(cart);
}
function removeItem(id) {
let cart = getCart();
delete cart[id];
setCart(cart);
}
function calcSubtotal(items) {
let s = 0;
for (let i = 0; i < items.length; i++) { s += items[i].price * items[i].quantity; }
return s;
}
function filterDiscountLines(lines) {
let result = [];
for (let i = 0; i < lines.length; i++) { if (!lines[i].isFree) { result.push(lines[i]); } }
return result;
}
function totalWeightKg(items) {
let w = 0;
for (let i = 0; i < items.length; i++) { w += items[i].weight * items[i].quantity; }
return w / 1000;
}
function getShopTime() {
let tz = C.timezone || "";
let now = new Date();
if (!tz) { return { h: now.getHours(), m: now.getMinutes(), day: now.getDay() }; }
let parts = new Intl.DateTimeFormat("en-US", {
timeZone: tz, hour: "2-digit", minute: "2-digit", weekday: "short", hour12: false
}).formatToParts(now);
let h = 0, m = 0, dayStr = "";
for (let i = 0; i < parts.length; i++) {
if (parts[i].type === "hour") { h = parseInt(parts[i].value, 10); }
if (parts[i].type === "minute") { m = parseInt(parts[i].value, 10); }
if (parts[i].type === "weekday") { dayStr = parts[i].value; }
}
let dayMap = { Sun: 0, Mon: 1, Tue: 2, Wed: 3, Thu: 4, Fri: 5, Sat: 6 };
return { h: h, m: m, day: (dayMap[dayStr] !== undefined ? dayMap[dayStr] : now.getDay()) };
}
function calculateDiscount(items, subtotal) {
let totalDiscount = 0;
let lines = [];
let freeShipping = false;
let happyHourActive = false;
let hints = [];
for (let ci = 0; ci < CAMPAIGN_CONFIG.length; ci++) {
let c = CAMPAIGN_CONFIG[ci];
if (c.type === "tier_discount") {
let tiers = (c.tiers || []).slice().sort(function(a, b) { return a.minOrderTotal - b.minOrderTotal; });
let applied = false;
for (let ti = tiers.length - 1; ti >= 0; ti--) {
if (subtotal >= tiers[ti].minOrderTotal) {
let amount = tiers[ti].discountType === "percentage"
? Math.round(subtotal * tiers[ti].discountAmount / 100)
: tiers[ti].discountAmount;
totalDiscount += amount;
lines.push({ label: c.label, amount: amount });
applied = true;
break;
}
}
if (!applied) {
for (let ti = 0; ti < tiers.length; ti++) {
if (subtotal < tiers[ti].minOrderTotal) {
let remaining = tiers[ti].minOrderTotal - subtotal;
let discAmt = tiers[ti].discountType === "percentage"
? tiers[ti].discountAmount + "%"
: fmt(tiers[ti].discountAmount) + " " + currencySymbol;
hints.push(fmt(remaining) + " " + currencySymbol + " " + L("discountProgressPrefix") + " " + discAmt + " " + L("discountProgressSuffix"));
break;
}
}
}
}
else if (c.type === "multi_unit") {
let pid = c.productId;
let cartItem = null;
for (let ii = 0; ii < items.length; ii++) {
if (items[ii].id === pid) { cartItem = items[ii]; break; }
}
let tiers = (c.tiers || []).slice().sort(function(a, b) { return a.minQuantity - b.minQuantity; });
let currentQty = cartItem ? cartItem.quantity : 0;
let applied = false;
for (let ti = tiers.length - 1; ti >= 0; ti--) {
if (currentQty >= tiers[ti].minQuantity) {
let lineTotal = cartItem.price * cartItem.quantity;
let amount = Math.min(tiers[ti].discountPerUnit * cartItem.quantity, lineTotal);
totalDiscount += amount;
lines.push({ label: c.label, amount: amount });
applied = true;
break;
}
}
if (!applied) {
for (let ti = 0; ti < tiers.length; ti++) {
if (currentQty < tiers[ti].minQuantity) {
let remaining = tiers[ti].minQuantity - currentQty;
let prodName = (PRODUCTS[pid] && PRODUCTS[pid].name) || pid;
hints.push(remaining + " " + L("unit") + " " + prodName + " " + L("discountProgressPrefix") + " " + fmt(tiers[ti].discountPerUnit) + " " + currencySymbol + "/" + L("unit") + " " + L("discountProgressSuffix"));
break;
}
}
}
}
else if (c.type === "free_shipping") {
let wKg = totalWeightKg(items);
let conditions = c.conditions || [];
let met = false;
for (let coi = 0; coi < conditions.length; coi++) {
let cond = conditions[coi];
if (cond.minWeight && wKg >= cond.minWeight) { met = true; break; }
if (cond.minOrderTotal && subtotal >= cond.minOrderTotal) { met = true; break; }
}
if (met) {
freeShipping = true;
lines.push({ label: c.label, amount: 0, isFree: true });
} else {
for (let coi = 0; coi < conditions.length; coi++) {
let cond = conditions[coi];
if (cond.minWeight && wKg < cond.minWeight) {
let remaining = Math.round((cond.minWeight - wKg) * 100) / 100;
let hint = (cond.hintTemplate || "").replace("{remaining}", remaining);
if (hint) { hints.push(hint); }
}
if (cond.minOrderTotal && subtotal < cond.minOrderTotal) {
let remaining = cond.minOrderTotal - subtotal;
let hint = (cond.hintTemplate || "").replace("{remaining}", fmt(remaining));
if (hint) { hints.push(hint); }
}
}
}
}
else if (c.type === "happy_hour") {
let t = getShopTime();
let sched = c.schedule || {};
let days = sched.days || [];
let dayNames = ["SUNDAY","MONDAY","TUESDAY","WEDNESDAY","THURSDAY","FRIDAY","SATURDAY"];
let dayName = dayNames[t.day];
let inDay = false;
for (let di = 0; di < days.length; di++) { if (days[di] === dayName) { inDay = true; break; } }
let startParts = (sched.startTime || "00:00").split(":");
let endParts = (sched.endTime || "00:00").split(":");
let startMin = parseInt(startParts[0], 10) * 60 + parseInt(startParts[1], 10);
let endMin = parseInt(endParts[0], 10) * 60 + parseInt(endParts[1], 10);
let nowMin = t.h * 60 + t.m;
let inTime = nowMin >= startMin && nowMin < endMin;
if (inDay && inTime) {
let amount = c.discountType === "percentage"
? Math.round(subtotal * c.discountValue / 100)
: c.discountValue;
totalDiscount += amount;
lines.push({ label: c.label, amount: amount });
happyHourActive = true;
}
}
}
return { totalDiscount: totalDiscount, lines: lines, freeShipping: freeShipping, happyHourActive: happyHourActive, hints: hints };
}
function render() {
let cart = getCart();
let items = getItems(cart);
let qty = 0;
for (let i = 0; i < items.length; i++) { qty += items[i].quantity; }
renderButtons(cart);
renderBadge(qty);
renderBasket(items);
updateLinks();
}
function renderButtons(cart) {
let buttons = document.querySelectorAll("button[data-id]");
for (let i = 0; i < buttons.length; i++) {
let btn = buttons[i];
let id = btn.getAttribute("data-id");
let qty = cart[id] || 0;
if (qty > 0) {
btn.className = "qty-ctrl";
empty(btn);
let minus = actionImg("/img/minus.png", "-", "minus", id);
let qtyEl = txt(span, qty + " " + L("unit"));
let plus = actionImg("/img/plus.png", "+", "plus", id);
btn.append(minus, qtyEl, plus);
} else {
btn.className = "";
btn.textContent = addToBasketText;
}
}
}
function createBadge() {
badge = a("hidden");
badge.id = "basket-badge";
badge.href = "#basket";
badge.append(img("/img/basket.png", L("basket")), txt(span, "0"));
badge.addEventListener("click", function(e) {
e.preventDefault();
if (lastQty === 0) { return; }
basketOpen = true;
renderBasket(getItems());
basketSection.scrollIntoView({ behavior: "smooth" });
});
document.querySelector("header").append(badge);
}
function renderBadge(qty) {
lastQty = qty;
badge.querySelector("span").textContent = qty;
if (qty > 0) { show(badge); }
else { hide(badge); }
}
function updateBadgePosition() {
if (!badge) { return; }
let badgeH = badge.offsetHeight || 80;
if (lastQty === 0) {
badge.style.top = "calc(50% - " + (badgeH / 2) + "px)";
return;
}
let rect = basketSection.getBoundingClientRect();
let badgeTop = rect.top - badgeH / 2;
if (navEl) {
let nc = navEl.getBoundingClientRect().top + navEl.offsetHeight / 2;
if (nc > 0) { badgeTop = Math.min(nc - badgeH / 2, badgeTop); }
}
badgeTop = Math.max(10, Math.min(badgeTop, window.innerHeight - badgeH - 10));
badge.style.top = badgeTop + "px";
}
function initBasketDOM() {
emptyEl = div("empty hidden");
emptyEl.append(img("/img/basket.png", L("basket")), txt(p, L("emptyBasket")));
let descP = p();
let pLink = a();
pLink.href = C.productsPage || "/pages/urunlerimiz.html";
pLink.textContent = L("productsLinkText");
descP.append(pLink, " " + L("emptyBasketDesc"));
emptyEl.append(descP);
basketSection.append(emptyEl);
if (warningText && !C.restaurantMode) {
descEl = h5("hidden");
parseBr(warningText, descEl);
basketSection.append(descEl);
}
wrapEl = div("wrap hidden");
toggleBtnEl = button();
toggleInfoEl = i();
toggleBtnEl.append(txt(b, L("basket")), toggleInfoEl, em());
toggleBtnEl.addEventListener("click", function() {
basketOpen = !basketOpen;
if (basketOpen) { show(contentEl); }
else { hide(contentEl); }
toggleBtnEl.classList.toggle("open", basketOpen);
updateBadgePosition();
});
wrapEl.append(toggleBtnEl);
contentEl = div("hidden");
itemsEl = div("items");
totalsEl = div("totals");
contentEl.append(itemsEl, totalsEl);
if (C.isBasketDesc && !C.restaurantMode) {
let descWrap = div("basket-desc-wrap");
descInputEl = document.createElement("textarea");
descInputEl.className = "basket-desc-input";
descInputEl.placeholder = L("basketDescPlaceholder");
descInputEl.title = L("basketDescTooltip");
descInputEl.rows = 2;
descWrap.append(descInputEl);
contentEl.append(descWrap);
}
let payOpts = C.paymentOptions || [];
if (payOpts.length > 1 && !C.restaurantMode) {
let payWrap = div("payment-options-wrap");
let radioGroup = div("payment-radios");
for (let pi = 0; pi < payOpts.length; pi++) {
let lbl = document.createElement("label");
let radio = document.createElement("input");
radio.type = "radio";
radio.name = "basket-payment";
radio.value = payOpts[pi];
if (pi === 0) { radio.checked = true; }
lbl.append(radio, " " + payOpts[pi]);
radioGroup.append(lbl);
}
payWrap.append(radioGroup);
contentEl.append(payWrap);
}
let waBtn = txt(button, L("whatsAppOrder"), "wa");
waBtn.addEventListener("click", function() { sendWhatsApp.apply(null, getOrderArgs()); });
contentEl.append(waBtn);
if (tgUsername) {
let tgBtn = txt(button, L("telegramOrder"), "tg");
tgBtn.addEventListener("click", function() { sendTelegram.apply(null, getOrderArgs()); });
contentEl.append(tgBtn);
}
if (waWarningText && !C.restaurantMode) {
let warn = h6();
parseBr(waWarningText, warn);
contentEl.append(warn);
}
if (window.WAITER_NAME || window.TABLE_NO) {
let infoEl = div("table-info");
if (window.WAITER_NAME) { infoEl.append(txt(span, L("waiterLabel") + ": " + window.WAITER_NAME)); }
if (window.TABLE_NO) { infoEl.append(txt(span, L("tableLabel") + ": " + window.TABLE_NO)); }
contentEl.append(infoEl);
}
wrapEl.append(contentEl);
basketSection.append(wrapEl);
}
function renderBasket(items) {
if (items.length === 0) {
show(emptyEl);
if (descEl) { hide(descEl); }
hide(wrapEl);
basketOpen = false;
hide(contentEl);
toggleBtnEl.classList.remove("open");
updateBadgePosition();
return;
}
hide(emptyEl);
if (descEl) { show(descEl); }
show(wrapEl);
if (basketOpen) { show(contentEl); }
else { hide(contentEl); }
toggleBtnEl.classList.toggle("open", basketOpen);
empty(itemsEl);
let subtotal = calcSubtotal(items);
for (let i = 0; i < items.length; i++) {
let item = items[i];
let lineTotal = item.price * item.quantity;
let row = div();
let del = actionImg("/img/delete.png", L("delete"), "delete", item.id, "del");
let qc = div("qty-ctrl");
let qMinus = actionImg("/img/minus.png", "-", "minus", item.id);
let qPlus = actionImg("/img/plus.png", "+", "plus", item.id);
qc.append(qMinus, txt(span, item.quantity), qPlus);
row.append(del, img("/img/products/" + item.img, item.name), txt(b, item.name), qc, txt(span, fmt(lineTotal) + " " + currencySymbol));
if (item.ord === 0) {
row.append(txt(small, L("notForOnlineOrder"), "not-for-order"));
}
itemsEl.append(row);
}
let totalQty = 0;
for (let i = 0; i < items.length; i++) { totalQty += items[i].quantity; }
toggleInfoEl.textContent = "(" + totalQty + " " + L("itemSuffix") + " " + L("for") + " " + L("total") + " " + fmt(subtotal) + " " + currencySymbol + ")";
empty(totalsEl);
let discountResult = calculateDiscount(items, subtotal);
let discountTotal = discountResult.totalDiscount;
let dLines = filterDiscountLines(discountResult.lines);
if (C.restaurantMode) {
if (discountTotal > 0) {
for (let di = 0; di < dLines.length; di++) {
totalsEl.append(makeRow(dLines[di].label + ":", "-" + fmt(dLines[di].amount) + " " + currencySymbol, "discount"));
}
}
totalsEl.append(makeRow(L("total") + ":", fmt(subtotal - discountTotal) + " " + currencySymbol, "total"));
} else {
let shipping = discountResult.freeShipping ? 0 : calculateShippingPrice(items);
let total = subtotal - discountTotal + shipping;
totalsEl.append(makeRow(L("subtotal") + ":", fmt(subtotal) + " " + currencySymbol));
if (discountTotal > 0) {
for (let di = 0; di < dLines.length; di++) {
totalsEl.append(makeRow(dLines[di].label + ":", "-" + fmt(dLines[di].amount) + " " + currencySymbol, "discount"));
}
}
let freeShippingCampaign = discountResult.freeShipping
? (discountResult.lines.filter(function(l) { return l.isFree; })[0] || {}).label || L("freeShipping")
: null;
let shippingLabel = freeShippingCampaign || (shipping > 0 ? fmt(shipping) + " " + currencySymbol : L("freeShipping"));
totalsEl.append(makeRow(L("shipping") + ":", shippingLabel));
totalsEl.append(makeRow(L("total") + ":", fmt(total) + " " + currencySymbol, "total"));
}
for (let hi = 0; hi < discountResult.hints.length; hi++) {
let hintEl = div("campaign-hint");
hintEl.textContent = discountResult.hints[hi];
totalsEl.append(hintEl);
}
if (discountResult.happyHourActive && C.timezone) {
let warnEl = div("happy-hour-warning");
warnEl.textContent = L("happyHourTimezoneWarning");
totalsEl.append(warnEl);
}
updateBadgePosition();
}
function updateLinks() {
let qs = location.search;
let links = document.querySelectorAll("a[href]");
for (let i = 0; i < links.length; i++) {
let link = links[i];
let href = link.getAttribute("href");
if (!href) { continue; }
if (href.charAt(0) === "#") { continue; }
if (href.indexOf("://") !== -1) { continue; }
if (href.indexOf("mailto:") === 0) { continue; }
if (href.indexOf("tel:") === 0) { continue; }
let hashPos = href.indexOf("#");
let hash = hashPos !== -1 ? href.substring(hashPos) : "";
let base = hashPos !== -1 ? href.substring(0, hashPos) : href;
base = base.split("?")[0];
link.setAttribute("href", base + qs + hash);
}
}
function getSelectedPayment() {
let opts = C.paymentOptions || [];
if (opts.length === 0) { return ""; }
if (opts.length === 1) { return opts[0]; }
let radios = document.querySelectorAll('input[name="basket-payment"]');
for (let r = 0; r < radios.length; r++) {
if (radios[r].checked) { return radios[r].value; }
}
return opts[0];
}
function getBasketDesc() {
if (!descInputEl) { return ""; }
return descInputEl.value.trim();
}
function getOrderArgs() {
let items = getItems();
let subtotal = calcSubtotal(items);
let discountResult = calculateDiscount(items, subtotal);
let shipping = (C.restaurantMode || discountResult.freeShipping) ? 0 : calculateShippingPrice(items);
return [items, subtotal, discountResult, shipping, subtotal - discountResult.totalDiscount + shipping];
}
function buildOrderMsg(greetingKey, items, subtotal, discountResult, shipping, total) {
let msg = "";
if (window.WAITER_NAME) { msg += "[" + L("waiterLabel") + ": " + window.WAITER_NAME + "]\n"; }
if (window.TABLE_NO) { msg += "[" + L("tableLabel") + ": " + window.TABLE_NO + "]\n"; }
msg += L(greetingKey) + "\n\n";
for (let i = 0; i < items.length; i++) {
msg += "*" + items[i].quantity + " x " + items[i].name + "*: " + fmt(items[i].price * items[i].quantity) + " " + currencySymbol + "\n";
}
let allLines = discountResult ? discountResult.lines : [];
let dLines = filterDiscountLines(allLines);
if (!C.restaurantMode) {
let freeLabel = (discountResult && discountResult.freeShipping)
? ((allLines.filter(function(l) { return l.isFree; })[0] || {}).label || L("freeShipping"))
: null;
msg += L("shipping") + ": " + (freeLabel || (shipping > 0 ? fmt(shipping) + " " + currencySymbol : L("freeShipping"))) + "\n";
}
msg += L("total") + ": *" + fmt(total) + " " + currencySymbol + "*";
let extras = [];
let payment = getSelectedPayment();
if (payment) { extras.push(L("paymentLabel") + ": *" + payment + "*"); }
for (let di = 0; di < dLines.length; di++) {
extras.push(dLines[di].label + ": *-" + fmt(dLines[di].amount) + " " + currencySymbol + "*");
}
let desc = getBasketDesc();
if (desc) { extras.push(L("noteLabel") + ": " + desc); }
if (extras.length > 0) { msg += "\n\n" + extras.join("\n"); }
return msg;
}
function sendWhatsApp(items, subtotal, discountResult, shipping, total) {
let encoded = encodeURIComponent(buildOrderMsg("whatsAppGreeting", items, subtotal, discountResult, shipping, total));
if (IS_MOBILE) { window.open("https://wa.me/" + waNumber + "?text=" + encoded, "_blank"); }
else { window.open("https://web.whatsapp.com/send?phone=" + waNumber + "&text=" + encoded, "_blank"); }
}
function sendTelegram(items, subtotal, discountResult, shipping, total) {
let encoded = encodeURIComponent(buildOrderMsg("telegramGreeting", items, subtotal, discountResult, shipping, total));
window.open("https://t.me/" + tgUsername + "?text=" + encoded, "_blank");
}
document.addEventListener("click", function(e) {
let t = e.target;
if (t.tagName === "IMG" && t.hasAttribute("data-action")) {
e.stopPropagation();
let action = t.getAttribute("data-action");
let id = t.getAttribute("data-id");
if (action === "plus") { updateQty(id, 1); }
else if (action === "minus") { updateQty(id, -1); }
else if (action === "delete") { removeItem(id); }
return;
}
let btn = t;
while (btn && btn.tagName !== "BUTTON") { btn = btn.parentElement; }
if (btn && btn.hasAttribute("data-id") && !btn.classList.contains("qty-ctrl")) {
addToBasket(btn.getAttribute("data-id"));
}
});
document.addEventListener("DOMContentLoaded", function() {
createBadge();
navEl = document.querySelector("nav");
let fb = document.querySelector("button[data-id]");
if (fb) { addToBasketText = fb.textContent.trim(); }
initBasketDOM();
if (getItems().length > 0) { basketOpen = true; }
render();
window.addEventListener("scroll", updateBadgePosition, { passive: true });
window.addEventListener("resize", updateBadgePosition, { passive: true });
document.addEventListener("click", function(e) {
let a = e.target;
while (a && a.tagName !== "A") { a = a.parentElement; }
if (!a || !a.hasAttribute("data-ci")) { return; }
let ci = parseInt(a.getAttribute("data-ci"), 10);
if (isNaN(ci) || ci < 0 || ci >= CAMPAIGN_CONFIG.length) { return; }
let c = CAMPAIGN_CONFIG[ci];
if (!c || !c.addProducts || !c.addProducts.length) {
e.preventDefault();
basketOpen = true;
renderBasket(getItems());
basketSection.scrollIntoView({ behavior: "smooth" });
return;
}
let items = getItems();
let subtotal = calcSubtotal(items);
let disc = calculateDiscount(items, subtotal);
let alreadyApplied = false;
if (c.type === "free_shipping") { alreadyApplied = disc.freeShipping; }
else {
for (let li = 0; li < disc.lines.length; li++) {
if (disc.lines[li].label === c.label) { alreadyApplied = true; break; }
}
}
e.preventDefault();
if (!alreadyApplied) {
let cart = getCart();
for (let i = 0; i < c.addProducts.length; i++) {
let ap = c.addProducts[i];
cart[ap.id] = (cart[ap.id] || 0) + ap.qty;
}
setCart(cart);
}
basketOpen = true;
renderBasket(getItems());
basketSection.scrollIntoView({ behavior: "smooth" });
});
});
})();

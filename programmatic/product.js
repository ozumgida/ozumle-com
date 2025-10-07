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

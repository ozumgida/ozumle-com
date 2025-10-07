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

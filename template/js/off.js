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

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

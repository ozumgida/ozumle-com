let _nav = document.querySelector("nav");
if (_nav) { _nav.addEventListener("click", function(e) { if (e.target === this) { this.classList.toggle("open"); } }); }

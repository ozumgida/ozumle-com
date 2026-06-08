(function() {
  var catsEl = document.querySelector('.filter-cats');
  var tagsEl = document.querySelector('.filter-tags');
  if (!catsEl) return;

  var selectedCats = [];
  var selectedTags = [];

  function getItems() {
    return document.querySelectorAll('ul.prd li');
  }

  function applyFilter() {
    var items = getItems();
    for (var i = 0; i < items.length; i++) {
      var item = items[i];
      var cat = item.dataset.cat || '';
      var tags = item.dataset.tags ? item.dataset.tags.split(' ') : [];
      var catOk = !selectedCats.length || selectedCats.indexOf(cat) !== -1;
      var tagOk = !selectedTags.length || selectedTags.some(function(t) { return tags.indexOf(t) !== -1; });
      item.hidden = !(catOk && tagOk);
    }
    // Hide empty groups
    var groups = document.querySelectorAll('.cat-group');
    for (var g = 0; g < groups.length; g++) {
      var visible = groups[g].querySelectorAll('li:not([hidden])');
      groups[g].hidden = visible.length === 0;
    }
  }

  function updateTagRow() {
    if (!tagsEl) return;
    var chips = tagsEl.querySelectorAll('.chip');
    for (var i = 0; i < chips.length; i++) {
      var chip = chips[i];
      var tag = chip.dataset.tag;
      var relevant = false;
      if (!selectedCats.length) {
        relevant = true;
      } else {
        var items = getItems();
        for (var j = 0; j < items.length; j++) {
          var item = items[j];
          if (selectedCats.indexOf(item.dataset.cat || '') !== -1) {
            var tags = item.dataset.tags ? item.dataset.tags.split(' ') : [];
            if (tags.indexOf(tag) !== -1) { relevant = true; break; }
          }
        }
      }
      chip.hidden = !relevant;
      if (!relevant) {
        chip.classList.remove('active');
        var idx = selectedTags.indexOf(tag);
        if (idx !== -1) selectedTags.splice(idx, 1);
      }
    }
  }

  catsEl.addEventListener('click', function(e) {
    var chip = e.target.closest ? e.target.closest('.chip') : e.target;
    if (!chip || !chip.classList.contains('chip')) return;
    var cat = chip.dataset.cat;

    if (cat === '') {
      selectedCats = [];
      selectedTags = [];
      var allCatChips = catsEl.querySelectorAll('.chip');
      for (var i = 0; i < allCatChips.length; i++) allCatChips[i].classList.remove('active');
      if (tagsEl) {
        var allTagChips = tagsEl.querySelectorAll('.chip');
        for (var j = 0; j < allTagChips.length; j++) allTagChips[j].classList.remove('active');
      }
      chip.classList.add('active');
    } else {
      var allBtn = catsEl.querySelector('[data-cat=""]');
      if (allBtn) allBtn.classList.remove('active');
      var idx = selectedCats.indexOf(cat);
      if (idx === -1) { selectedCats.push(cat); chip.classList.add('active'); }
      else            { selectedCats.splice(idx, 1); chip.classList.remove('active'); }
      if (!selectedCats.length && allBtn) allBtn.classList.add('active');
    }

    updateTagRow();
    applyFilter();
  });

  if (tagsEl) {
    tagsEl.addEventListener('click', function(e) {
      var chip = e.target.closest ? e.target.closest('.chip') : e.target;
      if (!chip || !chip.classList.contains('chip')) return;
      var tag = chip.dataset.tag;
      var idx = selectedTags.indexOf(tag);
      if (idx === -1) { selectedTags.push(tag); chip.classList.add('active'); }
      else            { selectedTags.splice(idx, 1); chip.classList.remove('active'); }
      applyFilter();
    });
  }
})();

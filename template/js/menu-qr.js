(function() {
  var params = new URLSearchParams(location.search);
  window.TABLE_NO = params.get('t') || '';
  window.WAITER_NAME = localStorage.getItem('waiter') || '';
})();

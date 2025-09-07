(function(){
  function getLocale(){
    var urlParams = new URLSearchParams(window.location.search);
    var p = urlParams.get('locale');
    if (p) { try { localStorage.setItem('locale', p); } catch(e){} return p; }
    try { var s = localStorage.getItem('locale'); if (s) return s; } catch(e){}
    return (navigator.language || '').toLowerCase().indexOf('ja')>=0 ? 'ja' : 'en';
  }
  function applyI18n(){
    var loc = getLocale();
    document.documentElement.setAttribute('data-locale', loc);
    var dict = (window.I18N && window.I18N[loc]) || {};
    document.querySelectorAll('.i18n').forEach(function(el){
      var key = el.getAttribute('data-key');
      var parts = key.split('.');
      var cur = dict; parts.forEach(function(k){ if(cur) cur = cur[k]; });
      if (cur && typeof cur === 'string') el.textContent = cur;
    });
  }
  function loadTopCompanies(){
    fetch('/companies.json?per=5').then(function(r){return r.json()}).then(function(items){
      var ul = document.getElementById('top-companies-nav'); if(!ul) return;
      ul.innerHTML='';
      items.slice(0,5).forEach(function(c){
        var li=document.createElement('li');
        var a=document.createElement('a'); a.href='/companies/'+c.id; a.textContent=c.name; li.appendChild(a);
        ul.appendChild(li);
      });
    }).catch(function(){});
  }
  document.addEventListener('DOMContentLoaded', function(){
    applyI18n();
    loadTopCompanies();
  });
})();

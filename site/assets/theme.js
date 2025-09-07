// Theme init and toggle
(function initTheme(){
  try {
    var stored = localStorage.getItem('theme');
    var prefersDark = window.matchMedia && window.matchMedia('(prefers-color-scheme: dark)').matches;
    var theme = stored || (prefersDark ? 'dark' : 'light');
    document.documentElement.setAttribute('data-theme', theme);
  } catch (e) {
    document.documentElement.setAttribute('data-theme', 'dark');
  }
})();

window.addEventListener('DOMContentLoaded', function(){
  var btns = document.querySelectorAll('.theme-toggle');
  function updateLabel(){
    var theme = document.documentElement.getAttribute('data-theme');
    // Show the icon for the NEXT theme (toggle hint): 🌞 switches to light, 🌙 switches to dark
    var nextIcon = theme === 'dark' ? '🌞' : '🌙';
    var nextTitle = theme === 'dark' ? 'Switch to bright theme' : 'Switch to dark theme';
    btns.forEach(function(btn){
      btn.textContent = nextIcon;
      btn.setAttribute('aria-label', nextTitle);
      btn.setAttribute('title', nextTitle);
    });
  }
  updateLabel();

  btns.forEach(function(btn){
    btn.addEventListener('click', function(){
      var current = document.documentElement.getAttribute('data-theme');
      var next = current === 'dark' ? 'light' : 'dark';
      document.documentElement.setAttribute('data-theme', next);
      try { localStorage.setItem('theme', next); } catch (e) {}
      updateLabel();
    });
  });
});


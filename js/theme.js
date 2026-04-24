(function(){
  var t = localStorage.getItem('alex-theme') || 'light';
  document.documentElement.setAttribute('data-theme', t);
})();
function toggleTheme(){
  var c = document.documentElement.getAttribute('data-theme');
  var n = c === 'light' ? 'dark' : 'light';
  document.documentElement.setAttribute('data-theme', n);
  localStorage.setItem('alex-theme', n);
}
document.addEventListener('DOMContentLoaded', function(){
  var path = location.pathname.split('/').pop() || 'index.html';
  document.querySelectorAll('.nav-links a').forEach(function(a){
    var href = (a.getAttribute('href') || '');
    if(href && href !== '#' && href !== '' && path === href) a.classList.add('active');
  });
});

(function(){
  var saved=null; try{saved=localStorage.getItem('lang')}catch(e){}
  var q=new URLSearchParams(location.search).get('lang');
  var l=q||saved||((navigator.language||'en').toLowerCase().indexOf('tr')===0?'tr':'en');
  function set(x){document.documentElement.className=x;document.documentElement.lang=x;
    document.querySelectorAll('.lang button').forEach(function(b){b.classList.toggle('on',b.dataset.l===x)});
    try{localStorage.setItem('lang',x)}catch(e){}}
  set(l);
  document.addEventListener('DOMContentLoaded',function(){set(l);
    document.querySelectorAll('.lang button').forEach(function(b){b.onclick=function(){l=b.dataset.l;set(l)}})});
})();

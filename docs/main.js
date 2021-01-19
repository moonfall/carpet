console.log("hello");
console.log(location.hash);
window.addEventListener("hashchange", function (){
  var contentDiv = document.getElementById("app");
  contentDiv.innerHTML = location.hash;
});

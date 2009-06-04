function swap(id) {
  var elem = document.getElementById("f" + id);
  var link = document.getElementById("link" + id);
  var text = link.childNodes[0];

  if (elem.className == "hidden") {
    elem.className = "visible";
    text.data = "-";
  } else {
    elem.className = "hidden";
    text.data = "+";
  }
}

function adapter() {
  const dip = document.documentElement.clientWidth;
  const rootFontSize = dip / 20;
  document.documentElement.style.fontSize = rootFontSize + "px";
}
adapter();
window.onresize = adapter;

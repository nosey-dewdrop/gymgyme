// topbar.js - her sayfanın üstü: hareket arayan arama çubuğu + "my moves (n)"
// dropdown'ı. beğeniler cihazda durur (gg_mymoves); moves.html ile ortak dil.
(function () {
  // gorunur surum etiketi (Damla kurali: github.io testinde hangi surume
  // baktigin belli olsun) - sw.js cache surumuyle birlikte elle guncellenir.
  const GG_V = "v60";
  const bar = document.querySelector(".topbar");
  if (bar) {
    const v = document.createElement("span");
    v.className = "vtag";
    v.textContent = GG_V;
    bar.appendChild(v);
  }
  // HER SAYFANIN ALTINA da görünür sürüm (Damla: aşağı kaydırınca da görülsün,
  // cache eski mi anlaşılsın). sayfa sonuna küçük bir satır.
  window.addEventListener("DOMContentLoaded", function () {
    const f = document.createElement("p");
    f.textContent = "gymgyme " + GG_V;
    f.style.cssText = "text-align:center;font-size:11px;opacity:.5;color:#7a0a24;margin:18px 0 14px;";
    document.body.appendChild(f);
  });

  const KEY = "gg_mymoves";

  function getKept() {
    try { return JSON.parse(localStorage.getItem(KEY)) || []; } catch (_) { return []; }
  }
  function setKept(list) {
    try { localStorage.setItem(KEY, JSON.stringify(list)); } catch (_) {}
    window.dispatchEvent(new Event("gg-mymoves-changed"));
  }
  function toggleMove(m) {
    const list = getKept();
    const i = list.indexOf(m);
    if (i === -1) list.push(m); else list.splice(i, 1);
    setKept(list);
  }
  // moves.html ve coach.js de kullanır
  window.GG_MYMOVES = { get: getKept, toggle: toggleMove };

  function movesFlat() {
    const out = [];
    if (typeof MOVE_DB === "undefined") return out;
    Object.keys(MOVE_DB).forEach((c) => MOVE_DB[c].forEach((m) => out.push({ m, c })));
    return out;
  }

  // ── arama: sonuçlar listelenir, sayfa ancak TIKLANINCA değişir ──
  const search = document.getElementById("topSearch");
  const drop = document.getElementById("searchDrop");
  if (search && drop) {
    search.addEventListener("input", function () {
      const v = this.value.trim().toLowerCase();
      drop.innerHTML = "";
      if (!v) { drop.classList.remove("open"); return; }
      const hits = movesFlat().filter((x) => x.m.indexOf(v) !== -1).slice(0, 8);
      hits.forEach((x) => {
        const d = document.createElement("div");
        d.className = "sr";
        const name = document.createElement("span"); name.textContent = x.m;
        const cat = document.createElement("small"); cat.textContent = x.c;
        d.append(name, cat);
        d.addEventListener("click", () => { location.href = "moves.html?q=" + encodeURIComponent(x.m); });
        drop.appendChild(d);
      });
      const foot = document.createElement("div");
      foot.className = "sr srall";
      foot.textContent = hits.length ? "see all results in the moves list" : "no such move yet - suggest it!";
      foot.addEventListener("click", () => {
        location.href = hits.length ? "moves.html?q=" + encodeURIComponent(v) : "suggest.html";
      });
      drop.appendChild(foot);
      drop.classList.add("open");
    });
    document.addEventListener("click", (e) => {
      if (!e.target.closest(".searchwrap")) drop.classList.remove("open");
    });
  }

  // ── my moves artık kendi SAYFASI (Damla, 15 tem): nav'daki sayaç linki
  // güncel kalır; sıralama + playlist kurma my-moves.html'de yaşar. ──
  const btn = document.getElementById("movesBtn");
  if (!btn) return;
  function renderKept() {
    btn.textContent = "my moves (" + getKept().length + ")";
  }
  renderKept();
  window.addEventListener("gg-mymoves-changed", renderKept);
  window.addEventListener("storage", renderKept);
})();

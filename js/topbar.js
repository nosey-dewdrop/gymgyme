// topbar.js - her sayfanın üstü: hareket arayan arama çubuğu + "my moves (n)"
// dropdown'ı. beğeniler cihazda durur (gg_mymoves); moves.html ile ortak dil.
(function () {
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

  // ── my moves dropdown: hover'la açılır, beğenilenleri listeler ──
  const btn = document.getElementById("movesBtn");
  const panel = document.getElementById("movesPanel");
  if (!btn || !panel) return;
  let closeT = null;
  const show = () => { clearTimeout(closeT); btn.classList.add("open"); panel.classList.add("open"); };
  const hide = () => { closeT = setTimeout(() => { btn.classList.remove("open"); panel.classList.remove("open"); }, 250); };
  [btn, panel].forEach((el) => {
    el.addEventListener("mouseenter", show);
    el.addEventListener("mouseleave", hide);
  });
  btn.addEventListener("click", () => {   // dokunmatik için
    panel.classList.contains("open") ? hide() : show();
  });

  function renderKept() {
    const kept = getKept();
    btn.textContent = "my moves (" + kept.length + ")";
    panel.innerHTML = "";
    const hint = document.createElement("p");
    hint.className = "mhint";
    hint.textContent = "the moves you liked - they line up in your next workout.";
    panel.appendChild(hint);
    if (!kept.length) {
      const e = document.createElement("p");
      e.className = "mhint";
      e.innerHTML = 'nothing yet - open the <a href="moves.html" style="color:var(--cherry);font-weight:bold">moves list</a> and ♥ a few.';
      panel.appendChild(e);
      return;
    }
    kept.forEach((m) => {
      const d = document.createElement("div");
      d.className = "krow";
      const name = document.createElement("span"); name.textContent = m;
      const x = document.createElement("button");
      x.type = "button"; x.textContent = "♥"; x.title = "unlike";
      x.addEventListener("click", (e) => { e.stopPropagation(); toggleMove(m); });
      d.append(name, x);
      panel.appendChild(d);
    });
    const foot = document.createElement("p");
    foot.className = "kfoot";
    foot.innerHTML = 'build tonight\'s set list with these on the <a href="coach.html">personal trainer</a>.';
    panel.appendChild(foot);
  }
  renderKept();
  window.addEventListener("gg-mymoves-changed", renderKept);
  window.addEventListener("storage", renderKept);
})();

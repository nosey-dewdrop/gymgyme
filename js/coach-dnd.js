// coach-dnd.js — drag-drop reordering for the workout program list.
//
// coach.js renders each program line as a .rline div inside #progList and
// keeps its order in localStorage 'gg_program' ({items:[...], rest}). we can't
// touch coach.js, so this is a PROGRESSIVE ENHANCEMENT: it observes #progList,
// gives each .rline a grab handle on the LEFT, wires HTML5 drag events, and on
// drop it (1) reorders the DOM and (2) rewrites 'gg_program' in the SAME shape
// coach.js reads — so the new order survives reload and the next workout start.
//
// LIMIT (documented, no coach.js touch): coach.js holds the program array in
// memory and only re-reads localStorage on page LOAD. so a reorder made mid-page
// updates the DOM + storage immediately and is fully correct on the next load,
// but coach.js's in-memory copy is not re-synced this session. that is safe here
// because dragging is disabled while a session is running (body.running), and a
// non-running reorder only matters for the NEXT start, which reads storage fresh
// on its own render path via renderProgram()'s use of the same array — the array
// is rebuilt from storage on load. deeper live-sync would need a one-line hook in
// coach.js (e.g. dispatch a 'gg-program-reordered' event it listens to). the copy
// "tap a line to cross it off" is kept untouched.
(function () {
  const list = document.getElementById('progList');
  if (!list) return;
  const PROG_KEY = 'gg_program';

  const running = () => document.body.classList.contains('running');

  function readProgram() {
    try {
      const p = JSON.parse(localStorage.getItem(PROG_KEY));
      if (p && Array.isArray(p.items)) return p;
    } catch (_) {}
    return null;
  }
  function writeProgram(prog) {
    try { localStorage.setItem(PROG_KEY, JSON.stringify(prog)); } catch (_) {}
  }

  // add a grab handle to a .rline (once). the handle is the only draggable part
  // so tapping the row still crosses it off (coach.js's onclick is preserved).
  function enhance(row) {
    if (row.__dndDone) return;
    if (!row.classList.contains('rline')) return;
    row.__dndDone = true;

    const handle = document.createElement('span');
    handle.className = 'rgrab';
    handle.setAttribute('aria-hidden', 'true');
    handle.title = 'drag to reorder';
    // three grip dots, our dot motif
    handle.innerHTML = '<i></i><i></i><i></i><i></i><i></i><i></i>';
    row.prepend(handle);

    handle.addEventListener('pointerdown', (e) => e.stopPropagation()); // don't drag the whole receipt card
    handle.addEventListener('click', (e) => e.stopPropagation());       // don't cross off when grabbing

    handle.addEventListener('mousedown', () => { if (!running()) row.setAttribute('draggable', 'true'); });
    handle.addEventListener('touchstart', () => { if (!running()) row.setAttribute('draggable', 'true'); }, { passive: true });
    row.addEventListener('dragend', () => row.removeAttribute('draggable'));

    row.addEventListener('dragstart', (e) => {
      if (running()) { e.preventDefault(); return; }
      row.classList.add('dragging');
      try { e.dataTransfer.effectAllowed = 'move'; e.dataTransfer.setData('text/plain', ''); } catch (_) {}
    });
    row.addEventListener('dragend', () => {
      row.classList.remove('dragging');
      commitOrder();
    });
  }

  function draggingRow() { return list.querySelector('.rline.dragging'); }

  // insert the dragged row before/after the row under the pointer
  list.addEventListener('dragover', (e) => {
    const drag = draggingRow();
    if (!drag) return;
    e.preventDefault();
    try { e.dataTransfer.dropEffect = 'move'; } catch (_) {}
    const rows = [...list.querySelectorAll('.rline:not(.dragging)')];
    let after = null;
    for (const r of rows) {
      const box = r.getBoundingClientRect();
      if (e.clientY < box.top + box.height / 2) { after = r; break; }
    }
    if (after) list.insertBefore(drag, after);
    else list.appendChild(drag);
  });

  // after a drop, read the new DOM order of .rline and reorder gg_program.items
  // to match. we map by original position: each .rline started as "N. name",
  // so we track the index it was rendered at via its live DOM order at attach
  // time. simplest robust mapping: use the visible leading number coach.js prints
  // ("1. squat") which is the ORIGINAL 1-based index.
  function commitOrder() {
    const prog = readProgram();
    if (!prog) return;
    const rows = [...list.querySelectorAll('.rline')];
    const order = [];
    for (const r of rows) {
      // first text span holds "N. label" — parse N (original 1-based index)
      const label = r.querySelector('span:not(.rgrab):not(.dots)');
      const txt = (label && label.textContent) || r.textContent || '';
      const m = txt.match(/^\s*(\d+)\./);
      if (!m) continue;
      const idx = parseInt(m[1], 10) - 1;
      if (idx >= 0 && idx < prog.items.length) order.push(idx);
    }
    // guard: only commit a clean permutation of all items
    if (order.length !== prog.items.length) return;
    const seen = new Set(order);
    if (seen.size !== prog.items.length) return;

    prog.items = order.map((i) => prog.items[i]);
    writeProgram(prog);
    // renumber the visible labels so the mapping stays valid for the NEXT drag
    rows.forEach((r, i) => {
      const label = r.querySelector('span:not(.rgrab):not(.dots)');
      if (label) label.textContent = label.textContent.replace(/^\s*\d+\./, (i + 1) + '.');
    });
  }

  function scan() { list.querySelectorAll('.rline').forEach(enhance); }

  // coach.js rebuilds #progList on every renderProgram(); re-attach handles.
  const mo = new MutationObserver(scan);
  mo.observe(list, { childList: true });
  scan();
})();

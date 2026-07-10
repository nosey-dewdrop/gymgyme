// directory page - vanilla JS, no build, no libraries, NO backend.
// navbar picks the category (hash routing); importance = font size, that's it.
// content = bundled seed (suggestions arrive by mail and get merged in); my program = localStorage.
const CATEGORIES = ['healthy-living-articles', 'home-workouts', 'pilates', 'ballet', 'yoga', 'gym', 'calisthenics', 'bodyweight'];
const DEFAULT_CATEGORY = 'home-workouts';
const PROGRAM_KEY = 'hl_program';

let allEntries = [...SEED_ENTRIES];

// more recommended = bigger font. size is the only hierarchy on this site.
function linkSize(count, max) {
  const t = max <= 1 ? 0 : Math.min((count - 1) / (max - 1), 1);
  return (13 + t * 11).toFixed(1) + 'px'; // 13px → 24px
}

// deterministic color per contributor name - dark enough to read on pink
function nameColor(name) {
  let h = 0;
  for (const ch of name.toLowerCase()) h = (h * 31 + ch.charCodeAt(0)) >>> 0;
  return `hsl(${h % 360}, 65%, 26%)`;
}

function el(tag, cls, text) {
  const n = document.createElement(tag);
  if (cls) n.className = cls;
  if (text) n.textContent = text;
  return n;
}

// ---- my program (localStorage, full add/remove/clear) ----
function getProgram() {
  try { return JSON.parse(localStorage.getItem(PROGRAM_KEY)) || []; } catch { return []; }
}
function saveProgram(list) {
  localStorage.setItem(PROGRAM_KEY, JSON.stringify(list));
  updateProgramCount();
}
// several moves can share one source url (e.g. NHS pages) - identity is title+url
function moveKey(m) { return m.title + '|' + m.url; }
function inProgram(entry) { return getProgram().some(m => moveKey(m) === moveKey(entry)); }
function toggleProgram(entry) {
  const list = getProgram();
  const i = list.findIndex(m => moveKey(m) === moveKey(entry));
  if (i >= 0) list.splice(i, 1);
  else list.push({ title: entry.title, url: entry.url, description: entry.description, category: entry.category, how: entry.how, muscles: entry.muscles, durationSec: entry.durationSec });
  saveProgram(list);
  render();
}
function moveInProgram(key, dir) {
  const list = getProgram();
  const i = list.findIndex(m => moveKey(m) === key);
  const j = i + dir;
  if (i < 0 || j < 0 || j >= list.length) return;
  [list[i], list[j]] = [list[j], list[i]];
  saveProgram(list);
  render();
}
function updateProgramCount() {
  const n = getProgram().length;
  const link = document.getElementById('nav-program');
  if (link) link.textContent = n ? `my program (${n})` : 'my program';
}

// ---- profile: name + interest, localStorage only ----
const PROFILE_KEY = 'hl_profile';
function getProfile() {
  try { return JSON.parse(localStorage.getItem(PROFILE_KEY)); } catch { return null; }
}
function renderGreet() {
  const box = document.getElementById('greet');
  box.textContent = '';
  const p = getProfile();
  if (!p || !p.name) return; // onboarding takes over the page instead
  box.appendChild(el('span', null, `hi, ${p.name}! good day to move a little.`));
  const edit = el('button', 'mini', 'not you?');
  edit.onclick = () => { localStorage.removeItem(PROFILE_KEY); renderGreet(); render(); };
  box.append(' ', edit);
}

// first visit: the page itself is the onboarding, then never again
function renderOnboarding(dir) {
  document.getElementById('cat-title').textContent = 'welcome!';
  dir.appendChild(el('p', 'tag', 'before you wander around: two tiny questions. everything stays in your browser, we never see it.'));

  const name = el('input');
  name.placeholder = 'what should we call you?';
  name.maxLength = 40;
  const nameP = el('p', 'ob-row');
  nameP.appendChild(name);
  dir.appendChild(nameP);

  dir.appendChild(el('p', 'ob-label', 'and what do you do? pick as many as you like:'));
  const boxes = [];
  const list = el('p', 'ob-row');
  for (const c of CATEGORIES.filter(c => c !== 'healthy-living-articles')) {
    const lab = el('label', 'ob-check');
    const cb = el('input');
    cb.type = 'checkbox';
    cb.value = c;
    boxes.push(cb);
    lab.appendChild(cb);
    lab.append(' ' + c);
    list.appendChild(lab);
  }
  dir.appendChild(list);

  const go = el('button', null, "let's go");
  go.onclick = () => {
    const n = name.value.trim();
    if (!n) { name.focus(); return; }
    const interests = boxes.filter(b => b.checked).map(b => b.value);
    localStorage.setItem(PROFILE_KEY, JSON.stringify({ name: n, interests }));
    location.hash = '#' + (interests[0] || DEFAULT_CATEGORY);
    renderGreet();
    render();
  };
  const goP = el('p', 'ob-row');
  goP.appendChild(go);
  dir.appendChild(goP);
}

function currentCategory() {
  const hash = location.hash.replace('#', '');
  if (hash === 'my-program') return 'my-program';
  if (CATEGORIES.includes(hash)) return hash;
  const p = getProfile();
  const first = p && (p.interests && p.interests[0] || p.interest);
  return CATEGORIES.includes(first) ? first : DEFAULT_CATEGORY;
}

// ---- workout days + last-done + day plans (localStorage) ----
const DAYS_KEY = 'hl_days';
const LASTDONE_KEY = 'hl_lastdone';
const PLAN_KEY = 'hl_plan';
function getPlan() { try { return JSON.parse(localStorage.getItem(PLAN_KEY)) || {}; } catch { return {}; } }
function savePlan(plan) { localStorage.setItem(PLAN_KEY, JSON.stringify(plan)); }
function addToDay(iso, m) {
  const plan = getPlan();
  const day = plan[iso] || [];
  if (!day.some(x => moveKey(x) === moveKey(m))) day.push({ title: m.title, url: m.url, description: m.description, how: m.how });
  plan[iso] = day;
  savePlan(plan);
  render();
}
function removeFromDay(iso, m) {
  const plan = getPlan();
  plan[iso] = (plan[iso] || []).filter(x => moveKey(x) !== moveKey(m));
  if (!plan[iso].length) delete plan[iso];
  savePlan(plan);
  render();
}
function isoToday() { const d = new Date(); return d.getFullYear() + '-' + String(d.getMonth() + 1).padStart(2, '0') + '-' + String(d.getDate()).padStart(2, '0'); }
function getDays() { try { return JSON.parse(localStorage.getItem(DAYS_KEY)) || []; } catch { return []; } }
function toggleDay(iso) {
  const days = getDays();
  const i = days.indexOf(iso);
  if (i >= 0) days.splice(i, 1); else days.push(iso);
  localStorage.setItem(DAYS_KEY, JSON.stringify(days));
  render();
}
function getLastDone() { try { return JSON.parse(localStorage.getItem(LASTDONE_KEY)) || {}; } catch { return {}; } }
function markDone(m) {
  const map = getLastDone();
  map[moveKey(m)] = isoToday();
  localStorage.setItem(LASTDONE_KEY, JSON.stringify(map));
  const days = getDays();
  if (!days.includes(isoToday())) { days.push(isoToday()); localStorage.setItem(DAYS_KEY, JSON.stringify(days)); }
  render();
}
function getMeta(m) {
  const found = allEntries.find(e => moveKey(e) === moveKey(m)) || {};
  return { how: m.how || found.how, muscles: m.muscles || found.muscles || [], durationSec: m.durationSec || found.durationSec || null };
}
function getHow(m) { return getMeta(m).how; }

// program stats: how long it takes and whether it's all legs
function renderProgramStats(dir, list) {
  const metas = list.map(getMeta);
  const totalSec = metas.reduce((s, m) => s + (m.durationSec || 45), 0);
  const mins = Math.max(1, Math.round(totalSec / 60));
  const counts = {};
  for (const m of metas) for (const mus of m.muscles) counts[mus] = (counts[mus] || 0) + 1;
  const parts = Object.entries(counts).sort((a, b) => b[1] - a[1]);
  const spread = parts.map(([k, v]) => k + ' ×' + v).join(', ');
  const p = el('p', 'progstats');
  p.appendChild(el('span', null, 'duration: ~' + mins + ' min'));
  if (spread) p.appendChild(el('span', null, ' - muscles: ' + spread));
  dir.appendChild(p);
  const totalTags = parts.reduce((s, [, v]) => s + v, 0);
  if (parts.length && list.length >= 3 && parts[0][1] / totalTags > 0.55) {
    dir.appendChild(el('p', 'progstats nudge', 'heads up: this program is mostly ' + parts[0][0] + ' - maybe sprinkle in some ' + (parts[0][0] === 'core' ? 'legs or back' : 'core or back') + '?'));
  }
}
// every move row gets a "how?" toggle - hover works too, but click is for everyone
function appendHow(dir, row, how) {
  const p = el('p', 'howto hidden', how);
  const btn = el('button', 'mini', 'how?');
  btn.onclick = () => {
    const hidden = p.classList.toggle('hidden');
    btn.textContent = hidden ? 'how?' : 'got it';
  };
  row.append(' ', btn);
  dir.appendChild(row);
  dir.appendChild(p);
}

function lastDoneText(m) {
  const iso = getLastDone()[moveKey(m)];
  if (!iso) return 'never';
  const diff = Math.round((new Date(isoToday()) - new Date(iso)) / 86400000);
  if (diff <= 0) return 'today';
  if (diff === 1) return 'yesterday';
  return diff + ' days ago';
}

let calOffset = 0; // months back/forward from the current one
let selectedDay = null; // clicked day shows its plan below the calendar
let armedMove = null; // two-tap planning for touch: tap "plan" on a move, then tap a day

function renderCalendar(dir) {
  const now = new Date();
  const shown = new Date(now.getFullYear(), now.getMonth() + calOffset, 1);
  const y = shown.getFullYear(), mo = shown.getMonth();
  const monthName = shown.toLocaleString('en', { month: 'long' }).toLowerCase();

  const head = el('p', 'cal-head');
  const prev = el('button', 'mini', '‹ earlier');
  prev.onclick = () => { calOffset--; render(); };
  const title = el('h2', 'cal-title', monthName + ' ' + y);
  const next = el('button', 'mini', 'later ›');
  next.onclick = () => { calOffset++; render(); };
  head.append(prev, title, next);
  dir.appendChild(head);

  const days = getDays();
  const grid = el('div', 'cal');
  for (const d of ['mo', 'tu', 'we', 'th', 'fr', 'sa', 'su']) grid.appendChild(el('span', 'cal-h', d));
  const firstDow = (new Date(y, mo, 1).getDay() + 6) % 7; // monday first
  for (let i = 0; i < firstDow; i++) grid.appendChild(el('span', 'cal-d empty'));
  const plan = getPlan();
  const total = new Date(y, mo + 1, 0).getDate();
  for (let d = 1; d <= total; d++) {
    const iso = y + '-' + String(mo + 1).padStart(2, '0') + '-' + String(d).padStart(2, '0');
    let cls = 'cal-d';
    if (days.includes(iso)) cls += ' done';
    if (iso === isoToday()) cls += ' today';
    if (iso === selectedDay) cls += ' sel';
    if (armedMove) cls += ' armable';
    const cell = el('button', cls, String(d));
    if (plan[iso] && plan[iso].length) cell.appendChild(el('i', 'plandot', '•'));
    cell.onclick = () => {
      if (armedMove) { const m = armedMove; armedMove = null; selectedDay = iso; addToDay(iso, m); return; }
      selectedDay = (selectedDay === iso) ? null : iso; render();
    };
    cell.ondragover = ev => ev.preventDefault();
    cell.ondrop = ev => {
      ev.preventDefault();
      const key = ev.dataTransfer.getData('text/plain');
      const m = getProgram().find(x => moveKey(x) === key);
      if (m) { selectedDay = iso; addToDay(iso, m); }
    };
    grid.appendChild(cell);
  }
  dir.appendChild(grid);
  if (armedMove) {
    const hint = el('p', 'small armed-hint', 'now tap a day to plan "' + armedMove.title + '" - ');
    const cancel = el('button', 'mini', 'cancel');
    cancel.onclick = () => { armedMove = null; render(); };
    hint.appendChild(cancel);
    dir.appendChild(hint);
  } else {
    dir.appendChild(el('p', 'small', 'drag a move onto a day (or tap "plan" then a day) - tap a day to see its plan - "did it!" marks today. lives only in this browser: clearing browser data clears it too.'));
  }
  if (selectedDay && !armedMove) renderDayPlan(dir, selectedDay);
}

function renderDayPlan(dir, iso) {
  const nice = new Date(iso + 'T00:00').toLocaleString('en', { day: 'numeric', month: 'long' }).toLowerCase();
  dir.appendChild(el('h2', 'dayplan-title', 'plan for ' + nice));
  const moves = getPlan()[iso] || [];
  if (!moves.length) dir.appendChild(el('p', 'small', 'nothing planned - drag a move from your program onto this day.'));
  for (const m of moves) {
    const row = el('p', 'entry');
    const a = el('a', null, m.title);
    a.href = m.url; a.rel = 'noopener'; a.target = '_blank';
    if (m.how) a.title = m.how;
    row.appendChild(a);
    if (m.description) row.appendChild(el('span', 'desc', ' - ' + m.description.replace(' · ', ' - ')));
    const rm = el('button', 'mini noprint', 'remove'); rm.onclick = () => removeFromDay(iso, m);
    row.append(' ', rm);
    dir.appendChild(row);
  }
  const doneBtn = el('button', 'mini', getDays().includes(iso) ? '✓ done - undo' : 'mark this day done');
  doneBtn.onclick = () => toggleDay(iso);
  const p2 = el('p', 'ob-row'); p2.appendChild(doneBtn); dir.appendChild(p2);
}

// "make me a program": pure formula, no ai - time budget + muscle balance + stretch to finish
function generateProgram(minutes, allowedEq) {
  const pool = allEntries.filter(e => e.kind === 'exercise' && (e.equipment || []).every(q => q === 'no equipment' || allowedEq.includes(q)));
  for (let i = pool.length - 1; i > 0; i--) { const j = Math.floor(Math.random() * (i + 1)); [pool[i], pool[j]] = [pool[j], pool[i]]; }
  const budget = minutes * 60;
  const picked = [];
  const counts = {};
  let total = 0;
  for (const e of pool) {
    const dur = e.durationSec || 45;
    if (total + dur > budget) continue;
    const primary = (e.muscles || [])[0];
    if (primary && (counts[primary] || 0) >= Math.ceil((picked.length + 1) / 2)) continue; // no single-muscle pileup
    picked.push(e);
    total += dur;
    for (const m of e.muscles || []) counts[m] = (counts[m] || 0) + 1;
    if (budget - total < 30) break;
  }
  const si = picked.findIndex(e => /stretch/i.test(e.title));
  if (si >= 0 && si !== picked.length - 1) picked.push(picked.splice(si, 1)[0]); // cool down at the end
  return picked.map(e => ({ title: e.title, url: e.url, description: e.description, category: e.category, how: e.how, muscles: e.muscles, durationSec: e.durationSec }));
}

function renderGenerator(dir) {
  dir.appendChild(el('p', 'ob-label', 'in a hurry? tell gymgyme what you have and it builds one:'));
  const row = el('p', 'ob-row genrow');
  const mins = el('select');
  for (const m of [10, 15, 20, 30]) { const o = el('option', null, m + ' minutes'); o.value = m; mins.appendChild(o); }
  mins.value = '15';
  row.appendChild(mins);
  const boxes = [];
  for (const q of ['wall', 'mat', 'chair', 'towel', 'water bottle']) {
    const lab = el('label', 'ob-check');
    const cb = el('input'); cb.type = 'checkbox'; cb.checked = true; cb.value = q;
    boxes.push(cb); lab.appendChild(cb); lab.append(' ' + q);
    row.appendChild(lab);
  }
  const go = el('button', null, 'make me a program');
  go.onclick = () => {
    if (getProgram().length && !confirm('this replaces your current program - go on?')) return;
    const prog = generateProgram(parseInt(mins.value, 10), boxes.filter(b => b.checked).map(b => b.value));
    if (!prog.length) { alert('could not fit anything - loosen the equipment boxes.'); return; }
    saveProgram(prog);
    render();
  };
  row.append(' ', go);
  dir.appendChild(row);
}

function renderProgram(dir) {
  renderGenerator(dir);
  const list = getProgram();
  if (!list.length) {
    dir.appendChild(el('p', 'loading', 'your program is empty - open a category and hit “+ add” on the moves you like. it lives only in this browser.'));
    renderCalendar(dir);
    return;
  }
  list.forEach((m, i) => {
    const row = el('p', 'entry');
    row.draggable = true;
    row.ondragstart = ev => ev.dataTransfer.setData('text/plain', moveKey(m));
    row.appendChild(el('span', 'kindmark', (i + 1) + '. '));
    const a = el('a', null, m.title);
    a.href = m.url; a.rel = 'noopener'; a.target = '_blank';
    row.appendChild(a);
    if (m.description) row.appendChild(el('span', 'desc', ' - ' + m.description.replace(' · ', ' - ')));
    const meta = getMeta(m);
    row.appendChild(el('span', 'by', ' - ~' + (meta.durationSec || 45) + 's - last done: ' + lastDoneText(m)));
    const did = el('button', 'mini', 'did it!'); did.onclick = () => markDone(m);
    const planBtn = el('button', 'mini noprint', armedMove && moveKey(armedMove) === moveKey(m) ? 'tap a day…' : 'plan');
    planBtn.onclick = () => { armedMove = (armedMove && moveKey(armedMove) === moveKey(m)) ? null : m; render(); };
    const up = el('button', 'mini noprint', '↑'); up.onclick = () => moveInProgram(moveKey(m), -1);
    const down = el('button', 'mini noprint', '↓'); down.onclick = () => moveInProgram(moveKey(m), 1);
    const rm = el('button', 'mini noprint', 'remove'); rm.onclick = () => toggleProgram(m);
    row.append(' ', did, ' ', planBtn, ' ', up, ' ', down, ' ', rm);
    const how = getHow(m);
    if (how) appendHow(dir, row, how);
    else dir.appendChild(row);
  });

  renderProgramStats(dir, list);
  renderCalendar(dir);

  const pdf = el('button', null, 'print / save as pdf');
  pdf.onclick = () => window.print();
  const clear = el('button', 'mini clear', 'clear the whole program');
  clear.onclick = () => { if (confirm('remove all moves from your program?')) { saveProgram([]); render(); } };
  const actions = el('p', 'ob-row');
  actions.append(pdf, ' ', clear);
  dir.appendChild(actions);
}

// ---- filters (exercise categories only): equipment + muscles ----
let filterEq = 'all';
let filterMus = 'all';
const EQ_OPTIONS = ['all', 'no equipment', 'wall', 'mat', 'chair', 'towel', 'water bottle'];
const MUS_OPTIONS = ['all', 'legs', 'glutes', 'core', 'back', 'chest', 'arms', 'shoulders'];

function filterRow(dir, label, options, current, setter) {
  const p = el('p', 'filters');
  p.appendChild(el('span', 'flabel', label + ': '));
  for (const opt of options) {
    const b = el('button', 'mini fopt' + (opt === current ? ' fon' : ''), opt);
    b.onclick = () => { setter(opt); render(); };
    p.appendChild(b);
  }
  dir.appendChild(p);
}

function matchesFilters(e) {
  if (filterEq !== 'all' && !(e.equipment || []).includes(filterEq)) return false;
  if (filterMus !== 'all' && !(e.muscles || []).includes(filterMus)) return false;
  return true;
}

function updateStats() {
  const links = allEntries.filter(e => e.kind === 'link').length;
  const moves = allEntries.filter(e => e.kind === 'exercise').length;
  const a = document.getElementById('stat-articles');
  const w = document.getElementById('stat-workouts');
  if (a) a.textContent = `articles (${links})`;
  if (w) w.textContent = `workouts (${moves})`;
}

function render() {
  updateStats();
  const cat = currentCategory();
  document.getElementById('cat-title').textContent = cat === 'my-program' ? 'my program' : cat;
  document.title = (cat === 'my-program' ? 'my program' : cat) + ' - a community directory';
  for (const a of document.querySelectorAll('#nav a')) {
    a.classList.toggle('on', a.getAttribute('href') === '#' + cat);
  }

  const dir = document.getElementById('directory');
  dir.textContent = '';

  if (!getProfile()) { renderOnboarding(dir); return; }
  if (cat === 'my-program') { renderProgram(dir); return; }

  let list = allEntries.filter(e => e.category === cat);
  const hasMoves = list.some(e => e.kind === 'exercise');
  if (hasMoves) {
    const box = el('div', 'filterbox');
    filterRow(box, 'equipment', EQ_OPTIONS, filterEq, v => { filterEq = v; });
    filterRow(box, 'muscles', MUS_OPTIONS, filterMus, v => { filterMus = v; });
    dir.appendChild(box);
    list = list.filter(e => e.kind !== 'exercise' || matchesFilters(e));
  }
  const max = Math.max(1, ...list.map(e => e.recommend_count));

  for (const e of list) {
    const row = el('p', 'entry');
    const a = el('a', null, e.title);
    a.href = e.url; a.rel = 'noopener'; a.target = '_blank';
    a.style.fontSize = linkSize(e.recommend_count, max);
    if (e.how) a.title = e.how; // hover: how to do the move
    row.appendChild(a);
    if (e.description) {
      const parts = e.kind === 'exercise' ? e.description.split(' · ') : [e.description];
      row.appendChild(el('span', 'desc', ' - ' + parts[0]));
      if (parts[1]) {
        row.appendChild(el('span', 'desc', ' - '));
        row.appendChild(el('i', 'eq', parts[1]));
      }
    }
    if (e.kind === 'exercise') {
      const btn = el('button', 'mini', inProgram(e) ? '✓ in your program' : '+ add');
      btn.onclick = () => toggleProgram(e);
      row.append(' ', btn);
    }
    if (e.how) appendHow(dir, row, e.how);
    else dir.appendChild(row);
  }
  if (!list.length) {
    if (hasMoves || filterEq !== 'all' || filterMus !== 'all') {
      dir.appendChild(el('p', 'loading', 'nothing matches these filters - try loosening them.'));
    } else {
      const empty = el('p', 'loading', 'nothing in ' + cat + ' yet - be the first: ');
      const link = el('a', 'suggest-big', 'suggest something!');
      link.href = 'suggest.html';
      empty.appendChild(link);
      dir.appendChild(empty);
    }
  }

  const names = [...new Set(allEntries.map(e => e.contributor))];
  const contribs = document.getElementById('contributors');
  contribs.textContent = '';
  for (const name of names) {
    const s = el('span', null, name);
    s.style.color = nameColor(name);
    contribs.appendChild(s);
  }
}

window.addEventListener('hashchange', render);
updateProgramCount();
renderGreet();
render();

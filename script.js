// directory page - vanilla JS, no build, no libraries.
// navbar picks the category (hash routing); importance = font size, that's it.
// content = bundled seed + supabase (when the table is live); my program = localStorage.
const CATEGORIES = ['healthy-living-articles', 'home-workouts', 'pilates', 'ballet', 'yoga', 'gym', 'calisthenics', 'bodyweight'];
const DEFAULT_CATEGORY = 'home-workouts';
const HEADERS = { apikey: SUPABASE_ANON_KEY, Authorization: 'Bearer ' + SUPABASE_ANON_KEY };
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
  else list.push({ title: entry.title, url: entry.url, description: entry.description, category: entry.category, how: entry.how });
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

// ---- workout days + last-done (localStorage) ----
const DAYS_KEY = 'hl_days';
const LASTDONE_KEY = 'hl_lastdone';
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
function getHow(m) {
  if (m.how) return m.how;
  const found = allEntries.find(e => moveKey(e) === moveKey(m));
  return found && found.how;
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

function renderCalendar(dir) {
  const now = new Date();
  const y = now.getFullYear(), mo = now.getMonth();
  const monthName = now.toLocaleString('en', { month: 'long' }).toLowerCase();
  dir.appendChild(el('h2', null, monthName + ' ' + y));
  const days = getDays();
  const grid = el('div', 'cal');
  for (const d of ['mo', 'tu', 'we', 'th', 'fr', 'sa', 'su']) grid.appendChild(el('span', 'cal-h', d));
  const firstDow = (new Date(y, mo, 1).getDay() + 6) % 7; // monday first
  for (let i = 0; i < firstDow; i++) grid.appendChild(el('span', 'cal-d empty'));
  const total = new Date(y, mo + 1, 0).getDate();
  for (let d = 1; d <= total; d++) {
    const iso = y + '-' + String(mo + 1).padStart(2, '0') + '-' + String(d).padStart(2, '0');
    const cell = el('button', 'cal-d' + (days.includes(iso) ? ' done' : '') + (iso === isoToday() ? ' today' : ''), String(d));
    cell.onclick = () => toggleDay(iso);
    grid.appendChild(cell);
  }
  dir.appendChild(grid);
  dir.appendChild(el('p', 'small', 'tap a day to mark it - "did it!" on a move marks today by itself. lives only in this browser.'));
}

function renderProgram(dir) {
  const list = getProgram();
  if (!list.length) {
    dir.appendChild(el('p', 'loading', 'your program is empty - open a category and hit “+ add” on the moves you like. it lives only in this browser.'));
    renderCalendar(dir);
    return;
  }
  list.forEach((m, i) => {
    const row = el('p', 'entry');
    row.appendChild(el('span', 'kindmark', (i + 1) + '. '));
    const a = el('a', null, m.title);
    a.href = m.url; a.rel = 'noopener'; a.target = '_blank';
    row.appendChild(a);
    if (m.description) row.appendChild(el('span', 'desc', ' - ' + m.description.replace(' · ', ' - ')));
    row.appendChild(el('span', 'by', ' - last done: ' + lastDoneText(m)));
    const did = el('button', 'mini', 'did it!'); did.onclick = () => markDone(m);
    const up = el('button', 'mini noprint', '↑'); up.onclick = () => moveInProgram(moveKey(m), -1);
    const down = el('button', 'mini noprint', '↓'); down.onclick = () => moveInProgram(moveKey(m), 1);
    const rm = el('button', 'mini noprint', 'remove'); rm.onclick = () => toggleProgram(m);
    row.append(' ', did, ' ', up, ' ', down, ' ', rm);
    const how = getHow(m);
    if (how) appendHow(dir, row, how);
    else dir.appendChild(row);
  });

  renderCalendar(dir);

  const pdf = el('button', null, 'print / save as pdf');
  pdf.onclick = () => window.print();
  const clear = el('button', 'mini clear', 'clear the whole program');
  clear.onclick = () => { if (confirm('remove all moves from your program?')) { saveProgram([]); render(); } };
  const actions = el('p', 'ob-row');
  actions.append(pdf, ' ', clear);
  dir.appendChild(actions);
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

  const list = allEntries.filter(e => e.category === cat);
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
    const empty = el('p', 'loading', 'nothing in ' + cat + ' yet - be the first: ');
    const link = el('a', 'suggest-big', 'suggest something!');
    link.href = 'suggest.html';
    empty.appendChild(link);
    dir.appendChild(empty);
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

// supabase is the live layer on top of the bundled seed: its rows win by url, new rows join.
async function loadRemote() {
  try {
    const res = await fetch(`${SUPABASE_URL}/rest/v1/hl_entries?approved=eq.true&select=kind,category,title,url,description,contributor,recommend_count&order=recommend_count.desc,title.asc`, { headers: HEADERS });
    if (!res.ok) return;
    const remote = await res.json();
    if (!remote.length) return;
    const byKey = new Map(allEntries.map(e => [moveKey(e), e]));
    for (const r of remote) byKey.set(moveKey(r), r);
    allEntries = [...byKey.values()].sort((a, b) => b.recommend_count - a.recommend_count || a.title.localeCompare(b.title));
    render();
  } catch { /* offline or table not created yet - bundled seed already rendered */ }
}

window.addEventListener('hashchange', render);
updateProgramCount();
renderGreet();
render();
loadRemote();

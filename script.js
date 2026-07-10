// directory page — vanilla JS, no build, no libraries.
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

// deterministic color per contributor name — dark enough to read on pink
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
function inProgram(url) { return getProgram().some(m => m.url === url); }
function toggleProgram(entry) {
  const list = getProgram();
  const i = list.findIndex(m => m.url === entry.url);
  if (i >= 0) list.splice(i, 1);
  else list.push({ title: entry.title, url: entry.url, description: entry.description, category: entry.category });
  saveProgram(list);
  render();
}
function moveInProgram(url, dir) {
  const list = getProgram();
  const i = list.findIndex(m => m.url === url);
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

function currentCategory() {
  const hash = location.hash.replace('#', '');
  if (hash === 'my-program') return 'my-program';
  return CATEGORIES.includes(hash) ? hash : DEFAULT_CATEGORY;
}

function renderProgram(dir) {
  const list = getProgram();
  if (!list.length) {
    dir.appendChild(el('p', 'loading', 'your program is empty — open a category and hit “+ add” on the moves you like. it lives only in this browser.'));
    return;
  }
  list.forEach((m, i) => {
    const row = el('p', 'entry');
    row.appendChild(el('span', 'kindmark', (i + 1) + '. '));
    const a = el('a', null, m.title);
    a.href = m.url; a.rel = 'noopener'; a.target = '_blank';
    row.appendChild(a);
    if (m.description) row.appendChild(el('span', 'desc', ' — ' + m.description));
    const up = el('button', 'mini', '↑'); up.onclick = () => moveInProgram(m.url, -1);
    const down = el('button', 'mini', '↓'); down.onclick = () => moveInProgram(m.url, 1);
    const rm = el('button', 'mini', 'remove'); rm.onclick = () => toggleProgram(m);
    row.append(' ', up, ' ', down, ' ', rm);
    dir.appendChild(row);
  });
  const clear = el('button', 'mini clear', 'clear the whole program');
  clear.onclick = () => { if (confirm('remove all moves from your program?')) { saveProgram([]); render(); } };
  dir.appendChild(clear);
}

function render() {
  const cat = currentCategory();
  document.getElementById('cat-title').textContent = cat === 'my-program' ? 'my program' : cat;
  document.title = (cat === 'my-program' ? 'my program' : cat) + ' — a community directory';
  for (const a of document.querySelectorAll('#nav a')) {
    a.classList.toggle('on', a.getAttribute('href') === '#' + cat);
  }

  const dir = document.getElementById('directory');
  dir.textContent = '';

  if (cat === 'my-program') { renderProgram(dir); return; }

  const list = allEntries.filter(e => e.category === cat);
  const max = Math.max(1, ...list.map(e => e.recommend_count));

  for (const e of list) {
    const row = el('p', 'entry');
    if (e.kind === 'exercise') row.appendChild(el('span', 'kindmark', '(move) '));
    const a = el('a', null, e.title);
    a.href = e.url; a.rel = 'noopener'; a.target = '_blank';
    a.style.fontSize = linkSize(e.recommend_count, max);
    row.appendChild(a);
    if (e.description) row.appendChild(el('span', 'desc', ' — ' + e.description));
    row.appendChild(el('span', 'by', ` · ${e.contributor}` + (e.recommend_count > 1 ? ` · recommended ${e.recommend_count}×` : '')));
    if (e.kind === 'exercise') {
      const btn = el('button', 'mini', inProgram(e.url) ? '✓ in your program' : '+ add');
      btn.onclick = () => toggleProgram(e);
      row.append(' ', btn);
    }
    dir.appendChild(row);
  }
  if (!list.length) dir.appendChild(el('p', 'loading', 'nothing in ' + cat + ' yet — be the first to suggest something.'));

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
    const byUrl = new Map(allEntries.map(e => [e.url, e]));
    for (const r of remote) byUrl.set(r.url, r);
    allEntries = [...byUrl.values()].sort((a, b) => b.recommend_count - a.recommend_count || a.title.localeCompare(b.title));
    render();
  } catch { /* offline or table not created yet — bundled seed already rendered */ }
}

window.addEventListener('hashchange', render);
updateProgramCount();
render();
loadRemote();

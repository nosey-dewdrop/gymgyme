// healthy living directory — vanilla JS, no build, no libraries.
const CATEGORIES = ['healthy-living-articles', 'home-workouts', 'pilates', 'ballet', 'yoga', 'gym', 'calisthenics', 'bodyweight'];
const HEADERS = { apikey: SUPABASE_ANON_KEY, Authorization: 'Bearer ' + SUPABASE_ANON_KEY };

// darker pink = recommended more
function linkShade(count, max) {
  const t = max <= 1 ? 0 : Math.min((count - 1) / (max - 1), 1);
  const from = [142, 0, 56];   // #8E0038
  const to = [61, 0, 26];      // #3D001A
  const c = from.map((f, i) => Math.round(f + (to[i] - f) * t));
  return `rgb(${c[0]},${c[1]},${c[2]})`;
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

async function load() {
  const dir = document.getElementById('directory');
  try {
    const res = await fetch(`${SUPABASE_URL}/rest/v1/hl_entries?approved=eq.true&select=kind,category,title,url,description,contributor,recommend_count&order=recommend_count.desc,title.asc`, { headers: HEADERS });
    if (!res.ok) throw new Error(res.status);
    const entries = await res.json();
    dir.textContent = '';
    const max = Math.max(1, ...entries.map(e => e.recommend_count));

    for (const cat of CATEGORIES) {
      const list = entries.filter(e => e.category === cat);
      if (!list.length) continue;
      const sec = el('div', 'cat');
      sec.appendChild(el('h2', null, cat));
      for (const e of list) {
        const row = el('p', 'entry');
        if (e.kind === 'exercise') row.appendChild(el('span', 'kindmark', '(move) '));
        const a = el('a', null, e.title);
        a.href = e.url;
        a.rel = 'noopener';
        a.target = '_blank';
        a.style.color = linkShade(e.recommend_count, max);
        row.appendChild(a);
        if (e.description) row.appendChild(el('span', 'desc', ' — ' + e.description));
        row.appendChild(el('span', 'by', ` · ${e.contributor}` + (e.recommend_count > 1 ? ` · recommended ${e.recommend_count}×` : '')));
        sec.appendChild(row);
      }
      dir.appendChild(sec);
    }
    if (!entries.length) dir.appendChild(el('p', 'loading', 'nothing here yet — be the first to suggest something below.'));

    const names = [...new Set(entries.map(e => e.contributor))];
    const contribs = document.getElementById('contributors');
    contribs.textContent = '';
    for (const name of names) {
      const s = el('span', null, name);
      s.style.color = nameColor(name);
      contribs.appendChild(s);
    }
  } catch (err) {
    dir.textContent = '';
    dir.appendChild(el('p', 'loading', 'could not load the directory right now — please try again in a bit.'));
  }
}

document.getElementById('suggest').addEventListener('submit', async ev => {
  ev.preventDefault();
  const form = ev.target;
  const msg = document.getElementById('form-msg');
  const body = {
    kind: form.kind.value,
    category: form.category.value,
    title: form.title.value.trim(),
    url: form.url.value.trim(),
    description: form.description.value.trim() || null,
    contributor: form.contributor.value.trim(),
  };
  msg.textContent = 'sending…';
  try {
    const res = await fetch(`${SUPABASE_URL}/rest/v1/hl_entries`, {
      method: 'POST',
      headers: { ...HEADERS, 'Content-Type': 'application/json', Prefer: 'return=minimal' },
      body: JSON.stringify(body),
    });
    if (!res.ok) throw new Error(res.status);
    form.reset();
    msg.textContent = 'got it — thank you! it shows up after a human takes a look. 🎀';
  } catch (err) {
    msg.textContent = 'could not send — check the link starts with https:// and try again.';
  }
});

load();

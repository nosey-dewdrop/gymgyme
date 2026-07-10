// suggest page - posts a suggestion to supabase; it publishes after approval.
const HEADERS = { apikey: SUPABASE_ANON_KEY, Authorization: 'Bearer ' + SUPABASE_ANON_KEY };

// sidebar counters (from the bundled seed)
document.getElementById('stat-articles').textContent = `articles (${SEED_ENTRIES.filter(e => e.kind === 'link').length})`;
document.getElementById('stat-workouts').textContent = `workouts (${SEED_ENTRIES.filter(e => e.kind === 'exercise').length})`;

// move-only fields: how, equipment, muscles, duration
const EQ_CHOICES = ['no equipment', 'wall', 'mat', 'chair', 'towel', 'water bottle', 'doorway', 'step'];
const MUS_CHOICES = ['legs', 'glutes', 'core', 'back', 'chest', 'arms', 'shoulders'];
function fillBoxes(id, choices) {
  const box = document.getElementById(id);
  for (const c of choices) {
    const lab = document.createElement('label');
    lab.className = 'ob-check';
    const cb = document.createElement('input');
    cb.type = 'checkbox';
    cb.value = c;
    lab.appendChild(cb);
    lab.append(' ' + c);
    box.appendChild(lab);
  }
}
fillBoxes('eq-boxes', EQ_CHOICES);
fillBoxes('mus-boxes', MUS_CHOICES);
function checked(id) {
  return [...document.querySelectorAll('#' + id + ' input:checked')].map(cb => cb.value);
}
const kindSel = document.querySelector('#suggest select[name="kind"]');
const moveFields = document.getElementById('move-fields');
function syncMoveFields() { moveFields.classList.toggle('hidden', kindSel.value !== 'exercise'); }
kindSel.addEventListener('change', syncMoveFields);
syncMoveFields();

document.getElementById('suggest').addEventListener('submit', async ev => {
  ev.preventDefault();
  const form = ev.target;
  const msg = document.getElementById('form-msg');
  const isMove = form.kind.value === 'exercise';
  const body = {
    kind: form.kind.value,
    category: form.category.value,
    title: form.title.value.trim(),
    url: form.url.value.trim(),
    description: form.description.value.trim() || null,
    how: isMove ? (form.how.value.trim() || null) : null, // optional - the link explains it anyway
    muscles: isMove && checked('mus-boxes').length ? checked('mus-boxes') : null,
    equipment: isMove && checked('eq-boxes').length ? checked('eq-boxes') : null,
    duration_sec: isMove && form.duration.value ? parseInt(form.duration.value, 10) : null,
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
    msg.textContent = 'got it - thank you! it shows up after a human takes a look. 🎀';
  } catch (err) {
    msg.textContent = 'could not send - check the link starts with https:// and try again.';
  }
});

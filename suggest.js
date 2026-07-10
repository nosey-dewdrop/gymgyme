// suggest page - zero backend: the form composes a mail, a human reads it and merges it in.
const SUGGEST_EMAIL = 'damummyphus@gmail.com';

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

document.getElementById('suggest').addEventListener('submit', ev => {
  ev.preventDefault();
  const form = ev.target;
  const msg = document.getElementById('form-msg');
  const isMove = form.kind.value === 'exercise';
  const lines = [
    'kind: ' + form.kind.value,
    'category: ' + form.category.value,
    'title: ' + form.title.value.trim(),
    'url: ' + form.url.value.trim(),
    'why: ' + form.description.value.trim(),
  ];
  if (isMove) {
    if (form.how.value.trim()) lines.push('how: ' + form.how.value.trim());
    if (checked('eq-boxes').length) lines.push('equipment: ' + checked('eq-boxes').join(', '));
    if (checked('mus-boxes').length) lines.push('muscles: ' + checked('mus-boxes').join(', '));
    if (form.duration.value) lines.push('duration: ~' + form.duration.value + 's');
  }
  lines.push('name to publish: ' + form.contributor.value.trim());
  const subject = 'gymgyme suggestion: ' + form.title.value.trim();
  location.href = 'mailto:' + SUGGEST_EMAIL + '?subject=' + encodeURIComponent(subject) + '&body=' + encodeURIComponent(lines.join('\n'));
  msg.textContent = 'your mail app just opened with everything filled in - hit send and a human takes it from there. 🎀';
});

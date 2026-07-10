// suggest page - posts a suggestion to supabase; it publishes after approval.
const HEADERS = { apikey: SUPABASE_ANON_KEY, Authorization: 'Bearer ' + SUPABASE_ANON_KEY };

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
    msg.textContent = 'got it - thank you! it shows up after a human takes a look. 🎀';
  } catch (err) {
    msg.textContent = 'could not send - check the link starts with https:// and try again.';
  }
});

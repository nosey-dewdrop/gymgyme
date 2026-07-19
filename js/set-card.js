// set-card.js — a shareable, privacy-safe "set card".
//
// when a workout summary appears (#summary un-hidden by coach.js), this renders
// a small share card: a dot-figure + total reps + score + date + the domain
// gymgyme.noseydewdrop.com, with DOWNLOAD (png) and SHARE (navigator.share, or
// copy fallback). NO photo, ever — only the dot geometry and the numbers, which
// is the whole point (nothing from the camera leaves the device).
//
// it never touches coach.js. it OBSERVES #summary visibility and READS the text
// coach.js already printed into #sumBody (total reps + average score). the card
// lives in its own .set-card node appended after #summary.
(function () {
  const summary = document.getElementById('summary');
  const sumBody = document.getElementById('sumBody');
  const sumTitle = document.getElementById('sumTitle');
  if (!summary || !sumBody) return;

  const INK = '#191320', LILA = '#8E6BA8', LILA_SOFT = '#F0E6F5', WASH = '#F5F2FA', LINE = '#E7E2EE', MUT = '#8B8496';
  const DOMAIN = 'gymgyme.noseydewdrop.com';

  // ---------- parse the numbers coach.js already rendered ----------
  function readStats() {
    const text = sumBody.textContent || '';
    let reps = null, heldS = null, score = null;
    let m = text.match(/(\d+)\s+reps/);
    if (m) reps = parseInt(m[1], 10);
    m = text.match(/held for (\d+)s total/);
    if (m) heldS = parseInt(m[1], 10);
    m = text.match(/averaged\s+(\d+)\s+out of\s+100/);
    if (m) score = parseInt(m[1], 10);
    const title = (sumTitle && sumTitle.textContent) || "today's set";
    return { reps, heldS, score, title };
  }

  function today() {
    try {
      return new Date().toLocaleDateString(undefined, { year: 'numeric', month: 'short', day: 'numeric' });
    } catch (_) { return new Date().toISOString().slice(0, 10); }
  }

  // ---------- the card node (built once) ----------
  let card = null, canvas = null, ctx = null;
  function build() {
    if (card) return;
    card = document.createElement('div');
    card.className = 'set-card';

    canvas = document.createElement('canvas');
    canvas.className = 'set-card-canvas';
    ctx = canvas.getContext('2d');
    card.appendChild(canvas);

    const row = document.createElement('div');
    row.className = 'set-card-actions';
    const dl = document.createElement('button');
    dl.type = 'button'; dl.className = 'set-card-btn'; dl.textContent = 'download';
    dl.addEventListener('click', download);
    const sh = document.createElement('button');
    sh.type = 'button'; sh.className = 'set-card-btn ghost'; sh.textContent = 'share';
    sh.addEventListener('click', share);
    const note = document.createElement('span');
    note.className = 'set-card-note';
    note.textContent = 'just the numbers and a dot figure - no photo, nothing from your camera.';
    row.append(dl, sh);
    card.append(row, note);

    summary.after(card);
  }

  // ---------- draw the card onto the canvas ----------
  const W = 720, H = 900;
  function drawFigure(cx, cy, scale) {
    // a single standing/mid-squat dot figure (side view), same dot language.
    const u = scale;
    const footY = cy + 150 * u;
    const d = 0.5;
    const ankle = { x: cx, y: footY };
    const knee = { x: cx + 30 * d * u, y: footY - (82 - 14 * d) * u };
    const hip = { x: cx - 34 * d * u, y: footY - (170 - 92 * d) * u };
    const sho = { x: hip.x + 128 * u * Math.sin(0.42 * d), y: hip.y - 128 * u * Math.cos(0.42 * d) };
    const head = { x: sho.x, y: sho.y - 40 * u };
    const elb = { x: sho.x + 20 * u, y: sho.y + 44 * u };
    const wri = { x: elb.x + 26 * u, y: elb.y + 30 * u };
    const toe = { x: ankle.x + 30 * u, y: footY + 4 * u };
    const segs = [[hip, sho, 90], [hip, knee, 52], [knee, ankle, 38], [sho, elb, 26], [elb, wri, 22], [ankle, toe, 12]];
    let seed = 424242;
    const rnd = () => (seed = (seed * 16807) % 2147483647) / 2147483647;
    ctx.fillStyle = INK;
    for (const [a, b, n] of segs) {
      for (let i = 0; i < n; i++) {
        const t = rnd();
        const nx = -(b.y - a.y), ny = (b.x - a.x);
        const L = Math.hypot(nx, ny) || 1;
        const off = (rnd() - 0.5) * 14 * u;
        const x = a.x + (b.x - a.x) * t + (nx / L) * off;
        const y = a.y + (b.y - a.y) * t + (ny / L) * off;
        ctx.globalAlpha = 0.35 + rnd() * 0.45;
        ctx.beginPath(); ctx.arc(x, y, 2, 0, Math.PI * 2); ctx.fill();
      }
    }
    // head cloud
    for (let i = 0; i < 40; i++) {
      const a = rnd() * Math.PI * 2, rr = (10 + rnd() * 12) * u;
      ctx.globalAlpha = 0.35 + rnd() * 0.45;
      ctx.beginPath(); ctx.arc(head.x + Math.cos(a) * rr, head.y + Math.sin(a) * rr, 2, 0, Math.PI * 2); ctx.fill();
    }
    // lit knee
    ctx.globalAlpha = 1; ctx.fillStyle = LILA;
    ctx.beginPath(); ctx.arc(knee.x, knee.y, 5, 0, Math.PI * 2); ctx.fill();
    ctx.strokeStyle = LILA; ctx.globalAlpha = 0.5; ctx.lineWidth = 1.5;
    ctx.beginPath(); ctx.arc(knee.x, knee.y, 13, 0, Math.PI * 2); ctx.stroke();
    ctx.globalAlpha = 1;
  }

  function render(stats) {
    const DPR = 2;
    canvas.width = W * DPR; canvas.height = H * DPR;
    ctx.setTransform(DPR, 0, 0, DPR, 0, 0);

    // panel
    ctx.fillStyle = WASH; ctx.fillRect(0, 0, W, H);
    ctx.strokeStyle = LINE; ctx.lineWidth = 1; ctx.strokeRect(0.5, 0.5, W - 1, H - 1);

    // header
    ctx.fillStyle = INK;
    ctx.font = '600 34px "Bricolage Grotesque", system-ui, sans-serif';
    ctx.textAlign = 'left';
    ctx.fillText('gymgyme', 48, 74);
    ctx.fillStyle = LILA;
    ctx.font = '600 15px "JetBrains Mono", ui-monospace, monospace';
    ctx.fillText((stats.title || 'your set').toUpperCase(), 48, 104);

    // figure
    drawFigure(W / 2, 300, 1.1);

    // floor dots
    ctx.fillStyle = 'rgba(142,107,168,.2)';
    for (let x = W * 0.3; x <= W * 0.7; x += 22) { ctx.beginPath(); ctx.arc(x, 470, 2, 0, Math.PI * 2); ctx.fill(); }

    // big number
    ctx.textAlign = 'center';
    const bigVal = stats.reps != null ? String(stats.reps) : (stats.heldS != null ? stats.heldS + 's' : '-');
    const bigLbl = stats.reps != null ? 'reps' : (stats.heldS != null ? 'held' : '');
    ctx.fillStyle = LILA;
    ctx.font = '600 120px "JetBrains Mono", ui-monospace, monospace';
    ctx.fillText(bigVal, W / 2, 620);
    ctx.fillStyle = MUT;
    ctx.font = '600 20px "JetBrains Mono", ui-monospace, monospace';
    ctx.fillText(bigLbl, W / 2, 656);

    // score + date row
    ctx.fillStyle = INK;
    ctx.font = '600 22px "Inter", system-ui, sans-serif';
    const scoreTxt = stats.score != null ? 'form ' + stats.score + '/100' : 'on-device form coach';
    ctx.fillText(scoreTxt, W / 2, 730);
    ctx.fillStyle = MUT;
    ctx.font = '400 18px "Inter", system-ui, sans-serif';
    ctx.fillText(today(), W / 2, 762);

    // footer domain
    ctx.strokeStyle = LINE; ctx.beginPath(); ctx.moveTo(48, H - 96); ctx.lineTo(W - 48, H - 96); ctx.stroke();
    ctx.fillStyle = LILA;
    ctx.font = '600 20px "JetBrains Mono", ui-monospace, monospace';
    ctx.fillText(DOMAIN, W / 2, H - 56);
    ctx.fillStyle = MUT;
    ctx.font = '400 14px "Inter", system-ui, sans-serif';
    ctx.fillText('the video never leaves your device', W / 2, H - 32);
  }

  function toBlob() {
    return new Promise((res) => {
      if (canvas.toBlob) canvas.toBlob(res, 'image/png');
      else res(null);
    });
  }

  async function download() {
    const url = canvas.toDataURL('image/png');
    const a = document.createElement('a');
    a.href = url; a.download = 'gymgyme-set-' + new Date().toISOString().slice(0, 10) + '.png';
    document.body.appendChild(a); a.click(); a.remove();
  }

  async function share() {
    const blob = await toBlob();
    const stats = readStats();
    const caption = (stats.reps != null ? stats.reps + ' reps' : (stats.heldS != null ? 'held ' + stats.heldS + 's' : 'a workout')) +
      (stats.score != null ? ', form ' + stats.score + '/100' : '') + ' - gymgyme.noseydewdrop.com';
    try {
      if (blob && navigator.canShare && navigator.canShare({ files: [new File([blob], 'gymgyme-set.png', { type: 'image/png' })] })) {
        await navigator.share({ files: [new File([blob], 'gymgyme-set.png', { type: 'image/png' })], text: caption });
        return;
      }
      if (navigator.share) { await navigator.share({ text: caption, url: 'https://gymgyme.noseydewdrop.com' }); return; }
    } catch (_) { return; }        // user cancelled — nothing to do
    // fallback: copy the caption
    try { await navigator.clipboard.writeText(caption); flash('copied'); }
    catch (_) { flash('press download to save the card'); }
  }

  let flashT = 0;
  function flash(msg) {
    let n = card.querySelector('.set-card-flash');
    if (!n) { n = document.createElement('span'); n.className = 'set-card-flash'; card.appendChild(n); }
    n.textContent = msg;
    clearTimeout(flashT);
    flashT = setTimeout(() => { if (n) n.textContent = ''; }, 2200);
  }

  // ---------- show/hide with the summary ----------
  function refresh() {
    const visible = summary && !summary.hidden;
    if (visible) {
      const stats = readStats();
      // only show a card if there is something real to show
      if (stats.reps == null && stats.heldS == null) { if (card) card.hidden = true; return; }
      build();
      render(stats);
      card.hidden = false;
    } else if (card) {
      card.hidden = true;
    }
  }

  const mo = new MutationObserver(refresh);
  mo.observe(summary, { attributes: true, attributeFilter: ['hidden'] });
  mo.observe(sumBody, { childList: true, subtree: true });
  refresh();
})();

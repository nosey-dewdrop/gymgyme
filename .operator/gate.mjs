// gate.mjs — Damla Kapısı kuyruk mekanizması (ASENKRON onay).
// Geri-alınamaz işlemler (STYLE-PIN, golden re-pin, mihenk onayı) kart olarak
// reports/gate/ altına düşer; zincir beklemeden diğer işlere devam eder.
// Damla kartı açar, "kalemim/onay" ya da "değil + gerekçe" der; karar aynı
// JSON'a yazılır; zincir sonraki turda okur. Pin ANCAK onayla yazılır.
//
//   node gate.mjs open <id> <type> <title> [contactHtmlRelPath]  -> kart aç (status=pending)
//   node gate.mjs list [pending|approved|rejected|all]           -> kuyruğu göster
//   node gate.mjs decide <id> approve|reject "<gerekçe>"          -> karar yaz
//   node gate.mjs get <id>                                        -> tek kart JSON
//
// Kart şeması: { id, type, title, contact, status, reason, createdAt, decidedAt }
// (createdAt/decidedAt zincir tarafından argümanla verilir — new Date() yok,
// script determinism; CLI stamp'i gate.stamp ile geçilir.)

import { readdirSync, readFileSync, writeFileSync, existsSync, mkdirSync } from 'fs';
import { dirname, join } from 'path';
import { fileURLToPath } from 'url';

// GATE yolu: OPERATOR_GATE env varsa onu kullan, yoksa calisilan dizinin
// altinda .operator/gate (her projeye kopyalanabilir — stitchu'ya sabit degil).
const GATE = process.env.OPERATOR_GATE || join(process.cwd(), '.operator', 'gate');
if (!existsSync(GATE)) mkdirSync(GATE, { recursive: true });

const cardPath = (id) => join(GATE, `${id}.json`);

export function openCard({ id, type, title, contact, stamp }) {
  if (existsSync(cardPath(id))) throw new Error(`kart zaten var: ${id}`);
  const card = { id, type, title, contact: contact || null, status: 'pending', reason: null, createdAt: stamp || null, decidedAt: null };
  writeFileSync(cardPath(id), JSON.stringify(card, null, 2));
  return card;
}

export function listCards(filter = 'all') {
  if (!existsSync(GATE)) return [];
  return readdirSync(GATE)
    .filter((f) => f.endsWith('.json'))
    .map((f) => JSON.parse(readFileSync(join(GATE, f), 'utf8')))
    .filter((c) => filter === 'all' || c.status === filter)
    .sort((a, b) => (a.id > b.id ? 1 : -1));
}

export function getCard(id) {
  if (!existsSync(cardPath(id))) return null;
  return JSON.parse(readFileSync(cardPath(id), 'utf8'));
}

export function decideCard(id, decision, reason, stamp) {
  const card = getCard(id);
  if (!card) throw new Error(`kart yok: ${id}`);
  if (card.status !== 'pending') throw new Error(`kart zaten kararlı: ${id} = ${card.status}`);
  card.status = decision === 'approve' ? 'approved' : 'rejected';
  card.reason = reason || null;
  card.decidedAt = stamp || null;
  writeFileSync(cardPath(id), JSON.stringify(card, null, 2));
  return card;
}

export function pendingCount() {
  return listCards('pending').length;
}

// ---- CLI ----------------------------------------------------------------
const isMain = process.argv[1] && fileURLToPath(import.meta.url) === process.argv[1];
if (isMain) {
  const [cmd, ...a] = process.argv.slice(2);
  try {
    if (cmd === 'open') {
      const c = openCard({ id: a[0], type: a[1], title: a[2], contact: a[3], stamp: a[4] });
      console.log('acildi (pending):', c.id, '-', c.title);
    } else if (cmd === 'list') {
      const rows = listCards(a[0] || 'all');
      if (!rows.length) console.log('kuyruk bos.');
      for (const c of rows) console.log(`[${c.status.toUpperCase().padEnd(8)}] ${c.id}  ${c.type}  "${c.title}"${c.reason ? '  → ' + c.reason : ''}`);
      console.log(`\npending: ${listCards('pending').length}`);
    } else if (cmd === 'decide') {
      const c = decideCard(a[0], a[1], a.slice(2).join(' '));
      console.log(`karar yazildi: ${c.id} = ${c.status}${c.reason ? '  (' + c.reason + ')' : ''}`);
    } else if (cmd === 'get') {
      console.log(JSON.stringify(getCard(a[0]), null, 2));
    } else {
      console.log('kullanim: gate.mjs open|list|decide|get ...');
      process.exit(2);
    }
  } catch (e) {
    console.error('HATA:', e.message);
    process.exit(1);
  }
}

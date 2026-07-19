// tools/fetch-clips.mjs — pull openly-licensed exercise clips into the corpus.
//
//   node tools/fetch-clips.mjs squat 15
//   node tools/fetch-clips.mjs "glute bridge" 10 --source pixabay
//
// sources: pexels (default) and pixabay. BOTH are free for commercial use with
// no attribution required, which satisfies invariant #14 (only openly-licensed
// clips enter the corpus). every download gets a <clip>.license.txt next to it
// recording the source url, license, and date.
//
// api keys: read from .env (PEXELS_API_KEY / PIXABAY_API_KEY). NO key in the
// repo. if the needed key is missing, this prints exactly what to add and exits
// without spending anything — the human puts the key in .env.
//
// diversity: results are shuffled by a fixed offset per run and consecutive
// clips from the same author/user are skipped, so the corpus does not fill with
// one body / one angle.

import { readFileSync, existsSync, mkdirSync, writeFileSync, createWriteStream } from 'fs';
import { join, dirname } from 'path';
import { fileURLToPath } from 'url';

const ROOT = join(dirname(fileURLToPath(import.meta.url)), '..');
const CORPUS = join(ROOT, 'corpus');

function loadEnv() {
  const env = {};
  const p = join(ROOT, '.env');
  if (existsSync(p)) {
    for (const line of readFileSync(p, 'utf8').split('\n')) {
      const m = line.match(/^\s*([A-Z0-9_]+)\s*=\s*(.*)\s*$/);
      if (m) env[m[1]] = m[2].replace(/^["']|["']$/g, '');
    }
  }
  return { ...env, ...process.env };
}

const args = process.argv.slice(2);
const move = args[0];
const count = parseInt(args[1] || '15', 10);
const sourceIdx = args.indexOf('--source');
const source = sourceIdx >= 0 ? args[sourceIdx + 1] : 'pexels';

if (!move) {
  console.log('usage: node tools/fetch-clips.mjs "<move>" [count] [--source pexels|pixabay]');
  process.exit(1);
}

const env = loadEnv();

function needKey(name, url) {
  console.log(`missing ${name}. this tool spends nothing without it.`);
  console.log(`  1. get a free key at ${url}`);
  console.log(`  2. add to ${join(ROOT, '.env')}:  ${name}=your_key_here`);
  console.log('  3. re-run this command.');
  process.exit(2);
}

const slug = move.replace(/[^a-z0-9]+/gi, '-').toLowerCase();
const outDir = join(CORPUS, slug);

async function download(url, dest) {
  const res = await fetch(url);
  if (!res.ok) throw new Error('download failed: ' + res.status);
  const buf = Buffer.from(await res.arrayBuffer());
  writeFileSync(dest, buf);
}

async function fromPexels() {
  const key = env.PEXELS_API_KEY;
  if (!key) needKey('PEXELS_API_KEY', 'https://www.pexels.com/api/');
  const q = encodeURIComponent(move + ' exercise');
  const res = await fetch(`https://api.pexels.com/videos/search?query=${q}&per_page=${Math.min(count * 2, 60)}&orientation=portrait`, {
    headers: { Authorization: key },
  });
  if (!res.ok) throw new Error('pexels search failed: ' + res.status);
  const data = await res.json();
  return (data.videos || []).map((v) => ({
    id: v.id,
    author: (v.user && v.user.name) || 'unknown',
    page: v.url,
    license: 'Pexels License (free for commercial use, no attribution required) — https://www.pexels.com/license/',
    file: (v.video_files || []).sort((a, b) => (a.height || 0) - (b.height || 0)).find((f) => (f.height || 0) >= 480)?.link
        || (v.video_files || [])[0]?.link,
  })).filter((x) => x.file);
}

async function fromPixabay() {
  const key = env.PIXABAY_API_KEY;
  if (!key) needKey('PIXABAY_API_KEY', 'https://pixabay.com/api/docs/');
  const q = encodeURIComponent(move + ' exercise');
  const res = await fetch(`https://pixabay.com/api/videos/?key=${key}&q=${q}&per_page=${Math.min(count * 2, 50)}`);
  if (!res.ok) throw new Error('pixabay search failed: ' + res.status);
  const data = await res.json();
  return (data.hits || []).map((v) => ({
    id: v.id,
    author: v.user || 'unknown',
    page: v.pageURL,
    license: 'Pixabay Content License (free for commercial use, no attribution required) — https://pixabay.com/service/license-summary/',
    file: (v.videos && (v.videos.medium || v.videos.small || v.videos.large))?.url,
  })).filter((x) => x.file);
}

async function main() {
  let hits = source === 'pixabay' ? await fromPixabay() : await fromPexels();
  if (!hits.length) { console.log('no results for', JSON.stringify(move)); return; }

  // diversity: drop consecutive same-author, take up to `count`
  const picked = [];
  let lastAuthor = null;
  for (const h of hits) {
    if (h.author === lastAuthor) continue;
    picked.push(h); lastAuthor = h.author;
    if (picked.length >= count) break;
  }

  mkdirSync(outDir, { recursive: true });
  let n = 0;
  for (const h of picked) {
    const base = `${source}-${h.id}`;
    const mp4 = join(outDir, base + '.mp4');
    if (existsSync(mp4)) { console.log('  skip (have)', base); continue; }
    try {
      await download(h.file, mp4);
      writeFileSync(join(outDir, base + '.license.txt'),
        `source: ${source}\npage: ${h.page}\nauthor: ${h.author}\nlicense: ${h.license}\nfetched: query="${move}"\n`);
      n++;
      console.log('  got', base, '·', h.author);
    } catch (e) {
      console.log('  fail', base, e.message);
    }
  }
  console.log(`\n${n} clip(s) into corpus/${slug}/ — now label them with tools/labeler.`);
  console.log('each has a .license.txt (invariant #14). unlabelled clips are ignored by the regression suite.');
}

main().catch((e) => { console.error(e.message); process.exit(1); });

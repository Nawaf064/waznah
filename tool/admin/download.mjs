import { mkdtempSync, writeFileSync, readFileSync, rmSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { resolve, dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { spawnSync } from 'node:child_process';

const [output, revision, ...extra] = process.argv.slice(2);
if (!output || extra.length || (revision && !/^[1-9]\d*$/.test(revision))) {
  throw new Error('Usage: node tool/admin/download.mjs OUTPUT.json [HISTORY_REVISION]');
}
const root = resolve(dirname(fileURLToPath(import.meta.url)), '../..');
const { initializeApp, applicationDefault } = await import('firebase-admin/app');
const { getFirestore } = await import('firebase-admin/firestore');
initializeApp({ credential: applicationDefault(), projectId: 'waznah-47376' });
const db = getFirestore();
const temporary = mkdtempSync(join(tmpdir(), 'waznah-catalog-'));
try {
  const path = revision ? `catalog_history/revision-${revision}` : 'catalog/published';
  const snapshot = await db.doc(path).get();
  if (!snapshot.exists) throw new Error('Requested catalog does not exist');
  const staging = join(temporary, 'snapshot.json');
  writeFileSync(staging, `${JSON.stringify(snapshot.data(), null, 2)}\n`, { flag: 'wx' });
  const checked = spawnSync(process.env.WAZNAH_DART ?? 'dart',
    ['run', 'tool/catalog.dart', 'validate', staging], { cwd: root, stdio: 'inherit' });
  if (checked.status !== 0) throw new Error('Invalid catalog; output was not created');
  writeFileSync(resolve(output), readFileSync(staging), { flag: 'wx' });
  console.log(`Saved ${path} to ${resolve(output)}; server data unchanged`);
} finally {
  await db.terminate();
  // Only the directory created by this invocation is removed.
  rmSync(temporary, { recursive: true, force: true });
}

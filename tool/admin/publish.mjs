import { readFileSync } from 'node:fs';
import { resolve, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import { spawnSync } from 'node:child_process';
import { isDeepStrictEqual } from 'node:util';
import { publishCatalog } from './publication.mjs';

const root = resolve(dirname(fileURLToPath(import.meta.url)), '../..');
const [path, flag] = process.argv.slice(2);
if (!path || flag !== '--publish') {
  throw new Error('Usage: node tool/admin/publish.mjs DRAFT.json --publish');
}
const input = resolve(path);
const dart = process.env.WAZNAH_DART ?? 'dart';
const draftBytes = readFileSync(input);
const result = spawnSync(dart, ['run', 'tool/catalog.dart', 'validate', input],
  { cwd: root, stdio: 'inherit', shell: false });
if (result.status !== 0) throw new Error('Catalog validation failed; nothing published');
if (!draftBytes.equals(readFileSync(input))) throw new Error('Draft changed during validation; retry');
const data = JSON.parse(draftBytes.toString('utf8'));
const { initializeApp, applicationDefault } = await import('firebase-admin/app');
const { getFirestore } = await import('firebase-admin/firestore');
initializeApp({ credential: applicationDefault(), projectId: 'waznah-47376' });
const db = getFirestore();
await publishCatalog(db, data);
const published = await db.doc('catalog/published').get();
if (!published.exists || !isDeepStrictEqual(published.data(), data)) {
  throw new Error('Publication committed but read-back differs; inspect the live catalog before retrying');
}
console.log(`Published catalog revision ${data.revision} to waznah-47376`);
console.log(`Verified server copy: ${data.parts.length} parts, ${data.workshops.length} workshops, ${data.services.length} services`);
await db.terminate();

import test from 'node:test';
import assert from 'node:assert/strict';
import { publishCatalog } from './publication.mjs';

class MemoryDatabase {
  docs = new Map();
  doc(path) { return path; }
  async runTransaction(action) {
    const pending = [];
    await action({
      get: async path => ({ exists: this.docs.has(path), data: () => structuredClone(this.docs.get(path)) }),
      create: (path, data) => {
        if (this.docs.has(path)) throw new Error('History already exists');
        pending.push([path, data]);
      },
      set: (path, data) => pending.push([path, data]),
    });
    for (const [path, data] of pending) this.docs.set(path, structuredClone(data));
  }
}
const first = { revision: 1, partIds: ['oil-filter'] };
test('First publication and update retain the prior revision', async () => {
  const db = new MemoryDatabase();
  await publishCatalog(db, first);
  const next = { revision: 2, partIds: ['oil-filter', 'new-part'] };
  await publishCatalog(db, next);
  assert.deepEqual(db.docs.get('catalog/published'), next);
  assert.deepEqual(db.docs.get('catalog_history/revision-1'), first);
});
test('Stale revision and removing saved part identities are rejected', async () => {
  const db = new MemoryDatabase();
  await publishCatalog(db, first);
  await assert.rejects(publishCatalog(db, first), /Revision conflict/);
  await assert.rejects(publishCatalog(db, { revision: 2, partIds: ['new-part'] }), /Keep existing/);
  assert.deepEqual(db.docs.get('catalog/published'), first);
  assert.equal(db.docs.size, 1);
});
test('A backup failure leaves the active catalog untouched', async () => {
  const db = new MemoryDatabase();
  await publishCatalog(db, first);
  db.docs.set('catalog_history/revision-1', { existing: true });
  await assert.rejects(publishCatalog(db, { ...first, revision: 2 }), /History already exists/);
  assert.deepEqual(db.docs.get('catalog/published'), first);
});

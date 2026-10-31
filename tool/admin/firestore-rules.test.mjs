import { before, after, beforeEach, test } from 'node:test';
import { readFileSync } from 'node:fs';
import { initializeTestEnvironment, assertFails, assertSucceeds } from '@firebase/rules-unit-testing';
import { doc, collection, getDoc, getDocs, setDoc, updateDoc, deleteDoc } from 'firebase/firestore';

let env;
before(async () => {
  if (!process.env.FIRESTORE_EMULATOR_HOST) throw new Error('Emulator required; refusing live project');
  env = await initializeTestEnvironment({projectId: 'demo-waznah-rules', firestore: {
    rules: readFileSync(new URL('../../firestore.rules', import.meta.url), 'utf8'),
  }});
});
after(async () => { if (env) await env.cleanup(); });
beforeEach(async () => { await env.clearFirestore(); });
const own = () => env.authenticatedContext('alice').firestore();
const favorite = (ids, revision = 1) => ({ids, revision});
const garage = (items, revision = 1) => ({revision, payload: {version: 1, car: null, items}});
async function seedCatalog() {
  await env.withSecurityRulesDisabled(async c => {
    await setDoc(doc(c.firestore(), 'catalog/published'), {partIds: ['remote-part'], revision: 1});
  });
}
test('Owner can save all thirteen bundled favorites before catalog publication', async () => {
  await assertSucceeds(setDoc(doc(own(), 'users/alice/private/favorites'), favorite([
    'oil-filter','brake-pads','battery','air-filter','spark-plugs','shock-absorber',
    'camry-air-filter','prado-cabin-filter','altima-spark-plug',
    'corolla-oil-filter','corolla-cross-oil-filter',
    'yaris-cabin-filter-denso','yaris-cabin-filter-japan',
  ])));
});
test('Guest and another account cannot read or write private data', async () => {
  const path = 'users/alice/private/favorites';
  await setDoc(doc(own(), path), favorite(['oil-filter']));
  for (const db of [env.unauthenticatedContext().firestore(), env.authenticatedContext('bob').firestore()]) {
    await assertFails(getDoc(doc(db, path)));
    await assertFails(setDoc(doc(db, path), favorite(['battery'], 2)));
  }
});
test('Unknown and mistyped favorite IDs are rejected', async () => {
  for (const ids of [['unknown'], [7], ['oil-filter', false]]) {
    await assertFails(setDoc(doc(own(), 'users/alice/private/favorites'), favorite(ids)));
  }
});
test('Published dynamic IDs are accepted in favorites and maintenance', async () => {
  await seedCatalog();
  await assertSucceeds(setDoc(doc(own(), 'users/alice/private/favorites'), favorite(['remote-part', 'oil-filter'])));
  await assertSucceeds(setDoc(doc(own(), 'users/alice/private/garage'), garage({'remote-part': 99})));
});
test('Maintenance quantities reject zero, negatives, fractions, strings and booleans', async () => {
  for (const quantity of [0, -1, 100, 1.5, '2', true, null]) {
    await assertFails(setDoc(doc(own(), 'users/alice/private/garage'), garage({'camry-air-filter': quantity})));
  }
  await assertSucceeds(setDoc(doc(own(), 'users/alice/private/garage'), garage({'camry-air-filter': 1, 'prado-cabin-filter': 99})));
});
test('Quantity validation also applies to published dynamic IDs', async () => {
  await seedCatalog();
  await assertFails(setDoc(doc(own(), 'users/alice/private/garage'), garage({'remote-part': 100})));
  await assertFails(setDoc(doc(own(), 'users/alice/private/garage'), garage({'unknown': 1})));
});
test('Stale revisions and extra fields cannot overwrite favorites', async () => {
  const ref = doc(own(), 'users/alice/private/favorites');
  await setDoc(ref, favorite(['oil-filter']));
  await assertFails(setDoc(ref, favorite(['battery'], 1)));
  await assertFails(setDoc(ref, {...favorite(['battery'], 2), admin: true}));
  await assertSucceeds(setDoc(ref, favorite(['battery'], 2)));
});
test('Invalid car and garage schema are rejected', async () => {
  const ref = doc(own(), 'users/alice/private/garage');
  await assertFails(setDoc(ref, {revision: 1, payload: {version: 2, car: null, items: {}}}));
  await assertFails(setDoc(ref, {revision: 1, payload: {version: 1, car: {brand: '', model:'m', year:2021, engine:'e'}, items: {}}}));
  await assertSucceeds(setDoc(ref, garage({})));
  await assertFails(updateDoc(ref, {revision: 1}));
});
test('Catalog requires authentication; all client publication attempts are denied', async () => {
  await seedCatalog();
  await assertSucceeds(getDoc(doc(own(), 'catalog/published')));
  await assertFails(getDoc(doc(env.unauthenticatedContext().firestore(), 'catalog/published')));
  for (const db of [own(), env.authenticatedContext('admin', {admin: true}).firestore()]) {
    await assertFails(setDoc(doc(db, 'catalog/published'), {partIds: [], revision:2}));
  }
});
test('History, list queries and deletes stay private and protected', async () => {
  await assertFails(getDoc(doc(own(), 'catalog_history/revision-1')));
  await assertFails(getDocs(collection(own(), 'users/alice/private')));
  const ref = doc(own(), 'users/alice/private/favorites');
  await setDoc(ref, favorite([]));
  await assertFails(deleteDoc(ref));
});
test('Oversized favorites list is rejected', async () => {
  await assertFails(setDoc(doc(own(), 'users/alice/private/favorites'), favorite(Array(201).fill('oil-filter'))));
});

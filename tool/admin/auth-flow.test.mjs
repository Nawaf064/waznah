import { test, after } from 'node:test';
import assert from 'node:assert/strict';
import { initializeApp, deleteApp } from 'firebase/app';
import {
  getAuth, connectAuthEmulator, createUserWithEmailAndPassword,
  signInWithEmailAndPassword, signOut, sendEmailVerification,
  applyActionCode, reload, sendPasswordResetEmail, confirmPasswordReset,
} from 'firebase/auth';
import {
  getFirestore, connectFirestoreEmulator, doc, setDoc, getDoc,
  terminate,
} from 'firebase/firestore';

// Fail closed before constructing any client: never run this against production.
if (process.env.FIREBASE_AUTH_EMULATOR_HOST !== '127.0.0.1:9099' ||
    process.env.FIRESTORE_EMULATOR_HOST !== '127.0.0.1:8080') {
  throw new Error('Both localhost emulators are required; refusing live services');
}
const projectId = 'demo-waznah-rules';
const app = initializeApp({ projectId, apiKey: 'fake-emulator-key', appId: 'test-only' }, 'auth-flow');
const auth = getAuth(app);
connectAuthEmulator(auth, 'http://127.0.0.1:9099', { disableWarnings: true });
const db = getFirestore(app);
connectFirestoreEmulator(db, '127.0.0.1', 8080);
const email = `flow-${Date.now()}@example.test`;
const password = 'Test-only-before-123!';
const replacement = 'Test-only-after-456!';
let uid;

async function actionCode(type) {
  const response = await fetch(`http://127.0.0.1:9099/emulator/v1/projects/${projectId}/oobCodes`);
  assert.equal(response.status, 200);
  const result = await response.json();
  const code = result.oobCodes.find(entry => entry.email === email && entry.requestType === type);
  assert.ok(code, `Expected locally generated ${type} code`);
  return code.oobCode;
}

after(async () => { await terminate(db); await deleteApp(app); });

test('New account can sign in again and restore its saved favorites', async () => {
  const created = await createUserWithEmailAndPassword(auth, email, password);
  uid = created.user.uid;
  const ref = doc(db, `users/${uid}/private/favorites`);
  await setDoc(ref, { ids: ['oil-filter'], revision: 1 });
  await signOut(auth);
  await assert.rejects(getDoc(ref), error => error.code === 'permission-denied');
  await assert.rejects(signInWithEmailAndPassword(auth, email, 'incorrect-password'));
  const signedIn = await signInWithEmailAndPassword(auth, email, password);
  assert.equal(signedIn.user.uid, uid);
  assert.deepEqual((await getDoc(ref)).data(), { ids: ['oil-filter'], revision: 1 });
});

test('Verification action updates email status and cannot be reused', async () => {
  assert.equal(auth.currentUser.emailVerified, false);
  await sendEmailVerification(auth.currentUser);
  const code = await actionCode('VERIFY_EMAIL');
  await applyActionCode(auth, code);
  await reload(auth.currentUser);
  assert.equal(auth.currentUser.emailVerified, true);
  await assert.rejects(applyActionCode(auth, code));
});

test('Reset action changes password without losing identity or saved data', async () => {
  await signOut(auth);
  await sendPasswordResetEmail(auth, email);
  const code = await actionCode('PASSWORD_RESET');
  await confirmPasswordReset(auth, code, replacement);
  await assert.rejects(confirmPasswordReset(auth, code, replacement));
  await assert.rejects(signInWithEmailAndPassword(auth, email, password));
  const signedIn = await signInWithEmailAndPassword(auth, email, replacement);
  assert.equal(signedIn.user.uid, uid);
  assert.deepEqual((await getDoc(doc(db, `users/${uid}/private/favorites`))).data().ids, ['oil-filter']);
});

test('A second authenticated account cannot access the first account data', async () => {
  await signOut(auth);
  await createUserWithEmailAndPassword(auth, `other-${email}`, password);
  const ref = doc(db, `users/${uid}/private/favorites`);
  await assert.rejects(getDoc(ref), error => error.code === 'permission-denied');
  await assert.rejects(setDoc(ref, { ids: ['battery'], revision: 2 }),
    error => error.code === 'permission-denied');
});

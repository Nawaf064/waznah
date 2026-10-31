import test from 'node:test';
import assert from 'node:assert/strict';
import { mkdtempSync, readFileSync, writeFileSync, existsSync, rmSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { resolve, dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { spawnSync } from 'node:child_process';

const root = resolve(dirname(fileURLToPath(import.meta.url)), '../..');
const fixture = JSON.parse(readFileSync(join(root, 'data/catalog-draft.json'), 'utf8'));
const dart = process.env.WAZNAH_DART ?? 'dart';
function run(...args) {
  return spawnSync(dart, ['run', 'tool/catalog.dart', ...args],
    { cwd: root, encoding: 'utf8' });
}

test('Prepare preserves prices, increments revision and refuses overwriting inputs', () => {
  const dir = mkdtempSync(join(tmpdir(), 'waznah-cli-test-'));
  try {
    const current = join(dir, 'current.json');
    const output = join(dir, 'next.json');
    writeFileSync(current, JSON.stringify(fixture));
    assert.equal(run('prepare', current, output).status, 0);
    const next = JSON.parse(readFileSync(output, 'utf8'));
    assert.deepEqual(next, { ...fixture, revision: fixture.revision + 1 });
    const saved = readFileSync(output, 'utf8');
    assert.notEqual(run('prepare', current, output).status, 0);
    assert.equal(readFileSync(output, 'utf8'), saved);
    assert.notEqual(run('prepare', current, current).status, 0);
    assert.deepEqual(JSON.parse(readFileSync(current, 'utf8')), fixture);
    assert.equal(run('validate', output).status, 0);
  } finally { rmSync(dir, { recursive: true, force: true }); }
});

test('Restore uses a new revision and refuses loss of customer part identities', () => {
  const dir = mkdtempSync(join(tmpdir(), 'waznah-cli-test-'));
  try {
    const current = join(dir, 'current.json');
    const history = join(dir, 'history.json');
    const output = join(dir, 'restored.json');
    const live = structuredClone(fixture);
    live.revision = 5;
    live.offers[0].priceHalalas += 100;
    writeFileSync(current, JSON.stringify(live));
    writeFileSync(history, JSON.stringify(fixture));
    assert.equal(run('prepare', current, output, history).status, 0);
    assert.deepEqual(JSON.parse(readFileSync(output, 'utf8')), { ...fixture, revision: 6 });
    const incomplete = structuredClone(fixture);
    const removedId = incomplete.parts.pop().id;
    incomplete.partIds = incomplete.partIds.filter(id => id !== removedId);
    incomplete.offers = incomplete.offers.filter(offer => offer.partId !== removedId);
    writeFileSync(history, JSON.stringify(incomplete));
    const rejected = join(dir, 'rejected.json');
    assert.notEqual(run('prepare', current, rejected, history).status, 0);
    assert.equal(existsSync(rejected), false);
    writeFileSync(history, '{broken');
    assert.notEqual(run('prepare', current, rejected, history).status, 0);
    assert.equal(existsSync(rejected), false);
  } finally { rmSync(dir, { recursive: true, force: true }); }
});

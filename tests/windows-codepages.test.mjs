import test from 'node:test';
import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import {inspectSav, readSav} from '../node/api.mjs';

const root = new URL('../fixtures/synthetic/windows-codepages/', import.meta.url);
const fixture = name => readFileSync(new URL(name, root));
const manifest = JSON.parse(fixture('manifest.json'));
const localPages = manifest.filter(entry => entry.profile !== 'utf-8');

test('local Windows and UTF-8 survey pairs preserve labels, missingness and decoded values', () => {
  for (const {profile, file, expected_text: expected} of localPages) {
    const local = readSav(fixture(file));
    const unicode = readSav(fixture(profile + '-utf8.sav'));
    assert.equal(local.dictionary.encoding.effective, profile);
    assert.equal(local.dictionary.encoding.selection_source, 'record20');
    for (const {dictionary, rows} of [local, unicode]) {
      assert.deepEqual(dictionary.variables.map(v => v.name), ['ID', 'SCORE', 'NOTE']);
      assert.equal(dictionary.variables[1].label, expected);
      assert.equal(dictionary.variables[1].value_labels[0].label, expected);
      assert.deepEqual(rows.map(row => row[0].text.trimEnd()), ['0012', 'NA', '\\N']);
      assert.deepEqual(rows.map(row => row[1].decimal), ['88', '99', null]);
      assert.deepEqual(rows.map(row => row[1].missing), ['present', 'user', 'system']);
      assert.deepEqual(rows.map(row => row[2].text), [expected, expected, expected]);
    }
    assert.notEqual(local.rows[0][2].logical_bytes_base64, unicode.rows[0][2].logical_bytes_base64);
  }
});

test('Windows declaration, machine-only fallback and confirmed overrides select a strict decoder', () => {
  const original = fixture('windows-1251.sav');
  const name = Buffer.from('windows-1251');
  const pos = original.indexOf(name);
  assert.ok(pos > 176);
  const machineOnly = Buffer.concat([original.subarray(0, pos - 16), original.subarray(pos + name.length)]);
  assert.equal(inspectSav(machineOnly).encoding.selection_source, 'machine_code');
  assert.equal(readSav(machineOnly).rows[0][2].text, 'Москва');
  const conflict = Buffer.from(original);
  conflict.write('windows-1250', pos);
  assert.throws(() => readSav(conflict), {code: 'EncodingConflict'});
  for (const encoding of ['CP1251', '1251']) {
    const data = readSav(conflict, {encoding});
    assert.equal(data.dictionary.encoding.selection_source, 'override');
    assert.ok(data.dictionary.warnings.some(w => w.warning_code === 'EncodingOverride'));
    assert.equal(data.rows[0][2].text, 'Москва');
  }
});

test('undefined Windows codec bytes in dictionary and row data fail without replacement', () => {
  const original = fixture('windows-1251.sav');
  const sample = Buffer.from('cceef1eae2e0', 'hex'); // Windows-1251 Moscow
  const dictionaryByte = original.indexOf(sample), rowByte = original.lastIndexOf(sample);
  assert.ok(dictionaryByte > 176 && rowByte > dictionaryByte);
  for (const offset of [dictionaryByte, rowByte]) {
    const bad = Buffer.from(original);
    bad[offset] = 0x98;
    assert.throws(() => readSav(bad), {code: 'InvalidEncoding'});
  }
});

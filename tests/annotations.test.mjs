import test from 'node:test';
import assert from 'node:assert/strict';
import {readFileSync, writeFileSync, mkdtempSync, rmSync} from 'node:fs';
import {tmpdir} from 'node:os';
import {join} from 'node:path';
import {spawnSync} from 'node:child_process';
import {createHash} from 'node:crypto';
import {inspectSav} from '../node/api.mjs';

const source = 'fixtures/synthetic/annotations-pspp.sav';
const bytes = readFileSync(source);
const cli = (...args) => spawnSync(process.execPath, ['bin/moonsav.mjs', ...args, '--json'], {encoding: 'utf8'});

test('PSPP-produced documents and attributes are exposed as structured metadata with original bytes', () => {
  const info = inspectSav(bytes);
  const annotations = info.dictionary_annotations;
  assert.deepEqual(annotations.document_lines.slice(0, 2).map(x => x.trimEnd()), ['Field survey', 'Second line']);
  assert.deepEqual(annotations.file_attributes, [
    {name: 'Project', values: ["team's / notes"]},
    {name: 'Stage', values: ['one', 'two']},
  ]);
  assert.deepEqual(annotations.variable_attributes.map(group => [group.variable_index, group.attributes.find(a => a.name === 'Units').values[0]]), [[0, 'points'], [1, 'visit']]);
  assert.deepEqual(annotations.sources.map(e => [e.record, e.subtype]), [[6, null], [7, 7], [7, 17], [7, 18]]);
  assert.deepEqual(annotations.multiple_response_sets.map(s => [s.name,s.label,s.variable_indices]), [['$items','Survey items',[0,1]]]);
  assert.ok(!info.uninterpreted_metadata.some(e => e.record === 6 || [17,18].includes(e.subtype)));
});

test('variable sets resolve named variables and preserve empty sets', () => {
  const data = readFileSync('fixtures/synthetic/annotations-varsets.sav');
  assert.deepEqual(inspectSav(data).dictionary_annotations.variable_sets, [
    {name: 'Survey', variable_indices: [1, 0]}, {name:'Empty', variable_indices:[]},
  ]);
});

test('bundle checker reinterprets annotation source bytes instead of trusting rewritten metadata', () => {
  const dir = mkdtempSync(join(tmpdir(),'moonsav-annotations-'));
  try {
    const out = join(dir, 'export');
    const exportResult = cli('export', source, '--out', out);
    assert.equal(exportResult.status, 0, exportResult.stderr);
    assert.equal(cli('check-bundle', out).status, 0);
    const metadata = join(out, 'metadata.json');
    const manifest = join(out, 'manifest.json');
    const changed = JSON.parse(readFileSync(metadata));
    changed.dictionary_annotations.variable_attributes[0].attributes[0].values[0] = 'changed';
    const buffer = Buffer.from(JSON.stringify(changed) + '\n');
    writeFileSync(metadata, buffer);
    const fileManifest = JSON.parse(readFileSync(manifest));
    fileManifest.files['metadata.json'] = {size_bytes:buffer.length, sha256:createHash('sha256').update(buffer).digest('hex')};
    writeFileSync(manifest, JSON.stringify(fileManifest) + '\n');
    const checked = cli('check-bundle', out);
    assert.equal(checked.status, 4, checked.stderr);
    assert.equal(JSON.parse(checked.stderr).error.code, 'IntegrityMismatch');
  } finally {
    rmSync(dir, {recursive:true, force:true});
  }
});

test('multiple-response definitions use byte lengths and retain counted values and label modes', () => {
  const data = readFileSync('fixtures/synthetic/annotations-mrsets.sav');
  const {multiple_response_sets: sets} = inspectSav(data).dictionary_annotations;
  assert.deepEqual(sets.map(s => [s.name,s.kind,s.category_labels,s.label_source,s.counted_value,s.label,s.variable_indices]), [
    ['$c','category',null,null,null,'中文',[0,1]],
    ['$d','dichotomy','variable_labels',null,'1',null,[0,1]],
    ['$e','dichotomy','counted_values','variable_label','0',null,[0,1]],
  ]);
});

test('unknown set members retain the whole record with an explicit warning', () => {
  const data = readFileSync('fixtures/synthetic/annotations-varsets.sav');
  const changed = Buffer.from(data);
  const offset = changed.indexOf('Survey= wave');
  assert.ok(offset > 176);
  changed.write('uhoh', offset + 'Survey= '.length);
  const d = inspectSav(changed);
  assert.deepEqual(d.dictionary_annotations.variable_sets, []);
  assert.equal(d.uninterpreted_metadata.filter(r => r.subtype === 5).length, 1);
  assert.ok(d.warnings.some(w => w.warning_code === 'UninterpretedMetadata'));
});

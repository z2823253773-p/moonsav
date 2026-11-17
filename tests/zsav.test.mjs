import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import {spawnSync} from 'node:child_process';
import {deflateSync} from 'node:zlib';
import {readSav, inspectSav} from '../node/api.mjs';

const bytes = name => fs.readFileSync(`fixtures/synthetic/${name}`);
const z = () => bytes('zsav-survey-zlib.zsav');
const cli = (...args) => spawnSync(process.execPath, ['bin/moonsav.mjs', ...args, '--json'], {encoding:'utf8', timeout:10000});

test('same independent survey preserves every Cell and variable dictionary under all three storage modes', () => {
  const data = ['zsav-survey-none.sav','zsav-survey-row.sav','zsav-survey-zlib.zsav'].map(n => readSav(bytes(n)));
  for (const d of data) {
    assert.equal(d.rows.length, 3);
    assert.equal(d.dictionary.variables.length, 6);
    assert.deepEqual(d.rows.map(r=>r[2].missing), ['present','user','system']);
    assert.equal(d.rows[0][0].text.trimEnd(), '0012');
    assert.equal(d.rows[1][0].text.trimEnd(), 'NA');
    assert.equal(d.rows[2][0].text.trimEnd(), '\\N');
    assert.equal(d.rows[0][4].text, '问卷备注'.repeat(140)+'0');
    assert.equal(d.dictionary.variables[5].print_format.code, 20);
    assert.equal(d.dictionary.variables[0].label, '编号');
    assert.equal(d.dictionary.variables[1].value_labels[0].label, '甲组');
    assert.deepEqual(d.rows, data[0].rows);
    assert.deepEqual(d.dictionary.variables, data[0].dictionary.variables);
  }
  assert.deepEqual(data.map(d=>d.dictionary.compression), [0,1,2]);
});

test('multiblock inflation crosses control and literal boundaries without changing opcode semantics', () => {
  const actual = readSav(bytes('zsav-multi.zsav'));
  assert.deepEqual(actual.rows, readSav(bytes('controls.sav')).rows);
  assert.deepEqual(actual.rows.map(r=>r[0].missing), ['present','present','system']);
  assert.equal(actual.rows[1][1].text, 'ABCDEFGH');
  assert.equal(readSav(bytes('zsav-zero.zsav')).rows.length, 0);
});

test('ZSAV inspect stays dictionary-only while full reads enforce an independent inflation budget', () => {
  assert.equal(inspectSav(z(), {maxInflatedBytes:1}).compression, 2);
  assert.throws(()=>readSav(z(), {maxInflatedBytes:1}), {code:'ResourceLimit'});
  const r = cli('validate','fixtures/synthetic/zsav-survey-zlib.zsav','--max-inflated-bytes','1');
  assert.equal(r.status, 6, r.stderr);
});

test('real producer multiblock file retains all 3000 long strings', () => {
  const d=readSav(bytes('zsav-produced-multi.zsav'));
  assert.equal(d.rows.length,3000);
  for(let i=0;i<3000;i++)assert.equal(d.rows[i][0].text,'问卷备注'.repeat(140)+String(i).padStart(4,'0'));
});

// Replace a one-block payload independently; keep the container directory coherent
// so this catches primitive failures, not just the outer offsets check.
function withPayload(original,payload) {
  const base=Number(original.readBigInt64LE(original.length-24));
  const oldTrailer=Number(original.readBigInt64LE(base+8));
  const prefix=Buffer.from(original.subarray(0,base+24));
  const trailer=Buffer.from(original.subarray(oldTrailer));
  const offset=prefix.length+payload.length;
  prefix.writeBigInt64LE(BigInt(offset),base+8);
  trailer.writeInt32LE(payload.length,44);
  return Buffer.concat([prefix,payload,trailer]);
}

test('bounded inflater rejects trailing and concatenated streams even inside a consistent container', () => {
  const original=z(),base=Number(original.readBigInt64LE(original.length-24));
  const trailer=Number(original.readBigInt64LE(base+8));
  const payload=original.subarray(base+24,trailer);
  for(const tail of [Buffer.from([0]),deflateSync(Buffer.from('extra'))]) {
    assert.throws(()=>readSav(withPayload(original,Buffer.concat([payload,tail]))),{code:'InvalidCompression'});
  }
});

test('inflation budget accepts the exact total and rejects one byte less before row collection', () => {
  const original=z(),base=Number(original.readBigInt64LE(original.length-24));
  const trailer=Number(original.readBigInt64LE(base+8));
  const total=original.readInt32LE(trailer+40);
  assert.equal(readSav(original,{maxInflatedBytes:total}).rows.length,3);
  assert.throws(()=>readSav(original,{maxInflatedBytes:total-1}),{code:'ResourceLimit'});
  for(const option of [{maxInflatedBytes:0},{maxInflatedBytes:268435457}])assert.throws(()=>readSav(original,option),{code:'ResourceLimit'});
});

test('oversized block declarations return a resource error before allocating or inflating', () => {
  const b=Buffer.from(z()),base=Number(b.readBigInt64LE(b.length-24));
  const trailer=Number(b.readBigInt64LE(base+8));
  b.writeInt32LE(16777217,trailer+16);
  b.writeInt32LE(16777217,trailer+40);
  assert.throws(()=>readSav(b),{code:'ResourceLimit'});
});

test('corrupt ZSAV containers and zlib streams fail without committing an export', () => {
  const original = z(), base = Number(original.readBigInt64LE(original.length-24));
  // Derive the header through the directory's first uncompressed offset.
  const trailer = Number(original.readBigInt64LE(base+8));
  const cases = [];
  const change = (name, mutate) => {const b=Buffer.from(original); mutate(b); cases.push([name,b]);};
  change('header-offset', b=>b.writeBigInt64LE(BigInt(base+1),base));
  change('huge-trailer-offset', b=>b.writeBigUInt64LE(0xffffffffffffffffn,base+8));
  change('block-count', b=>b.writeInt32LE(2147483647,trailer+20));
  change('compressed-overlap', b=>b.writeBigInt64LE(BigInt(base),trailer+32));
  change('wrong-raw-size', b=>b.writeInt32LE(1,trailer+40));
  change('checksum', b=>{b[trailer-1]^=1;});
  change('wrong-magic-compression', b=>{b.write('$FL2');});
  cases.push(['truncated',original.subarray(0,-1)], ['trailing',Buffer.concat([original,Buffer.from([0])])]);
  const dir=fs.mkdtempSync(path.join(os.tmpdir(),'moonsav-zsav-'));
  try {
    for (const [name,b] of cases) {
      assert.throws(()=>readSav(b), e=>e.code==='InvalidCompression'||e.code==='Truncated', name);
      const input=path.join(dir,name+'.zsav'),out=path.join(dir,name+'-bundle');
      fs.writeFileSync(input,b);
      const r=cli('export',input,'--out',out);
      assert.equal(r.status,4, name+': '+r.stderr);
      assert.ok(!fs.existsSync(out)||fs.existsSync(path.join(out,'INCOMPLETE')),name);
    }
  } finally {fs.rmSync(dir,{recursive:true,force:true});}
});

test('ZSAV exports retain compression2 metadata and pass the real bundle checker', () => {
  const dir=fs.mkdtempSync(path.join(os.tmpdir(),'moonsav-zsav-bundle-'));
  try {
    const out=path.join(dir,'bundle');
    const r=cli('export','fixtures/synthetic/zsav-survey-zlib.zsav','--out',out);
    assert.equal(r.status,0,r.stderr);
    assert.equal(cli('check-bundle',out).status,0);
    const metadata=JSON.parse(fs.readFileSync(path.join(out,'metadata.json')));
    assert.equal(metadata.compression,2);
  } finally {fs.rmSync(dir,{recursive:true,force:true});}
});

import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import {spawnSync} from 'node:child_process';
import {createHash} from 'node:crypto';
import {readSav,inspectSav} from '../node/api.mjs';
const bytes=name=>fs.readFileSync(`fixtures/synthetic/${name}`);
const pairs=JSON.parse(bytes('endian-provenance.json')).pairs;
const cli=(...args)=>spawnSync(process.execPath,['bin/moonsav.mjs',...args,'--json'],{encoding:'utf8',timeout:10000});

test('both byte orders and all three storage forms preserve the shared survey Cells and variable semantics',()=>{
 const all=[];
 for(const prefix of ['', 'be-'])for(const suffix of ['none.sav','row.sav','zlib.zsav']) {
  const d=readSav(bytes(prefix+'zsav-survey-'+suffix));all.push(d);
  assert.equal(d.dictionary.byte_order,prefix?'big':'little');
  assert.equal(d.rows.length,3);assert.equal(d.dictionary.variables.length,6);
  assert.deepEqual(d.rows.map(r=>r[2].missing),['present','user','system']);
  assert.equal(d.rows[0][0].text.trimEnd(),'0012');assert.equal(d.rows[1][0].text.trimEnd(),'NA');
  assert.equal(d.rows[0][4].text,'问卷备注'.repeat(140)+'0');
  assert.deepEqual(d.rows,all[0].rows);assert.deepEqual(d.dictionary.variables,all[0].dictionary.variables);
 }
});

test('endian propagation covers literal/control numbers, missing ranges, signed zero and nested long-string metadata',()=>{
 for(const p of pairs) {
  const le=readSav(bytes(p.source)),be=readSav(bytes(p.big_endian));
  assert.deepEqual(be.rows,le.rows,p.source);
  assert.deepEqual(be.dictionary.variables,le.dictionary.variables,p.source);
  for(const k of ['declared_rows','system_missing_hex','lowest_hex','highest_hex','weight_variable'])assert.deepEqual(be.dictionary[k],le.dictionary[k],p.source+': '+k);
 }
 const extra=readSav(bytes('be-endian-extra-le.sav'));
 assert.equal(extra.dictionary.weight_variable,0);assert.equal(extra.dictionary.declared_rows,3);
 assert.deepEqual(extra.rows.map(r=>r[0].missing),['user','user','system']);
 assert.equal(extra.dictionary.variables[0].display_width,12);
 assert.equal(readSav(bytes('be-negative-zero.sav')).rows[0][0].ieee754_hex,'8000000000000000');
 assert.deepEqual(readSav(bytes('be-endian-signed-zero-le.sav')).rows.map(r=>r[0].ieee754_hex),['8000000000000000','0000000000000000','3ff4000000000000']);
});

test('big-endian ZSAV inspect remains dictionary-only and inflation limits still apply',()=>{
 const b=bytes('be-zsav-survey-zlib.zsav');
 assert.equal(inspectSav(b,{maxInflatedBytes:1}).byte_order,'big');
 assert.throws(()=>readSav(b,{maxInflatedBytes:1}),{code:'ResourceLimit'});
});

test('contradictory machine order, malformed big-endian lengths and mixed standard bias fail explicitly',()=>{
 const original=bytes('be-endian-extra-le.sav');
 const b=Buffer.from(original),needle=Buffer.from('00000007000000030000000400000008','hex');
 const machine=b.indexOf(needle);assert.ok(machine>=176);
 b.writeInt32BE(2,machine+16+24);
 assert.throws(()=>readSav(b),{code:'InvalidDictionary',record:7,subtype:3,byte_offset:machine});
 const mixed=Buffer.from(original);mixed.set(original.subarray(84,92).toReversed(),84);
 assert.throws(()=>readSav(mixed),{code:'UnsupportedFloat'});
 const bad=Buffer.from(original);bad.writeInt32BE(-1,180+4);
 assert.throws(()=>readSav(bad),{code:'InvalidDictionary'});
 const huge=Buffer.from(original);huge.writeInt32BE(2147483647,68);
 assert.throws(()=>readSav(huge),{code:'ResourceLimit'});
 for(const n of [65,175,176,183,original.length-1])assert.throws(()=>readSav(original.subarray(0,n)),{code:'Truncated'});
});

test('layout3 and absent machine record work while corrupt big-endian ZSAV64-bit offsets reject',()=>{
 const b=Buffer.from(bytes('be-zsav-survey-none.sav'));b.writeInt32BE(3,64);
 assert.equal(readSav(b).dictionary.byte_order,'big');
 const marker=Buffer.from('00000007000000030000000400000008','hex'),at=b.indexOf(marker);
 assert.ok(at>=176);
 const withoutMachine=Buffer.concat([b.subarray(0,at),b.subarray(at+48)]);
 assert.throws(()=>readSav(withoutMachine),{code:'EncodingRequired'});
 assert.deepEqual(readSav(withoutMachine,{encoding:'utf-8'}).rows,readSav(b).rows);
 const unknown=Buffer.from(b);unknown.writeInt32BE(4,64);assert.throws(()=>readSav(unknown),{code:'UnsupportedLayout'});
 const z=Buffer.from(bytes('be-zsav-survey-zlib.zsav'));
 const base=Number(z.readBigInt64BE(z.length-24));
 z.writeBigUInt64BE(0xffffffffffffffffn,base+8);
 assert.throws(()=>readSav(z),{code:'InvalidCompression'});
});

test('big-endian bundles preserve source order and old bundles lacking byte_order remain readable',()=>{
 const dir=fs.mkdtempSync(path.join(os.tmpdir(),'moonsav-endian-'));
 try {
  const out=path.join(dir,'bundle');
  const r=cli('export','fixtures/synthetic/be-zsav-survey-zlib.zsav','--out',out);
  assert.equal(r.status,0,r.stderr);
  assert.equal(JSON.parse(fs.readFileSync(path.join(out,'metadata.json'))).byte_order,'big');
  assert.equal(cli('check-bundle',out).status,0);
  const old=path.join(dir,'old');
  assert.equal(cli('export','fixtures/synthetic/zsav-survey-row.sav','--out',old).status,0);
  const mpath=path.join(old,'metadata.json'),manifestPath=path.join(old,'manifest.json');
  const metadata=JSON.parse(fs.readFileSync(mpath));delete metadata.byte_order;
  const rewrite=()=>{
   const encoded=Buffer.from(JSON.stringify(metadata)+'\n');fs.writeFileSync(mpath,encoded);
   const manifest=JSON.parse(fs.readFileSync(manifestPath));manifest.files['metadata.json']={size_bytes:encoded.length,sha256:createHash('sha256').update(encoded).digest('hex')};
   fs.writeFileSync(manifestPath,JSON.stringify(manifest)+'\n');
  };
  rewrite();assert.equal(cli('check-bundle',old).status,0);
  metadata.byte_order='middle';rewrite();
  const bad=cli('check-bundle',old);assert.equal(bad.status,4);assert.equal(JSON.parse(bad.stderr).error.code,'IntegrityMismatch');
 } finally {fs.rmSync(dir,{recursive:true,force:true});}
});

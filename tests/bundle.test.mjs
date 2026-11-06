import test from 'node:test';import assert from 'node:assert/strict';import fs from 'node:fs';import os from 'node:os';import path from 'node:path';import {spawnSync}from'node:child_process';import {createHash}from'node:crypto';
const cli=(...args)=>{const p=spawnSync(process.execPath,['bin/moonsav.mjs',...args,'--json'],{encoding:'utf8'});return {code:p.status,out:p.stdout.trim()?JSON.parse(p.stdout):null,err:p.stderr.trim()?JSON.parse(p.stderr):null}};
const temp=fs.mkdtempSync(path.join(os.tmpdir(),'moonsav-test-'));
function bundle(name){const d=path.join(temp,name);assert.equal(cli('export','fixtures/synthetic/survey-row.sav','--out',d).code,0);return d}
function rehash(d,n){const p=path.join(d,'manifest.json'),m=JSON.parse(fs.readFileSync(p)),b=fs.readFileSync(path.join(d,n));m.files[n]={size_bytes:b.length,sha256:createHash('sha256').update(b).digest('hex')};fs.writeFileSync(p,JSON.stringify(m)+'\n')}
test('canonical and multiline CSV validate as one paired bundle',()=>{const d=bundle('valid');const r=cli('check-bundle',d);assert.equal(r.code,0);assert.equal(r.out.actual_rows,5)});
test('rehashing a wrong missing state cannot bypass semantic checker',()=>{const d=bundle('missing');const p=path.join(d,'data.ndjson'),a=fs.readFileSync(p,'utf8').trimEnd().split('\n').map(JSON.parse);a[0].cells[0].missing='user';fs.writeFileSync(p,a.map(JSON.stringify).join('\n')+'\n');rehash(d,'data.ndjson');const r=cli('check-bundle',d);assert.equal(r.code,4);assert.equal(r.err.error.code,'IntegrityMismatch')});
test('rehashing CSV that disagrees with canonical fails',()=>{const d=bundle('csv');const p=path.join(d,'data.csv');fs.writeFileSync(p,fs.readFileSync(p,'utf8').replace('0012','7777'));rehash(d,'data.csv');assert.equal(cli('check-bundle',d).code,4)});
test('INCOMPLETE always rejects an otherwise completed bundle',()=>{const d=bundle('incomplete');fs.writeFileSync(path.join(d,'INCOMPLETE'),'');const r=cli('check-bundle',d);assert.equal(r.code,4);assert.equal(r.err.error.code,'IncompleteBundle')});
test('missing canonical and symlink metadata reject',()=>{const d=bundle('missingfile');fs.unlinkSync(path.join(d,'data.ndjson'));assert.equal(cli('check-bundle',d).code,4);const e=bundle('symlink');const p=path.join(e,'metadata.json'),original=p+'.copy';fs.renameSync(p,original);fs.symlinkSync(original,p);assert.equal(cli('check-bundle',e).code,4)});
for(const [name,mutate]of[
 ['duplicate semantic label',m=>m.variables[0].value_labels.push({...m.variables[0].value_labels[0],label:'conflict',raw_label_base64:Buffer.from('conflict').toString('base64')})],
 ['bad weight reference',m=>m.weight_variable=999999],
 ['invalid discrete endpoint',m=>m.variables[0].user_missing.values[0].endpoint='highest'],
 ['impossible numeric slot width',m=>{m.variables[0].physical_slots=2;m.variables[1].physical_start=2;m.variables[2].physical_start=3;m.physical_slots++}]
])test(`rehashing metadata cannot admit ${name}`,()=>{const d=bundle(name.replaceAll(' ','-')),p=path.join(d,'metadata.json'),m=JSON.parse(fs.readFileSync(p));mutate(m);fs.writeFileSync(p,JSON.stringify(m)+'\n');rehash(d,'metadata.json');const r=cli('check-bundle',d);assert.equal(r.code,4);assert.equal(r.err.error.code,'IntegrityMismatch')});
test('canonical bytes parsed after a file swap must still match manifest hash',async()=>{const d=path.join(temp,'swap');assert.equal(cli('export','fixtures/synthetic/survey-row.sav','--out',d,'--format','ndjson').code,0);const{checkBundle}=await import('../node/checker.mjs');const target=path.join(d,'data.ndjson'),open=fs.openSync;let count=0,swapped=false;fs.openSync=function(p,...args){if(String(p)===target&&++count===2&&!swapped){swapped=true;const rows=fs.readFileSync(target,'utf8').trimEnd().split('\n').map(JSON.parse);rows[0].cells[0].decimal='42';rows[0].cells[0].ieee754_hex='4045000000000000';fs.writeFileSync(target,rows.map(JSON.stringify).join('\n')+'\n')}return open.call(this,p,...args)};try{assert.throws(()=>checkBundle(d),{code:'IntegrityMismatch'})}finally{fs.openSync=open}assert.equal(swapped,true)});
for(const name of['metadata.json','manifest.json','data.ndjson','data.csv'])test(`invalid UTF8 ${name} is a data rejection, not I/O`,()=>{const d=bundle('utf8-'+name);fs.writeFileSync(path.join(d,name),Buffer.of(255,10));if(name!=='manifest.json')rehash(d,name);const r=cli('check-bundle',d);assert.equal(r.code,4);assert.ok(['InvalidEncoding','IntegrityMismatch'].includes(r.err.error.code))});
for(const [name,mutate]of[['unsupported CSV policy',m=>m.csv.string_escape='backslash'],['unknown encoding selection policy',m=>m.encoding.selection_source='guess'],['unknown retained semantic extension',m=>m.uninterpreted_metadata=[{record:7,subtype:999,byte_offset:176,raw_base64:'AA=='}]]])test(`metadata policy ${name} cannot bypass checker with a new hash`,()=>{const d=bundle(name.replaceAll(' ','-')),p=path.join(d,'metadata.json'),m=JSON.parse(fs.readFileSync(p));mutate(m);fs.writeFileSync(p,JSON.stringify(m)+'\n');rehash(d,'metadata.json');assert.equal(cli('check-bundle',d).code,4)});

// Observe real descriptors; delegated opens/reads still exercise the filesystem.
// Removing checker-owned iterator cleanup must make these assertions fail.
for(const failure of['CSV header','canonical row','canonical final newline','extra CSV row'])test(`failed ${failure} check closes every opened data descriptor`,async()=>{
 const d=bundle('cleanup-'+failure.replaceAll(' ','-'));
 const canonical=path.join(d,'data.ndjson'),csv=path.join(d,'data.csv');
 if(failure==='CSV header'){fs.writeFileSync(csv,'WRONG'+fs.readFileSync(csv,'utf8'));rehash(d,'data.csv')}
 if(failure==='canonical row'){const rows=fs.readFileSync(canonical,'utf8').split('\n');rows[0]='{';fs.writeFileSync(canonical,rows.join('\n'));rehash(d,'data.ndjson')}
 if(failure==='canonical final newline'){fs.writeFileSync(canonical,fs.readFileSync(canonical).subarray(0,-1));rehash(d,'data.ndjson')}
 if(failure==='extra CSV row'){fs.appendFileSync(csv,'1,x,x\r\n');rehash(d,'data.csv')}
 const {checkBundle}=await import('../node/checker.mjs');
 const open=fs.openSync,observed=new Set();
 fs.openSync=function(p,...args){const fd=open.call(this,p,...args);if(String(p)===canonical||String(p)===csv)observed.add(fd);return fd};
 try{
  assert.throws(()=>checkBundle(d),{code:'IntegrityMismatch'});
  assert.ok(observed.size>0,'real data files were opened');
  for(const fd of observed)assert.throws(()=>fs.fstatSync(fd),{code:'EBADF'},'failed check must release its open files');
 }finally{
  fs.openSync=open;
  for(const fd of observed){try{fs.closeSync(fd)}catch(e){if(e.code!=='EBADF')throw e}}
 }
});

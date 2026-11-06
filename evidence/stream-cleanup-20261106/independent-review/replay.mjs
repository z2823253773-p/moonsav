import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import assert from 'node:assert/strict';
import { createHash } from 'node:crypto';
import { spawnSync } from 'node:child_process';
import { pathToFileURL } from 'node:url';
const root=process.cwd(), evidence=fs.mkdtempSync(path.join(os.tmpdir(),'moonsav-stream-review-'));
const rewrite=s=>s.replace("from'./api.mjs'",`from'${pathToFileURL(path.join(root,'node/api.mjs'))}'`).replace("from'./io.mjs'",`from'${pathToFileURL(path.join(root,'node/io.mjs'))}'`);
fs.writeFileSync(path.join(evidence,'checker-before.mjs'),rewrite(fs.readFileSync(new URL('./checker-before.txt',import.meta.url),'utf8')));
const before=(await import(pathToFileURL(path.join(evidence,'checker-before.mjs')))).checkBundle;
const after=(await import(pathToFileURL(path.join(root,'node/checker.mjs')))).checkBundle;
function rehash(d,n){const p=path.join(d,'manifest.json'),m=JSON.parse(fs.readFileSync(p)),b=fs.readFileSync(path.join(d,n));m.files[n]={size_bytes:b.length,sha256:createHash('sha256').update(b).digest('hex')};fs.writeFileSync(p,JSON.stringify(m)+'\n')}
const cases=[
 ['good',()=>{}],
 ['wrong header',d=>{const p=path.join(d,'data.csv');fs.writeFileSync(p,'WRONG'+fs.readFileSync(p));rehash(d,'data.csv')}],
 ['canonical syntax',d=>{const p=path.join(d,'data.ndjson'),rows=fs.readFileSync(p,'utf8').split('\n');rows[0]='{';fs.writeFileSync(p,rows.join('\n'));rehash(d,'data.ndjson')}],
 ['canonical no final newline',d=>{const p=path.join(d,'data.ndjson');fs.writeFileSync(p,fs.readFileSync(p).subarray(0,-1));rehash(d,'data.ndjson')}],
 ['CSV too many',d=>{fs.appendFileSync(path.join(d,'data.csv'),'1,x,x\r\n');rehash(d,'data.csv')}],
 ['CSV too few',d=>{const p=path.join(d,'data.csv'),s=fs.readFileSync(p,'utf8');fs.writeFileSync(p,s.slice(0,s.indexOf('\r\n')+2));rehash(d,'data.csv')}],
 ['CSV separator LF',d=>{const p=path.join(d,'data.csv');fs.writeFileSync(p,fs.readFileSync(p,'utf8').replace('\r\n','\n'));rehash(d,'data.csv')}],
 ['CSV unterminated quote',d=>{fs.appendFileSync(path.join(d,'data.csv'),'"');rehash(d,'data.csv')}],
 ['CSV empty',d=>{fs.writeFileSync(path.join(d,'data.csv'),'');rehash(d,'data.csv')}],
 ['NDJSON invalid UTF8',d=>{const p=path.join(d,'data.ndjson'),b=fs.readFileSync(p);b[0]=255;fs.writeFileSync(p,b);rehash(d,'data.ndjson')}],
 ['NDJSON open IO',()=>{}],
];
const outputs=[];
for(const [i,[label,mutate]] of cases.entries()){
 const d=path.join(evidence,'bundles',String(i));
 fs.mkdirSync(path.dirname(d),{recursive:true});
 const exported=spawnSync(process.execPath,['bin/moonsav.mjs','export','fixtures/synthetic/survey-row.sav','--out',d,'--json'],{encoding:'utf8'});
 assert.equal(exported.status,0,exported.stderr);mutate(d);
 const run=(check)=>{
  const open=fs.openSync,close=fs.closeSync,active=new Map(),opened=[];let canonicalOpens=0,error,result;
  fs.openSync=function(p,...args){if(label==='NDJSON open IO'&&String(p)===path.join(d,'data.ndjson')&&++canonicalOpens===2)throw Object.assign(new Error('review injected EIO'),{code:'EIO'});const fd=open.call(this,p,...args);if(['data.csv','data.ndjson'].includes(path.basename(String(p)))){active.set(fd,String(p));opened.push({fd,file:path.basename(String(p))})}return fd};
  fs.closeSync=function(fd){const r=close.call(this,fd);active.delete(fd);return r};
  try{result=check(d)}catch(e){error={code:e.code,message:e.message}}finally{fs.openSync=open;fs.closeSync=close}
  const leaked=[...active.entries()].map(([fd,p])=>({fd,file:path.basename(p)}));
  for(const [fd]of active)close(fd);
  return {error,result:result&&{status:result.status,actual_rows:result.actual_rows},opened,leaked};
 };
 const a=run(before),b=run(after);assert.deepEqual(b.error,a.error,`${label}: original error changed`);assert.deepEqual(b.result,a.result,`${label}: successful result changed`);assert.equal(b.leaked.length,0,`${label}: patched checker leaked`);outputs.push({label,before:a,after:b});
}
fs.writeFileSync(path.join(evidence,'experiments.json'),JSON.stringify(outputs,null,2)+'\n');
console.log(JSON.stringify(outputs.map(x=>({label:x.label,error:x.after.error?.code??null,beforeLeaks:x.before.leaked.length,afterLeaks:x.after.leaked.length})),null,2));

console.error('Evidence directory: '+evidence);

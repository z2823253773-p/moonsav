import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import {spawnSync} from 'node:child_process';
const root=process.cwd(),temp=fs.mkdtempSync(path.join(os.tmpdir(),'moonsav-package 中文 '));
const npmCli=[process.env.npm_execpath,path.join(path.dirname(process.execPath),'node_modules/npm/bin/npm-cli.js'),path.resolve(path.dirname(process.execPath),'../lib/node_modules/npm/bin/npm-cli.js')].find(p=>p&&fs.existsSync(p));
assert.ok(npmCli);
const isolated=Object.fromEntries(Object.entries(process.env).filter(([k])=>k.toLowerCase()!=='path'));isolated.PATH='';
function command(args,{cwd=temp,env=isolated}={}){return spawnSync(process.execPath,args,{cwd,env,encoding:'utf8',maxBuffer:4*1024*1024})}
const packed=command([npmCli,'pack','--pack-destination',temp,'--json'],{cwd:root,env:process.env});assert.equal(packed.status,0,packed.stderr);
const archive=path.join(temp,JSON.parse(packed.stdout)[0].filename);
const installed=command([npmCli,'install','--prefix',temp,'--offline','--ignore-scripts','--no-audit','--no-fund','--cache',path.join(temp,'empty-cache'),archive]);assert.equal(installed.status,0,installed.stderr);
const pkg=path.join(temp,'node_modules/moonsav');
function script(name,text){const p=path.join(temp,name);fs.writeFileSync(p,text);return command([p])}
test('installed package root exposes only the stable API and preserves legacy imports',()=>{
 const p=script('consumer.mjs',`import assert from 'node:assert/strict';import fs from 'node:fs';import * as api from 'moonsav';import * as legacy from 'moonsav/node/api.mjs';
 assert.deepEqual(Object.keys(api).sort(),['SavError','inspectSav','readSav']);assert.equal(api.readSav,legacy.readSav);assert.equal(api.SavError,legacy.SavError);
 const bytes=fs.readFileSync(new URL('./node_modules/moonsav/fixtures/synthetic/survey-row.sav',import.meta.url));const d=api.inspectSav(bytes);assert.equal(d.actual_rows,null);assert.equal(d.declared_rows,5);const data=api.readSav(bytes);assert.equal(data.rows.length,5);assert.equal(data.rows[0][1].text,'0012   ');assert.equal(data.rows[2][0].missing,'user');assert.equal(data.rows[3][0].missing,'system');assert.throws(()=>api.readSav(null),e=>e instanceof api.SavError&&e.code==='Usage');
 assert.ok(import.meta.resolve('moonsav/schemas/metadata.schema.json'));assert.ok(import.meta.resolve('moonsav/examples/read_bundle.py'));assert.ok(import.meta.resolve('moonsav/bin/moonsav.mjs'));console.log('passed');`);
 assert.equal(p.status,0,p.stderr);assert.equal(p.stdout.trim(),'passed');
});
test('fixed Node24 CommonJS can load the same synchronous package API',()=>{
 const p=script('consumer.cjs',`const assert=require('node:assert/strict'),api=require('moonsav'),legacy=require('moonsav/node/api.mjs');assert.deepEqual(Object.keys(api).sort(),['SavError','inspectSav','readSav']);assert.equal(api.inspectSav,legacy.inspectSav);assert.equal(require('moonsav/schemas/metadata.schema').type,'object');assert.equal(typeof require('moonsav/lib/moonsav').run,'function');console.log('passed');`);assert.equal(p.status,0,p.stderr);assert.equal(p.stdout.trim(),'passed');
});
test('installed declarations support strict NodeNext narrowing and reject wrong calls',()=>{
 fs.copyFileSync(path.join(root,'tests/types/consumer.mts'),path.join(temp,'consumer.mts'));
 const p=command([path.join(root,'node_modules/typescript/bin/tsc'),'--strict','--noEmit','--module','NodeNext','--moduleResolution','NodeNext','--target','ES2022','--lib','es2022','--exactOptionalPropertyTypes','--noUncheckedIndexedAccess','consumer.mts']);assert.equal(p.status,0,p.stdout+p.stderr);
});
test('installed Node example reports real missing counts without individual values',()=>{
 const example=path.join(pkg,'examples/read_sav.mjs'),p=command([example]);assert.equal(p.status,0,p.stderr);const r=JSON.parse(p.stdout);assert.equal(r.actual_rows,5);assert.equal(r.logical_variables,3);assert.deepEqual(r.columns.map(c=>c.counts),[[3,1,1],[5,0,0],[5,0,0]]);assert.deepEqual(r.columns.map(c=>c.name),['score','subject_code','note']);assert.equal(p.stderr,'');
 const source=path.join(temp,'问卷 example.sav');fs.copyFileSync(path.join(pkg,'fixtures/synthetic/survey-row.sav'),source);const explicit=command([example,source]);assert.equal(explicit.status,0,explicit.stderr);assert.deepEqual(JSON.parse(explicit.stdout),r);
 const bad=command([example,path.join(temp,'absent.sav')]);assert.notEqual(bad.status,0);assert.equal(bad.stdout,'');assert.match(bad.stderr,/ENOENT/);
});

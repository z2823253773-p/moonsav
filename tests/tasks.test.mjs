import test from'node:test';import assert from'node:assert/strict';import fs from'node:fs';import os from'node:os';import path from'node:path';import{spawnSync}from'node:child_process';
const cli=(args,json=true)=>spawnSync(process.execPath,['bin/moonsav.mjs',...args,...(json?['--json']:[])],{encoding:'utf8'}),tmp=fs.mkdtempSync(path.join(os.tmpdir(),'moonsav-tasks-'));
test('U2 human summaries truncate explicitly, JSON and exact-variable query remain complete',()=>{const human=cli(['inspect','fixtures/synthetic/wide.sav'],false);assert.equal(human.status,0);assert.match(human.stdout,/Variables showing 20 \/ total 25/);assert.match(human.stdout,/Value labels showing 10 \/ total 12/);assert.match(human.stdout,/actual rows not scanned/);const full=cli(['inspect','fixtures/synthetic/wide.sav']),d=JSON.parse(full.stdout);assert.equal(d.dictionary.variables.length,25);assert.equal(d.dictionary.variables[0].value_labels.length,12);assert.equal(d.actual_rows,null);const v=JSON.parse(cli(['inspect','fixtures/synthetic/wide.sav','--variable','V24']).stdout);assert.equal(v.variable.name,'V24');assert.equal(cli(['inspect','fixtures/synthetic/wide.sav','--variable','typo']).status,2)});
test('JSON success, warning, strict rejection and malformed input obey channels and exits',()=>{for(const args of[['validate','fixtures/synthetic/survey-row.sav'],['validate','fixtures/synthetic/warning.sav']]){const r=cli(args);assert.equal(r.status,0);assert.equal(r.stderr,'');assert.equal(r.stdout.trim().split('\n').length,1)}const w=cli(['validate','fixtures/synthetic/warning.sav','--fail-on-warning']);assert.equal(w.status,7);assert.equal(w.stdout,'');assert.equal(w.stderr.trim().split('\n').length,1);assert.equal(JSON.parse(w.stderr).error.code,'WarningRejected');for(const args of[[],['validate','fixtures/synthetic/survey-row.sav','--max-rows','0'],['inspect','fixtures/synthetic/survey-row.sav','--format','csv']])assert.equal(cli(args).status,2);assert.equal(cli(['validate','/nonexistent/moonsav-input.sav']).status,3)});
test('strict export rejects warnings before creating any output directory',()=>{const out=path.join(tmp,'strict');const r=cli(['export','fixtures/synthetic/warning.sav','--out',out,'--fail-on-warning']);assert.equal(r.status,7);assert.equal(fs.existsSync(out),false)});
test('U3 schema mismatch rejects, extras warn and strict checker refuses warnings',()=>{const out=path.join(tmp,'handoff');assert.equal(cli(['export','fixtures/synthetic/survey-row.sav','--out',out]).status,0);fs.writeFileSync(path.join(out,'notes.txt'),'unverified');const r=cli(['check-bundle',out]);assert.equal(r.status,0);assert.ok(JSON.parse(r.stdout).warnings.some(w=>w.warning_code==='UnverifiedExtraFile'));assert.equal(cli(['check-bundle',out,'--fail-on-warning']).status,7);const p=path.join(out,'manifest.json'),m=JSON.parse(fs.readFileSync(p));m.schema_version='moonsav.bundle/2';fs.writeFileSync(p,JSON.stringify(m));const b=cli(['check-bundle',out]);assert.equal(b.status,5);assert.equal(JSON.parse(b.stderr).error.code,'UnsupportedSchema')});
test('version reports the actual build compiler instead of a historical toolchain constant',()=>{const r=cli(['--version'],false);assert.equal(r.status,0);const v=JSON.parse(r.stdout),b=JSON.parse(fs.readFileSync('lib/build.json','utf8'));assert.equal(v.moon,b.moon);assert.equal(v.moonc,b.moonc)});

// GNU SAV format codes; literal expected categories are independent of product logic.
const formats=[
 [5,'F',12,2,false],[20,'DATE',11,0,true],[21,'TIME',12,2,true],
 [22,'DATETIME',24,2,true],[23,'ADATE',10,0,true],[24,'JDATE',7,0,true],
 [25,'DTIME',16,2,true],[26,'WKDAY',9,0,true],[27,'MONTH',9,0,true],
 [28,'MOYR',8,0,true],[29,'QYR',8,0,true],[30,'WKYR',10,0,true],
 [31,'PCT',12,2,false],[32,'DOT',12,2,false],[33,'CCA',12,2,false],
 [34,'CCB',12,2,false],[35,'CCC',12,2,false],[36,'CCD',12,2,false],
 [37,'CCE',12,2,false],[38,'EDATE',10,0,true],[39,'SDATE',10,0,true],
 [40,'MTIME',12,2,true],[41,'YMDHMS',24,2,true]
];
for(const [code,name,width,decimals,warn]of formats)test(`GNU ${name} warning and strict mode preserve raw numeric data`,async()=>{
 const source=path.join(tmp,'format-'+name+'.sav'),out=path.join(tmp,'format-'+name),strictOut=out+'-strict';
 const bytes=fs.readFileSync('fixtures/synthetic/survey-none.sav'),raw=(code<<16)|(width<<8)|decimals;
 assert.equal(bytes.readInt32LE(176),2);bytes.writeInt32LE(raw,192);bytes.writeInt32LE(raw,196);fs.writeFileSync(source,bytes);
 const inspected=cli(['inspect',source]);assert.equal(inspected.status,0,inspected.stderr);
 const dictionary=JSON.parse(inspected.stdout).dictionary;
 assert.equal(dictionary.warnings.filter(w=>w.warning_code==='RawDateFormat').length,warn?1:0);
 assert.equal(dictionary.variables[0].print_format.raw,raw);assert.equal(dictionary.variables[0].write_format.raw,raw);
 const {readSav}=await import('../node/api.mjs');assert.deepEqual(readSav(bytes).rows,readSav(fs.readFileSync('fixtures/synthetic/survey-none.sav')).rows);
 assert.equal(cli(['validate',source]).status,0);
 const strict=cli(['validate',source,'--fail-on-warning']);assert.equal(strict.status,warn?7:0,strict.stderr);
 if(warn)assert.equal(JSON.parse(strict.stderr).error.code,'WarningRejected');
 assert.equal(cli(['export',source,'--out',out]).status,0);
 const checked=cli(['check-bundle',out]);assert.equal(checked.status,0,checked.stderr);
 assert.equal(JSON.parse(checked.stdout).warnings.filter(w=>w.warning_code==='RawDateFormat').length,warn?1:0);
 assert.equal(cli(['check-bundle',out,'--fail-on-warning']).status,warn?7:0);
 const exported=cli(['export',source,'--out',strictOut,'--fail-on-warning']);assert.equal(exported.status,warn?7:0,exported.stderr);assert.equal(fs.existsSync(strictOut),!warn);
 if(!warn)assert.equal(cli(['check-bundle',strictOut,'--fail-on-warning']).status,0);
});
for(const [print,write]of[[5,40],[41,5],[40,41]])test(`date warning uses print ${print} and write ${write} once per variable`,()=>{
 const bytes=fs.readFileSync('fixtures/synthetic/survey-none.sav'),source=path.join(tmp,`mixed-format-${print}-${write}.sav`);
 bytes.writeInt32LE(print<<16|24<<8,192);bytes.writeInt32LE(write<<16|24<<8,196);fs.writeFileSync(source,bytes);
 const r=cli(['inspect',source]);assert.equal(r.status,0);const d=JSON.parse(r.stdout).dictionary;assert.equal(d.warnings.filter(w=>w.warning_code==='RawDateFormat').length,1);
 assert.equal(d.variables[0].print_format.code,print);assert.equal(d.variables[0].write_format.code,write);assert.equal(cli(['validate',source,'--fail-on-warning']).status,7);
});

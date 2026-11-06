import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import {spawnSync} from 'node:child_process';
import {createHash} from 'node:crypto';
import {readSav,inspectSav} from '../../node/api.mjs';
const base=path.resolve('.dev/date-warning-review-20261106');
const src=fs.readFileSync('.dev/sources/pspp-2.0.1/src/data/format.def','utf8');
const expected=new Set([...src.matchAll(/FMT\s*\(\s*\w+\s*,\s*\w+\s*,\s*-?\d+\s*,\s*\d+\s*,\s*(\d+)\s*,\s*FMT_CAT_(?:DATE|TIME|DATE_COMPONENT)\s*\)/g)].map(m=>+m[1]));
assert.equal(expected.size,15);
const original=fs.readFileSync('fixtures/synthetic/survey-none.sav');
const fixture=Buffer.from(original),dict=inspectSav(fixture);
const dataOffset=fixture.length-dict.declared_rows*dict.physical_slots*8;
assert.equal(fixture.readInt32LE(dataOffset-8),999);assert.equal(fixture.readInt32LE(dataOffset-4),0);
fixture.writeBigUInt64LE(0x8000000000000000n,dataOffset);
const unchangedRows=readSav(fixture).rows;
assert.equal(unchangedRows[0][0].ieee754_hex,'8000000000000000');
const summary={official_codes:[...expected].sort((a,b)=>a-b),numeric_variants:0,string_variants:0,mixed_variants:0,cli_cases:[],inherited_warning:null};
function count(d){return d.warnings.filter(w=>w.warning_code==='RawDateFormat').length}
for(const field of ['print','write'])for(let code=0;code<256;code++){
 const b=Buffer.from(fixture);b.writeInt32LE(code<<16|12<<8|2,field==='print'?192:196);
 const actual=readSav(b);assert.equal(count(actual.dictionary),expected.has(code)?1:0,`${field} ${code}`);
 assert.deepEqual(actual.rows,unchangedRows);summary.numeric_variants++;
}
for(const [p,w]of [[20,41],[31,40],[41,37],[31,37]]){
 const b=Buffer.from(fixture);b.writeInt32LE(p<<16|24<<8,192);b.writeInt32LE(w<<16|24<<8,196);
 assert.equal(count(inspectSav(b)),expected.has(p)||expected.has(w)?1:0);summary.mixed_variants++;
}
for(const code of expected){
 const b=Buffer.from(fixture),offset=dict.variables[1].source_offset;
 b.writeInt32LE(code<<16|12<<8,offset+16);b.writeInt32LE(code<<16|12<<8,offset+20);
 assert.equal(count(inspectSav(b)),0);assert.deepEqual(readSav(b).rows,unchangedRows);summary.string_variants++;
}
function cli(args){const r=spawnSync(process.execPath,['bin/moonsav.mjs',...args,'--json'],{encoding:'utf8'});return {status:r.status,stdout:r.stdout,stderr:r.stderr}}
for(const [p,w,warn]of [[31,37,false],[5,40,true],[41,5,true],[20,41,true]]){
 const b=Buffer.from(fixture),name=`p${p}-w${w}`,file=path.join(base,name+'.sav'),out=path.join(base,name+'-bundle'),strictOut=path.join(base,name+'-strict');
 b.writeInt32LE(p<<16|24<<8,192);b.writeInt32LE(w<<16|24<<8,196);fs.writeFileSync(file,b);
 for(const command of ['inspect','validate']){const r=cli([command,file,'--fail-on-warning']);assert.equal(r.status,warn?7:0);if(warn){assert.equal(r.stdout,'');assert.equal(JSON.parse(r.stderr).error.code,'WarningRejected')}}
 assert.equal(cli(['export',file,'--out',out]).status,0);
 assert.equal(cli(['check-bundle',out,'--fail-on-warning']).status,warn?7:0);
 assert.equal(cli(['export',file,'--out',strictOut,'--fail-on-warning']).status,warn?7:0);assert.equal(fs.existsSync(strictOut),!warn);
 summary.cli_cases.push({p,w,warn,passed:true});
}
const out=path.join(base,'p31-w37-bundle'),mp=path.join(out,'metadata.json'),metadata=JSON.parse(fs.readFileSync(mp));
assert.ok(Array.isArray(metadata.warnings));
metadata.warnings.push({warning_code:'RawDateFormat',scope:'variable:0',suggested_action:'historical false positive retained for review'});
fs.writeFileSync(mp,JSON.stringify(metadata)+'\n');const manifestPath=path.join(out,'manifest.json'),manifest=JSON.parse(fs.readFileSync(manifestPath)),mb=fs.readFileSync(mp);
manifest.files['metadata.json']={size_bytes:mb.length,sha256:createHash('sha256').update(mb).digest('hex')};fs.writeFileSync(manifestPath,JSON.stringify(manifest)+'\n');
const inherited=cli(['check-bundle',out]);assert.equal(inherited.status,0,inherited.stderr);assert.equal(JSON.parse(inherited.stdout).warnings.filter(w=>w.warning_code==='RawDateFormat').length,1);assert.equal(cli(['check-bundle',out,'--fail-on-warning']).status,7);
summary.inherited_warning={passed:true,strict_exit:7};
summary.build=JSON.parse(fs.readFileSync('lib/build.json'));fs.writeFileSync(path.join(base,'results.json'),JSON.stringify(summary,null,2)+'\n');console.log(JSON.stringify(summary,null,2));

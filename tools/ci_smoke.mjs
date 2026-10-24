// Cross-platform first-use and error/path checks against the actual npm archive.
import fs from'node:fs';import os from'node:os';import path from'node:path';import{spawnSync}from'node:child_process';import assert from'node:assert/strict';
const node=process.execPath,root=process.cwd(),temp=fs.mkdtempSync(path.join(os.tmpdir(),'moonsav-ci 中文 '));
function run(args,cwd=root){const r=spawnSync(node,args,{cwd,encoding:'utf8'});if(r.status)throw Error(JSON.stringify({args,status:r.status,stderr:r.stderr}));return r.stdout}
// npm.cmd through a shell loses argument boundaries for Unicode/space paths.
const npmCli=[process.env.npm_execpath,path.join(path.dirname(node),'node_modules/npm/bin/npm-cli.js'),path.resolve(path.dirname(node),'../lib/node_modules/npm/bin/npm-cli.js')].find(p=>p&&fs.existsSync(p));
assert.ok(npmCli,'npm JavaScript CLI is required for this development check');
const packed=spawnSync(node,[npmCli,'pack','--pack-destination',temp,'--json'],{encoding:'utf8'});assert.equal(packed.status,0,packed.stderr);const archive=path.join(temp,JSON.parse(packed.stdout)[0].filename);
const install=spawnSync(node,[npmCli,'install','--prefix',temp,'--offline','--ignore-scripts','--no-audit','--no-fund',archive],{encoding:'utf8'});assert.equal(install.status,0,install.stderr);
const pkg=path.join(temp,'node_modules','moonsav'),cli=path.join(pkg,'bin','moonsav.mjs'),source=path.join(pkg,'fixtures','synthetic','survey-row.sav'),bundle=path.join(temp,'输出 bundle');
run([cli,'--version']);assert.equal(JSON.parse(run([cli,'inspect',source,'--json'])).actual_rows,null);assert.equal(JSON.parse(run([cli,'validate',source,'--json'])).actual_rows,5);run([cli,'export',source,'--out',bundle,'--json']);assert.equal(JSON.parse(run([cli,'check-bundle',bundle,'--json'])).actual_rows,5);
const exists=spawnSync(node,[cli,'export',source,'--out',bundle,'--json'],{encoding:'utf8'});assert.equal(exists.status,3);assert.equal(JSON.parse(exists.stderr).error.code,'OutputExists');const bad=path.join(temp,'bad.sav');fs.writeFileSync(bad,'$FL3');const rejected=spawnSync(node,[cli,'validate',bad,'--json'],{encoding:'utf8'});assert.equal(rejected.status,5);assert.equal(JSON.parse(rejected.stderr).error.code,'UnsupportedCompression');
console.log(JSON.stringify({status:'passed',rows:5,platform:process.platform,node:process.version,path_unicode_and_spaces:true,archive_install:'offline'}));

import {spawnSync,execFileSync} from 'node:child_process';
import {mkdirSync,copyFileSync,readFileSync,writeFileSync,readdirSync} from 'node:fs';
import {createHash}from'node:crypto';import path from'node:path';
const version=execFileSync('moon',['version','--all'],{encoding:'utf8'});
const moon=version.match(/^moon (\S+)/m)?.[1],moonc=version.match(/^moonc (\S+)/m)?.[1];
const toolchains=JSON.parse(readFileSync('toolchain.json','utf8')).supported_builds;
if(!toolchains.some(t=>t.moon===moon&&t.moonc===moonc))throw new Error('Use an explicitly fixed toolchain pair in toolchain.json; do not silently upgrade');
if(process.version!=='v24.15.0'||process.versions.icu!=='78.2')throw new Error('Build requires Node24.15.0 / ICU78.2');
const r=spawnSync('moon',['build','--target','js','--release'],{stdio:'inherit'});
if(r.status!==0)process.exit(r.status??1);
mkdirSync('lib',{recursive:true});copyFileSync('_build/js/release/build/bridge/bridge.js','lib/moonsav.js');
const hash=createHash('sha256');function scan(dir){for(const d of readdirSync(dir,{withFileTypes:true}).sort((a,b)=>a.name.localeCompare(b.name))){const p=path.join(dir,d.name);if(d.isDirectory())scan(p);else if(/\.(mbt|mbti|mjs|json)$/.test(p)||d.name==='moon.pkg'){hash.update(p+'\0');hash.update(readFileSync(p));}}}scan('src');scan('node');hash.update(readFileSync('moon.mod'));hash.update(readFileSync('toolchain.json'));
let sha='unversioned',dirty=true;try{sha=execFileSync('git',['rev-parse','HEAD'],{encoding:'utf8'}).trim();dirty=!!execFileSync('git',['status','--porcelain'],{encoding:'utf8'}).trim()}catch{}
writeFileSync('lib/build.json',JSON.stringify({version:'0.1.0',git_sha:sha,dirty,source_tree_sha256:hash.digest('hex'),moon,moonc,node:process.version,icu:process.versions.icu})+'\n');

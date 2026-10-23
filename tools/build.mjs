import {spawnSync} from 'node:child_process';
import {mkdirSync,copyFileSync} from 'node:fs';
const r=spawnSync('moon',['build','--target','js','--release'],{stdio:'inherit'});
if(r.status!==0)process.exit(r.status??1);
mkdirSync('lib',{recursive:true});
copyFileSync('_build/js/release/build/bridge/bridge.js','lib/moonsav.js');

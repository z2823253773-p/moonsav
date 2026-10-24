// Test process only; excluded from npm package. Faults exercise real fs calls.
import fs from'node:fs';import path from'node:path';
const stage=process.env.MOONSAV_TEST_STAGE,target=process.env.MOONSAV_TEST_TARGET,source=process.env.MOONSAV_TEST_INPUT;const names=new Map();
const open=fs.openSync;fs.openSync=function(p,...a){const fd=open.call(this,p,...a);names.set(fd,String(p));return fd};
const kill=()=>process.kill(process.pid,'SIGKILL');
const mkdir=fs.mkdirSync;fs.mkdirSync=function(p,...a){const r=mkdir.call(this,p,...a);if(stage==='after-dir'&&String(p)===target)kill();return r};
const filewrite=fs.writeFileSync;fs.writeFileSync=function(p,...a){const r=filewrite.call(this,p,...a);if(stage==='after-marker'&&String(p)===path.join(target,'INCOMPLETE'))kill();return r};
const write=fs.writeSync;fs.writeSync=function(fd,...a){if(stage==='disk-full'&&names.get(fd)?.startsWith(target+path.sep)){const e=new Error('Simulated disk full');e.code='ENOSPC';throw e}const r=write.call(this,fd,...a);if(stage==='after-data'&&names.get(fd)===path.join(target,'data.ndjson'))kill();return r};
const close=fs.closeSync;fs.closeSync=function(fd){const n=names.get(fd),r=close.call(this,fd);if(stage==='after-metadata'&&n===path.join(target,'metadata.json')||stage==='after-manifest'&&n===path.join(target,'manifest.json'))kill();return r};
const unlink=fs.unlinkSync;fs.unlinkSync=function(p){const r=unlink.call(this,p);if(stage==='after-commit'&&String(p)===path.join(target,'INCOMPLETE'))kill();return r};
const read=fs.readSync;let changed=false;fs.readSync=function(fd,...a){const r=read.call(this,fd,...a);if(stage==='input-change'&&!changed&&names.get(fd)===source){changed=true;fs.appendFileSync(source,Buffer.of(0))}return r};
if(stage==='fail-report')process.stdout.write=function(){const e=new Error('Simulated report write failure');e.code='EPIPE';throw e};

from pathlib import Path
import os,sys,json,subprocess,shutil,hashlib,zipfile,platform
ROOT=Path.cwd(); OUT=ROOT/'.dev/node-integration-review/exact-artifacts'; DIST=ROOT/'.dev/integration-clean/dist'; records=[]
EXPECTED={'moonsav-0.1.0.tgz':('9366c3d597d5c4b846d0caa6c3741a62186428187b0378b0f59c7b89d5b33b8e',313794),'moonsav-source-0.1.0.zip':('f92ef14cd516f171cd8680e2a2357258869648c2444fe96f7daccbb98c2a4aa5',76185)}
def run(args,cwd,env,label):
 r=subprocess.run([str(x)for x in args],cwd=cwd,env=env,capture_output=True,text=True,timeout=150)
 (OUT/(label+'.stdout.log')).write_text(r.stdout);(OUT/(label+'.stderr.log')).write_text(r.stderr)
 records.append({'label':label,'command':[str(x)for x in args],'cwd':str(cwd),'environment':{k:env.get(k)for k in ['PATH','MOON_HOME']},'exit_code':r.returncode})
 (OUT/'commands.json').write_text(json.dumps(records,indent=2)+'\n')
 if r.returncode:raise RuntimeError(label+' exit '+str(r.returncode))
 return r.stdout
artifacts={}
for name,(sha,size)in EXPECTED.items():
 p=DIST/name;artifacts[name]={'sha256':hashlib.sha256(p.read_bytes()).hexdigest(),'size_bytes':p.stat().st_size};assert artifacts[name]=={'sha256':sha,'size_bytes':size}
(OUT/'archive-hashes.json').write_text(json.dumps(artifacts,indent=2)+'\n')
consumer=OUT/'offline consumer 中文';consumer.mkdir();(consumer/'package.json').write_text('{"name":"exact-moonsav-consumer","private":true}\n');only=OUT/'only-node';only.mkdir();node=Path(shutil.which('node')).resolve();(only/'node').symlink_to(node);env={**os.environ,'PATH':str(only)};env.pop('MOON_HOME',None)
npm=Path(shutil.which('npm')).resolve();run([node,npm,'install','--prefix',consumer,'--offline','--ignore-scripts','--no-audit','--no-fund','--cache',consumer/'empty-cache',DIST/'moonsav-0.1.0.tgz'],consumer,env,'offline-install')
pkg=consumer/'node_modules/moonsav';assert not(pkg/'node_modules').exists();sample=pkg/'fixtures/synthetic/survey-row.sav';bin=pkg/'bin/moonsav.mjs'
(consumer/'api.mjs').write_text("""import fs from 'node:fs';import assert from 'node:assert/strict';import * as api from 'moonsav';import * as old from 'moonsav/node/api.mjs';assert.deepEqual(Object.keys(api).sort(),['SavError','inspectSav','readSav']);assert.equal(api.SavError,old.SavError);assert.equal(api.readSav,old.readSav);const b=fs.readFileSync(process.argv[2]),d=api.readSav(b);assert.equal(api.inspectSav(b).actual_rows,null);assert.equal(d.dictionary.actual_rows,null);assert.equal(d.rows.length,5);assert.equal(d.rows[0][1].text,'0012   ');assert.equal(d.rows[2][0].missing,'user');assert.equal(d.rows[3][0].missing,'system');assert.throws(()=>api.readSav(null),e=>e instanceof api.SavError&&e.code==='Usage');console.log('ESM exact archive passed');\n""")
run([node,consumer/'api.mjs',sample],consumer,env,'root-esm')
(consumer/'api.cjs').write_text("""const assert=require('node:assert/strict'),api=require('moonsav'),old=require('moonsav/node/api.mjs');assert.deepEqual(Object.keys(api).sort(),['SavError','inspectSav','readSav']);assert.equal(api.SavError,old.SavError);assert.equal(api.readSav,old.readSav);assert.equal(require('moonsav/schemas/metadata.schema').$id,'https://moonsav.local/schemas/metadata/1');assert.equal(typeof require('moonsav/lib/moonsav').run,'function');console.log('CJS and legacy aliases exact archive passed');\n""")
run([node,consumer/'api.cjs'],consumer,env,'root-cjs-legacy')
shutil.copyfile(ROOT/'tests/types/consumer.mts',consumer/'consumer.mts');run([node,ROOT/'node_modules/typescript/bin/tsc','--strict','--noEmit','--module','NodeNext','--moduleResolution','NodeNext','--target','ES2022','--lib','es2022','--exactOptionalPropertyTypes','--noUncheckedIndexedAccess','consumer.mts'],consumer,env,'installed-types')
def counts(label,args):
 obj=json.loads(run(args,consumer,env,label));assert obj['actual_rows']==5 and obj['logical_variables']==3;assert[c['counts']for c in obj['columns']]==[[3,1,1],[5,0,0],[5,0,0]];return obj
example=pkg/'examples/read_sav.mjs';a=counts('example-default',[node,example]);explicit=consumer/'真实路径 example.sav';shutil.copyfile(sample,explicit);assert counts('example-explicit',[node,example,explicit])==a
version=json.loads(run([node,bin,'--version'],consumer,env,'cli-version'));(OUT/'installed-build-metadata.json').write_text((pkg/'lib/build.json').read_text());build=json.loads((pkg/'lib/build.json').read_text());assert build['git_sha']=='c89ce1aa9fdea8114fe0d8157ee4de043da66583' and build['dirty']==False and build['source_tree_sha256']=='9284c43f6b4fa169869e0a44128c0acc0b44b59aeb7b933fd7551b5a50e96caa'
ins=json.loads(run([node,bin,'inspect',sample,'--json'],consumer,env,'cli-inspect'));assert ins['actual_rows'] is None
val=json.loads(run([node,bin,'validate',sample,'--json'],consumer,env,'cli-validate'));assert val['actual_rows']==5
bundle=consumer/'bundle 中文';export=json.loads(run([node,bin,'export',sample,'--out',bundle,'--json'],consumer,env,'cli-export'));assert export['actual_rows']==5
check=json.loads(run([node,bin,'check-bundle',bundle,'--json'],consumer,env,'cli-check'));assert check['actual_rows']==5
run([sys.executable,pkg/'examples/read_bundle.py',bundle],consumer,env,'python-consumer')
node_result={'status':'passed','artifacts':artifacts,'platform':platform.platform(),'node':str(node),'runtime_path':str(only),'typescript':'host dev verifier only; resolves real installed declarations','runtime_dependencies':[],'build':build,'cli_version':version,'records':len(records)};(OUT/'node-result.json').write_text(json.dumps(node_result,indent=2)+'\n');print(json.dumps(node_result,indent=2))

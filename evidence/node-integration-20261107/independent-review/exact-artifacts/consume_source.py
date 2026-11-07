from pathlib import Path
import os,json,subprocess,zipfile,hashlib,shutil
ROOT=Path.cwd();OUT=ROOT/'.dev/node-integration-review/exact-artifacts';archive=ROOT/'.dev/integration-clean/dist/moonsav-source-0.1.0.zip';records=[]
assert hashlib.sha256(archive.read_bytes()).hexdigest()=='f92ef14cd516f171cd8680e2a2357258869648c2444fe96f7daccbb98c2a4aa5'
pairs={'old':Path('/Users/henryz/.moon/bin'),'new':Path('/Users/henryz/Desktop/比赛/moonsav/.dev/moon-ci/bin')}
for profile,bin in pairs.items():
 source=OUT/('source-'+profile);source.mkdir();env={**os.environ,'PATH':str(bin)+os.pathsep+os.environ['PATH']};env.pop('_',None);env.pop('MOON_HOME',None)
 with zipfile.ZipFile(archive)as z:
  assert all(not p.startswith('/')and'..'not in Path(p).parts for p in z.namelist());z.extractall(source)
 for target,args in [('version',[bin/'moon','version','--all']),('js',[bin/'moon','run','.','--target','js']),('native',[bin/'moon','run','.','--target','native']),('wasm-gc',[bin/'moon','run','.','--target','wasm-gc'])]:
  label=profile+'-'+target;cwd=source/'examples/consumer';r=subprocess.run([str(x)for x in args],cwd=cwd,env=env,capture_output=True,text=True,timeout=150)
  (OUT/(label+'.stdout.log')).write_text(r.stdout);(OUT/(label+'.stderr.log')).write_text(r.stderr)
  records.append({'label':label,'command':[str(x)for x in args],'cwd':str(cwd),'environment':{'PATH':env['PATH'],'MOON_HOME':env.get('MOON_HOME'),'underscore_removed':'_'not in env},'exit_code':r.returncode})
  (OUT/'source-commands.json').write_text(json.dumps(records,indent=2)+'\n')
  assert r.returncode==0,(label,r.stdout,r.stderr)
  if target!='version':assert 'U1: labels, unlabeled valid value, ID text, missing filter, retained rows, Stop and consumer failure passed' in r.stdout
  print(label,'passed',flush=True)
result={'status':'passed','source_archive_sha256':hashlib.sha256(archive.read_bytes()).hexdigest(),'profiles':{p:(OUT/(p+'-version.stdout.log')).read_text()for p in pairs},'consumer_backend_runs':6,'all_exits':0};(OUT/'source-result.json').write_text(json.dumps(result,indent=2)+'\n');print(json.dumps(result,indent=2))

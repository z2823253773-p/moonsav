"""Build, inspect and install actual archives in fresh directories."""
from pathlib import Path
import subprocess,json,sys,os,shutil,tempfile,hashlib,tarfile,zipfile

def run(output):
 root=Path(__file__).resolve().parents[1];out=Path(output).resolve();out.mkdir(parents=True,exist_ok=True);records=[]
 clean_env=dict(os.environ);clean_env.pop('_',None)
 def command(args,cwd=root,env=None):
  r=subprocess.run(args,cwd=cwd,env=clean_env if env is None else env,capture_output=True,text=True,timeout=120);i=len(records);(out/f'{i:02}-stdout.log').write_text(r.stdout);(out/f'{i:02}-stderr.log').write_text(r.stderr);records.append({'command':[str(a)for a in args],'cwd':'<consumer>'if cwd!=root else'.','exit_code':r.returncode});
  if r.returncode:raise RuntimeError(f'Package step {i} failed with exit {r.returncode}')
  return r.stdout
 try:
  command(['node','tools/build.mjs']);(root/'dist').mkdir(exist_ok=True);pack=json.loads(command(['npm','pack','--pack-destination','dist','--json']))[0];archive=root/'dist'/pack['filename'];members=[f['path']for f in pack['files']]
  allowed=['bin/','node/','lib/','fixtures/synthetic/','examples/read_bundle.py','examples/read_sav.mjs','schemas/','docs/CODEC_PROFILES.md','docs/CONTRACTS.md','licenses/','README.md','LICENSE','THIRD_PARTY.md','toolchain.json','package.json']
  if any(not any(n==p or n.startswith(p)for p in allowed)for n in members):raise RuntimeError('Unexpected npm archive file')
  with tarfile.open(archive)as tar:
   for m in tar.getmembers():
    if '..'in Path(m.name).parts or m.issym()or m.islnk():raise RuntimeError('Unsafe npm archive member')
    if m.isfile()and not m.name.endswith('.sav'):
     data=tar.extractfile(m).read()
     if b'/Users/henryz/'in data or b'/tmp/moonsav'in data:raise RuntimeError('Local path leaked into distributable')
  consumer=Path(tempfile.mkdtemp(prefix='moonsav-node-consumer-'));(consumer/'only-node').mkdir();os.symlink(shutil.which('node'),consumer/'only-node/node');env={**clean_env,'PATH':str(consumer/'only-node')};npm_cli=str(Path(shutil.which('npm')).resolve());node=shutil.which('node')
  command([node,npm_cli,'install','--prefix',str(consumer),'--offline','--ignore-scripts','--no-audit','--no-fund','--cache',str(consumer/'npm-cache'),str(archive)],cwd=consumer,env=env)
  bin=consumer/'node_modules/moonsav/bin/moonsav.mjs';sample=consumer/'node_modules/moonsav/fixtures/synthetic/survey-row.sav';bundle=consumer/'first bundle 中文'
  version=json.loads(command([node,str(bin),'--version'],cwd=consumer,env=env));inspect=json.loads(command([node,str(bin),'inspect',str(sample),'--json'],cwd=consumer,env=env));validate=json.loads(command([node,str(bin),'validate',str(sample),'--json'],cwd=consumer,env=env));export=json.loads(command([node,str(bin),'export',str(sample),'--out',str(bundle),'--json'],cwd=consumer,env=env));checked=json.loads(command([node,str(bin),'check-bundle',str(bundle),'--json'],cwd=consumer,env=env));assert inspect['actual_rows']is None and validate['actual_rows']==export['actual_rows']==checked['actual_rows']==5
  command([sys.executable,str(consumer/'node_modules/moonsav/examples/read_bundle.py'),str(bundle)],cwd=consumer)
  api=consumer/'api-consumer.mjs';api.write_text("import {readFileSync} from 'node:fs';import {readSav,inspectSav,SavError} from 'moonsav';const b=readFileSync(process.argv[2]);const d=readSav(b);if(d.rows.length!==5||inspectSav(b).actual_rows!==null||typeof SavError!=='function')throw Error('API consumer failed');console.log(JSON.stringify({rows:d.rows.length}));\n")
  command([node,str(api),str(sample)],cwd=consumer,env=env)
  summary=json.loads(command([node,str(consumer/'node_modules/moonsav/examples/read_sav.mjs')],cwd=consumer,env=env));assert summary['actual_rows']==5 and summary['columns'][0]['counts']==[3,1,1]
  # Standalone schemas and independent standard-library consumer from the installed package.
  import jsonschema
  for n in ['metadata','manifest']:
   schema=json.loads((consumer/f'node_modules/moonsav/schemas/{n}.schema.json').read_text());jsonschema.Draft202012Validator(schema).validate(json.loads((bundle/f'{n}.json').read_text()))
  row_schema=json.loads((consumer/'node_modules/moonsav/schemas/row.schema.json').read_text());validator=jsonschema.Draft202012Validator(row_schema)
  for line in (bundle/'data.ndjson').read_text().splitlines():validator.validate(json.loads(line))
  report_schema=json.loads((consumer/'node_modules/moonsav/schemas/report.schema.json').read_text());rv=jsonschema.Draft202012Validator(report_schema)
  for r in [inspect,validate,export,checked]:rv.validate(r)
  command(['moon','package','--frozen']);z=root/'_build/publish/z2823253773-moonsav-0.1.0.zip';source_archive=root/'dist/moonsav-source-0.1.0.zip';shutil.copy2(z,source_archive)
  source=Path(tempfile.mkdtemp(prefix='moonsav-moon-consumer-'))
  with zipfile.ZipFile(source_archive)as f:
   source_members=f.namelist()
   if any(n.startswith(('/', '.dev/','.cache/','evidence/','_build/'))or'..'in Path(n).parts for n in source_members):raise RuntimeError('Unexpected source archive content')
   f.extractall(source)
  for target in ['js','native','wasm-gc']:command(['moon','run','.','--target',target],cwd=source/'examples/consumer')
  artifacts={p.name:{'sha256':hashlib.sha256(p.read_bytes()).hexdigest(),'size_bytes':p.stat().st_size}for p in[archive,source_archive]}
  result={'status':'supported_pass','records':records,'cli_environment':{'PATH':'<node-only>','moon_on_PATH':False,'python_on_PATH':False,'network':'npm offline; runtime has no network code'},'version':version,'npm_members':members,'source_members':source_members,'artifacts':artifacts,'schema_validation':'metadata manifest every row and all successful report commands; jsonschema '+jsonschema.__version__,'consumer_rows':5}
 except Exception as e:result={'status':'supported_fail','records':records,'error':str(e)}
 (out/'result.json').write_text(json.dumps(result,indent=2,ensure_ascii=False)+'\n');return result
if __name__=='__main__':
 r=run(sys.argv[1]);print(json.dumps({'status':r['status'],'error':r.get('error'),'artifacts':r.get('artifacts')},indent=2));raise SystemExit(r['status']!='supported_pass')

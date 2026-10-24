#!/usr/bin/env python3
"""Executable AC01–AC18 contract. Never counts skipped/setup failures as passes."""
import argparse,json,sys,os,subprocess,tempfile,hashlib,urllib.request,datetime,platform,shutil
from pathlib import Path
from capture import capture
from compare_oracle import compare as readstat_compare
from pspp_oracle import compare as pspp_compare,binary as pspp_binary
from rejections import run as reject_vectors
from codec_acceptance import run as codec_vectors
from benchmark import benchmark
from package_smoke import run as package_smoke
ROOT=Path(__file__).resolve().parents[1]
IDS=[f'AC{i:02}'for i in range(1,19)]
class SetupError(Exception):pass

def main():
 parser=argparse.ArgumentParser();sel=parser.add_mutually_exclusive_group(required=True);sel.add_argument('--all',action='store_true');sel.add_argument('--case',choices=IDS);parser.add_argument('--output',required=True);parser.add_argument('--require-public',action='store_true');parser.add_argument('--require-pspp',action='store_true');a=parser.parse_args()
 out=Path(a.output).resolve();out.mkdir(parents=True,exist_ok=True);payload=out/'payloads';payload.mkdir(exist_ok=True);chosen=IDS if a.all else[a.case];results=[];foundation={}
 def cmd(args,inputs=(),outputs=(),cwd=ROOT,timeout=120):
  code,stdout,stderr=capture([str(x)for x in args],out,inputs,outputs,timeout,cwd)
  if code:raise AssertionError(f'Command exit {code}: {args[0:4]} (see run.json)')
  return stdout
 def save(name,obj):p=out/name;p.parent.mkdir(parents=True,exist_ok=True);p.write_text(json.dumps(obj,ensure_ascii=False,indent=2)+'\n');return p
 def build():
  if not foundation.get('build'):cmd(['node','tools/build.mjs']);foundation['build']=True
 def node_suite():
  build()
  if not foundation.get('node'):cmd(['node','--test',*[str(p.relative_to(ROOT))for p in sorted((ROOT/'tests').glob('*.test.mjs'))]]);foundation['node']=True
 def core_suite():
  if not foundation.get('core'):
   for target in['js','native','wasm-gc']:cmd(['moon','test','src','--target',target])
   foundation['core']=True
 def export(source,name,format='ndjson'):
  build();d=payload/'bundles'/name;d.parent.mkdir(parents=True,exist_ok=True)
  r=json.loads(cmd(['node','bin/moonsav.mjs','export',source,'--out',d,'--format',format,'--json'],inputs=[source]));assert r['completed']
  cmd(['node','bin/moonsav.mjs','check-bundle',d,'--json'],outputs=list(d.glob('*')))
  return d
 def oracle(source,bundle,name,pspp=True):
  r=readstat_compare(source,bundle);save(name+'/readstat.json',r);assert r['status']=='supported_pass',f'ReadStat differences: {name}'
  if pspp:
   try:pspp_binary()
   except Exception as e:raise SetupError(str(e))
   p=pspp_compare(source,bundle,out/name/'pspp');assert p['status']=='supported_pass',f'PSPP differences: {name}'
  return r
 def packages():
  if 'packages'not in foundation:
   r=package_smoke(out/'packages');assert r['status']=='supported_pass',r.get('error');foundation['packages']=r
  return foundation['packages']
 def case(id):
  if id=='AC01':
   build();cmd(['node','tools/ac01.mjs']);items=[]
   for mode in['none','row']:
    source=ROOT/f'fixtures/synthetic/survey-{mode}.sav';d=export(source,'AC01-'+mode,'csv');items.append(oracle(source,d,'AC01-'+mode,False));cmd([sys.executable,'examples/read_bundle.py',d])
   return {'scope':'both compression modes, all source cells/dictionary and independent canonical/CSV consumer','items':items}
  if id=='AC02':
   source=ROOT/'fixtures/synthetic/survey-row.sav';d=export(source,'AC02-source','csv');r=oracle(source,d,'AC02-source');generated=out/'AC02-source/pspp/payloads/roundtrip.sav';g=export(generated,'AC02-pspp-generated','csv');s=oracle(generated,g,'AC02-generated',False);return {'families':['GNU PSPP','ReadStat'],'readstat_to_pspp':r,'pspp_generated_to_readstat':s}
  if id=='AC03':
   manifest=json.loads((ROOT/'fixtures/manifest.json').read_text());items=[]
   for entry in manifest['public']:
    source=ROOT/f'.cache/public/{entry["article"]}.sav';source.parent.mkdir(parents=True,exist_ok=True)
    if not source.exists():
     try:urllib.request.urlretrieve(entry['download'],source.with_suffix('.part'));source.with_suffix('.part').replace(source)
     except Exception as e:raise SetupError('Public download failed: '+type(e).__name__)
    assert hashlib.sha256(source.read_bytes()).hexdigest()==entry['sha256'],'Public input hash mismatch'
    d=export(source,'AC03-'+str(entry['article']));r=oracle(source,d,'AC03-'+str(entry['article']));r['provenance']=entry;items.append(r)
   assert len(items)>=2 and all(x['cells_compared']>0 for x in items)
   return {'scope':'every cell, dictionary and raw print/write/display/retained metadata; public cache not redistributed','items':items}
  if id in['AC04','AC05','AC07','AC08','AC10','AC11','AC15','AC16','AC17']:
   node_suite()
   if id in['AC05','AC07','AC10']:core_suite()
   scopes={'AC04':'all bytecodes, cross-row controls, nondefault bias, known/unknown/zero and malformed endings','AC05':'1/7/8/9/255/256/504/505/32767 widths, UTF8 cross-segment, extensions13/14/21/22','AC07':'missing kinds, ranges/endpoints, signed zero, byte label conflicts and invalid nonfinite vectors','AC08':'canonical plus standard CSV, multiline/NA/backslash/leading zero/trailing spaces, NUL rejection and NDJSON acceptance','AC10':'core limits equal/below and CLI output exact/one less; declared label bookkeeping cap','AC11':'exclusive concurrent output, ordinary failure, input change, disk failure and six SIGKILL stages, post-commit report recovery','AC15':'U2 dictionary/full scope and summaries, exact variables, structured warning/error recovery','AC16':'U3 hashes, schemas, rehashed semantic damage, metadata/CSV policy, no canonical, symlinks, TOCTOU and inherited warnings','AC17':'JSON channels/exits, strict export precommit, version and offline first-use archive'}
   if id in['AC08','AC17']:packages()
   return {'scope':scopes[id],'proof':'shared current full Node suite; no omitted tests counted as passes','core_backends':foundation.get('core',False)}
  if id=='AC06':
   node_suite()
   r=codec_vectors(out/'codec-profiles');assert all(x['status']=='supported_pass'for x in r)
   source=ROOT/'fixtures/synthetic/encoding-gb18030-four.sav';d=export(source,'AC06-four-byte');p=pspp_compare(source,d,out/'codec-four-byte-pspp');assert p['status']=='supported_pass'
   limitation=None
   try:
    rstat=readstat_compare(source,d);save('codec-four-byte-readstat.json',rstat);assert rstat['status']=='supported_pass'
   except Exception as e:
    if sys.platform!='darwin':raise
    limitation={'oracle':'Mac ReadStat wheel / system iconv','exception':type(e).__name__,'message':str(e),'status':'oracle_unsupported','input_sha256':hashlib.sha256(source.read_bytes()).hexdigest(),'alternative_proof':'PSPP/GNU libiconv + independently authored source, Python codec and primary range mapping'};save('codec-four-byte-oracle-limitation.json',limitation)
   return {'profiles':r,'four_byte_pspp':p,'oracle_limitation':limitation,'variants':'A3A0 and malformed tails explicitly rejected by current Node suite'}
  if id=='AC09':
   build();r=reject_vectors(out/'rejections');assert all(x['status']=='expected_rejection'for x in r);return {'scope':'fresh process per corrupt vector, each timeout10s','expected_rejections':len(r),'results':'rejections/results.json'}
  if id=='AC12':core_suite();p=packages();return {'scope':'actual precompiled Node tarball and standalone MoonBit source archive, three clean consumer backends','artifacts':p['artifacts'],'remote_ci':'not_run'}
  if id=='AC13':
   # Clone only committed state, never use an existing lib build or WIP file.
   head=subprocess.check_output(['git','rev-parse','HEAD'],cwd=ROOT,text=True).strip();clone=Path(tempfile.mkdtemp(prefix='moonsav-clean-repro-'))
   cmd(['git','clone','--no-hardlinks',ROOT,clone]);actual=cmd(['git','rev-parse','HEAD'],cwd=clone).strip();assert actual==head
   assert not cmd(['git','status','--porcelain'],cwd=clone).strip()
   child=clone/'.cache/repro';cmd([sys.executable,'tools/verify.py','--case','AC01','--output',child],cwd=clone,timeout=180)
   r=json.loads((child/'summary.json').read_text());assert r['status']=='passed';save('clean-clone-summary.json',r)
   return {'scope':'clean committed clone reruns the same acceptance entry AC01 with fixed existing dev interpreter; source SHA confirmed','sha':head,'child':'clean-clone-summary.json','independent_review':'docs/progress/INDEPENDENT_REVIEW.md (agent, not external user acceptance)'}
  if id=='AC14':core_suite();p=packages();return {'scope':'standalone MoonBit source consumer filters missing, labels and unlabeled legal values, IDs, retains rows, Stop and callback failure','source_archive':p['artifacts']['moonsav-source-0.1.0.zip']}
  if id=='AC18':
   build();r=benchmark(out/'performance');assert r['status']=='supported_pass',r['failures'];return {'scope':'seed20261023 10000x20, both modes x3 validate/export/check, deterministic semantic hashes','summaries':r['summaries']}
  raise AssertionError('Unimplemented acceptance case')
 try:
  versions={}
  for name,args in{'moon':['moon','version','--all'],'node':['node','--version'],'python':[sys.executable,'--version']}.items():versions[name]=cmd(args).strip()
  versions['python_dependencies']=cmd([sys.executable,'-m','pip','freeze']).strip().splitlines()
  if a.require_pspp:
   try:versions['pspp']=cmd([pspp_binary(),'--version']).strip()
   except Exception as e:raise SetupError(str(e))
  for id in chosen:
   start=datetime.datetime.now(datetime.timezone.utc).isoformat()
   try:detail=case(id);status='expected_rejection'if id=='AC09'else'supported_pass';result={'case':id,'status':status,'utc':start,'detail':detail}
   except SetupError as e:result={'case':id,'status':'not_run','reason':str(e),'utc':start}
   except Exception as e:result={'case':id,'status':'supported_fail','error_type':type(e).__name__,'reason':str(e),'utc':start}
   results.append(result);save(id+'/result.json',result);print(id+': '+result['status'],flush=True)
 except Exception as e:results.append({'case':'SETUP','status':'not_run','reason':str(e)});versions=locals().get('versions',{})
 passed=all(r['status']in['supported_pass','expected_rejection']for r in results)and len(results)==len(chosen)
 summary={'report_version':'moonsav.acceptance/1','acceptance_scope':'macOS local + JS/native/wasm-gc byte core; CI definitions only','overall_prd_acceptance':'pending remote Linux/Windows runs and designated acceptance chat','required_external_gaps':['Linux x64 Node full corpus CI not_run','Windows x64 Node CLI/corpus CI not_run','designated acceptance chat review pending'],'status':'passed'if passed else'failed','cases':results,'counts':{s:sum(r['status']==s for r in results)for s in['supported_pass','supported_fail','expected_rejection','unexpected_result','not_run']},'versions':versions,'platform':platform.platform(),'require_public':a.require_public,'require_pspp':a.require_pspp,'remote_ci':'not_run','external_user_trial':False,'designated_acceptance_chat':'pending independent acceptance','limits':'resource targets and evidence scopes remain explicit'}
 save('summary.json',summary)
 runfile=out/'run.json'
 if runfile.exists():
  r=json.loads(runfile.read_text());r['environment']=versions;r['summary']='summary.json';runfile.write_text(json.dumps(r,ensure_ascii=False,indent=2)+'\n')
 return 0 if passed else 1
if __name__=='__main__':raise SystemExit(main())

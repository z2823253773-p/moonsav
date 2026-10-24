import sys,subprocess,time,json,statistics,hashlib,shutil,platform
from pathlib import Path
import pandas as pd,pyreadstat,numpy as np

def benchmark(output):
 root=Path(__file__).resolve().parents[1];out=Path(output);out.mkdir(parents=True,exist_ok=True);cache=root/'.cache/performance';cache.mkdir(parents=True,exist_ok=True)
 rng=np.random.default_rng(20261023);values={}
 for i in range(20):
  if i%2==0:
   a=rng.normal(size=10000);a[::101]=99;a[::257]=np.nan;values[f'n{i}']=a
  else:values[f's{i}']=[f'{k:04d},中'if k%3==0 else f'ID{k:05d}' for k in range(10000)]
 frame=pd.DataFrame(values);records=[];hashes={};failures=[]
 for mode in ['none','row']:
  source=cache/f'perf-{mode}.sav';pyreadstat.write_sav(frame,str(source),row_compress=mode=='row',missing_ranges={n:[99.]for n in values if n.startswith('n')})
  b=bytearray(source.read_bytes());b[109:118]=b'01 JAN 26';b[118:126]=b'00:00:00';source.write_bytes(b)
  for repeat in range(3):
   bundle=cache/f'bundle-{mode}-{repeat}'
   if bundle.exists():shutil.rmtree(bundle)
   jobs=[('validate',['validate',str(source),'--json']),('export',['export',str(source),'--out',str(bundle),'--json']),('check-bundle',['check-bundle',str(bundle),'--json'])]
   for task,args in jobs:
    cmd=['/usr/bin/time','-l','node','bin/moonsav.mjs',*args]if sys.platform=='darwin'else['/usr/bin/time','-v','node','bin/moonsav.mjs',*args]
    start=time.perf_counter();r=subprocess.run(cmd,cwd=root,capture_output=True,text=True,timeout=120);seconds=time.perf_counter()-start
    rss=None
    for line in r.stderr.splitlines():
     if 'maximum resident set size'in line:
      try:rss=int(line.split()[0])
      except ValueError:rss=int(line.rsplit(':',1)[1])*1024
     elif 'Maximum resident set size'in line:rss=int(line.rsplit(':',1)[1])*1024
    records.append({'mode':mode,'repeat':repeat,'task':task,'command':cmd,'exit_code':r.returncode,'seconds':seconds,'peak_rss_bytes':rss,'input_sha256':hashlib.sha256(source.read_bytes()).hexdigest()})
    (out/f'{mode}-{repeat}-{task}-stdout.log').write_text(r.stdout);(out/f'{mode}-{repeat}-{task}-stderr.log').write_text(r.stderr)
    if r.returncode:failures.append({'mode':mode,'task':task,'repeat':repeat,'exit_code':r.returncode})
   semantic={n:hashlib.sha256((bundle/n).read_bytes()).hexdigest()for n in ['data.ndjson','data.csv','metadata.json','codebook.md']if(bundle/n).exists()};hashes[f'{mode}-{repeat}']=semantic
 for mode in ['none','row']:
  if not(hashes[f'{mode}-0']==hashes[f'{mode}-1']==hashes[f'{mode}-2']):failures.append({'mode':mode,'reason':'nondeterministic_semantic_output'})
 summaries=[]
 for mode in ['none','row']:
  for task in ['validate','export','check-bundle']:
   rows=[r for r in records if r['mode']==mode and r['task']==task];median=statistics.median(r['seconds']for r in rows);peak=max((r['peak_rss_bytes']or 0)for r in rows);ok=median<=30 and 0<peak<=536870912 and all(r['exit_code']==0 for r in rows);summaries.append({'mode':mode,'task':task,'median_seconds':median,'peak_rss_bytes':peak,'passed':ok})
   if not ok:failures.append({'mode':mode,'task':task,'reason':'performance_target'})
 result={'reference_machine':platform.platform(),'seed':20261023,'rows':10000,'variables':20,'runs':records,'summaries':summaries,'semantic_hashes':hashes,'failures':failures,'status':'supported_pass'if not failures else'supported_fail'}
 (out/'results.json').write_text(json.dumps(result,indent=2)+'\n');return result
if __name__=='__main__':
 r=benchmark(sys.argv[1]);print(json.dumps({'status':r['status'],'summaries':r['summaries'],'failures':r['failures']},indent=2));raise SystemExit(bool(r['failures']))

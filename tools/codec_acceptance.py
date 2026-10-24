from pathlib import Path
import subprocess,json,sys
from compare_oracle import compare as readstat_compare
from pspp_oracle import compare as pspp_compare

def run(output):
 out=Path(output);out.mkdir(parents=True,exist_ok=True);root=Path(__file__).resolve().parents[1];results=[]
 for enc in ['utf-8','windows-1252','gbk','gb18030']:
  source=root/f'fixtures/synthetic/encoding-{enc}.sav';bundle=out.resolve()/'payloads'/'bundles'/enc
  if not bundle.exists():
   bundle.parent.mkdir(parents=True,exist_ok=True)
   r=subprocess.run(['node','bin/moonsav.mjs','export',str(source),'--out',str(bundle),'--json'],cwd=root,capture_output=True,text=True)
   if r.returncode:results.append({'encoding':enc,'status':'supported_fail','stage':'moonsav_export','exit':r.returncode});continue
  r=readstat_compare(source,bundle);(out/f'{enc}-readstat.json').write_text(json.dumps(r,indent=2)+'\n');p=pspp_compare(source,bundle,out/f'{enc}-pspp');results.append({'encoding':enc,'readstat':r['status'],'pspp':p['status'],'status':'supported_pass'if r['status']==p['status']=='supported_pass'else'supported_fail'})
 (out/'results.json').write_text(json.dumps(results,indent=2)+'\n');return results
if __name__=='__main__':
 r=run(sys.argv[1]);print(json.dumps(r,indent=2));raise SystemExit(any(x['status']!='supported_pass'for x in r))

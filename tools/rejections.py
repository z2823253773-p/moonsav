"""Each malformed vector is a fresh CLI process with a 10 second timeout."""
from pathlib import Path
import subprocess,struct,json,random,tempfile,hashlib
from fixture_writer import sav,extension,I,D

def run(output):
 root=Path(__file__).resolve().parents[1];out=Path(output);out.mkdir(parents=True,exist_ok=True);payloads=out/'payloads';payloads.mkdir(exist_ok=True)
 base=sav([{'name':'X'}],[[1.],[None]],compressed=True)
 def change(b,pos,value,fmt='<i'):
  b=bytearray(b);struct.pack_into(fmt,b,pos,value);return bytes(b)
 cases=[('fl3',b'$FL3',5,'UnsupportedCompression'),('bigendian',change(base,64,0x02000000),5,'UnsupportedLayout'),('other-format',b'SPSS PORT FILE',4,'InvalidMagic'),('unknown-extension',sav([{'name':'X'}],[[1.]],extensions=extension(999,b'x')),5,'UnsupportedExtension'),('nan',sav([{'name':'X'}],[[float('nan')]]),5,'UnsupportedNumeric'),('inf',sav([{'name':'X'}],[[float('inf')]]),5,'UnsupportedNumeric'),('too-many-slots',change(base,68,2147483647),6,'ResourceLimit'),('declared-more-rows',change(base,80,3),4,'CaseCountMismatch'),('declared-less-rows',change(base,80,1),4,'CaseCountMismatch')]
 # Header and every critical structural region truncation, never a valid complete case stream.
 for n in [0,1,3,4,63,64,67,68,71,72,83,91,108,175,176,179,180,199,207,len(base)-1]:cases.append((f'truncate-{n}',base[:n],4,'Truncated'))
 results=[]
 for name,b,expected,code in cases:
  p=payloads/(name+'.sav');p.write_bytes(b)
  try:r=subprocess.run(['node','bin/moonsav.mjs','validate',str(p),'--json'],cwd=root,capture_output=True,text=True,timeout=10);actual=r.returncode;report=json.loads(r.stderr)if r.stderr else{};actual_code=report.get('error',{}).get('code');passed=actual==expected and actual_code==code
  except subprocess.TimeoutExpired:actual=124;actual_code='timeout';passed=False
  results.append({'case':name,'sha256':hashlib.sha256(b).hexdigest(),'size_bytes':len(b),'expected_exit':expected,'actual_exit':actual,'expected_code':code,'actual_code':actual_code,'status':'expected_rejection'if passed else'unexpected_result'})
 (out/'results.json').write_text(json.dumps(results,indent=2)+'\n');return results
if __name__=='__main__':
 r=run(__import__('sys').argv[1]);print(json.dumps({'cases':len(r),'expected_rejection':sum(x['status']=='expected_rejection'for x in r),'unexpected_result':[x for x in r if x['status']=='unexpected_result']},indent=2));raise SystemExit(any(x['status']=='unexpected_result'for x in r))

"""GNU PSPP independent executable oracle. Only aggregate results are saved."""
import csv,json,subprocess,struct,hashlib,os
from pathlib import Path
import pyreadstat

def binary():
 root=Path(__file__).resolve().parents[1]
 p=os.environ.get('MOONSAV_PSPP')
 if p:return p
 for p in [root/'.dev/pspp/bin/pspp',root/'.dev/sources/pspp-2.0.1/src/ui/terminal/pspp']:
  if p.exists():return str(p)
 import shutil
 p=shutil.which('pspp')
 if not p:raise RuntimeError('PSPP executable unavailable; use tools/setup-pspp.sh or set MOONSAV_PSPP')
 return p

def compare(source,bundle,output):
 source=Path(source).resolve();bundle=Path(bundle).resolve();out=Path(output).resolve();out.mkdir(parents=True,exist_ok=True);payloads=out/'payloads';payloads.mkdir(exist_ok=True)
 _,ref=pyreadstat.read_sav(str(source),metadataonly=True,user_missing=True,disable_datetime_conversion=True)
 metadata=json.loads((bundle/'metadata.json').read_text());numeric=[n for n,t in ref.readstat_variable_types.items()if t!='string'];count=len(ref.column_names)
 # Avoid date display conversion and independently expose missing predicates.
 aux=[];commands=["SET DECIMAL=DOT.",f"GET FILE='{str(source).replace(chr(39),chr(39)*2)}'."]
 commands.append(f"SAVE OUTFILE='{payloads/'roundtrip.sav'}' /COMPRESSED.")
 if numeric:commands.append('FORMATS '+' '.join(numeric)+' (E40.16).')
 for i,name in enumerate(ref.column_names):
  if name in numeric:
   commands.append(f'COMPUTE ZZMSV{i}=MISSING({name}).');aux.append(f'ZZMSV{i}')
   commands.append(f'COMPUTE ZZSYS{i}=SYSMIS({name}).');aux.append(f'ZZSYS{i}')
 csvpath=payloads/'oracle.csv';commands.append(f"SAVE TRANSLATE OUTFILE='{csvpath}' /TYPE=CSV /REPLACE /FIELDNAMES /CELLS=VALUES /MISSING=IGNORE.")
 syntax=payloads/'oracle.sps';syntax.write_text('\n'.join(commands)+'\n')
 proc=subprocess.run([binary(),'--batch',str(syntax)],capture_output=True,text=True,timeout=90)
 (out/'stdout.log').write_text(proc.stdout);(out/'stderr.log').write_text(proc.stderr)
 differences=[];n=0;compared=0
 if proc.returncode==0:
  _,roundtrip=pyreadstat.read_sav(str(payloads/'roundtrip.sav'),metadataonly=True,user_missing=True,disable_datetime_conversion=True)
  for i,v in enumerate(metadata['variables']):
   if v['type']=='string':
    actual=next((x for n,x in roundtrip.missing_ranges.items()if n.casefold()==v['name'].casefold()),[])
    expected=[x['text'].rstrip(' ')for x in v['user_missing']['values']]
    if len(actual)!=len(expected)or any(not any(a['lo']==a['hi']==x for a in actual)for x in expected):differences.append({'field':'string_missing_definition','variable_index':i})
  with csvpath.open(newline='',encoding='utf-8')as f,(bundle/'data.ndjson').open()as canonical:
   rows=csv.DictReader(f)
   for raw,line in zip(rows,canonical,strict=True):
    row=json.loads(line)
    for i,(v,c)in enumerate(zip(metadata['variables'],row['cells'])):
     actual=next(value for key,value in raw.items()if key.casefold()==v['name'].casefold());system=v['type']=='numeric'and float(raw[f'ZZSYS{i}'])==1
     missing=('system'if system else'user'if float(raw[f'ZZMSV{i}'])==1 else'present')if v['type']=='numeric'else c['missing']
     if missing!=c['missing']:differences.append({'field':'missing_kind','variable_index':i,'row':n})
     if v['type']=='string':ok=actual==c['text'].rstrip(' ')
     elif system:ok=c['decimal']is None
     else:ok=struct.pack('>d',float(actual)).hex()==c['ieee754_hex']
     if not ok:differences.append({'field':'value','variable_index':i,'row':n})
     compared+=1
    n+=1
  if n!=metadata['actual_rows']:differences.append({'field':'actual_rows'})
 result={'family':'GNU PSPP','version':subprocess.run([binary(),'--version'],capture_output=True,text=True).stdout.splitlines()[0],'command':[binary(),'--batch','<generated-syntax>'],'exit_code':proc.returncode,'input_sha256':hashlib.sha256(source.read_bytes()).hexdigest(),'actual_rows':n,'logical_variables':count,'cells_and_missing_predicates_compared':compared,'differences':differences[:50],'difference_count':len(differences),'scope':'all values and numeric missing predicates; string missing definitions verified separately through PSPP roundtrip, numeric formats neutralized; no cell values in report','status':'supported_pass'if proc.returncode==0 and not differences else'supported_fail'}
 (out/'result.json').write_text(json.dumps(result,indent=2)+'\n');return result
if __name__=='__main__':
 import sys
 r=compare(*sys.argv[1:]);print(json.dumps(r,indent=2));raise SystemExit(r['status']!='supported_pass')

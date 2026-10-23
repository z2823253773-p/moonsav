"""Read canonical values with Python's standard library; no NA/type inference.
First run: moonsav check-bundle BUNDLE. This reader independently cross-checks CSV.
"""
import csv,json,sys,struct,base64
from pathlib import Path

def read_bundle(directory):
 p=Path(directory);m=json.loads((p/'metadata.json').read_text(encoding='utf-8'))
 with (p/'data.ndjson').open(encoding='utf-8') as f:
  csv_file=(p/'data.csv').open(encoding='utf-8',newline='') if (p/'data.csv').exists() else None
  try:
   view=csv.reader(csv_file) if csv_file else None
   if view:assert next(view)==[v['name'] for v in m['variables']]
   n=0
   for line in f:
    row=json.loads(line);assert row['row']==n;assert len(row['cells'])==len(m['variables'])
    visible=[]
    for v,c in zip(m['variables'],row['cells']):
     assert c['kind']==v['type']
     if c['kind']=='string':
      raw=base64.b64decode(c['logical_bytes_base64'],validate=True);assert len(raw)==v['width'];visible.append(c['text'])
     elif c['missing']=='system':assert c['decimal'] is None;visible.append('')
     else:
      value=struct.unpack('>d',bytes.fromhex(c['ieee754_hex']))[0]
      assert struct.pack('>d',float(c['decimal']))==struct.pack('>d',value);visible.append(c['decimal'])
    if view:assert next(view)==visible
    yield row['cells'];n+=1
   assert n==m['actual_rows']
   if view:assert next(view,None) is None
  finally:
   if csv_file:csv_file.close()

if __name__=='__main__':
 count=0;present=0
 for cells in read_bundle(sys.argv[1]):
  count+=1;present+=sum(c['missing']=='present' for c in cells)
 print(json.dumps({'rows':count,'present_cells':present,'scope':'canonical_and_csv_independent_consumption'}))

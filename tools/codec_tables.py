"""Freeze codec adapters against primary CP936 data and independent Python codec.
GB18030 is the stable intersection; ambiguity is explicitly rejected, never guessed.
"""
from pathlib import Path
import json,hashlib,base64,struct
src=Path('.dev/sources');out=Path('node/codec-data.json')
cp={}
for line in (src/'CP936.TXT').read_text().splitlines():
 fields=line.split('#')[0].split()
 if len(fields)>=2:cp[int(fields[0],16)]=int(fields[1],16)
# Validate primary CP936 mapping against the independent Python implementation.
differences=[]
for key,value in cp.items():
 b=key.to_bytes(1 if key<256 else 2,'big')
 try:text=b.decode('gbk')
 except UnicodeDecodeError:text=None
 if text != chr(value):differences.append({'hex':b.hex(),'primary':value,'python':text})
# CP936 0x80 Euro differs from strict GBK; declare and reject as a variant.
assert differences==[{'hex':'80','primary':8364,'python':None}],differences
arr=[]
for a in range(0x81,0xff):
 for b in range(0x40,0xff):
  try:s=bytes([a,b]).decode('gb18030');arr.append(ord(s))
  except UnicodeDecodeError:arr.append(0xffffffff)
ranges=[]
for line in (src/'index-gb18030-ranges.txt').read_text().splitlines():
 if line and not line.startswith('#'):
  a,b,*_=line.split();ranges.append([int(a),int(b,16)])
out.write_text(json.dumps({'cp936':{str(k):v for k,v in cp.items() if k>255},'gb18030_two':base64.b64encode(struct.pack('<'+'I'*len(arr),*arr)).decode(),'ranges':ranges},separators=(',',':'))+'\n')
Path('evidence/codec-primary.json').write_text(json.dumps({'sources':{str(p.name):hashlib.sha256(p.read_bytes()).hexdigest() for p in [src/'CP936.TXT',src/'index-gb18030-ranges.txt']},'cp936_python_differences':differences,'note':'GB18030 Python/Node differences rejected by adapter; four-byte range mapping cross-check required'},indent=2)+'\n')

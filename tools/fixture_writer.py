"""Tiny independent test writer from GNU SAV layout, not a product writer.
Fixtures contain only invented values. Never imports MoonSav.
"""
import struct
I=lambda n:struct.pack('<i',n)
D=lambda n:struct.pack('<d',n)
SYSMIS=struct.pack('<Q',0xffefffffffffffff)
def extension(n,data,size=1):return I(7)+I(n)+I(size)+I(len(data)//size)+data
def sav(variables,rows,encoding='UTF-8',compressed=False,bias=100.,declared=None,extensions=b''):
 slots=sum(1 if v.get('width',0)==0 else (v['width']+7)//8 for v in variables)
 header=b'$FL2'+b'@(#) MoonSav independent fixture'.ljust(60,b' ')+b''.join(I(x) for x in [2,slots,int(compressed),0,len(rows) if declared is None else declared])+D(bias)+b'01 JAN 26'+b'00:00:00'+b'Synthetic'.ljust(64,b' ')+b'\0'*3
 dictionary=b''
 for v in variables:
  w=v.get('width',0);miss=v.get('missing',[]);mc=v.get('missing_count',len(miss));fmt=v.get('format',(1 if w else 5)<<16|((w if w else 8)&255)<<8)
  label=v.get('label');name=v['name'].encode('ascii').ljust(8,b' ')
  dictionary+=b''.join(I(x)for x in[2,w,int(label is not None),mc,fmt,fmt])+name
  if label is not None:dictionary+=I(len(label))+label+b'\0'*((-len(label))%4)
  dictionary+=b''.join(x if isinstance(x,bytes)else D(x)for x in miss)
  for _ in range((w+7)//8-1):dictionary+=I(2)+I(-1)+I(0)*4+b' '*8
 # Explicit labels, associated with physical variable start.
 slot=1
 for v in variables:
  if v.get('labels'):
   dictionary+=I(3)+I(len(v['labels']))
   for val,label in v['labels']:
    raw=val if isinstance(val,bytes)else D(val)
    dictionary+=raw+bytes([len(label)])+label+b' '*((-(len(label)+1))%8)
   dictionary+=I(4)+I(1)+I(slot)
  slot+=1 if not v.get('width')else(v['width']+7)//8
 dictionary+=extension(3,b''.join(I(x)for x in[1,0,0,-1,1,1,2,{'UTF-8':65001,'windows-1252':1252,'GBK':936,'GB18030':54936}.get(encoding,2)]),4)
 dictionary+=extension(20,encoding.encode())+extensions+I(999)+I(0)
 chunks=[]
 for row in rows:
  for v,value in zip(variables,row):
   w=v.get('width',0)
   if w:chunks.extend([value.ljust((w+7)//8*8,b' ')[i:i+8]for i in range(0,(w+7)//8*8,8)])
   else:chunks.append(SYSMIS if value is None else value if isinstance(value,bytes)else D(value))
 if not compressed:data=b''.join(chunks)
 else:
  # Literal opcode stream deliberately crosses row and eight-control boundaries.
  chunks.append(None);data=b''
  for i in range(0,len(chunks),8):
   block=chunks[i:i+8];data+=bytes(252 if c is None else 253 for c in block).ljust(8,b'\0')+b''.join(c for c in block if c is not None)
 return header+dictionary+data

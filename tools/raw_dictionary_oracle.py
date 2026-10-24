"""Independent standard-library raw field audit, supplementary to ReadStat/PSPP.
No source cell values are reported. Reads original sequential record boundaries.
"""
import struct,base64

def fields(data):
 pos=176;slot=0;raw={};extensions={};logical=[]
 def i32():
  nonlocal pos
  n=struct.unpack_from('<i',data,pos)[0];pos+=4;return n
 while True:
  offset=pos;record=i32()
  if record==2:
   width,flag,count,pr,wr=struct.unpack_from('<iiiii',data,pos);pos+=20;name=data[pos:pos+8];pos+=8;label=None
   if flag:n=i32();label=data[pos:pos+n];pos+=(n+3)//4*4
   missing=[data[pos+i*8:pos+(i+1)*8]for i in range(abs(count))];pos+=8*abs(count)
   if width>=0:raw[slot]={'offset':offset,'width':width,'name':name,'label':label,'missing_count':count,'missing':missing,'print':pr,'write':wr,'logical':len(logical)};logical.append(slot)
   slot+=1
  elif record==3:
   n=i32()
   for _ in range(n):
    pos+=8;length=data[pos];pos+=(length+1+7)//8*8
   assert i32()==4
   n=i32();pos+=4*n
  elif record==6:n=i32();pos+=80*n
  elif record==7:
   subtype,size,count=i32(),i32(),i32();payload=data[pos:pos+size*count];pos+=size*count;extensions[subtype]=(size,count,payload)
  elif record==999:assert i32()==0;break
  else:raise ValueError('Unknown audit record')
 return raw,extensions

def audit(data,meta):
 raw,extensions=fields(data);differences=[]
 for i,v in enumerate(meta['variables']):
  r=raw.get(v['physical_start'])
  if r is None:differences.append({'field':'raw_variable_start','variable_index':i});continue
  for key,actual,expected in [('source_offset',v['source_offset'],r['offset']),('print_format_raw',v['print_format']['raw'],r['print']),('write_format_raw',v['write_format']['raw'],r['write'])]:
   if actual!=expected:differences.append({'field':key,'variable_index':i})
  if r['missing_count']and v['type']=='numeric':
   for a,b in zip(v['user_missing']['values'],r['missing']):
    if a['ieee754_hex']!=struct.unpack('<Q',b)[0].to_bytes(8,'big').hex():differences.append({'field':'raw_missing_atom','variable_index':i})
  if 11 in extensions:
   size,count,payload=extensions[11];stride=count//len(raw);vals=struct.unpack('<'+'i'*count,payload);start=r['logical']*stride
   expected=[vals[start],vals[start+1]if stride==3 else None,vals[start+stride-1]]
   if [v['measure'],v['display_width'],v['alignment']]!=expected:differences.append({'field':'display_measure_alignment','variable_index':i})
  elif any(v[k]is not None for k in ['measure','display_width','alignment']):differences.append({'field':'undeclared_display','variable_index':i})
 weight=struct.unpack_from('<i',data,76)[0];idx=meta['weight_variable']
 if (weight==0)!=(idx is None)or idx is not None and meta['variables'][idx]['physical_start']!=weight-1:differences.append({'field':'weight_reference'})
 for e in meta['uninterpreted_metadata']:
  if e['record']==7:
   payload=extensions.get(e['subtype'])
   if not payload or base64.b64decode(e['raw_base64'])!=payload[2]:differences.append({'field':'uninterpreted_payload'})
 return differences

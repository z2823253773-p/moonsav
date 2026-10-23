"""Full ReadStat comparison; evidence contains aggregate differences only, never rows."""
import json,struct,hashlib,re,sys
from pathlib import Path
import pyreadstat

def compare(source,bundle):
 source=Path(source);bundle=Path(bundle);df,oracle=pyreadstat.read_sav(str(source),user_missing=True,disable_datetime_conversion=True,apply_value_formats=False,output_format='dict')
 meta=json.loads((bundle/'metadata.json').read_text());differences=[];compared=0;normalizations={'string_trailing_ascii_spaces':0,'system_missing_to_None':0,'label_trailing_ascii_spaces':0}
 def diff(field,index=None):
  if len(differences)<50:differences.append({'field':field,'variable_index':index})
 if [v['name']for v in meta['variables']]!=oracle.column_names:diff('names_or_order')
 if len(meta['variables'])!=len(oracle.column_names):diff('variable_count')
 for i,v in enumerate(meta['variables']):
  name=v['name'];typ=oracle.readstat_variable_types.get(name);expected='numeric'if typ in ['double','int8','int16','int32','float']else'string'
  if v['type']!=expected:diff('storage_type',i)
  if v['label']!=oracle.column_names_to_labels.get(name):
   other=oracle.column_names_to_labels.get(name)
   if isinstance(v['label'],str) and isinstance(other,str) and v['label'].rstrip(' ')==other:normalizations['label_trailing_ascii_spaces']+=1
   else:diff('variable_label',i)
  if v['width']!=(0 if expected=='numeric'else oracle.variable_storage_width[name]):
   # ReadStat reports rounded physical width for ordinary strings; exact SAV width remains authoritative.
   if expected!='string' or not(v['width']<=oracle.variable_storage_width[name] < v['width']+8):diff('storage_width',i)
  ol=oracle.variable_value_labels.get(name,{})
  if len(v['value_labels'])!=len(ol):diff('value_label_count',i)
  for label in v['value_labels']:
   a=label['value'];key=float(a['decimal'])if a['type']=='numeric'else a['text'].rstrip(' ')
   if ol.get(key)!=label['label']:diff('value_label',i)
  missing=oracle.missing_ranges.get(name,[]);mv=v['user_missing']['values']
  if v['user_missing']['kind']=='discrete':
   if len(missing)!=len(mv):diff('missing_definitions_count',i)
   for a in mv:
    key=float(a['decimal'])if a['type']=='numeric'else a['text'].rstrip(' ')
    if not any(x['lo']==x['hi']==key for x in missing):diff('missing_definition',i)
  elif len(missing)!=(1 if v['user_missing']['kind']=='range'else 2):diff('range_missing_definition_count',i)
 # Oracle numeric user missing retains original values; missing classification independent from MoonSav.
 n=0
 with (bundle/'data.ndjson').open()as f:
  for line in f:
   row=json.loads(line)
   if row['row']!=n:diff('row_sequence')
   for i,(v,c)in enumerate(zip(meta['variables'],row['cells'])):
    value=df[v['name']][n];compared+=1
    if v['type']=='string':
     if c['text'].rstrip(' ')!=value:diff('string_text',i)
     if c['text']!=value:normalizations['string_trailing_ascii_spaces']+=1
     expected='user'if any(x['lo']==x['hi']==value for x in oracle.missing_ranges.get(v['name'],[]))else'present'
    elif value is None or isinstance(value,float)and value!=value:
     expected='system';normalizations['system_missing_to_None']+=1
     if c['decimal']is not None:diff('system_value',i)
    else:
     if struct.pack('>d',value).hex()!=c['ieee754_hex']:diff('numeric_bits',i)
     expected='user'if any(x['lo']<=value<=x['hi']for x in oracle.missing_ranges.get(v['name'],[]))else'present'
    if c['missing']!=expected:diff('missing_kind',i)
   n+=1
 if n!=oracle.number_rows or n!=meta['actual_rows']:diff('actual_rows')
 risk_columns=sum(bool(re.search(r'姓名|电话|手机|IP|邮箱|email|name|address|日期|时间',n,re.I))for n in oracle.column_names)
 return {'input_sha256':hashlib.sha256(source.read_bytes()).hexdigest(),'size_bytes':source.stat().st_size,'actual_rows':n,'logical_variables':len(meta['variables']),'cells_compared':compared,'dictionary_compared':['names','order','type','width','variable_labels','value_labels','user_missing_definitions'],'differences':differences,'normalizations':normalizations,'screening':{'potential_identifier_columns':risk_columns,'raw_redistribution':False,'cell_values_in_evidence':False},'oracle':'ReadStat via pyreadstat '+pyreadstat.__version__,'status':'supported_pass'if not differences else'supported_fail'}
if __name__=='__main__':
 r=compare(sys.argv[1],sys.argv[2]);print(json.dumps(r,ensure_ascii=False,indent=2));raise SystemExit(bool(r['differences']))

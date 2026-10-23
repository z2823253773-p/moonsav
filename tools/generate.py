"""Independent ReadStat generator; never imports MoonSav."""
from pathlib import Path
import json, hashlib, struct
import pandas as pd
import pyreadstat
out=Path('fixtures/synthetic');out.mkdir(parents=True, exist_ok=True)
source={'score':[1.,2.,99.,None,7.25], 'subject_code':['0012','NA',r'\N','    ','尾空 '], 'note':['x,y','a"b','line\nbreak','ok','中文']}
df=pd.DataFrame(source)
for compression in (False,True):
 p=out/('survey-row.sav' if compression else 'survey-none.sav')
 pyreadstat.write_sav(df,str(p), column_labels={'score':'得分','subject_code':'研究编号'}, variable_value_labels={'score':{1.:'A',2.:'B',99.:'未回答'}}, missing_ranges={'score':[99.]}, row_compress=compression, variable_format={'score':'F8.2'})
 # Writer timestamps are nonsemantic but input fixtures must be reproducible.
 b=bytearray(p.read_bytes());b[109:118]=b'01 JAN 26';b[118:126]=b'00:00:00';p.write_bytes(b)
(out/'source.json').write_text(json.dumps(source,ensure_ascii=False,indent=2)+'\n')
print(json.dumps({p.name:hashlib.sha256(p.read_bytes()).hexdigest() for p in out.glob('*.sav')},indent=2))

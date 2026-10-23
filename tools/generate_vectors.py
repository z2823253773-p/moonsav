from pathlib import Path
from fixture_writer import sav,extension,I,D
p=Path('fixtures/synthetic')
for enc,text in [('UTF-8','中�'),('windows-1252','café €'),('GBK','中文'),('GB18030','中文𐀀')]:
 codec={'UTF-8':'utf-8','windows-1252':'cp1252','GBK':'gbk','GB18030':'gb18030'}[enc]
 b=text.encode(codec);label=('文字' if enc!='windows-1252'else'café').encode(codec)
 p.joinpath('encoding-'+enc.lower()+'.sav').write_bytes(sav([{'name':'TEXT','width':len(b),'label':label,'missing':[b'NA      '],'labels':[(b'NA      ',label)]}],[[b],[b'NA']],encoding=enc))
p.joinpath('nul.sav').write_bytes(sav([{'name':'TEXT','width':4}],[[b'a\0b ']]))
p.joinpath('single-missing.sav').write_bytes(sav([{'name':'SCORE'}],[[None],[None]],compressed=True))
p.joinpath('zero.sav').write_bytes(sav([{'name':'SCORE'}],[],compressed=True))
p.joinpath('negative-zero.sav').write_bytes(sav([{'name':'NUMBER'}],[[-0.0],[1.7976931348623157e308],[-1.7976931348623155e308]]))
p.joinpath('range.sav').write_bytes(sav([{'name':'RANGE','missing_count':-3,'missing':[1.,2.,99.]}],[[0.],[1.],[1.5],[2.],[99.],[None]]))
p.joinpath('duplicate-name.sav').write_bytes(sav([{'name':'SAME'},{'name':'SAME'}],[[1.,2.]]))
p.joinpath('bad-utf8.sav').write_bytes(sav([{'name':'TEXT','width':1}],[[b'\x81']]))
p.joinpath('variant-gb18030.sav').write_bytes(sav([{'name':'TEXT','width':2}],[[bytes.fromhex('a3a0')]],encoding='GB18030'))
# Data labels do not imply missing; byte-key matching keeps distinct sources distinct.
p.joinpath('labeled-99.sav').write_bytes(sav([{'name':'CODE','labels':[(99.,b'No answer')]}],[[99.]]))
for width in [1,7,8,9]:p.joinpath(f'width-{width}.sav').write_bytes(sav([{'name':'TEXT','width':width}],[[b'x'*width],[b' '*width]],compressed=True))

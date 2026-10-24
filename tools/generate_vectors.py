from pathlib import Path
from fixture_writer import sav,extension,I,D
p=Path('fixtures/synthetic')
for enc,text in [('UTF-8','中�'),('windows-1252','café €'),('GBK','中文'),('GB18030','中文')]:
 codec={'UTF-8':'utf-8','windows-1252':'cp1252','GBK':'gbk','GB18030':'gb18030'}[enc]
 b=text.encode(codec);label=('文字' if enc!='windows-1252'else'café').encode(codec)
 p.joinpath('encoding-'+enc.lower()+'.sav').write_bytes(sav([{'name':'TEXT','width':len(b),'label':label,'missing':[b'NA      '],'labels':[(b'NA      ',label)]}],[[b],[b'NA']],encoding=enc))
p.joinpath('string-nul.sav').write_bytes(sav([{'name':'TEXT','width':4}],[[b'a\0b ']]))
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
# Literal, integer, space, system, no-op and end opcodes, with a non-default bias.
vars=[{'name':'N'},{'name':'S','width':8}]
prefix=sav(vars,[],compressed=True,bias=7.,declared=3)[:-8]
controls=bytes([8,254,0,253,253,255,253,252])+D(7.25)+b'ABCDEFGH'+b'NA      '
p.joinpath('controls.sav').write_bytes(prefix+controls)
b=bytearray(prefix+controls);b[80:84]=I(-1);p.joinpath('controls-unknown.sav').write_bytes(b)
p.joinpath('early-end.sav').write_bytes(prefix+bytes([252])+b'\0'*7)
p.joinpath('literal-truncated.sav').write_bytes(prefix+bytes([253])+b'\0'*7+D(1.)[:4])
p.joinpath('midrow-end.sav').write_bytes(prefix+bytes([8,252])+b'\0'*6)
# Numeric extremes, date display and LOWEST/HIGHEST retain tagged endpoint bits.
lo=bytes.fromhex('feffffffffffefff');hi=bytes.fromhex('ffffffffffffef7f')
p.joinpath('lowest-highest.sav').write_bytes(sav([{'name':'R','missing_count':-2,'missing':[lo,hi]}],[[-1e100],[0.],[1e100],[None]]))
p.joinpath('date-display.sav').write_bytes(sav([{'name':'DAY','format':20<<16|11<<8}],[[1234567890.],[None]],extensions=extension(11,I(3)+I(12)+I(1),4)))
# Dictionary semantic warning preserved and strict-warning behavior.
p.joinpath('warning.sav').write_bytes(sav([{'name':'X'}],[[1.]],extensions=extension(18,b'X:$Role(\'0\')/')))
# Supplemental dictionary indexes and invalid/ambiguous encoding declarations.
b=sav([{'name':'X'}],[[1.]])
record=I(7)+I(20)+I(1)+I(5)+b'UTF-8';p.joinpath('encoding-required.sav').write_bytes(b.replace(record,b'').replace(I(65001),I(2),1))
p.joinpath('encoding-conflict.sav').write_bytes(b.replace(I(65001),I(1252),1))

p.joinpath('encoding-gb18030-four.sav').write_bytes(sav([{'name':'TEXT','width':8,'label':'文字'.encode('gb18030'),'missing':[b'NA      '],'labels':[(b'NA      ','文字'.encode('gb18030'))]}],[[('中文𐀀').encode('gb18030')],[b'NA']],encoding='GB18030'))
wide=[{'name':f'V{i}'}for i in range(25)]
wide[0]['labels']=[(float(i),f'label-{i}'.encode())for i in range(1,13)]
p.joinpath('wide.sav').write_bytes(sav(wide,[[float(i+j)for i in range(25)]for j in range(3)]))

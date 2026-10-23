import tables from './codec-data.json' with {type:'json'};
const gbTwo=Buffer.from(tables.gb18030_two,'base64');
const decoders=Object.fromEntries(['utf-8','windows-1252','gbk','gb18030'].map(e=>[e,new TextDecoder(e,{fatal:true,ignoreBOM:true})]));
const variant=()=>{const e=new Error('Ambiguous or unsupported code page variant');e.code='UnsupportedEncodingVariant';throw e;};
const invalid=()=>{const e=new Error('Illegal encoding bytes');e.code='InvalidEncoding';throw e;};
export function strictDecode(bytes,encoding) {
 if(!decoders[encoding])variant();
 if(encoding==='utf-8')return decoders[encoding].decode(bytes);
 if(encoding==='windows-1252') {
  // Microsoft CP1252 defines no character at these five byte positions.
  if(bytes.some(x=>[0x81,0x8d,0x8f,0x90,0x9d].includes(x)))invalid();
  return decoders[encoding].decode(bytes);
 }
 const out=[];
 for(let i=0;i<bytes.length;) {
  const a=bytes[i++];if(a<128){out.push(String.fromCodePoint(a));continue;}
  if(a===0x80)variant();if(a<0x81||a>0xfe||i>=bytes.length)invalid();
  const b=bytes[i++];let expected;
  if(encoding==='gb18030'&&b>=0x30&&b<=0x39) {
   if(i+1>=bytes.length)invalid();const c=bytes[i++],d=bytes[i++];
   if(c<0x81||c>0xfe||d<0x30||d>0x39)invalid();
   const pointer=(((a-0x81)*10+b-0x30)*126+c-0x81)*10+d-0x30;
   if((pointer>39419&&pointer<189000)||pointer>1237575)invalid();
   let range=tables.ranges[0];for(const r of tables.ranges){if(r[0]>pointer)break;range=r;}
   expected=range[1]+pointer-range[0];
   const chunk=Uint8Array.of(a,b,c,d);let decoded;
   try{decoded=decoders.gb18030.decode(chunk)}catch{invalid()}
   // Revisions with competing mappings cannot be inferred from the SAV name.
   if(decoded!==String.fromCodePoint(expected))variant();
   out.push(decoded);
  } else {
   if(b<0x40||b>0xfe||b===0x7f)invalid();
   if(encoding==='gbk') {
    expected=tables.cp936[String(a*256+b)];if(expected===undefined)invalid();
   } else {
    expected=gbTwo.readUInt32LE(((a-0x81)*191+b-0x40)*4);if(expected===0xffffffff)invalid();
   }
   const decoded=decoders[encoding].decode(Uint8Array.of(a,b));
   if(decoded!==String.fromCodePoint(expected))variant();
   out.push(decoded);
  }
 }
 return out.join('');
}

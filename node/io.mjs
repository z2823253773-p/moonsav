import fs from 'node:fs';
import {createHash} from 'node:crypto';
import {SavError} from './api.mjs';
export const sha256=b=>createHash('sha256').update(b).digest('hex');
export function readInput(path,max=268435456) {
 const fd=fs.openSync(path,'r');
 try {
  const a=fs.fstatSync(fd,{bigint:true});if(!a.isFile())throw new SavError({code:'Io',message:'Input must be a local regular file'});
  if(a.size>BigInt(max))throw new SavError({code:'ResourceLimit',message:'input_bytes exceeds limit'});
  const parts=[];let size=0;
  while(true){const b=Buffer.alloc(Math.min(65536,max-size+1));const n=fs.readSync(fd,b,0,b.length,null);if(!n)break;size+=n;if(size>max)throw new SavError({code:'ResourceLimit',message:'input_bytes exceeds limit while reading'});parts.push(b.subarray(0,n));}
  const z=fs.fstatSync(fd,{bigint:true}),p=fs.statSync(path,{bigint:true});
  if(['size','mtimeNs','ctimeNs','ino','dev'].some(k=>a[k]!==z[k]||a[k]!==p[k]))throw new SavError({code:'InputChanged',message:'Input changed while reading; obtain a stable copy and retry'});
  return Buffer.concat(parts,size);
 }finally{fs.closeSync(fd)}
}
export function* textLines(path,maxLine=16777216) {
 const fd=fs.openSync(path,'r');let buf=Buffer.alloc(0);
 try{while(true){const chunk=Buffer.alloc(65536);const n=fs.readSync(fd,chunk,0,chunk.length,null);if(!n)break;buf=Buffer.concat([buf,chunk.subarray(0,n)]);let pos;while((pos=buf.indexOf(10))>=0){if(pos>maxLine)throw new SavError({code:'ResourceLimit',message:'Record exceeds payload budget'});yield new TextDecoder('utf-8',{fatal:true,ignoreBOM:true}).decode(buf.subarray(0,pos));buf=buf.subarray(pos+1)}if(buf.length>maxLine)throw new SavError({code:'ResourceLimit',message:'Record exceeds payload budget'})}if(buf.length)throw new SavError({code:'IntegrityMismatch',message:'NDJSON requires final newline'});}finally{fs.closeSync(fd)}
}
// Frames CSV records only. MoonBit validates quoting, fields and semantic values.
export function* csvRecords(path,maxRecord=16777216) {
 const fd=fs.openSync(path,'r');let parts=[],size=0,quoted=false,prev=-1;
 try{while(true){const chunk=Buffer.alloc(65536);const n=fs.readSync(fd,chunk,0,chunk.length,null);if(!n)break;let start=0;for(let i=0;i<n;i++){const c=chunk[i];size++;if(size>maxRecord)throw new SavError({code:'ResourceLimit',message:'CSV record exceeds payload budget'});if(c===34)quoted=!quoted;if(c===10&&!quoted){parts.push(chunk.subarray(start,i+1));if(prev!==13)throw new SavError({code:'IntegrityMismatch',message:'CSV record separator must be CRLF'});yield new TextDecoder('utf-8',{fatal:true,ignoreBOM:true}).decode(Buffer.concat(parts,size));parts=[];size=0;start=i+1;}prev=c;}if(start<n)parts.push(Buffer.from(chunk.subarray(start,n)));}if(size||quoted)throw new SavError({code:'IntegrityMismatch',message:'Unterminated CSV record'});}finally{fs.closeSync(fd)}
}

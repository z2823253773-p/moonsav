import * as core from '../lib/moonsav.js';
import {strictDecode} from './codec.mjs';
let active=false;
export class SavError extends Error {
 constructor(info) {super(info.message);Object.assign(this,info);}
}
export function dispatch(input,command,options={},sink=()=>{}) {
 if(active) throw new SavError({code:'ConsumerFailed',message:'Node adapter calls cannot be reentered'});
 active=true;
 globalThis.__moonsavDecode=(b,e)=>{try{return '\0'+strictDecode(b,e)}catch(x){return x.code==='UnsupportedEncodingVariant'?x.code:'InvalidEncoding'}};
 let sinkError;
 globalThis.__moonsavEmit=(k,s)=>{try{sink(k,s)}catch(e){sinkError=e;throw e}};
 try {
  const r=JSON.parse(core.run(input,command,options.encoding??'',options.maxRows??1000000,options.maxInputBytes??268435456,options.maxOutputBytes??536870912));
  if(sinkError)throw sinkError;
  if(!r.ok) throw new SavError(r.error);
  return r;
 } finally {active=false;delete globalThis.__moonsavEmit;delete globalThis.__moonsavDecode;}
}
export function inspectSav(input,options={}) {return dispatch(input,'inspect',options).dictionary;}
export function readSav(input,options={}) {
 const rows=[];
 const r=dispatch(input,'read',options,(k,s)=>{if(k==='ndjson')rows.push(JSON.parse(s).cells)});
 return {dictionary:r.dictionary,rows};
}

export function checkerCall(name,...args) {
 globalThis.__moonsavDecode=(b,e)=>{try{return '\0'+strictDecode(b,e)}catch(x){return x.code==='UnsupportedEncodingVariant'?x.code:'InvalidEncoding'}};
 try {const r=JSON.parse(core[name](...args));if(!r.ok)throw new SavError(r.error);return r}finally{delete globalThis.__moonsavDecode}
}

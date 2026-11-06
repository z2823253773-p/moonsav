import * as core from '../lib/moonsav.js';
import {strictDecode} from './codec.mjs';
import {types as utilTypes} from 'node:util';
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
function validateByteCall(input,options) {
 if(!ArrayBuffer.isView(input)||!(input instanceof Uint8Array))throw new SavError({code:'Usage',message:'Input must be Uint8Array or Buffer'});
 if(!options||typeof options!=='object'||Array.isArray(options)||utilTypes.isProxy(options))throw new SavError({code:'Usage',message:'Options must be an ordinary data object'});
 const prototype=Object.getPrototypeOf(options);
 if(prototype!==Object.prototype&&prototype!==null)throw new SavError({code:'Usage',message:'Options cannot inherit custom properties'});
 const maxima={maxRows:1000000,maxInputBytes:268435456,maxOutputBytes:536870912};
 const normalized=Object.create(null),properties=Object.getOwnPropertyDescriptors(options);
 for(const key of Reflect.ownKeys(properties)) {
  if(typeof key!=='string'||(key!=='encoding'&&!Object.hasOwn(maxima,key)))throw new SavError({code:'Usage',message:'Unknown byte API option'});
  const descriptor=properties[key];
  if(!Object.hasOwn(descriptor,'value'))throw new SavError({code:'Usage',message:'Options cannot contain accessors'});
  const value=descriptor.value;if(value===undefined)continue;
  if(key==='encoding') {if(typeof value!=='string'||!value.trim())throw new SavError({code:'Usage',message:'encoding must be a nonempty string'});}
  else if(Object.hasOwn(maxima,key)) {
   if(!Number.isSafeInteger(value))throw new SavError({code:'Usage',message:key+' must be an integer'});
   if(value<=0||value>maxima[key])throw new SavError({code:'ResourceLimit',message:key+' may only lower the positive compiled limit'});
  }
  normalized[key]=value;
 }
 return normalized;
}
export function inspectSav(input,options={}) {return dispatch(input,'inspect',validateByteCall(input,options)).dictionary;}
export function readSav(input,options={}) {
 options=validateByteCall(input,options);
 const rows=[];
 const r=dispatch(input,'read',options,(k,s)=>{if(k==='ndjson')rows.push(JSON.parse(s).cells)});
 return {dictionary:r.dictionary,rows};
}

export function checkerCall(name,...args) {
 globalThis.__moonsavDecode=(b,e)=>{try{return '\0'+strictDecode(b,e)}catch(x){return x.code==='UnsupportedEncodingVariant'?x.code:'InvalidEncoding'}};
 try {const r=JSON.parse(core[name](...args));if(!r.ok)throw new SavError(r.error);return r}finally{delete globalThis.__moonsavDecode}
}

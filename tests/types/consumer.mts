import {inspectSav, readSav, SavError, type SavDataset, type SavCell, type SavAtom} from 'moonsav';
import {readSav as legacyRead} from 'moonsav/node/api.mjs';
declare const bytes: Uint8Array;
const dictionary=inspectSav(bytes,{encoding:undefined,maxRows:undefined,maxInputBytes:undefined,maxOutputBytes:undefined});
const scope:'dictionary_only'=dictionary.validation_scope;
const actual:null=dictionary.actual_rows;
const declared:number|null=dictionary.declared_rows;
const dataset:SavDataset=readSav(bytes,{encoding:'UTF8',maxRows:5});
const oldDataset:SavDataset=legacyRead(bytes);
for(const row of dataset.rows)for(const cell of row){
 const valid:SavCell=cell;
 if(cell.kind==='string'){
  const text:string=cell.text;const bits:null=cell.ieee754_hex;
  // @ts-expect-error string cells do not contain a numeric decimal
  cell.decimal.toUpperCase();
 }else if(cell.missing==='system'){
  const decimal:null=cell.decimal;const bits:string=cell.ieee754_hex;
  // @ts-expect-error system missing has no decimal string
  cell.decimal.toUpperCase();
 }else{const decimal:string=cell.decimal;const missing:'present'|'user'=cell.missing;}
}
for(const variable of dictionary.variables){
 const measure:0|1|2|3|null=variable.measure;
 const alignment:0|1|2|null=variable.alignment;
}
for(const variable of dictionary.variables)for(const label of variable.value_labels){
 const atom:SavAtom=label.value;
 if(atom.type==='numeric'){const width:8=atom.width;const decimal:string=atom.decimal;}
 else{const text:string=atom.text;const decimal:null=atom.decimal;}
}
try{readSav(bytes)}catch(error){if(error instanceof SavError){const code:string=error.code;const offset:number|null|undefined=error.byte_offset;}}
// @ts-expect-error options use integers, not strings
readSav(bytes,{maxRows:'5'});
// @ts-expect-error option typos are not part of the stable interface
inspectSav(bytes,{maxRoes:5});
// @ts-expect-error explicit null is not an options object
readSav(bytes,null);
// @ts-expect-error raw ArrayBuffer must be wrapped
readSav(new ArrayBuffer(8));
// @ts-expect-error the root package does not export internal bridge calls
import {dispatch} from 'moonsav';
// @ts-expect-error declared rows can be unknown
const guaranteedRows:number=dictionary.declared_rows;

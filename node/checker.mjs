import fs from 'node:fs';import path from 'node:path';import {createHash} from 'node:crypto';
import {checkerCall,SavError}from'./api.mjs';import{readInput,sha256,textLines,csvRecords,decodeUtf8}from'./io.mjs';
function fail(code,message){throw new SavError({code,message})}
export function checkBundle(directory,options={}) {
 const o={maxRows:1000000,maxInputBytes:268435456,maxOutputBytes:536870912,...options};
 const limits=[o.maxRows,o.maxInputBytes,o.maxOutputBytes];
 let entries;try{const s=fs.lstatSync(directory);if(!s.isDirectory()||s.isSymbolicLink())fail('IntegrityMismatch','Bundle must be an ordinary directory');entries=fs.readdirSync(directory)}catch(e){if(e instanceof SavError)throw e;fail('IntegrityMismatch','Bundle directory is missing or unreadable')}
 if(entries.includes('INCOMPLETE'))fail('IncompleteBundle','Bundle has an INCOMPLETE marker; retry export in a new directory');
 const regular=name=>{if(!entries.includes(name))fail('IntegrityMismatch','Required bundle file is missing');const p=path.join(directory,name),s=fs.lstatSync(p);if(!s.isFile()||s.isSymbolicLink())fail('IntegrityMismatch','Bundle file must be regular and cannot be a symlink');return p;};
 const manifestBytes=readInput(regular('manifest.json'),Math.min(o.maxOutputBytes,16777216));
 const manifestText=decodeUtf8(manifestBytes);
 const manifest=checkerCall('check_manifest_bridge',manifestText,...limits).manifest;
 for(const [name,record]of Object.entries(manifest.files)) {
  const file=regular(name),s=fs.statSync(file);if(s.size!==record.size_bytes)fail('IntegrityMismatch','Bundle file size mismatch');
  // Hash the same actual opened file bytes without retaining whole data payloads.
  const fd=fs.openSync(file,fs.constants.O_RDONLY|(fs.constants.O_NOFOLLOW??0));
  try{const h=createHash('sha256');let total=0;while(true){const b=Buffer.alloc(65536),n=fs.readSync(fd,b,0,b.length,null);if(!n)break;total+=n;if(total>record.size_bytes)fail('IntegrityMismatch','File changed during hash check');h.update(b.subarray(0,n));}if(total!==record.size_bytes||h.digest('hex')!==record.sha256)fail('IntegrityMismatch','Bundle SHA256 mismatch')}finally{fs.closeSync(fd)}
 }
 const metadataBytes=readInput(regular('metadata.json'),o.maxOutputBytes);if(sha256(metadataBytes)!==manifest.files['metadata.json'].sha256)fail('IntegrityMismatch','Metadata changed before semantic checking');
 const metadata=decodeUtf8(metadataBytes);
 const d=checkerCall('check_start_bridge',metadata,manifestText,...limits).dictionary;
 const warnings=[...d.warnings];
 const expected=new Set(['manifest.json',...Object.keys(manifest.files)]);
 for(const name of entries)if(!expected.has(name)){const stat=fs.lstatSync(path.join(directory,name));if(!stat.isFile()||stat.isSymbolicLink())fail('IntegrityMismatch','Extra bundle entries must be ordinary files');warnings.push({warning_code:'UnverifiedExtraFile',scope:'bundle',suggested_action:'Extra ordinary files were not verified or used as data'})}
 if(o.strict&&warnings.length)fail('WarningRejected','Bundle warnings rejected by --fail-on-warning');
 const streams={};const track=name=>{const h=createHash('sha256');let total=0;streams[name]=()=>{const f=manifest.files[name];if(total!==f.size_bytes||h.digest('hex')!==f.sha256)fail('IntegrityMismatch','Parsed data bytes disagree with manifest')};return b=>{total+=b.length;if(total>manifest.files[name].size_bytes)fail('IntegrityMismatch','Data grew while parsing');h.update(b)}};
 let csv=null;if(manifest.profile==='csv_with_canonical'){csv=csvRecords(regular('data.csv'),o.maxOutputBytes,track('data.csv'));const header=csv.next();if(header.done)fail('IntegrityMismatch','CSV header is missing');checkerCall('check_row_bridge','',header.value,1)}
 for(const line of textLines(regular('data.ndjson'),o.maxOutputBytes,track('data.ndjson'))){const view=csv?.next();if(view?.done)fail('IntegrityMismatch','CSV has too few records');checkerCall('check_row_bridge',line,view?.value??'',csv?2:0)}
 if(csv&&!csv.next().done)fail('IntegrityMismatch','CSV has too many records');
 for(const finish of Object.values(streams))finish();
 const summary=checkerCall('check_end_bridge').summary;
 return {report_version:'moonsav.report/1',command:'check-bundle',status:warnings.length?'passed_with_warnings':'passed',validation_scope:'bundle',declared_rows:d.declared_rows,actual_rows:summary.actual_rows,logical_variables:d.logical_variables,warnings,uninterpreted_metadata:d.uninterpreted_metadata,error:null,counts:summary.counts,completed:true,authentication:'not_provided'};
}

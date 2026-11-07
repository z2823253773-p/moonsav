// Run after installing the npm archive. Omitting FILE uses the licensed sample.
import fs from 'node:fs';
import {readSav, SavError} from 'moonsav';
try {
 if(process.argv.length>3)throw Object.assign(new Error('Usage: node read_sav.mjs [FILE.sav]'),{code:'Usage'});
 const source=process.argv[2]??new URL('../fixtures/synthetic/survey-row.sav',import.meta.url);
 const {dictionary,rows}=readSav(fs.readFileSync(source));
 const columns=dictionary.variables.map(v=>({index:v.index,name:v.name,type:v.type,width:v.width,counts:[0,0,0]}));
 for(const row of rows)for(let i=0;i<row.length;i++){
  const kind=row[i].missing;columns[i].counts[kind==='present'?0:kind==='user'?1:2]++;
 }
 console.log(JSON.stringify({actual_rows:rows.length,logical_variables:columns.length,columns},null,2));
} catch(error) {
 console.error(JSON.stringify({code:error instanceof SavError?error.code:error.code??'ExampleFailed',message:error.message}));
 process.exitCode=1;
}

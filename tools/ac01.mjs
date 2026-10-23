import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import {readSav} from '../node/api.mjs';
for (const mode of ['none','row']) {
 const d=readSav(readFileSync(`fixtures/synthetic/survey-${mode}.sav`));
 assert.equal(d.dictionary.variables.length,3);
 assert.equal(d.rows.length,5);
 assert.deepEqual(d.rows.map(r=>r[0].missing),['present','present','user','system','present']);
 assert.equal(d.dictionary.variables[0].label,'得分');
 assert.equal(d.dictionary.variables[0].value_labels.length,3);
 assert.equal(d.rows[0][1].text.trimEnd(),'0012');
 assert.equal(d.rows[1][1].text.trimEnd(),'NA');
 assert.equal(d.rows[2][1].text.trimEnd(),'\\N');
 assert.equal(d.rows[2][2].text.trimEnd(),'line\nbreak');
 assert.equal(d.rows[4][0].decimal,'7.25');
 console.log(`${mode}: 5 rows / 3 variables, dictionary and missing semantics pass`);
}

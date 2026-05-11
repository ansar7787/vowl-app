// Final patch to add 5 more entries to dialect_drill_pool.js
const fs = require('fs');
const path = require('path');
const poolPath = path.join(__dirname, 'pools/dialect_drill_pool.js');
const content = fs.readFileSync(poolPath, 'utf8');
const insertionPoint = content.lastIndexOf('console.log');
const entries = [
  {instruction:'Choose the correct pronunciation.',fields:{word:'receipt',options:['rih-SEET','REE-sept'],correctAnswerIndex:0,hint:'P is silent.'}},
  {instruction:'Choose the correct pronunciation.',fields:{word:'island',options:['EYE-lund','IS-lund'],correctAnswerIndex:0,hint:'S is silent.'}},
  {instruction:'Choose the correct pronunciation.',fields:{word:'listen',options:['LIS-un','LIS-ten'],correctAnswerIndex:0,hint:'T is silent.'}},
  {instruction:'Choose the correct pronunciation.',fields:{word:'muscle',options:['MUH-sul','MUS-kul'],correctAnswerIndex:0,hint:'C is silent.'}},
  {instruction:'Choose the correct pronunciation.',fields:{word:'sword',options:['SORD','SWORD'],correctAnswerIndex:0,hint:'W is silent.'}},
];
let extra = '\n  // === FINAL PATCH ===\n';
for (const e of entries) extra += '  pool.push(' + JSON.stringify(e) + ');\n';
fs.writeFileSync(poolPath, content.slice(0, insertionPoint) + extra + content.slice(insertionPoint));
console.log('Added 5 more dialect entries, now at ' + (597 + entries.length));

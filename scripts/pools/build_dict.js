const fs = require('fs');
const path = require('path');

async function buildDict() {
  console.log('Loading CMU dictionary...');
  const cmu = await import('cmu-pronouncing-dictionary');
  const dict = {};
  for(const k in cmu.dictionary) {
    dict[k] = cmu.dictionary[k];
  }
  
  const outPath = path.join(__dirname, 'cmu_dict.json');
  console.log(`Writing dictionary to ${outPath}...`);
  fs.writeFileSync(outPath, JSON.stringify(dict, null, 2));
  console.log('Done!');
}

buildDict().catch(console.error);

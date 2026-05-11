/**
 * Global Production Script
 * Re-generates ALL curriculum categories to ensure 100% quality and consistency.
 */
const { execSync } = require('child_process');

const scripts = [
  'generate_accent.js',
  'generate_grammar.js',
  'generate_listening.js',
  'generate_vocabulary.js',
  'generate_reading.js',
  'generate_writing.js',
  'generate_roleplay.js',
  'generate_speaking.js',
  'generate_kids.js'
];

console.log('--- STARTING GLOBAL CURRICULUM PRODUCTION ---');

scripts.forEach(script => {
  console.log(`Running ${script}...`);
  try {
    const output = execSync(`node scripts/${script}`, { encoding: 'utf8' });
    console.log(output);
  } catch (error) {
    console.error(`Error running ${script}:`, error.message);
  }
});

console.log('--- GLOBAL CURRICULUM PRODUCTION COMPLETE ---');

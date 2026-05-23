const fs = require('fs');
const file = 'lib/features/accent/shadowing_challenge/presentation/pages/shadowing_challenge_screen.dart';
const content = fs.readFileSync(file, 'utf8');

let braceCount = 0;
let lines = content.split('\n');

for (let i = 0; i < lines.length; i++) {
  let line = lines[i];
  for (let char of line) {
    if (char === '{') {
      braceCount++;
    } else if (char === '}') {
      braceCount--;
    }
  }
  console.log(`Line ${i + 1}: brace count = ${braceCount}`);
}

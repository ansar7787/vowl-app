const fs = require('fs');
const path = require('path');

const dir = './assets/curriculum/accent';
const files = fs.readdirSync(dir);

for (const file of files) {
  if (file.endsWith('.json')) {
    fs.unlinkSync(path.join(dir, file));
  }
}

console.log("Accent Curriculum Directory Cleared.");

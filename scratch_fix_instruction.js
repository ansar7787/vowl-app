const fs = require('fs');
const path = require('path');
const dir = 'lib/features/kids_zone/presentation/widgets/layouts';
const files = fs.readdirSync(dir).filter(f => f.endsWith('.dart'));

let updatedFiles = 0;

for (const file of files) {
  const filepath = path.join(dir, file);
  let content = fs.readFileSync(filepath, 'utf8');
  let originalContent = content;

  content = content.replace(/quest\.instruction \?\?/g, 'quest.question ??');
  
  // also handle standard null check if present: `quest.instruction == null`
  // although it's mostly `quest.instruction ?? "?"`

  if (content !== originalContent) {
      fs.writeFileSync(filepath, content, 'utf8');
      updatedFiles++;
      console.log('Updated: ' + file);
  }
}
console.log('Updated ' + updatedFiles + ' files to use quest.question');

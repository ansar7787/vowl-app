const fs = require('fs');
const path = require('path');
const dir = 'lib/features/kids_zone/presentation/widgets/layouts';
const files = fs.readdirSync(dir).filter(f => f.endsWith('.dart'));

let updatedFiles = 0;

for (const file of files) {
  const filepath = path.join(dir, file);
  let content = fs.readFileSync(filepath, 'utf8');
  let originalContent = content;

  // Find Text(context.tr('games.kids_..._drag', ...))
  // and replace with AutoSizeText(..., maxLines: 2, minFontSize: 10)
  
  const textTrRegex = /Text\(\s*context\.tr\(\s*'games\.kids_[a-z_]+_drag'[\s\S]*?\),\s*style:\s*TextStyle\([\s\S]*?\),\s*\)/g;
  
  content = content.replace(textTrRegex, (match) => {
      // replace Text( with AutoSizeText(
      let newMatch = match.replace(/^Text\(/, 'AutoSizeText(');
      // add maxLines and minFontSize before the final closing parenthesis
      newMatch = newMatch.replace(/\s*\)$/, ',\n                  maxLines: 2,\n                  minFontSize: 10,\n                  textAlign: TextAlign.center,\n                )');
      return newMatch;
  });

  if (content !== originalContent) {
      fs.writeFileSync(filepath, content, 'utf8');
      updatedFiles++;
  }
}
console.log('Updated ' + updatedFiles + ' files for instruction Text conversions.');

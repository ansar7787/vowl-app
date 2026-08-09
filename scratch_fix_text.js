const fs = require('fs');
const path = require('path');
const dir = 'lib/features/kids_zone/presentation/widgets/layouts';
const files = fs.readdirSync(dir).filter(f => f.endsWith('.dart'));

let updatedFiles = 0;

for (const file of files) {
  const filepath = path.join(dir, file);
  let content = fs.readFileSync(filepath, 'utf8');
  let originalContent = content;

  // 1. Change all FontWeight.w900 to FontWeight.w700
  // and maybe change 16.sp to 18.sp or 20.sp for single words? The user mentioned "size too bold and size that also bad". Let's just fix w900 first.
  content = content.replace(/FontWeight\.w900/g, 'FontWeight.w700');
  content = content.replace(/FontWeight\.w800/g, 'FontWeight.w700');

  // 2. Convert AutoSizeText to FittedBox for single line text
  // We look for:
  // AutoSizeText(
  //   [text],
  //   style: TextStyle(...),
  //   textAlign: ...,
  //   maxLines: 1,
  //   minFontSize: ...,
  // )
  // and replace with FittedBox
  
  const autoSizeRegex = /AutoSizeText\(\s*([^,]+),\s*style:\s*(TextStyle\([\s\S]*?\)),\s*textAlign:\s*([^,]+),\s*maxLines:\s*1,\s*minFontSize:\s*[\d.]+,\s*\)/g;
  
  content = content.replace(autoSizeRegex, (match, textArg, styleArg, textAlignArg) => {
      return `FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  ${textArg},
                  style: ${styleArg},
                  textAlign: ${textAlignArg},
                ),
              )`;
  });

  const autoSizeRegex2 = /AutoSizeText\(\s*([^,]+),\s*style:\s*(TextStyle\([\s\S]*?\)),\s*maxLines:\s*1,\s*minFontSize:\s*[\d.]+,\s*\)/g;
  content = content.replace(autoSizeRegex2, (match, textArg, styleArg) => {
      return `FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  ${textArg},
                  style: ${styleArg},
                ),
              )`;
  });
  
  // also handle standard Text() that might overflow, if any are single word options...
  // but most of the layouts use AutoSizeText.

  if (content !== originalContent) {
      fs.writeFileSync(filepath, content, 'utf8');
      updatedFiles++;
  }
}
console.log('Updated ' + updatedFiles + ' files.');

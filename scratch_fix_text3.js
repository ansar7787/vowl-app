const fs = require('fs');
const path = require('path');
const dir = 'lib/features/kids_zone/presentation/widgets/layouts';
const files = fs.readdirSync(dir).filter(f => f.endsWith('.dart'));

let updatedFiles = 0;

for (const file of files) {
  const filepath = path.join(dir, file);
  let content = fs.readFileSync(filepath, 'utf8');
  let originalContent = content;

  // 1. Change FontWeight.w900 and w800 to FontWeight.w700
  content = content.replace(/FontWeight\.w900/g, 'FontWeight.w700');
  content = content.replace(/FontWeight\.w800/g, 'FontWeight.w700');

  // 2. Convert AutoSizeText to FittedBox for single line text (the options/draggables)
  // AutoSizeText( text, style: TextStyle(...), textAlign: ..., maxLines: 1, minFontSize: ..., )
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

  // 3. The instructions (Text -> AutoSizeText)
  // We look for exactly:
  // Text(
  //   context.tr(
  //     'games.kids_...',
  //     fallback: '...',
  //   ),
  //   style: TextStyle(...),
  // )
  // and replace the outer Text() with AutoSizeText() with maxLines/minFontSize.
  // Using a more robust state machine or simpler regex:
  
  const textTrRegex = /Text\(\s*(context\.tr\(\s*'games\.kids_[a-z_]+_drag'[\s\S]*?\)),\s*style:\s*(TextStyle\([\s\S]*?\)),\s*\)/g;
  content = content.replace(textTrRegex, (match, trCall, textStyle) => {
      return `AutoSizeText(
                  ${trCall},
                  style: ${textStyle},
                  maxLines: 2,
                  minFontSize: 10,
                  textAlign: TextAlign.center,
                )`;
  });

  if (content !== originalContent) {
      fs.writeFileSync(filepath, content, 'utf8');
      updatedFiles++;
  }
}
console.log('Updated ' + updatedFiles + ' files correctly.');

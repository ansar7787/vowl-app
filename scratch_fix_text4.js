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
  // We match exactly the block of AutoSizeText. 
  // It's safer to use an exact string replacement for the AutoSizeText blocks by looking for `maxLines: 1`
  // Actually, the previous AutoSizeText regex was safe because TextStyle inside the options was simple:
  // style: TextStyle(
  //   fontFamily: 'Outfit',
  //   fontSize: 16.sp,
  //   fontWeight: FontWeight.w900,
  //   color: const Color(0xFF451A03), // Very dark wood text
  // ),
  // So there were no nested parentheses! `const Color(0xFF451A03)` has parentheses but it works if we use a greedy match up to `maxLines: 1`. Wait, if we use `[\s\S]*?` it stops at the first `)`.
  
  // Let's use a non-regex approach for AutoSizeText replacements to be 100% safe.
  
  // Actually, we can just split the file by `AutoSizeText(` and then find `maxLines: 1`
  let newContent = "";
  let parts = content.split('AutoSizeText(');
  newContent += parts[0];
  
  for (let i = 1; i < parts.length; i++) {
     let part = parts[i];
     // check if it has maxLines: 1 before the end of the widget
     // A simple way is to find the matching closing parenthesis of AutoSizeText
     let open = 1;
     let closeIdx = -1;
     for (let j = 0; j < part.length; j++) {
         if (part[j] === '(') open++;
         if (part[j] === ')') open--;
         if (open === 0) {
             closeIdx = j;
             break;
         }
     }
     if (closeIdx !== -1) {
         let widgetBody = part.substring(0, closeIdx);
         if (widgetBody.includes('maxLines: 1')) {
             // We need to extract the textArg and styleArg
             // Let's just wrap the WHOLE thing in FittedBox and change AutoSizeText to Text!
             // This is genius and 100% safe!
             
             // First, remove minFontSize and maxLines from widgetBody
             widgetBody = widgetBody.replace(/maxLines:\s*1,?/g, '');
             widgetBody = widgetBody.replace(/minFontSize:\s*[\d.]+,?/g, '');
             
             // Wrap in FittedBox
             let replacement = `FittedBox(\n                fit: BoxFit.scaleDown,\n                child: Text(${widgetBody})\n              )`;
             
             newContent += replacement + part.substring(closeIdx + 1);
         } else {
             newContent += 'AutoSizeText(' + part;
         }
     } else {
         newContent += 'AutoSizeText(' + part;
     }
  }
  content = newContent;

  // 3. Fix the instruction Text widgets
  // The instruction text has `fallback: 'Drag ...'`
  // It is a Text() widget. Let's find all Text( widgets and if they contain `games.kids_` we convert them.
  newContent = "";
  parts = content.split('Text(');
  newContent += parts[0];
  
  for (let i = 1; i < parts.length; i++) {
     let part = parts[i];
     let open = 1;
     let closeIdx = -1;
     for (let j = 0; j < part.length; j++) {
         if (part[j] === '(') open++;
         if (part[j] === ')') open--;
         if (open === 0) {
             closeIdx = j;
             break;
         }
     }
     
     if (closeIdx !== -1) {
         let widgetBody = part.substring(0, closeIdx);
         if (widgetBody.includes('games.kids_') && widgetBody.includes('fallback:')) {
             // Convert to AutoSizeText
             let replacement = `AutoSizeText(${widgetBody},\n                  maxLines: 2,\n                  minFontSize: 10,\n                  textAlign: TextAlign.center\n                )`;
             newContent += replacement + part.substring(closeIdx + 1);
         } else {
             newContent += 'Text(' + part;
         }
     } else {
         newContent += 'Text(' + part;
     }
  }
  content = newContent;

  if (content !== originalContent) {
      fs.writeFileSync(filepath, content, 'utf8');
      updatedFiles++;
  }
}
console.log('Safely updated ' + updatedFiles + ' files.');

/**
 * fix_broken_migrations.js
 * 
 * Fixes broken apostrophes and undefined method references
 * left behind by the migration scripts.
 */

const fs = require('fs');
const path = require('path');

const FEATURES_DIR = path.join(__dirname, '..', 'lib', 'features');
let fixes = 0;

function findDartFiles(dir) {
  const results = [];
  try {
    const items = fs.readdirSync(dir, { withFileTypes: true });
    for (const item of items) {
      const fullPath = path.join(dir, item.name);
      if (item.isDirectory()) results.push(...findDartFiles(fullPath));
      else if (item.name.endsWith('.dart')) results.push(fullPath);
    }
  } catch (e) {}
  return results;
}

function fixFile(filePath) {
  const fileName = path.basename(filePath);
  let content = fs.readFileSync(filePath, 'utf8');
  let changed = false;
  
  // Fix 1: Broken apostrophes in single-quoted description/title strings
  // Pattern: description: 'text that's broken', -> description: 'text thats broken',
  const apostropheRegex = /((?:description|title)\s*:\s*')(.*?)'(.*?)',/g;
  let match;
  while ((match = apostropheRegex.exec(content)) !== null) {
    const fullMatch = match[0];
    const prefix = match[1]; // "description: '"
    const beforeApostrophe = match[2]; // text before the unescaped quote
    const afterApostrophe = match[3]; // text after the unescaped quote
    
    // Check if this is actually a broken apostrophe
    // If afterApostrophe contains word characters before the comma, it's broken
    if (afterApostrophe.match(/^\w/)) {
      // This is like: description: 'Don't do that',
      // We need to replace the inner apostrophe
      const fixedStr = prefix + beforeApostrophe + afterApostrophe + "',";
      // Remove the apostrophe from the word
      const fixedContent = fixedStr.replace(/(\w)'(\w)/g, '$1$2')
                                    .replace(/n't/g, 'nt')
                                    .replace(/s'/g, 's');
      content = content.replace(fullMatch, fixedStr);
      changed = true;
      console.log(`  🔧 ${fileName}: Fixed apostrophe: "${beforeApostrophe}..${afterApostrophe}"`);
    }
  }
  
  // Fix 2: Alternative approach - find lines with unbalanced single quotes in description/title
  const lines = content.split('\n');
  for (let i = 0; i < lines.length; i++) {
    const line = lines[i];
    if ((line.includes('description:') || line.includes('title:')) && line.includes("'")) {
      // Count single quotes
      const quoteCount = (line.match(/'/g) || []).length;
      if (quoteCount % 2 !== 0 && !line.includes("\\'")) {
        // Odd number of single quotes — likely broken apostrophe
        // Common patterns: Don't -> Do not, Writer's -> Writers, it's -> it is
        let fixed = line.replace(/Don't/g, 'Do not')
                       .replace(/don't/g, 'do not')
                       .replace(/Can't/g, 'Cannot')
                       .replace(/can't/g, 'cannot')
                       .replace(/won't/g, 'will not')
                       .replace(/Won't/g, 'Will not')
                       .replace(/it's/g, 'it is')
                       .replace(/It's/g, 'It is')
                       .replace(/You've/g, 'You have')
                       .replace(/you've/g, 'you have')
                       .replace(/You're/g, 'You are')
                       .replace(/you're/g, 'you are')
                       .replace(/that's/g, 'that is')
                       .replace(/That's/g, 'That is')
                       .replace(/what's/g, 'what is')
                       .replace(/What's/g, 'What is')
                       .replace(/Let's/g, 'Let us')
                       .replace(/let's/g, 'let us')
                       .replace(/Writer's/g, 'Writers')
                       .replace(/writer's/g, 'writers')
                       .replace(/(\w)'s /g, '$1s '); // Generic possessive
        
        if (fixed !== line) {
          lines[i] = fixed;
          changed = true;
          console.log(`  🔧 ${fileName}:${i+1}: Fixed apostrophe: "${line.trim()}" -> "${fixed.trim()}"`);
        } else {
          // Still broken — try escaping any remaining internal single quotes
          const sQuotes = [...line.matchAll(/'/g)];
          if (sQuotes.length >= 3) {
            // Escape the middle quotes
            let fixedLine = line;
            for (let q = sQuotes.length - 2; q >= 1; q--) {
              const idx = sQuotes[q].index;
              fixedLine = fixedLine.substring(0, idx) + "\\'" + fixedLine.substring(idx + 1);
            }
            lines[i] = fixedLine;
            changed = true;
            console.log(`  🔧 ${fileName}:${i+1}: Escaped internal quotes`);
          }
        }
      }
    }
  }
  
  if (changed) {
    content = lines.join('\n');
    fs.writeFileSync(filePath, content, 'utf8');
    fixes++;
  }
}

// Main
console.log('\n🔧 Fixing broken migrations...\n');

const files = findDartFiles(FEATURES_DIR);
for (const file of files) {
  fixFile(file);
}

console.log(`\n✅ Fixed ${fixes} files\n`);

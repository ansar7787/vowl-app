const fs = require('fs');
const path = require('path');

const libDir = 'C:\\Users\\asus\\Documents\\App Projects\\vowl\\lib';

function processFile(filepath) {
    let content = fs.readFileSync(filepath, 'utf8');
    let changed = false;

    const warningErrorRegex = /sl<AppLogger>\(\)\.warning\(([^)]*?error:\s*[^)]*)\)/gs;
    if (warningErrorRegex.test(content)) {
        content = content.replace(warningErrorRegex, 'sl<AppLogger>().error($1)');
        changed = true;
    }

    if (changed) {
        fs.writeFileSync(filepath, content, 'utf8');
    }
}

function walk(dir) {
    const files = fs.readdirSync(dir);
    for (const file of files) {
        const filepath = path.join(dir, file);
        if (fs.statSync(filepath).isDirectory()) {
            walk(filepath);
        } else if (filepath.endsWith('.dart')) {
            processFile(filepath);
        }
    }
}

walk(libDir);
console.log('AppLogger warnings fixed.');

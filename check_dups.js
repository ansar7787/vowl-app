const fs = require('fs');

const content = fs.readFileSync('assets/translations/en.json', 'utf8');
const lines = content.split('\n');

const keyRegex = /^\s*"([^"]+)"\s*:/;
let currentPath = [];
let keysInPath = new Map();

for (let i = 0; i < lines.length; i++) {
    const line = lines[i];
    
    // Check if it's an object open
    if (line.includes('{')) {
        const match = line.match(keyRegex);
        if (match) {
            const key = match[1];
            currentPath.push(key);
            keysInPath.set(currentPath.join('.'), new Set());
        } else {
            currentPath.push('__obj' + i + '__');
            keysInPath.set(currentPath.join('.'), new Set());
        }
    }

    const match = line.match(keyRegex);
    if (match) {
        const key = match[1];
        const pathStr = currentPath.join('.');
        
        if (!keysInPath.has(pathStr)) {
            keysInPath.set(pathStr, new Set());
        }
        
        if (keysInPath.get(pathStr).has(key)) {
            console.log(`Duplicate key found: "${key}" at line ${i + 1} (path: ${pathStr})`);
        } else {
            keysInPath.get(pathStr).add(key);
        }
    }
    
    if (line.includes('}')) {
        currentPath.pop();
    }
}

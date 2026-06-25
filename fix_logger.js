const fs = require('fs');
const path = require('path');

const libDir = 'C:\\Users\\asus\\Documents\\App Projects\\vowl\\lib';

function processFile(filepath) {
    let content = fs.readFileSync(filepath, 'utf8');
    
    if (!/AppLogger\.(error|warning|debug|info)\s*\(/.test(content)) {
        return;
    }

    content = content.replace(/AppLogger\.info\s*\(/g, 'sl<AppLogger>().debug(');
    content = content.replace(/AppLogger\.error\s*\(/g, 'sl<AppLogger>().error(');
    content = content.replace(/AppLogger\.warning\s*\(/g, 'sl<AppLogger>().warning(');
    content = content.replace(/AppLogger\.debug\s*\(/g, 'sl<AppLogger>().debug(');

    if (content.includes('sl<') && !content.includes('injection_container.dart')) {
        const importRegex = /^import\s+['"].*?['"];/gm;
        let match;
        let lastMatch;
        while ((match = importRegex.exec(content)) !== null) {
            lastMatch = match;
        }
        
        if (lastMatch) {
            const insertPos = lastMatch.index + lastMatch[0].length;
            content = content.substring(0, insertPos) + "\nimport 'package:vowl/core/utils/injection_container.dart';" + content.substring(insertPos);
        } else {
            content = "import 'package:vowl/core/utils/injection_container.dart';\n" + content;
        }
    }

    fs.writeFileSync(filepath, content, 'utf8');
}

function walk(dir) {
    const files = fs.readdirSync(dir);
    for (const file of files) {
        const filepath = path.join(dir, file);
        if (fs.statSync(filepath).isDirectory()) {
            walk(filepath);
        } else if (filepath.endsWith('.dart') && !filepath.endsWith('app_logger.dart') && !filepath.endsWith('injection_container.dart')) {
            processFile(filepath);
        }
    }
}

walk(libDir);
console.log('AppLogger fixed.');

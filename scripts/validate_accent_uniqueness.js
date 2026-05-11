const fs = require('fs');
const path = require('path');

const dir = path.join(__dirname, '../assets/curriculum/elite_mastery');
const files = fs.readdirSync(dir).filter(f => f.startsWith('accentShadowing_'));

const allTexts = new Set();
const duplicates = [];

files.forEach(file => {
    const data = JSON.parse(fs.readFileSync(path.join(dir, file), 'utf8'));
    data.quests.forEach(q => {
        if (allTexts.has(q.textToSpeak.toLowerCase())) {
            duplicates.push(`${q.textToSpeak} in ${file}`);
        }
        allTexts.add(q.textToSpeak.toLowerCase());
    });
});

if (duplicates.length > 0) {
    console.log(`DUPLICATES FOUND: ${duplicates.length}`);
    console.log(duplicates.slice(0, 5).join('\n'));
} else {
    console.log(`SUCCESS: All ${allTexts.size} questions are unique across all ${files.length} files.`);
}

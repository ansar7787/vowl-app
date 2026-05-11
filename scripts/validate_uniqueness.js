const fs = require('fs');
const path = require('path');

const dir = path.join(__dirname, '../assets/curriculum/elite_mastery');
const files = fs.readdirSync(dir).filter(f => f.startsWith('speedSpelling_'));

const allWords = new Set();
const duplicates = [];

files.forEach(file => {
    const data = JSON.parse(fs.readFileSync(path.join(dir, file), 'utf8'));
    data.quests.forEach(q => {
        if (allWords.has(q.word.toLowerCase())) {
            duplicates.push(`${q.word} in ${file}`);
        }
        allWords.add(q.word.toLowerCase());
    });
});

if (duplicates.length > 0) {
    console.log("DUPLICATES FOUND:");
    console.log(duplicates.join('\n'));
} else {
    console.log(`SUCCESS: All ${allWords.size} questions are unique across all ${files.length} files.`);
}

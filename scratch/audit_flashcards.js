const fs = require('fs');
const path = require('path');

const curriculumDir = path.join('c:', 'Users', 'asus', 'Documents', 'App Projects', 'vowl', 'assets', 'curriculum', 'vocabulary');
const files = fs.readdirSync(curriculumDir).filter(f => f.startsWith('flashcards_') && f.endsWith('.json'));

let totalQuests = 0;
const words = new Set();
const ids = new Set();
const errors = [];

files.forEach(file => {
    const content = JSON.parse(fs.readFileSync(path.join(curriculumDir, file), 'utf8'));
    content.quests.forEach((q, idx) => {
        totalQuests++;
        
        // 1. Check ID uniqueness
        if (ids.has(q.id)) errors.push(`Duplicate ID: ${q.id} in ${file}`);
        ids.add(q.id);
        
        // 2. Check Word uniqueness
        if (words.has(q.word)) errors.push(`Duplicate Word: ${q.word} in ${file}`);
        words.add(q.word);
        
        // 3. Check Fields
        const requiredFields = ['id', 'interactionType', 'instruction', 'xp', 'coins', 'hint', 'explanation', 'word', 'correctAnswer', 'definition', 'example', 'topicEmoji'];
        requiredFields.forEach(f => {
            if (q[f] === undefined || q[f] === null || q[f] === '') {
                errors.push(`Missing or empty field '${f}' in ${file} at index ${idx} (ID: ${q.id})`);
            }
        });
        
        // 4. Check specific values
        if (q.interactionType !== 'flip') errors.push(`Wrong interactionType: ${q.interactionType} in ${file} (ID: ${q.id})`);
        if (q.xp !== 10) errors.push(`Wrong XP: ${q.xp} in ${file} (ID: ${q.id})`);
        if (q.coins !== 10) errors.push(`Wrong Coins: ${q.coins} in ${file} (ID: ${q.id})`);
    });
});

console.log(`--- FLASHCARD AUDIT REPORT ---`);
console.log(`Total Files Checked: ${files.length}`);
console.log(`Total Quests Checked: ${totalQuests}`);
console.log(`Unique Words Found: ${words.size}`);
console.log(`Unique IDs Found: ${ids.size}`);

if (errors.length > 0) {
    console.log(`\nFound ${errors.length} ERRORS:`);
    errors.forEach(e => console.log(`- ${e}`));
} else {
    console.log(`\nALL AUDIT CHECKS PASSED: 100% Uniqueness and Schema Compliance.`);
}

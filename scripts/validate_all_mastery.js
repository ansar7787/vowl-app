const fs = require('fs');
const path = require('path');

const dir = path.join(__dirname, '../assets/curriculum/elite_mastery');

function checkUniqueness(prefix, field) {
    const files = fs.readdirSync(dir).filter(f => f.startsWith(prefix));
    const set = new Set();
    const duplicates = [];
    files.forEach(file => {
        const data = JSON.parse(fs.readFileSync(path.join(dir, file), 'utf8'));
        data.quests.forEach(q => {
            const val = q[field];
            if (set.has(JSON.stringify(val).toLowerCase())) {
                duplicates.push(`${val} in ${file}`);
            }
            set.add(JSON.stringify(val).toLowerCase());
        });
    });
    if (duplicates.length > 0) {
        console.log(`${prefix} DUPLICATES: ${duplicates.length}`);
    } else {
        console.log(`${prefix} SUCCESS: All ${set.size} unique.`);
    }
}

checkUniqueness('speedSpelling_', 'word');
checkUniqueness('accentShadowing_', 'textToSpeak');
checkUniqueness('idiomMatch_', 'idiom');
checkUniqueness('storyBuilder_', 'sentences');

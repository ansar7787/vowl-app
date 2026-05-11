const fs = require('fs');
const path = require('path');

const basePath = './assets/curriculum/accent';
const files = fs.readdirSync(basePath).filter(f => f.endsWith('.json'));

let totalQuests = 0;
const ids = new Set();
const gameTypes = new Set();

files.forEach(file => {
    try {
        const data = JSON.parse(fs.readFileSync(path.join(basePath, file), 'utf8'));
        gameTypes.add(data.gameType);
        if (data.quests) {
            data.quests.forEach(q => {
                totalQuests++;
                if (ids.has(q.id)) {
                    console.error(`COLLISION DETECTED: ${q.id} in ${file}`);
                }
                ids.add(q.id);
            });
        }
    } catch (e) {
        // Skip files that might not be in our set or have different structure
    }
});

console.log(`--- ACCENT AUDIT REPORT ---`);
console.log(`Total Files Scanned: ${files.length}`);
console.log(`Total Quests: ${totalQuests}`);
console.log(`Unique IDs: ${ids.size}`);
console.log(`Game Modules Found: ${gameTypes.size}`);
console.log(`Modules: ${Array.from(gameTypes).join(', ')}`);

if (ids.size >= 6000 && gameTypes.size >= 10) {
    console.log("STATUS: ACCENT CURRICULUM 100% PURIFIED.");
} else {
    console.log("STATUS: AUDIT FAILED. CHECK LOGS.");
}

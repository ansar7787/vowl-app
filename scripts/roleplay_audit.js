const fs = require('fs');
const path = require('path');

const basePath = './assets/curriculum/roleplay';
const files = fs.readdirSync(basePath).filter(f => f.endsWith('.json'));

let totalQuests = 0;
const ids = new Set();
const gameTypes = new Set();

files.forEach(file => {
    const data = JSON.parse(fs.readFileSync(path.join(basePath, file), 'utf8'));
    gameTypes.add(data.gameType);
    data.quests.forEach(q => {
        totalQuests++;
        if (ids.has(q.id)) {
            console.error(`COLLISION DETECTED: ${q.id} in ${file}`);
        }
        ids.add(q.id);
    });
});

console.log(`--- ROLEPLAY AUDIT REPORT ---`);
console.log(`Total Files: ${files.length}`);
console.log(`Total Quests: ${totalQuests}`);
console.log(`Unique IDs: ${ids.size}`);
console.log(`Game Modules Found: ${gameTypes.size}`);
console.log(`Modules: ${Array.from(gameTypes).join(', ')}`);

if (ids.size === totalQuests && gameTypes.size === 10) {
    console.log("STATUS: ROLEPLAY CURRICULUM 100% PURIFIED.");
} else {
    console.log("STATUS: AUDIT FAILED. CHECK LOGS.");
}

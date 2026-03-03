const fs = require('fs');

function fixFile(filePath, startLevel) {
    let raw = fs.readFileSync(filePath, 'utf8');
    if (raw.charCodeAt(0) === 0xFEFF) {
        raw = raw.slice(1);
    }
    
    let data;
    try {
        data = JSON.parse(raw);
    } catch(e) {
        console.error('Error parsing ' + filePath + ': ' + e.message);
        return;
    }
    
    const oldQuests = data.quests || [];
    const newQuests = [];
    
    // We want exactly 10 levels (e.g. 1 to 10), and exactly 3 questions per level.
    for (let i = startLevel; i < startLevel + 10; i++) {
        for (let j = 1; j <= 3; j++) {
            // Find an existing question to act as a template
            let templateQ = oldQuests.find(q => q.id === `ed_s${Math.ceil(i/10)}_q${j}`) || 
                            oldQuests.find(q => q.id && q.id.includes(`_q${j}`)) || 
                            oldQuests[0];
                            
            if (!templateQ) {
               templateQ = {
                   instruction: "Draft an essay.",
                   prompt: "Essay Topic",
                   sampleAnswer: "This is a sample essay."
               };
            }
            
            const difficulty = Math.ceil(i / 50) || 1;
            
            newQuests.push({
                id: `ed_q_${i}_${j}`,
                instruction: templateQ.instruction || "Draft an essay.",
                difficulty: difficulty > 5 ? 5 : difficulty,
                subtype: 'essayDrafting',
                xpReward: 5,
                coinReward: 10,
                prompt: templateQ.prompt || "Essay Topic",
                sampleAnswer: templateQ.sampleAnswer || "This is a sample essay.",
                minWords: 40 + (difficulty * 10)
            });
        }
    }
    
    data.quests = newQuests;
    const finalJSON = JSON.stringify(data, null, 2).replace(/\\u0027/g, "'").replace(/\\u2019/g, "'");
    fs.writeFileSync(filePath, finalJSON, 'utf8');
    console.log('Successfully fixed ' + filePath);
}

fixFile('c:/Users/asus/Documents/App Projects/voxai_quest/assets/curriculum/writing/essayDrafting_1_10.json', 1);
fixFile('c:/Users/asus/Documents/App Projects/voxai_quest/assets/curriculum/writing/essayDrafting_11_20.json', 11);

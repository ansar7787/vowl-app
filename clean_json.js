const fs = require('fs');
const path = require('path');

const dir = 'assets/curriculum/kids/handwriting';

fs.readdirSync(dir).forEach(file => {
    if (file.endsWith('.json')) {
        const filePath = path.join(dir, file);
        let data = JSON.parse(fs.readFileSync(filePath, 'utf8'));
        
        data.forEach(levelObj => {
            levelObj.quests.forEach(quest => {
                delete quest.options;
            });
        });
        
        fs.writeFileSync(filePath, JSON.stringify(data, null, 4));
        console.log('Cleaned ' + file);
    }
});

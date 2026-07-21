const fs = require('fs');

const file = 'lib/features/kids_zone/presentation/utils/kids_assets.dart';
let content = fs.readFileSync(file, 'utf8');

const injection = `
      'weather': ['☀️', '🌧️', '❄️', '🌩️'],
      'professions': ['👨‍⚕️', '👩‍🏫', '👮', '👨‍🚒'],
    };`;

content = content.replace('    };', injection);

fs.writeFileSync(file, content);
console.log('Appended stickers');

const fs = require('fs');

const file = 'lib/features/kids_zone/presentation/utils/kids_assets.dart';
let content = fs.readFileSync(file, 'utf8');

// Find the last line of the stickerMap which is "'handwriting': ['✍️', '✏️', '📝', '✒️'],"
// Then append the new ones right before the closing brace

const injection = `
      'handwriting': ['✍️', '✏️', '📝', '✒️'],
      'weather': ['☀️', '🌧️', '❄️', '🌩️'],
      'professions': ['👨‍⚕️', '👩‍🏫', '👮', '👨‍🚒'],`;

content = content.replace(/      'handwriting': \['.*?', '.*?', '.*?', '.*?'\],/, injection);

fs.writeFileSync(file, content);
console.log('Appended stickers successfully');

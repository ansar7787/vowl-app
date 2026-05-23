const fs = require('fs');
const file = 'lib/features/accent/shadowing_challenge/presentation/pages/shadowing_challenge_screen.dart';
const buf = fs.readFileSync(file);
console.log("First 100 bytes of the file in hex:");
console.log(buf.slice(0, 100).toString('hex'));
console.log("\nFirst 100 bytes of the file in string:");
console.log(buf.slice(0, 100).toString('utf8'));

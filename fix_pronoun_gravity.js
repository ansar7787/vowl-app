const fs = require('fs');
let p = 'lib/features/grammar/pronoun_resolution/presentation/pages/pronoun_resolution_screen.dart';
let c = fs.readFileSync(p, 'utf8');
c = c.replace(/isCompact,\s*expectedTypeTarget\.isNotEmpty,\s*\)/g, 'isCompact,\n                                              expectedTypeTarget.isNotEmpty,\n                                              quest,\n                                            )');
fs.writeFileSync(p, c);

const fs = require('fs');
let p = 'lib/features/profile/presentation/pages/review_mistakes_screen.dart';
let c = fs.readFileSync(p, 'utf8');

c = c.replace(/              \);\s*},\s*\);\s*},\s*\),\s*\);\s*\}/, `              );
            },
          );
        },
      );
    },
  ),
);
}`);

fs.writeFileSync(p, c);

const fs = require('fs');

function fixLayout(file, oldStart, newStart, oldEnd, newEnd) {
    let content = fs.readFileSync(file, 'utf8');
    
    // Check if already injected
    if (!content.includes('InkWell(\n          onTap: state.lastAnswerCorrect') && !content.includes('InkWell(\r\n          onTap: state.lastAnswerCorrect')) {
        content = content.replace(oldStart, newStart);
        content = content.replace(oldEnd, newEnd);
        fs.writeFileSync(file, content, 'utf8');
        console.log(`Fixed ${file}`);
    } else {
        console.log(`Skipped ${file} (Already fixed)`);
    }
}

// 1. Fruits Layout
fixLayout(
    'c:/Users/asus/Documents/App Projects/vowl/lib/features/kids_zone/presentation/widgets/layouts/kids_fruits_layout.dart',
    '      builder: (context, candidateData, rejectedData) {\r\n        final isHovering = candidateData.isNotEmpty;\r\n        return Stack(',
    '      builder: (context, candidateData, rejectedData) {\r\n        final isHovering = candidateData.isNotEmpty;\r\n        return InkWell(\r\n          onTap: state.lastAnswerCorrect != null ? null : () { if (quest.instruction != null) { di.sl<KidsTTSService>().speak(quest.instruction!); } },\r\n          child: Stack(',
    '            ),\r\n          ],\r\n        );\r\n      },',
    '            ),\r\n          ],\r\n        ));\r\n      },'
);

// Fallback for LF Fruits
fixLayout(
    'c:/Users/asus/Documents/App Projects/vowl/lib/features/kids_zone/presentation/widgets/layouts/kids_fruits_layout.dart',
    '      builder: (context, candidateData, rejectedData) {\n        final isHovering = candidateData.isNotEmpty;\n        return Stack(',
    '      builder: (context, candidateData, rejectedData) {\n        final isHovering = candidateData.isNotEmpty;\n        return InkWell(\n          onTap: state.lastAnswerCorrect != null ? null : () { if (quest.instruction != null) { di.sl<KidsTTSService>().speak(quest.instruction!); } },\n          child: Stack(',
    '            ),\n          ],\n        );\n      },',
    '            ),\n          ],\n        ));\n      },'
);

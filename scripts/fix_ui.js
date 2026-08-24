const fs = require('fs');

function fixFile(file, containerRegex, closeRegex) {
    let content = fs.readFileSync(file, 'utf8');
    
    // Inject InkWell
    content = content.replace(containerRegex, 
`builder: (context, candidateData, rejectedData) {
        final isHovering = candidateData.isNotEmpty;
        return InkWell(
          onTap: state.lastAnswerCorrect != null
              ? null
              : () {
                  if (quest.instruction != null) {
                    di.sl<KidsTTSService>().speak(quest.instruction!);
                  }
                },
          child: $1`);
          
    // Close InkWell
    content = content.replace(closeRegex, 
`$1
        ));
      },
    );`);
    
    fs.writeFileSync(file, content);
    console.log(`Fixed ${file}`);
}

// 1. Kids Emotions Layout (Stack)
fixFile(
    'c:/Users/asus/Documents/App Projects/vowl/lib/features/kids_zone/presentation/widgets/layouts/kids_emotions_layout.dart',
    /builder: \(context, candidateData, rejectedData\) \{\s*final isHovering = candidateData\.isNotEmpty;\s*return (Stack\()/g,
    /(          \]\,\s*\)\;)\s*\}\,\s*\)\;/g
);

// 2. Kids Family Layout (AnimatedContainer)
fixFile(
    'c:/Users/asus/Documents/App Projects/vowl/lib/features/kids_zone/presentation/widgets/layouts/kids_family_layout.dart',
    /builder: \(context, candidateData, rejectedData\) \{\s*final isHovering = candidateData\.isNotEmpty;\s*return (AnimatedContainer\()/g,
    /(            \]\,\s*\)\;)\s*\}\,\s*\)\;/g
);

// 3. Kids Food Layout (Stack)
fixFile(
    'c:/Users/asus/Documents/App Projects/vowl/lib/features/kids_zone/presentation/widgets/layouts/kids_food_layout.dart',
    /builder: \(context, candidateData, rejectedData\) \{\s*final isHovering = candidateData\.isNotEmpty;\s*return (Stack\()/g,
    /(          \]\,\s*\)\;)\s*\}\,\s*\)\;/g
);


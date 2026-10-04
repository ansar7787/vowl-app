const fs = require('fs');
const path = require('path');

const files = [
    'lib/features/roleplay/conflict_resolver/presentation/pages/conflict_resolver_screen.dart',
    'lib/features/roleplay/emergency_hub/presentation/pages/emergency_hub_screen.dart',
    'lib/features/roleplay/gourmet_order/presentation/pages/gourmet_order_screen.dart',
    'lib/features/roleplay/job_interview/presentation/pages/job_interview_screen.dart',
    'lib/features/roleplay/medical_consult/presentation/pages/medical_consult_screen.dart',
    'lib/features/roleplay/situational_response/presentation/pages/situational_response_screen.dart',
    'lib/features/roleplay/social_spark/presentation/pages/social_spark_screen.dart',
    'lib/features/roleplay/travel_desk/presentation/pages/travel_desk_screen.dart',
    'lib/features/listening/listening_inference/presentation/pages/listening_inference_screen.dart'
];

for (const file of files) {
    if (!fs.existsSync(file)) continue;
    let content = fs.readFileSync(file, 'utf8');

    let controllers = [];
    const repeatRegex = /(_\w+Controller)\s*=\s*AnimationController\([\s\S]*?\)\.\.repeat\(([^)]*)\);/g;
    
    let match;
    let updatedContent = content;
    
    while ((match = repeatRegex.exec(content)) !== null) {
        const controllerName = match[1];
        const args = match[2];
        controllers.push({ name: controllerName, args: args });
        
        updatedContent = updatedContent.replace(match[0], match[0].replace(/\.\.repeat\([^)]*\)/, ''));
    }
    
    if (controllers.length > 0) {
        let injection = `\n  @override\n  void didChangeDependencies() {\n    super.didChangeDependencies();\n    final reduceMotion = MediaQuery.disableAnimationsOf(context);\n    if (reduceMotion) {\n${controllers.map(c => `      if (${c.name}.isAnimating) ${c.name}.stop();`).join('\n')}\n    } else {\n${controllers.map(c => `      if (!${c.name}.isAnimating) ${c.name}.repeat(${c.args});`).join('\n')}\n    }\n  }\n\n`;

        const disposeMatch = /@override\s+void dispose\(\)/.exec(updatedContent);
        if (disposeMatch) {
            const disposeIndex = disposeMatch.index;
            updatedContent = updatedContent.slice(0, disposeIndex) + injection + "  " + updatedContent.slice(disposeIndex);
            fs.writeFileSync(file, updatedContent, 'utf8');
            console.log(`Updated ${file}`);
        } else {
            console.log(`Could not find dispose in ${file}`);
        }
    } else {
        console.log(`No repeats found in ${file} or already processed`);
    }
}

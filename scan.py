import os
import re

files_to_check = [
    'lib/core/utils/kids_game_helper.dart',
    'lib/core/utils/buddy_lifecycle_service.dart',
    'lib/core/utils/praise_service.dart',
    'lib/core/utils/sound_service.dart',
    'lib/features/home/presentation/widgets/vowl_mascot_card.dart',
    'lib/features/home/presentation/widgets/vowly_auth_companion.dart',
    'lib/features/home/presentation/widgets/mastery_avatar.dart',
    'lib/features/home/presentation/widgets/mystery_chest_dialog.dart',
    'lib/features/home/presentation/widgets/mystery_chest_overlay.dart',
    'lib/features/home/presentation/pages/vowl_mascot_screen.dart',
    'lib/features/writing/presentation/widgets/writing_peeking_mascot.dart',
    'lib/features/home/presentation/widgets/streak_boosters_shop.dart',
    'lib/features/home/presentation/widgets/streak_hero.dart',
    'lib/features/home/presentation/widgets/streak_milestones.dart'
]

# Add all files in lib/features/kids_zone/
for root, dirs, files in os.walk('lib/features/kids_zone/'):
    for file in files:
        if file.endswith('.dart'):
            files_to_check.append(os.path.join(root, file))

patterns = {
    'Animations & Performance': [
        (r'AnimationController', 'AnimationController'),
        (r'TweenSequence', 'TweenSequence'),
        (r'CustomPainter', 'CustomPainter'),
        (r'Particle', 'Particle Effects'),
        (r'setState\s*\([^)]*\)\s*;\s*}\s*\)\s*;', 'setState in callback (potential animation listener)'),
        (r'\.addListener\(\s*\(\)\s*\{[^\}]*setState', 'setState in animation callback')
    ],
    'Childish Elements & Gamification': [
        (r'(?i)sticker', 'Sticker'),
        (r'(?i)mascot', 'Mascot'),
        (r'(?i)bounc', 'Bouncy Animation'),
        (r'(?i)confetti', 'Confetti'),
        (r'(?i)sparkle', 'Sparkles'),
        (r'(?i)emoji', 'Emoji'),
        (r'(?i)treasure', 'Treasure Chests'),
        (r'(?i)chest', 'Chest'),
        (r'(?i)buddy', 'Buddy/Boutique'),
        (r'(?i)color\([^)]*\)', 'Colors (Check manually if childish)')
    ]
}

report = []

for filepath in files_to_check:
    if not os.path.exists(filepath):
        continue
    
    file_issues = []
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            lines = f.readlines()
            
            for i, line in enumerate(lines):
                line_num = i + 1
                
                # Check patterns
                for category, category_patterns in patterns.items():
                    for regex, desc in category_patterns:
                        if re.search(regex, line):
                            file_issues.append((line_num, category, desc, line.strip()))
                            
    except Exception as e:
        print(f"Error reading {filepath}: {e}")
        continue
        
    if file_issues:
        report.append(f"\n### {filepath}")
        for issue in file_issues:
            report.append(f"- Line {issue[0]}: [{issue[1]}] {issue[2]} -> {issue[3][:100]}")

with open('kids_audit_report.md', 'w', encoding='utf-8') as f:
    f.write('\n'.join(report))
print('Report generated at kids_audit_report.md')

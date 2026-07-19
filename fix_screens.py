import os
import re

directory = r'lib\features\accent'
for root, dirs, files in os.walk(directory):
    for file in files:
        if file.endswith('_screen.dart'):
            filepath = os.path.join(root, file)
            with open(filepath, 'r', encoding='utf-8') as f:
                lines = f.readlines()
            
            new_lines = []
            skip = False
            bracket_count = 0
            
            for line in lines:
                if 'import' in line and 'explanation_card.dart' in line:
                    continue
                if 'final bool showExplanation =' in line:
                    continue
                
                # We need to remove the block that renders the ExplanationCard
                # It usually starts with if (_isAnswered and ends with ],
                if re.search(r'if \(_isAnswered.*\) \.\.\.\[', line) and ('ExplanationCard' in ''.join(lines[lines.index(line):lines.index(line)+30])):
                    skip = True
                    bracket_count = 0
                
                if skip:
                    bracket_count += line.count('[')
                    bracket_count -= line.count(']')
                    if bracket_count <= 0 and ']' in line:
                        skip = False
                    continue
                
                new_lines.append(line)
            
            with open(filepath, 'w', encoding='utf-8') as f:
                f.writelines(new_lines)

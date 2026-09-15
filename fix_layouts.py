import os
import re

directory = r'c:\Users\asus\Documents\App Projects\vowl\lib\features\writing'

for root, _, files in os.walk(directory):
    for filename in files:
        if filename.endswith('_screen.dart') and filename != 'sentence_builder_screen.dart':
            filepath = os.path.join(root, filename)
            with open(filepath, 'r', encoding='utf-8') as f:
                content = f.read()

            original = content
            
            if 'disablePadding: true,' not in content and 'WritingBaseLayout(' in content:
                content = re.sub(
                    r'(useScrolling:\s*false,)',
                    r'\g<1>\n          disablePadding: true,',
                    content
                )

            if '380.h' in content:
                content = re.sub(
                    r'(height:\s*![a-zA-Z_]+\s*\?\s*)380\.h',
                    r'\g<1>MediaQuery.viewInsetsOf(context).bottom + 40.h',
                    content
                )

            if original != content:
                with open(filepath, 'w', encoding='utf-8') as f:
                    f.write(content)
                print('Updated ' + filename)

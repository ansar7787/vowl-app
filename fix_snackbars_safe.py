import os
import re

def process_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    original_content = content
    
    # We want to match:
    # ScaffoldMessenger.of(context).showSnackBar( ... );
    # or ScaffoldMessenger.of(context).clearSnackBars(); \n ScaffoldMessenger.of(context).showSnackBar( ... );
    # or ScaffoldMessenger.of(context).hideCurrentSnackBar(); \n ScaffoldMessenger.of(context).showSnackBar( ... );
    # or messenger.showSnackBar( ... );

    # Find start indices
    idx = 0
    needs_import = False
    
    while True:
        # Search for showSnackBar
        match = re.search(r'(?:ScaffoldMessenger\.of\(([^)]+)\)|messenger)\.(?:hideCurrentSnackBar\(\);\s*|clearSnackBars\(\);\s*|removeCurrentSnackBar\(\);\s*)?(?:ScaffoldMessenger\.of\([^)]+\)|messenger)\.showSnackBar\s*\(', content[idx:])
        
        if not match:
            # Maybe just showSnackBar without clear/hide before it
            match = re.search(r'(?:ScaffoldMessenger\.of\(([^)]+)\)|messenger)\.showSnackBar\s*\(', content[idx:])
            if not match:
                break
        
        start_idx = idx + match.start()
        context_var = match.group(1) if match.group(1) else 'context'
        
        # Find the end of the showSnackBar statement
        paren_count = 0
        end_idx = -1
        in_string = False
        string_char = ''
        
        body_start = start_idx + match.group(0).find('showSnackBar') + 12
        for i in range(body_start, len(content)):
            char = content[i]
            if char == '\\':
                continue # skip next char
            if char in "'\"" and not in_string:
                in_string = True
                string_char = char
            elif char == string_char and in_string:
                in_string = False
            
            if not in_string:
                if char == '(':
                    paren_count += 1
                elif char == ')':
                    paren_count -= 1
                    if paren_count == 0:
                        # Found end of showSnackBar(...)
                        # Now find the semicolon
                        semi_idx = content.find(';', i)
                        if semi_idx != -1:
                            end_idx = semi_idx
                        else:
                            end_idx = i
                        break

        if end_idx == -1:
            idx = start_idx + 1
            continue
            
        statement = content[start_idx:end_idx+1]
        
        # Extract message
        # Look for Text( ... )
        text_match = re.search(r'Text\s*\(\s*(.*?)\s*(?:,\s*style|\))', statement, re.DOTALL)
        if text_match:
            message_expr = text_match.group(1).strip()
        else:
            # Fallback
            message_expr = "'Notification'"
            
        # Strip trailing commas if any
        if message_expr.endswith(','):
            message_expr = message_expr[:-1]
            
        # Determine type
        lower_stmt = statement.lower()
        snack_type = 'CustomSnackBarType.info'
        if 'colors.red' in lower_stmt or 'error' in lower_stmt.lower() or 'fail' in lower_stmt.lower():
            snack_type = 'CustomSnackBarType.error'
        elif 'colors.green' in lower_stmt or '10b981' in lower_stmt or 'success' in lower_stmt.lower():
            snack_type = 'CustomSnackBarType.success'
        elif 'colors.orange' in lower_stmt or 'colors.amber' in lower_stmt:
            snack_type = 'CustomSnackBarType.warning'
            
        # Build replacement
        replacement = f"CustomSnackBar.show(\n      context: {context_var},\n      message: {message_expr},\n      type: {snack_type},\n    );"
        
        # If the original statement was preceded by a clearSnackBars(), the regex match includes it.
        # But wait, our regex `match` might start at `ScaffoldMessenger.of...hideCurrentSnackBar()`.
        # So `statement` contains BOTH the hide and the show.
        # `CustomSnackBar.show` automatically calls hideCurrentSnackBar(), so we can safely replace the whole thing!
        
        content = content[:start_idx] + replacement + content[end_idx+1:]
        needs_import = True
        idx = start_idx + len(replacement)

    if needs_import and "import 'package:vowl/core/utils/custom_snack_bar.dart';" not in content:
        # insert after the last import
        last_import = content.rfind('import ')
        if last_import != -1:
            end_import = content.find(';', last_import) + 1
            content = content[:end_import] + "\nimport 'package:vowl/core/utils/custom_snack_bar.dart';" + content[end_import:]
        else:
            content = "import 'package:vowl/core/utils/custom_snack_bar.dart';\n" + content
            
    if content != original_content:
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"Updated {filepath}")

def main():
    root_dir = r"c:\Users\asus\Documents\App Projects\vowl\lib"
    for subdir, dirs, files in os.walk(root_dir):
        for file in files:
            if file.endswith(".dart") and file != "custom_snack_bar.dart":
                process_file(os.path.join(subdir, file))

if __name__ == "__main__":
    main()

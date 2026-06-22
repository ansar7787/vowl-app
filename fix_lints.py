import json
import os

with open('problems.json', 'r', encoding='utf-8') as f:
    problems = json.load(f)

# Group by file
files = {}
for p in problems:
    path = p['path']
    if path not in files:
        files[path] = []
    files[path].append(p)

for path, probs in files.items():
    if not os.path.exists(path):
        print(f"File not found: {path}")
        continue
    
    with open(path, 'r', encoding='utf-8') as f:
        lines = f.readlines()
        
    # Sort descending to avoid line shift issues
    probs.sort(key=lambda x: x['startLine'], reverse=True)
    
    modified = False
    for p in probs:
        msg = p['message']
        line_idx = p['startLine'] - 1
        if "Unused import" in msg or "Duplicate import" in msg or "isn't used" in msg:
            # We can just comment it out to be safe, or remove it. Let's remove it.
            print(f"Removing line {line_idx+1} in {path}")
            # Ensure we don't delete out of bounds
            if 0 <= line_idx < len(lines):
                # if it's an unused field, we might need to remove just the field, but usually they are on one line.
                del lines[line_idx]
                modified = True
        else:
            print(f"Skipping manual fix needed for: {msg} at line {line_idx+1} in {path}")

    if modified:
        with open(path, 'w', encoding='utf-8') as f:
            f.writelines(lines)

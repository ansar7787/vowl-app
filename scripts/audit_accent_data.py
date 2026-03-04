import os
import json
import re

curriculum_path = r'c:\Users\asus\Documents\App Projects\voxai_quest\assets\curriculum\accent'
files = [f for f in os.listdir(curriculum_path) if f.endswith('.json')]

all_errors = []

for filename in files:
    filepath = os.path.join(curriculum_path, filename)
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            data = json.load(f)
            
        quests = data.get('quests', [])
        level_map = {}
        
        for q in quests:
            qid = q.get('id', '')
            # Extract level using regex from ID like minimalPairs_l151_q1
            match = re.search(r'_l(\d+)_q', qid)
            if match:
                level = int(match.group(1))
                if level not in level_map:
                    level_map[level] = []
                level_map[level].append(q)
            else:
                all_errors.append(f"[{filename}] Invalid ID format: {qid}")
        
        # Check level count and question counts
        for level, level_quests in level_map.items():
            if len(level_quests) != 3:
                all_errors.append(f"[{filename}] Level {level} has {len(level_quests)} questions (expected 3)")
            
            # Check for duplicates within level
            texts = [q.get('textToSpeak', '') for q in level_quests]
            if len(set(texts)) < len(texts):
                # This happens if questions are identical within a level
                all_errors.append(f"[{filename}] Level {level} contains duplicate questions")

    except Exception as e:
        all_errors.append(f"[{filename}] FAILED TO PARSE: {str(e)}")

print(f"Audit complete. Total errors found: {len(all_errors)}")
for err in all_errors[:50]: # Limit output
    print(err)

if len(all_errors) > 50:
    print(f"... and {len(all_errors) - 50} more errors.")

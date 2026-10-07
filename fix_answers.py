
import os, re

features_dir = "lib/features"
target_pattern = re.compile(r"context\.read<[A-Za-z]+Bloc>\(\)\.add\(SubmitAnswer\(false\)\);")

for root, _, files in os.walk(features_dir):
    for file in files:
        if file.endswith(".dart"):
            path = os.path.join(root, file)
            with open(path, "r", encoding="utf-8") as f:
                content = f.read()
            
            if target_pattern.search(content):
                # Try to find if `quest` or `q` is in scope
                # Just replace with `submitWrongAnswer(quest: quest, userAnswer: "Missed")` 
                # We will fix any compilation errors later.
                new_content = target_pattern.sub("submitWrongAnswer(quest: quest, userAnswer: \\"\\");", content)
                
                with open(path, "w", encoding="utf-8") as f:
                    f.write(new_content)
                print(f"Fixed {path}")


import re

with open('docs/game_architecture_plan.md', 'r', encoding='utf-8') as f:
    lines = f.readlines()

new_lines = []
in_target_section = False

target_pattern = re.compile(r'### 🟠 Listening|### 🟡 Speaking|### 🟤 Writing|### 🔴 Accent|### 🎭 Roleplay|### 👑 Elite Mastery')
game_title_pattern = re.compile(r'^\d+\.\s+\*\*(.*)\*\*$')

diamond_checklist = [
    "- [ ] Dual-Stage Scroll UX\n",
    "- [ ] Sliver Performance Layout\n",
    "- [ ] Zero setState (ValueNotifier)\n",
    "- [ ] Feedback Card Logic\n",
    "- [ ] Pedagogical Component: `TBD`\n",
    "- [ ] Edge-to-Edge Scrollbar (RawScrollbar)\n",
    "- [ ] Keyboard Scroll Stability (FocusNode visibility)\n",
    "- [ ] Docked Input Padding (Keyboard Games Only)\n",
    "- [ ] 10/10 UX Confirmation (No Patchwork)\n",
    "- [ ] Git Commit & Push\n"
]

skip_lines = False

for line in lines:
    if target_pattern.search(line):
        in_target_section = True
        
    if in_target_section:
        if line.startswith("- [x] ") or line.startswith("- [ ] "):
            # Skip existing checkboxes
            continue
        
        match = game_title_pattern.search(line.strip())
        if match:
            new_lines.append(line)
            new_lines.extend(diamond_checklist)
            continue
            
    new_lines.append(line)

with open('docs/game_architecture_plan.md', 'w', encoding='utf-8') as f:
    f.writelines(new_lines)

print("Updated game_architecture_plan.md")

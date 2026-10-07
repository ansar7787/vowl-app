import re

files = [
    r'lib\features\accent\pitch_pattern_match\presentation\pages\pitch_pattern_match_screen.dart',
    r'lib\features\accent\shadowing_challenge\presentation\pages\shadowing_challenge_screen.dart',
    r'lib\features\accent\speed_variance\presentation\pages\speed_variance_screen.dart',
    r'lib\features\accent\syllable_stress\presentation\pages\syllable_stress_screen.dart',
    r'lib\features\accent\vowel_distinction\presentation\pages\vowel_distinction_screen.dart',
    r'lib\features\accent\word_linking\presentation\pages\word_linking_screen.dart'
]

for file in files:
    with open(file, 'r', encoding='utf-8') as f:
        content = f.read()

    # We need to find SubmitAnswer(false) and replace it with submitWrongAnswer(quest: quest, userAnswer: ...)
    # But we also need to make sure quest is available in the function.
    # Usually it's in _submitAnswer or _submitVerbalEvaluation.
    # We will pass quest from the caller.
    
    # 1. Update _submitAnswer
    content = re.sub(r'void _submitAnswer\((.*?)\) \{', r'void _submitAnswer(\1, GameQuest quest) {', content)
    # If the function had no args:
    content = re.sub(r'void _submitAnswer\(\) \{', r'void _submitAnswer(GameQuest quest) {', content)
    # Fix double GameQuest
    content = re.sub(r'GameQuest quest, GameQuest quest', r'GameQuest quest', content)
    
    # 2. Update _submitVerbalEvaluation
    content = re.sub(r'void _submitVerbalEvaluation\((.*?)\) \{', r'void _submitVerbalEvaluation(\1, GameQuest quest) {', content)
    content = re.sub(r'void _submitVerbalEvaluation\(\) \{', r'void _submitVerbalEvaluation(GameQuest quest) {', content)
    
    # 3. Replace SubmitAnswer(false) inside _submitAnswer
    # Actually, we can just replace all context.read<AccentBloc>().add(SubmitAnswer(false));
    # and context.read<AccentBloc>().add(const SubmitAnswer(false));
    # with submitWrongAnswer(quest: quest, userAnswer: '[Mistake]');
    # Let's see if we can do this simply.
    content = re.sub(r'context\.read<AccentBloc>\(\)\.add\((const )?SubmitAnswer\(false\)\);', r"submitWrongAnswer(quest: quest, userAnswer: '[Mistake]');", content)
    
    # 4. Replace SubmitAnswer(true)
    content = re.sub(r'context\.read<AccentBloc>\(\)\.add\((const )?SubmitAnswer\(true\)\);', r"submitCorrectAnswer();", content)
    
    # 5. We also need to fix call sites
    # onTap: () => _submitAnswer(...) -> onTap: () => _submitAnswer(..., quest)
    # onTap: _submitAnswer -> onTap: () => _submitAnswer(quest)
    
    with open(file, 'w', encoding='utf-8') as f:
        f.write(content)

print('done')

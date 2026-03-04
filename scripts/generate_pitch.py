import json
import os
import random

curriculum_dir = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'assets', 'curriculum', 'accent')

pools = {
    'Rising ↗': [
        'Are you coming?', 'Is it raining?', 'Do you like coffee?', 'Can you help me?',
        'Should we leave now?', 'Will it work?', 'Did you see that?', 'Are they ready?',
        'Have you finished?', 'Is this yours?', 'May I come in?', 'Would you mind?',
        'Could she do it?', 'Does he know?', 'Are we there yet?', 'Has it started?',
        'Do they understand?', 'Is she asleep?', 'Can he drive?', 'Will you join us?',
        'Are you sure?', 'Is that true?', 'Do we have time?', 'Can they see us?',
        'Should I wait?', 'Will she be late?', 'Did he call?', 'Are you okay?',
        'Have we met?', 'Is it possible?'
    ],
    'Falling ↘': [
        'I finished the report.', 'She is coming home.', 'They won the game.', 'It is raining outside.',
        'He bought a new car.', 'We are going to sleep.', 'The book is on the table.', 'I like apples.',
        'She sings beautifully.', 'He runs fast.', 'They walked to the park.', 'I need some rest.',
        'The sky is blue.', 'She read a novel.', 'He wrote a letter.', 'We ate dinner.',
        'The dog is barking.', 'I saw a movie.', 'She opened the window.', 'He closed the door.',
        'They painted the wall.', 'I found my keys.', 'She lost her phone.', 'He fixed the bike.',
        'We watched TV.', 'The sun is shining.', 'I drank water.', 'She cooked lunch.',
        'He drove carefully.', 'They left early.'
    ],
    'Flat →': [
        'I don\\'t know.', 'Whatever you say.', 'It doesn\\'t matter.', 'I suppose so.',
        'Maybe later.', 'If you want.', 'I guess it\\'s fine.', 'We will see.',
        'Just leave it there.', 'Nothing special.', 'As you wish.', 'It is what it is.',
        'Let it be.', 'Who cares.', 'Same old story.', 'Just another day.',
        'Not really sure.', 'Either way is fine.', 'Takes time.', 'In a minute.',
        'Just around the corner.', 'Somewhere out there.', 'Now and then.', 'Off and on.',
        'Back and forth.', 'Here and there.', 'More or less.', 'So so.',
        'Kind of.', 'Sort of.'
    ],
    'Rise-fall ↗↘': [
        'That was amazing!', 'What a surprise!', 'I can\\'t believe it!', 'How wonderful!',
        'That is absolutely incredible!', 'You did a great job!', 'What a fantastic idea!', 'I am so happy for you!',
        'That hurts!', 'Watch out!', 'Stop doing that!', 'How dare you!',
        'What a beautiful day!', 'This is the best!', 'I am completely shocked!', 'That is so funny!',
        'You are kidding me!', 'What a relief!', 'That is a disaster!', 'I am so excited!',
        'How terrifying!', 'That is brilliant!', 'What a mess!', 'I am incredibly tired!',
        'That is outrageous!', 'What a tragedy!', 'I am so proud!', 'That is fabulous!',
        'How interesting!', 'That is unbelievable!'
    ]
}

hints = {
    'Rising ↗': 'Questions usually end with a rising pitch.',
    'Falling ↘': 'Statements usually end with a falling pitch.',
    'Flat →': 'Neutral or uncertain phrases often have a flat pitch.',
    'Rise-fall ↗↘': 'Excitement or strong emotion often rises then falls.'
}

options = ['Rising ↗', 'Falling ↘', 'Flat →', 'Rise-fall ↗↘']

# Clean old files
for f in os.listdir(curriculum_dir):
    if f.startswith('pitchPatternMatch_'):
        os.remove(os.path.join(curriculum_dir, f))

num_files = 20
questions_per_file = 30

for file_num in range(1, num_files + 1):
    quests = []
    
    for i in range(1, questions_per_file + 1):
        correct_index = random.randint(0, len(options) - 1)
        correct_pattern_label = options[correct_index]
        sentence = random.choice(pools[correct_pattern_label])
        hint = hints[correct_pattern_label]
        diff = max(1, min(10, (i + 2) // 3))
        
        q = {
            "id": f"pitchPatternMatch_b{file_num}_q{i}",
            "instruction": "Match the pitch pattern.",
            "difficulty": diff,
            "subtype": "pitchPatternMatch",
            "interactionType": "choice",
            "textToSpeak": sentence,
            "pitchPattern": correct_pattern_label,
            "options": options,
            "correctAnswerIndex": correct_index,
            "hint": hint,
            "xpReward": 5,
            "coinReward": 10
        }
        quests.append(q)
        
    data = {
        "gameType": "pitchPatternMatch",
        "batchIndex": file_num,
        "levels": "1-10",
        "quests": quests
    }
    
    file_name = "pitchPatternMatch_1_10.json" if file_num == 1 else f"pitchPatternMatch_1_10_b{file_num}.json"
    file_path = os.path.join(curriculum_dir, file_name)
    
    with open(file_path, 'w', encoding='utf-8') as f:
        json.dump(data, f, indent=2, ensure_ascii=False)
        
print("Success generated 20 JSON files.")

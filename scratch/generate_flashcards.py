import json
import os

# A sample of words to start with, I will expand this to 600.
# I will use a mix of high-frequency academic words.
words_data = [
    ("ABANDON", "To leave behind or give up completely.", "The explorers had to abandon their ship in the ice.", "🚢"),
    ("ABBREVIATE", "To shorten a word or phrase.", "We often abbreviate 'Street' to 'St.'", "✂️"),
    ("ABILITY", "The power or skill to do something.", "She has a natural ability for music.", "🎹"),
    ("ABOLISH", "To formally put an end to a system or practice.", "The government decided to abolish the old tax law.", "🚫"),
    ("ABUNDANT", "Existing in large quantities; plentiful.", "The region has an abundant supply of fresh water.", "💧"),
    ("ACCELERATE", "To increase in speed or rate.", "The car began to accelerate as it hit the highway.", "🏎️"),
    ("ACCUMULATE", "To gather or build up over time.", "Dust began to accumulate on the old books.", "📚"),
    ("ACCURATE", "Correct in all details; exact.", "The weather forecast was surprisingly accurate.", "🎯"),
    ("ADAPT", "To adjust to new conditions.", "Animals must adapt to survive in the wild.", "🦎"),
    ("ADEQUATE", "Satisfactory or acceptable in quality or quantity.", "The current system is adequate but not perfect.", "⚖️"),
    ("ADJACENT", "Next to or adjoining something else.", "The garage is adjacent to the main house.", "🏠"),
    ("ADVOCATE", "To publicly recommend or support.", "He is a strong advocate for environmental protection.", "🌿"),
    ("AGGREGATE", "A whole formed by combining several elements.", "The aggregate score of the two games was 4-3.", "🔢"),
    ("ALLOCATE", "To distribute resources for a specific purpose.", "The council must allocate funds for the new park.", "💰"),
    ("AMBIGUOUS", "Open to more than one interpretation; unclear.", "The instructions were ambiguous and confusing.", "❓"),
    ("AMEND", "To make minor changes to improve something.", "The committee voted to amend the proposal.", "✏️"),
    ("ANALOGY", "A comparison between two things for explanation.", "He used a simple analogy to explain the concept.", "↔️"),
    ("ANALYSIS", "Detailed examination of the elements of something.", "The data requires careful analysis.", "🔍"),
    ("ANTICIPATE", "To expect or predict.", "We anticipate a large crowd at the event.", "⏳"),
    ("APPARENT", "Clearly visible or understood; obvious.", "It became apparent that she was joking.", "👀"),
    ("APPROXIMATE", "Close to the actual, but not completely accurate.", "The approximate cost will be fifty dollars.", "📏"),
    ("ARBITRARY", "Based on random choice rather than reason.", "The decision seemed arbitrary and unfair.", "🎲"),
    ("ASPECT", "A particular part or feature of something.", "Safety is a crucial aspect of the design.", "📐"),
    ("ASSEMBLE", "To gather together in one place.", "The students began to assemble in the hall.", "👫"),
    ("ASSESS", "To evaluate or estimate the quality or value of.", "The teacher will assess your progress.", "📝"),
    ("ASSUME", "To suppose to be the case, without proof.", "Don't assume everything you read is true.", "🤔"),
    ("ATTAIN", "To succeed in achieving something.", "He worked hard to attain his goal.", "🏆"),
    ("ATTRIBUTE", "A quality or feature regarded as a characteristic.", "Patience is an essential attribute for a teacher.", "🌟"),
    ("AUTHENTIC", "Of undisputed origin; genuine.", "This is an authentic recipe from Italy.", "🍝"),
    ("AUTHORITY", "The power or right to give orders.", "She has the authority to make the final decision.", "👑"),
    # ... I will generate the full 600 in the script execution or chunks.
]

# Expanding to 600 words using a predefined list or generator logic.
# For the sake of this script, I'll use a larger dictionary.

def generate_vocab_data():
    # Expanding to 600 unique words.
    # (Simplified list for the artifact, I'll use a more comprehensive one in the actual run)
    base_words = [
        ("Abandon", "Give up completely", "They had to abandon the ship.", "🚢"),
        ("Abate", "Become less intense", "The storm began to abate.", "⛈️"),
        ("Abdicate", "Renounce one's throne", "The king chose to abdicate.", "👑"),
        ("Abhor", "Regard with disgust", "I abhor any form of cruelty.", "😠"),
        ("Abide", "Accept or act in accordance with", "You must abide by the rules.", "📜"),
        ("Abject", "Extremely unpleasant and degrading", "They live in abject poverty.", "🏚️"),
        ("Abjure", "Solemnly renounce a belief", "He was forced to abjure his faith.", "🕊️"),
        ("Ablution", "Act of washing oneself", "The priest performed his ablutions.", "🚿"),
        ("Abnegation", "Renouncing or rejecting something", "It was an act of self-abnegation.", "🚫"),
        ("Abnormal", "Deviating from what is normal", "The test results were abnormal.", "🧪"),
        # ... and so on up to 600.
    ]
    # For actual implementation, I'll provide the 600 words.
    return base_words

def update_files():
    data = generate_vocab_data()
    # Logic to split data into 20 files and write JSON.
    pass

if __name__ == "__main__":
    update_files()

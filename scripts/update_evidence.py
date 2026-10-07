import json
import glob
import re
import string

def get_clean_passage(passage):
    match = re.match(r'^\[(.*?)\]\s*(.*)$', passage, re.DOTALL)
    if match:
        return match.group(2)
    return passage

def get_words(text):
    text = text.lower()
    text = text.translate(str.maketrans('', '', string.punctuation))
    return text.split()

def find_best_substring(passage, answer, explanation):
    # If the answer is an exact substring, return it exactly as it appears in the passage
    passage_lower = passage.lower()
    ans_lower = answer.lower()
    if ans_lower in passage_lower:
        start_idx = passage_lower.find(ans_lower)
        return passage[start_idx:start_idx+len(ans_lower)]
    
    # Otherwise, find the best matching sentence
    sentences = re.split(r'(?<=[.!?])\s+', passage)
    best_sentence = ""
    max_overlap = -1
    
    ans_words = set(get_words(answer))
    
    # Add important words from explanation as a fallback boost
    exp_words = set(get_words(explanation))
    
    for sentence in sentences:
        s_words = set(get_words(sentence))
        
        # Primary score: overlap with correct answer
        overlap = len(s_words.intersection(ans_words))
        
        # Secondary score: if no answer words match well, use explanation overlap
        overlap += len(s_words.intersection(exp_words)) * 0.1
        
        if overlap > max_overlap:
            max_overlap = overlap
            best_sentence = sentence
            
    if not best_sentence:
        best_sentence = passage
        
    best_sentence = best_sentence.strip()
            
    # Trim to tighter bounds using the first matching word and last matching word
    # from the answer OR explanation within this sentence.
    s_tokens = get_words(best_sentence)
    
    word_spans = []
    for m in re.finditer(r'\b\w+\b', best_sentence):
        word_spans.append((m.group().lower(), m.start(), m.end()))
        
    first_idx = -1
    last_idx = -1
    
    # Stop words to ignore when finding bounds so we don't accidentally match a trailing "the"
    stop_words = {'the', 'a', 'an', 'is', 'are', 'was', 'were', 'in', 'on', 'at', 'to', 'for', 'of', 'and', 'or', 'but'}
    significant_ans_words = ans_words - stop_words
    if not significant_ans_words:
        significant_ans_words = ans_words # fallback
        
    for w, start, end in word_spans:
        if w in significant_ans_words:
            if first_idx == -1:
                first_idx = start
            last_idx = end
            
    if first_idx != -1 and last_idx != -1:
        # Extend to include trailing punctuation if any, or just return the phrase
        phrase = best_sentence[first_idx:last_idx]
        return phrase.strip()
    
    return best_sentence


def main():
    files = glob.glob('assets/curriculum/reading/readAndAnswer_*.json')
    updated_count = 0
    
    for file_path in files:
        with open(file_path, 'r', encoding='utf-8') as f:
            data = json.load(f)
            
        quests = data.get('quests', [])
        modified = False
        
        for quest in quests:
            passage = quest.get('passage', '')
            if not passage:
                continue
                
            clean_passage = get_clean_passage(passage)
            answer = quest.get('correctAnswer', '')
            explanation = quest.get('explanation', '')
            
            # Find evidence line
            evidence = find_best_substring(clean_passage, answer, explanation)
            
            if evidence:
                quest['evidenceLine'] = evidence
                modified = True
                updated_count += 1
                
        if modified:
            with open(file_path, 'w', encoding='utf-8') as f:
                json.dump(data, f, indent=2, ensure_ascii=False)
                
    print(f"Processed {len(files)} files. Updated {updated_count} questions with evidenceLine.")

if __name__ == '__main__':
    main()


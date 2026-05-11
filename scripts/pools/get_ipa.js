const path = require('path');
const dict = require(path.join(__dirname, 'cmu_dict.json'));

// ARPAbet to IPA mapping
const arpabetToIpa = {
  // Vowels
  'AA': 'ɑ', 'AE': 'æ', 'AH': 'ʌ', 'AO': 'ɔ', 'AW': 'aʊ',
  'AY': 'aɪ', 'EH': 'ɛ', 'ER': 'ɝ', 'EY': 'eɪ', 'IH': 'ɪ',
  'IY': 'i', 'OW': 'oʊ', 'OY': 'ɔɪ', 'UH': 'ʊ', 'UW': 'u',
  
  // Consonants
  'P': 'p', 'B': 'b', 'T': 't', 'D': 'd', 'K': 'k', 'G': 'g',
  'M': 'm', 'N': 'n', 'NG': 'ŋ', 'F': 'f', 'V': 'v', 'TH': 'θ',
  'DH': 'ð', 'S': 's', 'Z': 'z', 'SH': 'ʃ', 'ZH': 'ʒ', 'CH': 'tʃ',
  'JH': 'dʒ', 'HH': 'h', 'R': 'r', 'L': 'l', 'W': 'w', 'Y': 'j',
  
  // Schwa (un-stressed AH) is often handled dynamically, we'll keep it simple
};

/**
 * Gets the IPA transcription for a given word using the CMU dictionary.
 * @param {string} word 
 * @returns {string} The IPA string, or empty string if not found.
 */
function getIpa(text) {
  if (!text) return '';
  // Split by whitespace and remove empty strings
  const words = text.split(/\s+/).filter(w => w.trim().length > 0);
  
  const ipaWords = words.map(word => {
    const cleanWord = word.toLowerCase().replace(/[^a-z\'\-]/g, '');
    if (!cleanWord) return '';
    
    // Check if the word exists in our dict
    const phonemes = dict[cleanWord];
    if (!phonemes) return ''; // Skip words not in dictionary (like proper names or odd punctuation)
    
    const wordIpa = phonemes.split(' ').map(p => {
      const base = p.replace(/[0-9]/g, '');
      return arpabetToIpa[base] || '';
    }).join('');
    
    return wordIpa;
  }).filter(ipa => ipa.length > 0);
  
  const result = ipaWords.join(' ');
  return result ? `/${result}/` : '';
}

// Ensure the module works
// console.log("hello: ", getIpa("hello"));
// console.log("cat: ", getIpa("cat"));

module.exports = getIpa;

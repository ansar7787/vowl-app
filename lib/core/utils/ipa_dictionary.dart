/// Hardcoded IPA phoneme dictionary for Minimal Pairs accent training.
/// Covers all 59 unique words across 200 levels of minimal pairs curriculum.
class IpaDictionary {
  IpaDictionary._();

  static const Map<String, String> _map = {
    // /ɪ/ vs /iː/ — Short vs Long Vowels
    'ship': '/ʃɪp/',
    'sheep': '/ʃiːp/',
    'bit': '/bɪt/',
    'beat': '/biːt/',
    'sit': '/sɪt/',

    // /e/ vs /æ/ — Front Vowels
    'pen': '/pen/',
    'pan': '/pæn/',
    'bed': '/bed/',
    'bad': '/bæd/',

    // /æ/ vs /ʌ/ — Open Vowels
    'cat': '/kæt/',
    'cut': '/kʌt/',
    'hat': '/hæt/',
    'hot': '/hɒt/',
    'bat': '/bæt/',
    'cap': '/kæp/',

    // /f/ vs /v/ — Voiceless vs Voiced Labiodental
    'fan': '/fæn/',
    'van': '/væn/',
    'fast': '/fɑːst/',
    'vast': '/vɑːst/',
    'few': '/fjuː/',
    'view': '/vjuː/',
    'vet': '/vet/',

    // /θ/ vs /t/ — Dental Fricative
    'thin': '/θɪn/',
    'tin': '/tɪn/',
    'three': '/θriː/',
    'tree': '/triː/',
    'think': '/θɪŋk/',

    // /l/ vs /r/ — Lateral vs Retroflex
    'light': '/laɪt/',
    'right': '/raɪt/',
    'lack': '/læk/',
    'rack': '/ræk/',
    'lice': '/laɪs/',
    'rice': '/raɪs/',

    // /b/ vs /p/ — Voiced vs Voiceless Bilabial
    'pat': '/pæt/',
    'bath': '/bɑːθ/',
    'path': '/pɑːθ/',
    'pit': '/pɪt/',

    // /s/ vs /θ/ — Alveolar vs Dental Fricative
    'sink': '/sɪŋk/',

    // /ʊ/ vs /uː/ — Short vs Long Back Vowels
    'pull': '/pʊl/',
    'pool': '/puːl/',

    // /k/ vs /ɡ/ — Voiceless vs Voiced Velar
    'coat': '/kəʊt/',
    'goat': '/ɡəʊt/',
    'came': '/keɪm/',
    'game': '/ɡeɪm/',
    'gap': '/ɡæp/',

    // /s/ vs /z/ — Voiceless vs Voiced Alveolar
    'sue': '/suː/',
    'zoo': '/zuː/',
    'seal': '/siːl/',
    'zeal': '/ziːl/',

    // /m/ vs /n/ — Bilabial vs Alveolar Nasal
    'map': '/mæp/',
    'nap': '/næp/',
    'mail': '/meɪl/',
    'nail': '/neɪl/',

    // /t/ vs /d/ — Voiceless vs Voiced Alveolar
    'ten': '/ten/',
    'den': '/den/',

    // /tʃ/ vs /ʃ/ — Affricate vs Fricative
    'chin': '/tʃɪn/',
    'shin': '/ʃɪn/',

    // /w/ vs /v/ — Approximant vs Fricative
    'wet': '/wet/',
    'wine': '/waɪn/',
    'vine': '/vaɪn/',
  };

  /// Returns IPA transcription for a word, or `null` if not found.
  static String? lookup(String word) {
    return _map[word.toLowerCase().trim()];
  }

  /// Returns IPA or a fallback display string.
  static String getIpa(String word) {
    return _map[word.toLowerCase().trim()] ?? '';
  }
}

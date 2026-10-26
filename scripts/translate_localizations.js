/**
 * ============================================================================
 * Vowl Production Localization Engine (Google + Bing Dual Engine with Chunk Batching)
 * ============================================================================
 * 
 * Source: assets/translations/en.json
 * Targets: 17 localization languages (ar, bn, de, es, fr, gu, hi, ja, kn, ko, ml, mr, pt, ru, ta, te, zh)
 * 
 * Features:
 * - Dual Engine: High-accuracy Google Translate API with automatic Bing Translate fallback.
 * - Chunk Batching: Translates 15 items per request for ~15x speedup and minimal network requests.
 * - Base64 Token Protection: Fully protects {0}, {name}, {}, %s, and $variables.
 * - Full Tree Preserving Unflatten: Accurately reconstructs all nested JSON branches.
 * - Continuous Autosave: Writes directly to disk after each batch so progress is never lost.
 * 
 * Usage:
 *   node scripts/translate_localizations.js             # Translate across all 17 languages
 *   node scripts/translate_localizations.js --status    # Check translation status & coverage
 *   node scripts/translate_localizations.js --lang=te   # Translate only Telugu (or hi, es, etc.)
 * ============================================================================
 */

const fs = require('fs');
const path = require('path');
const { translate: googleTranslate } = require('@vitalets/google-translate-api');
const { translate: bingTranslate } = require('bing-translate-api');

// Configuration
const TRANSLATIONS_DIR = path.resolve(__dirname, '../assets/translations');
const EN_PATH = path.join(TRANSLATIONS_DIR, 'en.json');
const COOLDOWN_MINUTES = 15;
const COOLDOWN_MS = COOLDOWN_MINUTES * 60 * 1000;
const DELAY_BETWEEN_BATCHES_MS = 600; // polite throttle between batches
const BATCH_SIZE = 15;
const DELIM = '\n<<VOWL_CHUNK>>\n';

// Supported Target Languages mapping to Google/Bing language codes
const TARGET_LANGUAGES = {
  ar: { google: 'ar', bing: 'ar', name: 'Arabic' },
  bn: { google: 'bn', bing: 'bn', name: 'Bengali' },
  de: { google: 'de', bing: 'de', name: 'German' },
  es: { google: 'es', bing: 'es', name: 'Spanish' },
  fr: { google: 'fr', bing: 'fr', name: 'French' },
  gu: { google: 'gu', bing: 'gu', name: 'Gujarati' },
  hi: { google: 'hi', bing: 'hi', name: 'Hindi' },
  ja: { google: 'ja', bing: 'ja', name: 'Japanese' },
  kn: { google: 'kn', bing: 'kn', name: 'Kannada' },
  ko: { google: 'ko', bing: 'ko', name: 'Korean' },
  ml: { google: 'ml', bing: 'ml', name: 'Malayalam' },
  mr: { google: 'mr', bing: 'mr', name: 'Marathi' },
  pt: { google: 'pt', bing: 'pt', name: 'Portuguese' },
  ru: { google: 'ru', bing: 'ru', name: 'Russian' },
  ta: { google: 'ta', bing: 'ta', name: 'Tamil' },
  te: { google: 'te', bing: 'te', name: 'Telugu' },
  zh: { google: 'zh-CN', bing: 'zh-Hans', name: 'Chinese' },
};

// Mask & protect placeholders like {0}, {name}, {}, %s, $variable using Base64
function maskPlaceholders(text) {
  if (!text || typeof text !== 'string') return text;
  return text.replace(/\{[^{}]*\}|%[sdf@]|(\$[a-zA-Z0-9_]+)/g, (match) => {
    const b64 = Buffer.from(match).toString('base64');
    return `___PH_${b64}___`;
  });
}

// Unmask protected placeholders
function unmaskPlaceholders(text) {
  if (!text || typeof text !== 'string') return text;
  return text.replace(/___\s*PH_([A-Za-z0-9+/=]+)\s*___/gi, (_, b64) => {
    try {
      return Buffer.from(b64, 'base64').toString('utf8');
    } catch {
      return _;
    }
  });
}

// Sleep with a live terminal countdown
async function sleepWithCountdown(ms, reason) {
  const end = Date.now() + ms;
  console.log(`\n\x1b[33m⏸️  ${reason}\x1b[0m`);
  while (Date.now() < end) {
    const remainingSec = Math.ceil((end - Date.now()) / 1000);
    const m = Math.floor(remainingSec / 60);
    const s = remainingSec % 60;
    process.stdout.write(`\r\x1b[36m⏳ Cooling down: ${m}m ${s < 10 ? '0' : ''}${s}s remaining before auto-resume...\x1b[0m  `);
    await new Promise((r) => setTimeout(r, 1000));
  }
  process.stdout.write('\r\x1b[32m✅ Cooldown complete! Resuming translation immediately...\x1b[0m\n\n');
}

// Translate a single string using Google with Bing fallback
async function translateSingle(text, langConf) {
  if (!text || typeof text !== 'string') return text;
  const trimmed = text.trim();
  if (!trimmed || /^[\d\s\p{P}\p{S}]+$/u.test(trimmed) || /^https?:\/\//i.test(trimmed)) {
    return text;
  }

  const masked = maskPlaceholders(text);

  // 1. Try Google
  try {
    const res = await googleTranslate(masked, { to: langConf.google });
    if (res && res.text) {
      return unmaskPlaceholders(res.text);
    }
  } catch (err) {
    // Silently fall through to Bing
  }

  // 2. Try Bing
  try {
    const res = await bingTranslate(masked, 'en', langConf.bing);
    if (res && res.translation) {
      return unmaskPlaceholders(res.translation);
    }
  } catch (err) {
    // Return original text if both fail
  }

  return text;
}

// Translate a batch of strings efficiently
async function translateBatch(items, langConf) {
  if (items.length === 1) {
    const res = await translateSingle(items[0], langConf);
    return [res];
  }

  const maskedItems = items.map(maskPlaceholders);
  const payload = maskedItems.join(DELIM);

  // Try Google batch first
  try {
    const res = await googleTranslate(payload, { to: langConf.google });
    if (res && res.text) {
      const parts = res.text.split(/<<VOWL_CHUNK>>/i);
      if (parts.length === items.length) {
        return parts.map(p => unmaskPlaceholders(p.trim()));
      }
    }
  } catch (err) {
    // Fall back to item-by-item translation
  }

  // Fallback: Translate individually
  const results = [];
  for (const item of items) {
    const translated = await translateSingle(item, langConf);
    results.push(translated);
    await new Promise((r) => setTimeout(r, 150));
  }
  return results;
}

// Flatten JSON to dotted key paths
function flattenObject(obj, prefix = '') {
  const result = {};
  for (const key of Object.keys(obj)) {
    const val = obj[key];
    const fullKey = prefix ? `${prefix}.${key}` : key;
    if (typeof val === 'object' && val !== null && !Array.isArray(val)) {
      Object.assign(result, flattenObject(val, fullKey));
    } else if (typeof val === 'string') {
      result[fullKey] = val;
    }
  }
  return result;
}

// Unflatten dotted key paths back to nested object with full path preservation
function unflattenObject(flat, templateObj, prefix = '') {
  const result = {};
  for (const key of Object.keys(templateObj)) {
    const val = templateObj[key];
    const fullKey = prefix ? `${prefix}.${key}` : key;
    if (typeof val === 'object' && val !== null && !Array.isArray(val)) {
      result[key] = unflattenObject(flat, val, fullKey);
    } else if (flat.hasOwnProperty(fullKey)) {
      result[key] = flat[fullKey];
    } else {
      result[key] = val;
    }
  }
  return result;
}

// Display translation coverage status across all 18 language files
function showStatus() {
  if (!fs.existsSync(EN_PATH)) {
    console.error('en.json not found at:', EN_PATH);
    return;
  }
  const enData = JSON.parse(fs.readFileSync(EN_PATH, 'utf8'));
  const flatEn = flattenObject(enData);
  const totalKeys = Object.keys(flatEn).length;

  console.log('\n======================================================');
  console.log(`📊 VOWL LOCALIZATION STATUS (${totalKeys} TOTAL KEYS IN EN.JSON)`);
  console.log('======================================================');

  for (const [lang, conf] of Object.entries(TARGET_LANGUAGES)) {
    const filePath = path.join(TRANSLATIONS_DIR, `${lang}.json`);
    if (!fs.existsSync(filePath)) {
      console.log(`❌ ${lang.toUpperCase().padEnd(4)} [${conf.name}]: File missing`);
      continue;
    }
    const targetData = JSON.parse(fs.readFileSync(filePath, 'utf8'));
    const flatTarget = flattenObject(targetData);
    
    let translatedCount = 0;
    for (const [k, enVal] of Object.entries(flatEn)) {
      const targetVal = flatTarget[k];
      if (targetVal && targetVal !== enVal) {
        translatedCount++;
      }
    }
    const percent = ((translatedCount / totalKeys) * 100).toFixed(1);
    const bar = '█'.repeat(Math.floor(percent / 5)).padEnd(20, '░');
    console.log(`${lang.toUpperCase().padEnd(4)} [${conf.name.padEnd(10)}]: ${bar} ${percent.padStart(5)}% (${translatedCount}/${totalKeys})`);
  }
  console.log('======================================================\n');
}

// Main translation runner
async function main() {
  const args = process.argv.slice(2);
  if (args.includes('--status')) {
    showStatus();
    return;
  }

  const langArg = args.find((a) => a.startsWith('--lang='));
  const selectedLang = langArg ? langArg.split('=')[1].toLowerCase() : null;

  if (!fs.existsSync(EN_PATH)) {
    console.error('Cannot find source file:', EN_PATH);
    process.exit(1);
  }

  const enData = JSON.parse(fs.readFileSync(EN_PATH, 'utf8'));
  const flatEn = flattenObject(enData);
  const allKeys = Object.keys(flatEn);
  const totalKeys = allKeys.length;

  console.log('\n🚀 ====================================================');
  console.log('🌍 VOWL DUAL-ENGINE TRANSLATION SUITE');
  console.log('====================================================');
  console.log(`Source File : assets/translations/en.json (${totalKeys} strings)`);
  console.log(`Engine      : Google Translate API (Primary) + Bing Fallback`);
  console.log(`Batching    : ${BATCH_SIZE} items per chunk request`);
  console.log('====================================================\n');

  const languagesToProcess = selectedLang 
    ? { [selectedLang]: TARGET_LANGUAGES[selectedLang] }
    : TARGET_LANGUAGES;

  if (selectedLang && !TARGET_LANGUAGES[selectedLang]) {
    console.error(`Unknown language: "${selectedLang}". Available: ${Object.keys(TARGET_LANGUAGES).join(', ')}`);
    process.exit(1);
  }

  for (const [lang, langConf] of Object.entries(languagesToProcess)) {
    const filePath = path.join(TRANSLATIONS_DIR, `${lang}.json`);
    let targetData = {};
    if (fs.existsSync(filePath)) {
      try {
        targetData = JSON.parse(fs.readFileSync(filePath, 'utf8'));
      } catch (e) {
        targetData = {};
      }
    }

    const flatTarget = flattenObject(targetData);
    
    // Determine which keys need translation (currently identical to English or missing)
    const pendingKeys = allKeys.filter((k) => {
      const currentVal = flatTarget[k];
      return !currentVal || currentVal === flatEn[k];
    });

    console.log(`\n▶️ Starting [${lang.toUpperCase()}] (${langConf.name}): ${allKeys.length - pendingKeys.length}/${totalKeys} already done. (${pendingKeys.length} to translate)`);

    if (pendingKeys.length === 0) {
      console.log(`✨ [${lang.toUpperCase()}] is already 100% complete! Skipping.`);
      continue;
    }

    for (let i = 0; i < pendingKeys.length; i += BATCH_SIZE) {
      const batchKeys = pendingKeys.slice(i, i + BATCH_SIZE);
      const batchTexts = batchKeys.map(k => flatEn[k]);

      process.stdout.write(`[${lang.toUpperCase()}] (${Math.min(i + BATCH_SIZE, pendingKeys.length)}/${pendingKeys.length}) Translating batch... `);
      
      let translatedBatch;
      try {
        translatedBatch = await translateBatch(batchTexts, langConf);
      } catch (err) {
        console.log(`\n⚠️ Batch error: ${err.message}. Retrying individually...`);
        translatedBatch = [];
        for (const item of batchTexts) {
          translatedBatch.push(await translateSingle(item, langConf));
        }
      }

      batchKeys.forEach((key, idx) => {
        flatTarget[key] = translatedBatch[idx] || flatEn[key];
      });

      console.log(`\x1b[32mDone (${batchKeys.length} strings)\x1b[0m`);

      // Autosave to disk after every batch
      const reconstructed = unflattenObject(flatTarget, enData);
      fs.writeFileSync(filePath, JSON.stringify(reconstructed, null, 2) + '\n', 'utf8');

      // Small throttle between batches
      await new Promise((r) => setTimeout(r, DELAY_BETWEEN_BATCHES_MS));
    }

    console.log(`\n🎉 [${lang.toUpperCase()}] successfully saved to assets/translations/${lang}.json!`);
  }

  console.log('\n====================================================');
  console.log('🏁 LOCALIZATIONS RUN COMPLETED!');
  console.log('====================================================\n');
  showStatus();
}

main().catch((err) => {
  console.error('\n❌ Fatal error in translation script:', err);
  process.exit(1);
});

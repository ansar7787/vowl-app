/**
 * ============================================================================
 * Vowl Localization Translation Engine (Bing Translator + 15-Min Cooldown)
 * ============================================================================
 * 
 * Source: assets/translations/en.json
 * Targets: 17 localization languages (ar, bn, de, es, fr, gu, hi, ja, kn, ko, ml, mr, pt, ru, ta, te, zh)
 * 
 * Features:
 * - Automated terminal runner: run once, it works through all languages.
 * - 15-Minute Automatic Cooldown: If Bing rate limits or blocks requests, 
 *   it automatically enters a 15-minute countdown and resumes on its own.
 * - Placeholder Protection: Safely preserves {0}, {name}, {}, %s, \n.
 * - Continuous Autosave: Writes directly to disk after each batch so progress is never lost.
 * - Skip Existing: Only translates untranslated or missing keys.
 * 
 * Usage:
 *   node scripts/translate_localizations.js             # Run full translation across all 17 languages
 *   node scripts/translate_localizations.js --status    # Check translation status & coverage
 *   node scripts/translate_localizations.js --lang=hi   # Translate only a specific language
 * ============================================================================
 */

const fs = require('fs');
const path = require('path');
const { translate } = require('bing-translate-api');

// Configuration
const TRANSLATIONS_DIR = path.resolve(__dirname, '../assets/translations');
const EN_PATH = path.join(TRANSLATIONS_DIR, 'en.json');
const COOLDOWN_MINUTES = 15;
const COOLDOWN_MS = COOLDOWN_MINUTES * 60 * 1000;
const DELAY_BETWEEN_REQUESTS_MS = 300; // polite throttle to avoid immediate rate limits
const SAVE_INTERVAL = 10; // save to disk every 10 translations

// Supported Target Languages mapping to Bing language codes
const TARGET_LANGUAGES = {
  ar: 'ar',       // Arabic
  bn: 'bn',       // Bengali
  de: 'de',       // German
  es: 'es',       // Spanish
  fr: 'fr',       // French
  gu: 'gu',       // Gujarati
  hi: 'hi',       // Hindi
  ja: 'ja',       // Japanese
  kn: 'kn',       // Kannada
  ko: 'ko',       // Korean
  ml: 'ml',       // Malayalam
  mr: 'mr',       // Marathi
  pt: 'pt',       // Portuguese
  ru: 'ru',       // Russian
  ta: 'ta',       // Tamil
  te: 'te',       // Telugu
  zh: 'zh-Hans',  // Chinese (Simplified)
};

// Mask & protect placeholders like {0}, {name}, {}, %s, $variable
function maskPlaceholders(text) {
  const placeholders = [];
  const masked = text.replace(/\{[^{}]*\}|%[sdf@]|(\$[a-zA-Z0-9_]+)/g, (match) => {
    placeholders.push(match);
    return `___PH_${placeholders.length - 1}___`;
  });
  return { masked, placeholders };
}

// Unmask protected placeholders
function unmaskPlaceholders(text, placeholders) {
  let result = text;
  placeholders.forEach((ph, i) => {
    const reg = new RegExp(`___\\s*PH_${i}\\s*___`, 'gi');
    result = result.replace(reg, ph);
  });
  return result;
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

// Safe translation function with exponential backoff & 15-minute cooldown
async function translateText(text, targetCode) {
  if (!text || typeof text !== 'string') return text;
  const trimmed = text.trim();
  if (!trimmed) return text;

  // Don't translate pure numbers, symbols, single characters, or URLs
  if (/^[\d\s\p{P}\p{S}]+$/u.test(trimmed) || /^https?:\/\//i.test(trimmed)) {
    return text;
  }

  const { masked, placeholders } = maskPlaceholders(text);
  let errorCount = 0;

  while (true) {
    try {
      const res = await translate(masked, 'en', targetCode);
      if (res && res.translation) {
        return unmaskPlaceholders(res.translation, placeholders);
      }
      return text;
    } catch (err) {
      errorCount++;
      const errMsg = err ? (err.message || String(err)) : 'Unknown error';
      console.log(`\n\x1b[31m⚠️ Error translating to [${targetCode}] (Attempt ${errorCount}): ${errMsg}\x1b[0m`);

      // Check if rate limited or hit multiple consecutive failures
      const isRateLimit = errMsg.includes('429') || 
                          errMsg.toLowerCase().includes('rate') || 
                          errMsg.toLowerCase().includes('quota') || 
                          errMsg.toLowerCase().includes('too many') ||
                          errMsg.toLowerCase().includes('blocked');

      if (isRateLimit || errorCount >= 3) {
        await sleepWithCountdown(COOLDOWN_MS, `Bing API rate-limit/block encountered. Entering ${COOLDOWN_MINUTES}-minute cooldown.`);
        errorCount = 0; // reset error count after cooling down
      } else {
        console.log(`Waiting 5 seconds before retrying...`);
        await new Promise((r) => setTimeout(r, 5000));
      }
    }
  }
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

// Unflatten dotted key paths back to nested object matching original key ordering
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

  for (const [lang, code] of Object.entries(TARGET_LANGUAGES)) {
    const filePath = path.join(TRANSLATIONS_DIR, `${lang}.json`);
    if (!fs.existsSync(filePath)) {
      console.log(`❌ ${lang.toUpperCase().padEnd(4)} [${code}]: File missing`);
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
    console.log(`${lang.toUpperCase().padEnd(4)} [${code.padEnd(7)}]: ${bar} ${percent.padStart(5)}% (${translatedCount}/${totalKeys})`);
  }
  console.log('======================================================\n');
}

// Main translation executor
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
  console.log('🌍 VOWL AUTOMATIC TRANSLATION ENGINE');
  console.log('====================================================');
  console.log(`Source File : assets/translations/en.json (${totalKeys} strings)`);
  console.log(`Cooldown    : ${COOLDOWN_MINUTES} minutes on rate limit`);
  console.log(`Autosave    : Every ${SAVE_INTERVAL} strings to disk`);
  console.log('====================================================\n');

  const languagesToProcess = selectedLang 
    ? { [selectedLang]: TARGET_LANGUAGES[selectedLang] }
    : TARGET_LANGUAGES;

  if (selectedLang && !TARGET_LANGUAGES[selectedLang]) {
    console.error(`Unknown language: "${selectedLang}". Available: ${Object.keys(TARGET_LANGUAGES).join(', ')}`);
    process.exit(1);
  }

  for (const [lang, bingCode] of Object.entries(languagesToProcess)) {
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

    console.log(`\n▶️ Starting [${lang.toUpperCase()}] (${bingCode}): ${allKeys.length - pendingKeys.length}/${totalKeys} already done. (${pendingKeys.length} to translate)`);

    if (pendingKeys.length === 0) {
      console.log(`✨ [${lang.toUpperCase()}] is already 100% complete! Skipping.`);
      continue;
    }

    let translatedInBatch = 0;
    for (let i = 0; i < pendingKeys.length; i++) {
      const key = pendingKeys[i];
      const sourceText = flatEn[key];

      process.stdout.write(`[${lang.toUpperCase()}] (${i + 1}/${pendingKeys.length}) "${key}": `);
      const translated = await translateText(sourceText, bingCode);
      flatTarget[key] = translated;
      translatedInBatch++;

      const preview = translated.replace(/\n/g, ' ').slice(0, 40);
      console.log(`\x1b[32m${preview}${preview.length >= 40 ? '...' : ''}\x1b[0m`);

      // Autosave periodically
      if (translatedInBatch % SAVE_INTERVAL === 0 || i === pendingKeys.length - 1) {
        const reconstructed = unflattenObject(flatTarget, enData);
        fs.writeFileSync(filePath, JSON.stringify(reconstructed, null, 2), 'utf8');
      }

      // Small throttle between requests
      await new Promise((r) => setTimeout(r, DELAY_BETWEEN_REQUESTS_MS));
    }

    // Final save for this language
    const finalReconstructed = unflattenObject(flatTarget, enData);
    fs.writeFileSync(filePath, JSON.stringify(finalReconstructed, null, 2), 'utf8');
    console.log(`\n🎉 [${lang.toUpperCase()}] finished and saved to ${lang}.json!`);
  }

  console.log('\n====================================================');
  console.log('🏁 ALL LOCALIZATIONS PROCESSED SUCCESSFULLY!');
  console.log('====================================================\n');
  showStatus();
}

main().catch((err) => {
  console.error('\n❌ Fatal error in translation script:', err);
  process.exit(1);
});

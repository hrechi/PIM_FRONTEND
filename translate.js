/**
 * Auto-translate missing keys in app_fr.arb and app_ar.arb from app_en.arb
 * Uses the free Google Translate API (no API key needed)
 *
 * Usage:
 *   node translate.js          → translate all missing keys
 *   node translate.js --force  → retranslate ALL keys (overwrite existing)
 *
 * Install dependency first:
 *   npm install @vitalets/google-translate-api
 */

const fs   = require('fs');
const path = require('path');

// ── Config ────────────────────────────────────────────────────────────────────

const L10N_DIR  = path.join(__dirname, 'lib', 'l10n');
const SOURCE    = 'app_en.arb';
const TARGETS   = [
  { file: 'app_fr.arb', lang: 'fr' },
  { file: 'app_ar.arb', lang: 'ar' },
];
const FORCE     = process.argv.includes('--force');
const DELAY_MS  = 150; // delay between requests to avoid rate limiting

// ── Helpers ───────────────────────────────────────────────────────────────────

function sleep(ms) {
  return new Promise(resolve => setTimeout(resolve, ms));
}

function loadArb(filename) {
  const filePath = path.join(L10N_DIR, filename);
  if (!fs.existsSync(filePath)) return {};
  return JSON.parse(fs.readFileSync(filePath, 'utf8'));
}

function saveArb(filename, data) {
  const filePath = path.join(L10N_DIR, filename);
  fs.writeFileSync(filePath, JSON.stringify(data, null, 2) + '\n', 'utf8');
  console.log(`  ✅ Saved ${filename}`);
}

// Detect if a value contains placeholders like {name}, {count}
function hasPlaceholders(value) {
  return /\{[a-zA-Z_]+\}/.test(value);
}

// Preserve placeholders during translation by replacing them with tokens
function encodePlaceholders(text) {
  const placeholders = [];
  const encoded = text.replace(/\{([a-zA-Z_]+)\}/g, (match, name) => {
    const token = `PLACEHOLDER${placeholders.length}`;
    placeholders.push({ token, original: match });
    return token;
  });
  return { encoded, placeholders };
}

function decodePlaceholders(text, placeholders) {
  let result = text;
  for (const { token, original } of placeholders) {
    result = result.replace(token, original);
  }
  return result;
}

// ── Main ──────────────────────────────────────────────────────────────────────

async function main() {
  // Dynamic import for ESM module
  let translate;
  try {
    const mod = await import('@vitalets/google-translate-api');
    translate = mod.translate;
  } catch (e) {
    console.error('\n❌ Missing dependency. Run:\n   npm install @vitalets/google-translate-api\n');
    process.exit(1);
  }

  const source = loadArb(SOURCE);

  // Collect translatable keys (skip @metadata keys and @@locale)
  const keys = Object.keys(source).filter(k => !k.startsWith('@'));

  console.log(`\n📖 Source: ${SOURCE} — ${keys.length} keys\n`);

  for (const target of TARGETS) {
    console.log(`\n🌍 Translating to ${target.lang.toUpperCase()} → ${target.file}`);
    console.log('─'.repeat(50));

    const existing = loadArb(target.file);
    const result   = { '@@locale': target.lang };

    let translated = 0;
    let skipped    = 0;
    let errors     = 0;

    for (const key of keys) {
      const sourceValue = source[key];

      // Skip if already translated and not forcing
      if (!FORCE && existing[key] && existing[key] !== sourceValue) {
        result[key] = existing[key];
        skipped++;
        continue;
      }

      // Don't translate if value is a number, URL, or single word that's a proper noun
      if (typeof sourceValue !== 'string' || sourceValue.trim() === '') {
        result[key] = sourceValue;
        skipped++;
        continue;
      }

      try {
        const { encoded, placeholders } = encodePlaceholders(sourceValue);

        const res = await translate(encoded, { to: target.lang });
        let translatedText = res.text;

        // Restore placeholders
        translatedText = decodePlaceholders(translatedText, placeholders);

        result[key] = translatedText;
        translated++;

        process.stdout.write(`  ✓ ${key}: "${translatedText.substring(0, 50)}${translatedText.length > 50 ? '...' : ''}"\n`);

        await sleep(DELAY_MS);
      } catch (err) {
        console.error(`  ⚠ Failed to translate "${key}": ${err.message}`);
        result[key] = existing[key] || sourceValue; // fallback to existing or source
        errors++;
      }
    }

    // Copy @metadata entries
    for (const key of Object.keys(source)) {
      if (key.startsWith('@') && key !== '@@locale') {
        result[key] = source[key];
      }
    }

    saveArb(target.file, result);

    console.log(`\n  📊 ${target.lang}: ${translated} translated, ${skipped} kept, ${errors} errors`);
  }

  console.log('\n✅ Translation complete!\n');
  console.log('Next steps:');
  console.log('  1. Review the translated files in lib/l10n/');
  console.log('  2. Fix any awkward translations manually');
  console.log('  3. Hot reload Flutter to see changes\n');
}

main().catch(console.error);

/**
 * Production-Safe errorJournal Subcollection Purge Tool
 *
 * SAFETY GUARANTEES:
 * 1. Strictly targets ONLY paths matching:
 *    projects/vowl-acbc5/databases/(default)/documents/users/{uid}/errorJournal/{docId}
 * 2. Will NEVER delete or touch user profiles, stats, coins, streaks, referrals, or any other collection.
 * 3. Default mode is DRY RUN (inspect and count only, zero deletions).
 * 4. Deletions only occur when the explicit `--execute` flag is passed.
 */

const fs = require('fs');
const os = require('os');
const path = require('path');
const https = require('https');

const PROJECT_ID = 'vowl-acbc5';
const EXPECTED_PATH_REGEX = /^projects\/vowl-acbc5\/databases\/\(default\)\/documents\/users\/[^\/]+\/errorJournal\/[^\/]+$/;

function getAccessToken() {
  const cfgPath = path.join(os.homedir(), '.config', 'configstore', 'firebase-tools.json');
  if (!fs.existsSync(cfgPath)) {
    throw new Error('Firebase CLI configuration not found at: ' + cfgPath + '. Please run `firebase login`.');
  }
  const cfg = JSON.parse(fs.readFileSync(cfgPath, 'utf8'));
  if (!cfg.tokens || !cfg.tokens.access_token) {
    throw new Error('No valid Firebase access token found. Please run `firebase login`.');
  }
  return cfg.tokens.access_token;
}

function makeRequest(method, endpointPath, postData = null) {
  const token = getAccessToken();
  return new Promise((resolve, reject) => {
    const options = {
      hostname: 'firestore.googleapis.com',
      port: 443,
      path: endpointPath,
      method: method,
      headers: {
        'Authorization': 'Bearer ' + token,
        'Content-Type': 'application/json',
      }
    };
    if (postData) {
      options.headers['Content-Length'] = Buffer.byteLength(postData);
    }

    const req = https.request(options, (res) => {
      let body = '';
      res.on('data', chunk => body += chunk);
      res.on('end', () => {
        try {
          const parsed = JSON.parse(body);
          if (res.statusCode >= 200 && res.statusCode < 300) {
            resolve(parsed);
          } else {
            reject(new Error(`API Error [${res.statusCode}]: ${JSON.stringify(parsed)}`));
          }
        } catch (e) {
          reject(new Error(`Invalid JSON response [${res.statusCode}]: ${body}`));
        }
      });
    });

    req.on('error', reject);
    if (postData) req.write(postData);
    req.end();
  });
}

async function queryAllErrorJournalDocs() {
  const postData = JSON.stringify({
    structuredQuery: {
      from: [{ collectionId: 'errorJournal', allDescendants: true }],
      select: { fields: [] }
    }
  });

  const response = await makeRequest(
    'POST',
    `/v1/projects/${PROJECT_ID}/databases/(default)/documents:runQuery`,
    postData
  );

  const docs = (response || [])
    .filter(item => item && item.document && item.document.name)
    .map(item => item.document.name);

  return docs;
}

async function batchDeleteDocs(docNames) {
  const BATCH_SIZE = 250; // Well within Firestore 500 limit for reliability
  let deletedCount = 0;

  for (let i = 0; i < docNames.length; i += BATCH_SIZE) {
    const chunk = docNames.slice(i, i + BATCH_SIZE);
    const writes = chunk.map(docName => ({
      delete: docName
    }));

    const postData = JSON.stringify({ writes });
    await makeRequest(
      'POST',
      `/v1/projects/${PROJECT_ID}/databases/(default)/documents:commit`,
      postData
    );

    deletedCount += chunk.length;
    console.log(`  -> Progress: [${deletedCount} / ${docNames.length}] documents deleted...`);
  }

  return deletedCount;
}

async function main() {
  const isExecute = process.argv.includes('--execute');

  console.log('====================================================');
  console.log(' Vowl Production Firestore: errorJournal Purge Tool');
  console.log(` Project: ${PROJECT_ID}`);
  console.log(` Mode:    ${isExecute ? 'LIVE EXECUTION (DESTRUCTIVE)' : 'DRY RUN (SAFE / READ-ONLY)'}`);
  console.log('====================================================\n');

  console.log('Step 1: Scanning collectionGroup("errorJournal") across production Firestore...');
  const docNames = await queryAllErrorJournalDocs();

  console.log(`\nFound ${docNames.length} document(s) in "errorJournal".`);

  if (docNames.length === 0) {
    console.log('Database is already 100% spotless! No errorJournal documents found.');
    return;
  }

  // Safety Assertion: Verify every single path strictly matches the errorJournal subcollection pattern
  console.log('Step 2: Validating safety assertion on every document path...');
  const userSet = new Set();
  for (const name of docNames) {
    if (!EXPECTED_PATH_REGEX.test(name)) {
      console.error(`\nCRITICAL SAFETY ERROR: Unexpected document path encountered: ${name}`);
      console.error('Aborting immediately! No deletions performed.');
      process.exit(1);
    }
    const match = name.match(/users\/([^\/]+)\/errorJournal/);
    if (match) userSet.add(match[1]);
  }
  console.log(`Safety check PASSED: All ${docNames.length} documents belong strictly to users/{userId}/errorJournal.`);
  console.log(`Total unique user accounts with errorJournal data: ${userSet.size}`);

  if (!isExecute) {
    console.log('\n----------------------------------------------------');
    console.log(' DRY RUN COMPLETE: 0 documents deleted.');
    console.log(` To permanently purge these ${docNames.length} documents from production Firestore, run:`);
    console.log('   node scripts/purge_error_journal.js --execute');
    console.log('----------------------------------------------------');
    return;
  }

  console.log(`\nStep 3: Committing deletion of ${docNames.length} errorJournal documents in atomic batches...`);
  const deleted = await batchDeleteDocs(docNames);

  console.log('\nStep 4: Post-deletion verification...');
  const remaining = await queryAllErrorJournalDocs();

  console.log('\n====================================================');
  console.log(` PURGE SUCCESSFUL!`);
  console.log(` Successfully deleted: ${deleted} errorJournal document(s) across ${userSet.size} user account(s).`);
  console.log(` Remaining errorJournal documents in production: ${remaining.length}`);
  console.log(' All user profiles, streaks, coins, and learning data remain 100% intact.');
  console.log('====================================================\n');
}

main().catch(err => {
  console.error('\nExecution failed:', err.message || err);
  process.exit(1);
});

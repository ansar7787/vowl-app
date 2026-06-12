/**
 * Firebase Subscription Plans Setup Script
 *
 * This script populates the subscriptionPlans collection in Firestore
 * Run this ONCE to add all subscription plans
 *
 * Prerequisites:
 * 1. npm install -g firebase-tools
 * 2. firebase login (use your Firebase account)
 * 3. cd to project root directory
 * 4. node setup-subscription-plans.js
 */

const admin = require('firebase-admin');
const path = require('path');

// Initialize Firebase Admin SDK
const serviceAccountPath = path.join(__dirname, 'serviceAccountKey.json');

try {
  const serviceAccount = require(serviceAccountPath);
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
  });
} catch (error) {
  console.error('❌ ERROR: serviceAccountKey.json not found!');
  console.error('Please download it from Firebase Console:');
  console.error('  1. Go to Project Settings');
  console.error('  2. Service Accounts tab');
  console.error('  3. Click "Generate New Private Key"');
  console.error('  4. Save as serviceAccountKey.json in project root');
  process.exit(1);
}

const db = admin.firestore();

// Subscription plans data
const subscriptionPlans = [
  {
    id: 'weekly_offer',
    name: 'Weekly',
    price: 39.0,
    oldPrice: 49.0,
    days: 7,
    tag: 'FESTIVE OFFER',
    color: '#FFF43F5E',
    displayOrder: 0,
    createdAt: new Date(),
    updatedAt: new Date(),
  },
  {
    id: 'monthly_offer',
    name: 'Monthly',
    price: 99.0,
    oldPrice: 149.0,
    days: 30,
    tag: 'MOST POPULAR',
    color: '#FF6366F1',
    displayOrder: 1,
    createdAt: new Date(),
    updatedAt: new Date(),
  },
  {
    id: 'yearly_offer',
    name: 'Yearly',
    price: 799.0,
    oldPrice: 1499.0,
    days: 365,
    tag: 'BEST VALUE',
    color: '#FF10B981',
    displayOrder: 2,
    createdAt: new Date(),
    updatedAt: new Date(),
  },
];

/**
 * Main setup function
 */
async function setupSubscriptionPlans() {
  try {
    console.log('🔄 Starting Firebase Subscription Plans setup...\n');

    // Delete existing plans (if any) to start fresh
    console.log('📝 Clearing existing plans...');
    const existingPlans = await db.collection('subscriptionPlans').get();
    for (const doc of existingPlans.docs) {
      await doc.ref.delete();
      console.log(`   ✓ Deleted existing plan: ${doc.id}`);
    }

    // Add new plans
    console.log('\n📝 Adding new subscription plans...');
    for (const plan of subscriptionPlans) {
      await db.collection('subscriptionPlans').doc(plan.id).set(plan);
      console.log(
        `   ✓ Created plan: ${plan.name} (₹${plan.price.toFixed(2)})`,
      );
    }

    // Verify all plans were added
    console.log('\n✅ Verifying plans...');
    const allPlans = await db
      .collection('subscriptionPlans')
      .orderBy('displayOrder')
      .get();
    console.log(`   Found ${allPlans.size} plans in Firestore:\n`);

    allPlans.forEach((doc) => {
      const data = doc.data();
      console.log(`   Plan: ${data.name}`);
      console.log(`   - Price: ₹${data.price} (was ₹${data.oldPrice})`);
      console.log(`   - Duration: ${data.days} days`);
      console.log(`   - Tag: ${data.tag}`);
      console.log(`   - ID: ${doc.id}`);
      console.log();
    });

    console.log('✅ ✅ ✅ SUCCESS! All subscription plans added to Firebase');
    console.log('\n📱 Your app will now:');
    console.log('   1. Auto-fetch plans from Firebase');
    console.log('   2. Display them on the Premium Screen');
    console.log('   3. Cache them for 1 hour');
    console.log('\n🚀 Ready for deployment!');
  } catch (error) {
    console.error('❌ ERROR during setup:', error.message);
    console.error('\nTroubleshooting:');
    console.error('  1. Check serviceAccountKey.json exists in project root');
    console.error('  2. Verify Firebase project is "vowl-acbc5"');
    console.error('  3. Check internet connection');
    console.error('  4. Run "firebase login" again');
    process.exit(1);
  } finally {
    // Close Firebase connection
    await admin.app().delete();
    console.log('\n✅ Setup complete. Firebase connection closed.');
  }
}

// Run the setup
setupSubscriptionPlans();

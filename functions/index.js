const { onSchedule } = require('firebase-functions/v2/scheduler');
const { onCall, HttpsError } = require('firebase-functions/v2/https');
const admin = require('firebase-admin');
const crypto = require('crypto');
admin.initializeApp();

// --------------------------------------------------
// Prevents abuse by limiting payment verification calls per user.
const RATE_LIMIT_COOLDOWN_MS = 10000; // 10 seconds between payment calls

async function checkRateLimit(db, uid, operationType) {
  const rateLimitRef = db.collection('rate_limits').doc(uid);
  const rateLimitDoc = await rateLimitRef.get();
  const now = Date.now();

  if (rateLimitDoc.exists) {
    const lastCall = rateLimitDoc.data()[operationType] || 0;
    if (now - lastCall < RATE_LIMIT_COOLDOWN_MS) {
      throw new HttpsError(
        'resource-exhausted',
        'Too many requests. Please wait a few seconds and try again.',
      );
    }
  }

  // Update the rate limit timestamp
  await rateLimitRef.set({ [operationType]: now }, { merge: true });
}

// --------------------------------------------------
// Hard-fails if Razorpay keys are not configured. Never silently bypass.
function requireRazorpayKeys() {
  const keyId = process.env.RAZORPAY_KEY_ID;
  const secret = process.env.RAZORPAY_KEY_SECRET;

  if (!keyId || !secret) {
    console.error(
      'CRITICAL: RAZORPAY_KEY_ID or RAZORPAY_KEY_SECRET is not configured.',
    );
    throw new HttpsError(
      'failed-precondition',
      'Payment verification is not configured. Please contact support.',
    );
  }

  return { keyId, secret };
}

// --------------------------------------------------
// Fetches payment details from Razorpay and validates status + amount.
async function verifyRazorpayPayment(
  keyId,
  secret,
  paymentId,
  expectedAmountPaise,
) {
  const authHeader =
    'Basic ' + Buffer.from(keyId + ':' + secret).toString('base64');

  // Sanitize paymentId to prevent path traversal in the API URL
  if (!/^pay_[a-zA-Z0-9]+$/.test(paymentId)) {
    throw new HttpsError('invalid-argument', 'Invalid payment ID format.');
  }

  const response = await fetch(
    `https://api.razorpay.com/v1/payments/${paymentId}`,
    {
      method: 'GET',
      headers: { Authorization: authHeader },
    },
  );

  if (!response.ok) {
    console.error(
      `Razorpay API error for payment ${paymentId}: HTTP ${response.status}`,
    );
    throw new HttpsError('permission-denied', 'Invalid payment ID.');
  }

  const paymentData = await response.json();

  // Verify payment status
  if (
    paymentData.status !== 'captured' &&
    paymentData.status !== 'authorized'
  ) {
    console.warn(`Payment ${paymentId} status: ${paymentData.status}`);
    throw new HttpsError('permission-denied', 'Payment not successful.');
  }

  // Verify payment amount (prevents ₹1-for-premium attacks)
  if (expectedAmountPaise && paymentData.amount < expectedAmountPaise) {
    console.warn(
      `Payment ${paymentId} amount mismatch. Expected >=${expectedAmountPaise}, got ${paymentData.amount}`,
    );
    throw new HttpsError('permission-denied', 'Payment amount mismatch.');
  }

  return paymentData;
}

// --------------------------------------------------
// Verifies HMAC-SHA256 signature to prevent payment replay attacks.
function verifyRazorpaySignature(orderId, paymentId, signature, secret) {
  if (!orderId || !signature) {
    console.error(
      `SECURITY: Missing orderId or signature for payment ${paymentId}. Rejecting.`,
    );
    throw new HttpsError(
      'invalid-argument',
      'Payment verification data is incomplete. Please try again.',
    );
  }

  const expectedSignature = crypto
    .createHmac('sha256', secret)
    .update(orderId + '|' + paymentId)
    .digest('hex');

  const sigBuf = Buffer.from(signature, 'hex');
  const expectedBuf = Buffer.from(expectedSignature, 'hex');
  if (sigBuf.length !== expectedBuf.length || !crypto.timingSafeEqual(sigBuf, expectedBuf)) {
    console.error(`Signature mismatch for payment ${paymentId}`);
    throw new HttpsError('permission-denied', 'Invalid payment signature.');
  }
}

// --------------------------------------------------
// Creates a Razorpay order with the correct amount locked server-side.
// This prevents amount-tampering attacks where a client modifies the
// checkout amount before the SDK opens.
exports.createOrder = onCall(async (request) => {
  // 1. Auth Check
  if (!request.auth) {
    throw new HttpsError('unauthenticated', 'User must be logged in.');
  }

  const uid = request.auth.uid;
  const { planId, packId } = request.data;

  if (!planId && !packId) {
    throw new HttpsError('invalid-argument', 'Missing plan ID or pack ID.');
  }

  const db = admin.firestore();

  // 2. Rate Limiting — prevent order-spam
  await checkRateLimit(db, uid, 'lastOrderCreate');

  // 3. Fetch item from Firestore to get the real price
  let amountInSmallestUnit;
  let currency;
  let itemName;
  let itemDays = 0;

  if (planId) {
    const plansSnapshot = await db
      .collection('subscriptionPlans')
      .where('id', '==', planId)
      .limit(1)
      .get();

    if (plansSnapshot.empty) {
      throw new HttpsError('not-found', 'Invalid subscription plan.');
    }

    const planData = plansSnapshot.docs[0].data();
    amountInSmallestUnit = Math.round(planData.price * 100);
    currency = planData.currency || 'INR';
    itemName = planData.name;
    itemDays = planData.days;
  } else if (packId) {
    const packDoc = await db.collection('coinPacks').doc(packId).get();
    let packData;
    if (!packDoc.exists) {
      const fallbackPacks = {
        starter_pack: { coins: 500, keys: 0, price: 9, currency: 'INR' },
        explorer_pack: { coins: 1200, keys: 2, price: 19, currency: 'INR' },
        master_pack: { coins: 4000, keys: 8, price: 29, currency: 'INR' },
      };
      if (fallbackPacks[packId]) {
        packData = fallbackPacks[packId];
      } else {
        throw new HttpsError('not-found', 'Invalid coin pack.');
      }
    } else {
      packData = packDoc.data();
    }
    amountInSmallestUnit = Math.round(packData.price * 100);
    currency = packData.currency || 'INR';
    itemName = packData.titleFallback || 'Coin Pack';
  }

  // 4. Create Razorpay order via API
  const { keyId, secret } = requireRazorpayKeys();
  const authHeader =
    'Basic ' + Buffer.from(keyId + ':' + secret).toString('base64');

  let orderData;
  try {
    const response = await fetch('https://api.razorpay.com/v1/orders', {
      method: 'POST',
      headers: {
        Authorization: authHeader,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        amount: amountInSmallestUnit,
        currency: currency,
        receipt: `vowl_${uid.substring(0, 8)}_${Date.now()}`,
        notes: {
          userId: uid,
          ...(planId && { planId }),
          ...(packId && { packId }),
          itemName: itemName,
          itemDays: itemDays,
        },
      }),
    });

    if (!response.ok) {
      const errorBody = await response.text();
      let errorDesc = 'Unknown error';
      try {
        errorDesc = JSON.parse(errorBody).error.description || 'Unknown error';
      } catch (e) {}
      console.error(`Razorpay order creation failed: HTTP ${response.status} - ${errorDesc}`);
      throw new HttpsError('internal', 'Failed to create payment order.');
    }

    orderData = await response.json();
  } catch (error) {
    if (error instanceof HttpsError) throw error;
    console.error('Error creating Razorpay order:', error.message || 'Unknown error');
    throw new HttpsError('internal', 'Failed to create payment order.');
  }

  // 5. Store order reference for verification later
  await db
    .collection('orders')
    .doc(orderData.id)
    .set({
      userId: uid,
      ...(planId && { planId }),
      ...(packId && { packId }),
      amount: amountInSmallestUnit,
      currency: currency,
      razorpayOrderId: orderData.id,
      status: 'created',
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

  return {
    orderId: orderData.id,
    amount: amountInSmallestUnit,
    currency: currency,
    itemName: itemName,
    itemDays: itemDays,
  };
});

// --------------------------------------------------
// Called from the Flutter app after Razorpay success callback.
// Verifies the payment via Razorpay API before granting premium status.
exports.verifyPayment = onCall(async (request) => {
  // 1. Auth Check
  if (!request.auth) {
    throw new HttpsError('unauthenticated', 'User must be logged in.');
  }

  const uid = request.auth.uid;
  const { paymentId, orderId, signature, durationDays } = request.data;

  if (!paymentId) {
    throw new HttpsError('invalid-argument', 'Missing payment ID.');
  }

  const db = admin.firestore();

  // 2. Rate Limiting — prevent abuse/DDoS
  await checkRateLimit(db, uid, 'lastPremiumVerify');

  // 3. Validate plan duration — only allow real subscription plans
  const days = typeof durationDays === 'number' ? durationDays : 0;

  // Fetch the matching subscription plan from Firestore to get the expected price
  const plansSnapshot = await db
    .collection('subscriptionPlans')
    .where('days', '==', days)
    .limit(1)
    .get();

  if (plansSnapshot.empty) {
    console.warn(
      `Invalid subscription duration: ${days} days from user ${uid}`,
    );
    throw new HttpsError('invalid-argument', 'Invalid subscription plan.');
  }

  const planData = plansSnapshot.docs[0].data();
  const expectedAmountPaise = Math.round(planData.price * 100);
  const expectedCurrency = planData.currency || 'INR';

  // 4. Verify Razorpay Payment (Zero Trust)
  const { keyId, secret } = requireRazorpayKeys();

  try {
    // Verify signature if provided (prevents payment replay attacks)
    verifyRazorpaySignature(orderId, paymentId, signature, secret);

    // Verify payment with Razorpay API (status + amount)
    const paymentData = await verifyRazorpayPayment(
      keyId,
      secret,
      paymentId,
      expectedAmountPaise,
    );

    // Validate currency matches the plan's expected currency
    if (
      paymentData.currency &&
      paymentData.currency.toUpperCase() !== expectedCurrency.toUpperCase()
    ) {
      console.error(
        `Currency mismatch for payment ${paymentId}: expected ${expectedCurrency}, got ${paymentData.currency}`,
      );
      throw new HttpsError('permission-denied', 'Payment currency mismatch.');
    }
  } catch (error) {
    if (error instanceof HttpsError) throw error;
    console.error('Error verifying payment with Razorpay:', error);
    throw new HttpsError('internal', 'Failed to verify payment with gateway.');
  }

  // 5. Payment verified - Grant Premium
  const userRef = db.collection('users').doc(uid);
  let grantedExpiryDate = null;

  await db.runTransaction(async (transaction) => {
    const userDoc = await transaction.get(userRef);
    if (!userDoc.exists) {
      throw new HttpsError('not-found', 'User not found.');
    }

    const userData = userDoc.data();

    // Prevent duplicate claims for the same payment
    if (userData.lastPaymentId === paymentId) {
      console.warn(`Payment ${paymentId} already processed for user ${uid}`);
      grantedExpiryDate = userData.premiumExpiryDate?.toDate?.() || new Date();
      return;
    }

    const currentExpiry = userData.premiumExpiryDate?.toDate?.() || null;
    const base = (currentExpiry && currentExpiry > new Date()) ? currentExpiry : new Date();
    const expiryDate = new Date(base.getTime() + days * 24 * 60 * 60 * 1000);
    grantedExpiryDate = expiryDate;

    transaction.update(userRef, {
      isPremium: true,
      premiumExpiryDate: admin.firestore.Timestamp.fromDate(expiryDate),
      lastPaymentId: paymentId,
      lastPaymentDate: admin.firestore.FieldValue.serverTimestamp(),
    });
  });

  if (orderId) {
    const orderQuery = await db.collection('orders').where('orderId', '==', orderId).limit(1).get();
    if (!orderQuery.empty) {
      await orderQuery.docs[0].ref.update({ status: 'paid', paidAt: admin.firestore.FieldValue.serverTimestamp() });
    }
  }

  const finalIso = (grantedExpiryDate || new Date()).toISOString();
  console.log(
    `Premium granted to user ${uid} until ${finalIso}`,
  );
  return { success: true, expiryDate: finalIso };
});

// --------------------------------------------------
// Called from the Flutter app after Razorpay success callback.
// Verifies the payment via Razorpay API and grants items securely.
exports.verifyCoinPurchase = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError('unauthenticated', 'User must be logged in.');
  }

  const uid = request.auth.uid;
  const { paymentId, orderId, signature, packId } = request.data;

  if (!paymentId || !packId) {
    throw new HttpsError('invalid-argument', 'Missing payment ID or pack ID.');
  }

  const db = admin.firestore();

  // 1. Rate Limiting — prevent abuse/DDoS
  await checkRateLimit(db, uid, 'lastCoinVerify');

  // 2. Fetch the pack from the database to know how much it costs and what it gives
  const packDoc = await db.collection('coinPacks').doc(packId).get();
  let packData;
  if (!packDoc.exists) {
    const fallbackPacks = {
      starter_pack: { coins: 500, keys: 0, price: 9, currency: 'INR' },
      explorer_pack: { coins: 1200, keys: 2, price: 19, currency: 'INR' },
      master_pack: { coins: 4000, keys: 8, price: 29, currency: 'INR' },
    };
    if (fallbackPacks[packId]) {
      packData = fallbackPacks[packId];
    } else {
      throw new HttpsError('not-found', 'Invalid pack ID.');
    }
  } else {
    packData = packDoc.data();
  }
  const expectedAmountPaise = Math.round(packData.price * 100);
  const expectedCurrency = packData.currency || 'INR';

  // 3. Verify Razorpay Payment (Zero Trust — hard-fail if keys missing)
  const { keyId, secret } = requireRazorpayKeys();

  try {
    // Verify signature if provided (prevents payment replay attacks)
    verifyRazorpaySignature(orderId, paymentId, signature, secret);

    // Verify payment with Razorpay API (status + amount)
    const paymentData = await verifyRazorpayPayment(
      keyId,
      secret,
      paymentId,
      expectedAmountPaise,
    );

    // Validate currency matches the plan's expected currency
    if (
      paymentData.currency &&
      paymentData.currency.toUpperCase() !== expectedCurrency.toUpperCase()
    ) {
      console.error(
        `Currency mismatch for payment ${paymentId}: expected ${expectedCurrency}, got ${paymentData.currency}`,
      );
      throw new HttpsError('permission-denied', 'Payment currency mismatch.');
    }
  } catch (error) {
    if (error instanceof HttpsError) throw error;
    console.error('Error verifying payment with Razorpay:', error);
    throw new HttpsError('internal', 'Failed to verify payment with gateway.');
  }

  // 4. Prevent duplicate processing
  const userRef = db.collection('users').doc(uid);
  let coinsGranted = 0;
  let keysGranted = 0;

  await db.runTransaction(async (transaction) => {
    const userDoc = await transaction.get(userRef);
    if (!userDoc.exists) {
      throw new HttpsError('not-found', 'User not found.');
    }

    // Simple idempotency check
    if (userDoc.data().lastCoinPurchaseId === paymentId) {
      console.warn(`Payment ${paymentId} already processed for user ${uid}`);
      return;
    }

    const currentCoins = userDoc.data().coins || 0;
    const currentKeys = userDoc.data().goldenKeys || 0;
    const currentCoinHistory = userDoc.data().coinHistory || [];

    coinsGranted = packData.coins || 0;
    keysGranted = packData.keys || 0;

    if (coinsGranted > 0) {
      currentCoinHistory.unshift({
        titleKey: 'coin_history.purchased_coin_pack',
        amount: coinsGranted,
        isEarned: true,
        date: new Date().toISOString(),
      });

      // Limit array size to prevent document Bloat
      if (currentCoinHistory.length > 20) {
        currentCoinHistory.length = 20;
      }
    }

    transaction.update(userRef, {
      coins: currentCoins + coinsGranted,
      goldenKeys: currentKeys + keysGranted,
      lastCoinPurchaseId: paymentId,
      lastCoinPurchaseDate: admin.firestore.FieldValue.serverTimestamp(),
      lastCoinPackId: packId,
      coinHistory: currentCoinHistory,
    });
  });

  if (orderId) {
    const orderQuery = await db.collection('orders').where('orderId', '==', orderId).limit(1).get();
    if (!orderQuery.empty) {
      await orderQuery.docs[0].ref.update({ status: 'paid', paidAt: admin.firestore.FieldValue.serverTimestamp() });
    }
  }

  console.log(
    `Granted ${coinsGranted} coins and ${keysGranted} keys to user ${uid}`,
  );
  return { success: true, coinsGranted, keysGranted };
});

// --------------------------------------------------
// Automatically revokes premium when the subscription expires.
exports.checkPremiumExpiry = onSchedule('0 3 * * *', async (event) => {
  const db = admin.firestore();
  const now = admin.firestore.Timestamp.now();

  const expiredUsers = await db
    .collection('users')
    .where('isPremium', '==', true)
    .where('premiumExpiryDate', '<=', now)
    .get();

  if (expiredUsers.empty) {
    console.log('No expired premium users found.');
    return;
  }

  const BATCH_LIMIT = 500;
  for (let i = 0; i < expiredUsers.size; i += BATCH_LIMIT) {
    const batch = db.batch();
    const chunk = expiredUsers.docs.slice(i, i + BATCH_LIMIT);
    chunk.forEach((doc) => batch.update(doc.ref, { isPremium: false }));
    await batch.commit();
  }
  console.log(`Revoked premium for ${expiredUsers.size} users.`);
});

// 🏆 THE WEEKLY RECAP
// Runs every Sunday at 11:59 PM (Final Results)
exports.sendWeeklyRankings = onSchedule('59 23 * * 0', async (event) => {
  const db = admin.firestore();

  // 1. Get Top 100 learners by Total XP
  const snapshot = await db
    .collection('users')
    .orderBy('totalExp', 'desc')
    .limit(100)
    .get();

  if (snapshot.empty) return;

  const messages = [];
  const seenTokens = new Set();
  const duplicateCleanups = [];
  let rank = 1;

  snapshot.forEach((doc) => {
    const user = doc.data();
    const token = user.fcmToken;

    if (token) {
      if (seenTokens.has(token)) {
        // Device token already claimed by a higher-ranked / active user
        duplicateCleanups.push(
          doc.ref.update({ fcmToken: admin.firestore.FieldValue.delete() }),
        );
        return;
      }
      seenTokens.add(token);

      let title = 'Weekly Recap \u{1F4CA}';
      let body = `You placed #${rank} in the global rankings this week. Keep up the strong consistency!`;

      if (rank === 1) {
        title = '1st place this week! \u{1F451}';
        body = 'Outstanding achievement — you finished #1 on the global leaderboard!';
      } else if (rank === 2) {
        title = '2nd place this week! \u{1F948}';
        body = 'Incredible performance! You earned the silver podium spot this week.';
      } else if (rank === 3) {
        title = '3rd place this week! \u{1F949}';
        body = 'Podium finish! You earned bronze on the global leaderboard.';
      }

      messages.push({
        token: token,
        notification: {
          title: title,
          body: body,
        },
        data: {
          path: '/leaderboard',
          targetUserId: doc.id,
        },
        android: {
          priority: 'high',
          notification: {
            clickAction: 'FLUTTER_NOTIFICATION_CLICK',
            channelId: 'vowl_weekly_channel',
          },
        },
      });
    }
    rank++;
  });

  if (duplicateCleanups.length > 0) {
    try {
      await Promise.all(duplicateCleanups);
    } catch (e) {
      console.warn('Stale token cleanup error:', e);
    }
  }

  // 2. Efficient Batch Sending (sendEach)
  if (messages.length > 0) {
    try {
      const response = await admin.messaging().sendEach(messages);
      console.log(
        `Successfully sent ${response.successCount} ranking notifications.`,
      );
    } catch (error) {
      console.error('Error sending batch notifications:', error);
    }
  }
});

// 🔥 STREAK REMINDER
// Runs daily at 8:00 PM — nudges users who haven't logged in today
exports.sendStreakReminders = onSchedule('0 20 * * *', async (event) => {
  const db = admin.firestore();

  // Get start of today (UTC)
  const now = new Date();
  const startOfDay = new Date(now.getFullYear(), now.getMonth(), now.getDate());

  // Find users with active streaks who haven't logged in today
  const usersAtRisk = await db
    .collection('users')
    .where('currentStreak', '>', 0)
    .where('lastLoginDate', '<', admin.firestore.Timestamp.fromDate(startOfDay))
    .limit(500)
    .get();

  if (usersAtRisk.empty) {
    console.log('No streak-at-risk users found.');
    return;
  }

  // Production-grade deduplication: If a device token is linked to multiple accounts
  // (e.g. user switched accounts on the same phone without clean logout),
  // prioritize the account that logged in most recently and prune duplicate associations.
  const sortedDocs = [...usersAtRisk.docs].sort((a, b) => {
    const timeA = a.data().lastLoginDate?.toMillis ? a.data().lastLoginDate.toMillis() : 0;
    const timeB = b.data().lastLoginDate?.toMillis ? b.data().lastLoginDate.toMillis() : 0;
    return timeB - timeA;
  });

  const messages = [];
  const seenTokens = new Set();
  const duplicateCleanups = [];

  sortedDocs.forEach((doc) => {
    const user = doc.data();
    const token = user.fcmToken;
    if (token) {
      if (seenTokens.has(token)) {
        // Device token already used by a more recently active user.
        // Clean up the stale token from this older account to prevent future duplicates.
        duplicateCleanups.push(
          doc.ref.update({
            fcmToken: admin.firestore.FieldValue.delete(),
          })
        );
        return;
      }
      seenTokens.add(token);

      const streak = user.currentStreak || 0;
      const title = streak === 1
        ? 'Keep your momentum going \u{1F525}'
        : `Keep your ${streak}-day streak going \u{1F525}`;
      const body = 'A quick 2-minute practice will protect your daily streak.';

      messages.push({
        token: token,
        notification: {
          title: title,
          body: body,
        },
        data: {
          path: '/streak',
          targetUserId: doc.id,
        },
        android: {
          priority: 'high',
          notification: {
            clickAction: 'FLUTTER_NOTIFICATION_CLICK',
            channelId: 'vowl_streak_channel',
          },
        },
      });
    }
  });

  if (duplicateCleanups.length > 0) {
    try {
      await Promise.all(duplicateCleanups);
      console.log(`Cleaned up ${duplicateCleanups.length} stale duplicate tokens.`);
    } catch (e) {
      console.warn('Error cleaning up duplicate tokens:', e);
    }
  }

  if (messages.length > 0) {
    try {
      const response = await admin.messaging().sendEach(messages);
      console.log(
        `Sent ${response.successCount} streak reminders. Failed: ${response.failureCount}`,
      );

      // Clean up invalid tokens
      const cleanupPromises = [];
      response.responses.forEach((resp, idx) => {
        if (
          resp.error &&
          (resp.error.code === 'messaging/registration-token-not-registered' ||
            resp.error.code === 'messaging/invalid-registration-token')
        ) {
          const failedToken = messages[idx].token;
          // Remove stale token from Firestore
          cleanupPromises.push(
            db.collection('users')
              .where('fcmToken', '==', failedToken)
              .get()
              .then((snapshot) => {
                const deletes = [];
                snapshot.forEach((d) => {
                  deletes.push(d.ref.update({
                    fcmToken: admin.firestore.FieldValue.delete(),
                  }));
                });
                return Promise.all(deletes);
              })
          );
        }
      });
      await Promise.all(cleanupPromises);
    } catch (error) {
      console.error('Error sending streak reminders:', error);
    }
  }
});

// --------------------------------------------------
// Calculates top 50 users server-side to prevent Cache Stampedes on mobile clients.
exports.updateLeaderboardCache = onSchedule('0 */4 * * *', async (event) => {
  const db = admin.firestore();
  console.log('Starting scheduled leaderboard update...');

  try {
    const snapshot = await db
      .collection('users')
      .orderBy('totalExp', 'desc')
      .limit(50)
      .get();

    const usersData = [];

    snapshot.forEach((doc) => {
      const data = doc.data();
      usersData.push({
        id: doc.id,
        displayName: data.displayName || 'Unknown User',
        photoUrl: data.photoUrl || null,
        totalExp: data.totalExp || 0,
        currentStreak: data.currentStreak || 0,
        completedLevels: data.completedLevels || {},
        isPremium: data.isPremium || false,
      });
    });

    const cacheRef = db.collection('metadata').doc('leaderboard_cache');

    await cacheRef.set(
      {
        lastUpdated: admin.firestore.FieldValue.serverTimestamp(),
        users: usersData,
      },
      { merge: true },
    );

    console.log(
      `Successfully updated leaderboard cache with top ${usersData.length} users.`,
    );

    // Also update kids leaderboard cache
    const kidsSnapshot = await db
      .collection('users')
      .orderBy('kidsCoins', 'desc')
      .limit(50)
      .get();

    const kidsData = [];

    kidsSnapshot.forEach((doc) => {
      const data = doc.data();
      kidsData.push({
        id: doc.id,
        displayName: data.displayName || 'Unknown User',
        photoUrl: data.photoUrl || null,
        kidsCoins: data.kidsCoins || 0,
        currentStreak: data.currentStreak || 0,
        completedLevels: data.completedLevels || {},
        isPremium: data.isPremium || false,
      });
    });

    const kidsCacheRef = db
      .collection('metadata')
      .doc('kids_leaderboard_cache');

    await kidsCacheRef.set(
      {
        lastUpdated: admin.firestore.FieldValue.serverTimestamp(),
        users: kidsData,
      },
      { merge: true },
    );

    console.log(
      `Successfully updated kids leaderboard cache with top ${kidsData.length} users.`,
    );
  } catch (error) {
    console.error('Error updating leaderboard cache:', error);
  }
});

exports.validateIAPReceipt = onCall(async (request) => {
  // Ensure user is authenticated
  if (!request.auth) {
    throw new HttpsError('unauthenticated', 'User must be logged in');
  }

  const uid = request.auth.uid;
  const { purchaseToken, productId, grantType, days } = request.data;

  if (!purchaseToken || !productId) {
    throw new HttpsError('invalid-argument', 'Missing purchase data');
  }

  const db = admin.firestore();

  // Rate limiting
  await checkRateLimit(db, uid, 'lastIAPVerify');

  try {
    const { google } = require('googleapis');
    // Use service account credentials for Google Play Developer API
    const auth = new google.auth.GoogleAuth({
      scopes: ['https://www.googleapis.com/auth/androidpublisher'],
    });

    const androidPublisher = google.androidpublisher({ version: 'v3', auth });

    // Verify the purchase with Google Play (Supports both Subscriptions & In-App Products)
    let purchaseStateValid = false;
    if (grantType === 'premium') {
      try {
        const subResponse = await androidPublisher.purchases.subscriptions.get({
          packageName: 'com.vowl.app',
          subscriptionId: productId,
          token: purchaseToken,
        });
        const paymentState = subResponse.data.paymentState;
        purchaseStateValid = (paymentState === 1 || paymentState === 2 || !subResponse.data.cancelReason);
      } catch (subErr) {
        // Fallback to in-app product verification if configured as managed product
        const prodResponse = await androidPublisher.purchases.products.get({
          packageName: 'com.vowl.app',
          productId: productId,
          token: purchaseToken,
        });
        purchaseStateValid = (prodResponse.data.purchaseState === 0);
      }
    } else {
      const prodResponse = await androidPublisher.purchases.products.get({
        packageName: 'com.vowl.app',
        productId: productId,
        token: purchaseToken,
      });
      purchaseStateValid = (prodResponse.data.purchaseState === 0);
    }

    if (!purchaseStateValid) {
      throw new HttpsError('failed-precondition', 'Purchase is not valid');
    }

    // Prevent duplicate processing
    const userRef = db.collection('users').doc(uid);
    const userDoc = await userRef.get();
    if (!userDoc.exists) {
      throw new HttpsError('not-found', 'User not found');
    }
    if (userDoc.data().lastPurchaseToken === purchaseToken) {
      console.warn(`Purchase token already processed for user ${uid}`);
      return { success: true, message: 'Already processed' };
    }

    if (grantType === 'coins') {
      // --------------------------------------------------
      // Map IAP product IDs to coin pack IDs in Firestore
      const productToPackMap = {
        vowl_coins_100: 'starter_pack',
        vowl_coins_110: 'starter_pack',
        vowl_coins_500: 'explorer_pack',
        vowl_coins_1000: 'master_pack',
      };

      const packId = productToPackMap[productId];
      if (!packId) {
        throw new HttpsError(
          'invalid-argument',
          `Unknown coin product: ${productId}`,
        );
      }

      const packDoc = await db.collection('coinPacks').doc(packId).get();
      if (!packDoc.exists) {
        // Fallback amounts if Firestore packs not seeded yet
        const fallbackPacks = {
          starter_pack: { coins: 500, keys: 0 },
          explorer_pack: { coins: 1200, keys: 2 },
          master_pack: { coins: 4000, keys: 8 },
        };
        const fallback = fallbackPacks[packId] || { coins: 0, keys: 0 };

        await db.runTransaction(async (transaction) => {
          const freshUser = await transaction.get(userRef);
          const currentCoins = freshUser.data().coins || 0;
          const currentKeys = freshUser.data().goldenKeys || 0;
          const currentCoinHistory = freshUser.data().coinHistory || [];

          currentCoinHistory.unshift({
            titleKey: 'coin_history.purchased_coin_pack',
            amount: fallback.coins,
            isEarned: true,
            date: new Date().toISOString(),
          });
          if (currentCoinHistory.length > 20) currentCoinHistory.length = 20;

          transaction.update(userRef, {
            coins: currentCoins + fallback.coins,
            goldenKeys: currentKeys + fallback.keys,
            lastPurchaseToken: purchaseToken,
            lastPurchaseProductId: productId,
            lastPurchaseDate: admin.firestore.FieldValue.serverTimestamp(),
            coinHistory: currentCoinHistory,
          });
        });

        console.log(
          `Granted ${fallback.coins} coins (fallback) to user ${uid}`,
        );
        return {
          success: true,
          coinsGranted: fallback.coins,
          keysGranted: fallback.keys,
        };
      }

      const packData = packDoc.data();
      const coinsGranted = packData.coins || 0;
      const keysGranted = packData.keys || 0;

      await db.runTransaction(async (transaction) => {
        const freshUser = await transaction.get(userRef);
        const currentCoins = freshUser.data().coins || 0;
        const currentKeys = freshUser.data().goldenKeys || 0;
        const currentCoinHistory = freshUser.data().coinHistory || [];

        currentCoinHistory.unshift({
          titleKey: 'coin_history.purchased_coin_pack',
          amount: coinsGranted,
          isEarned: true,
          date: new Date().toISOString(),
        });
        if (currentCoinHistory.length > 20) currentCoinHistory.length = 20;

        transaction.update(userRef, {
          coins: currentCoins + coinsGranted,
          goldenKeys: currentKeys + keysGranted,
          lastPurchaseToken: purchaseToken,
          lastPurchaseProductId: productId,
          lastPurchaseDate: admin.firestore.FieldValue.serverTimestamp(),
          coinHistory: currentCoinHistory,
        });
      });

      console.log(
        `Granted ${coinsGranted} coins and ${keysGranted} keys to user ${uid} via IAP`,
      );
      return { success: true, coinsGranted, keysGranted };
    } else {
      // --------------------------------------------------
      const validPremiumProducts = ['vowl_premium_weekly', 'vowl_premium_monthly', 'vowl_premium_yearly'];
      if (!validPremiumProducts.includes(productId)) {
        throw new HttpsError('invalid-argument', 'Invalid premium product ID');
      }

      let premiumDays;
      if (productId.includes('weekly')) premiumDays = 7;
      else if (productId.includes('yearly')) premiumDays = 365;
      else premiumDays = 30; // monthly default

      const userData = userDoc.data();
      const currentExpiry = userData.premiumExpiryDate?.toDate?.() || null;
      const base = (currentExpiry && currentExpiry > new Date()) ? currentExpiry : new Date();
      const expiryDate = new Date(base.getTime() + premiumDays * 24 * 60 * 60 * 1000);

      await userRef.update({
        isPremium: true,
        premiumExpiryDate: admin.firestore.Timestamp.fromDate(expiryDate),
        lastPurchaseToken: purchaseToken,
        lastPurchaseProductId: productId,
        lastPurchaseDate: admin.firestore.FieldValue.serverTimestamp(),
      });

      console.log(
        `Premium granted to user ${uid} until ${expiryDate.toISOString()} via IAP`,
      );
      return { success: true, expiryDate: expiryDate.toISOString() };
    }

  } catch (error) {
    if (error instanceof HttpsError) throw error;
    console.error('IAP validation failed:', error.message || 'Unknown error');
    throw new HttpsError('internal', 'Purchase validation failed');
  }
});

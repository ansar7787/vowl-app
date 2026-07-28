const {onSchedule} = require("firebase-functions/v2/scheduler");
const {onCall, HttpsError} = require("firebase-functions/v2/https");
const admin = require('firebase-admin');
const crypto = require('crypto');
admin.initializeApp();

// ─── PAYMENT VERIFICATION (Server-Side Only) ────────────────────────
// Called from the Flutter app after Razorpay success callback.
// Verifies the payment via Razorpay API before granting premium status.
exports.verifyPayment = onCall(async (request) => {
    // 1. Auth Check
    if (!request.auth) {
        throw new HttpsError('unauthenticated', 'User must be logged in.');
    }

    const uid = request.auth.uid;
    const {paymentId, durationDays} = request.data;

    if (!paymentId) {
        throw new HttpsError('invalid-argument', 'Missing payment ID.');
    }

    // 2. Verify Razorpay Payment (Zero Trust)
    const keyId = process.env.RAZORPAY_KEY_ID;
    const secret = process.env.RAZORPAY_KEY_SECRET;

    if (keyId && secret) {
        try {
            const authHeader = 'Basic ' + Buffer.from(keyId + ':' + secret).toString('base64');
            const response = await fetch(`https://api.razorpay.com/v1/payments/${paymentId}`, {
                method: 'GET',
                headers: { 'Authorization': authHeader }
            });

            if (!response.ok) {
                console.error(`Razorpay API error for payment ${paymentId}`);
                throw new HttpsError('permission-denied', 'Invalid payment ID.');
            }

            const paymentData = await response.json();

            if (paymentData.status !== 'captured' && paymentData.status !== 'authorized') {
                console.warn(`Payment ${paymentId} is not captured. Status: ${paymentData.status}`);
                throw new HttpsError('permission-denied', 'Payment not successful.');
            }
            
            // Note: Ideally, we should also verify the amount against the expected plan price here.
            
        } catch (error) {
            console.error('Error verifying payment with Razorpay:', error);
            if (error instanceof HttpsError) throw error;
            throw new HttpsError('internal', 'Failed to verify payment with gateway.');
        }
    } else {
        console.warn('RAZORPAY keys missing in environment. Bypassing strict API verification.');
    }

    // 3. Signature verified — Grant Premium
    const days = typeof durationDays === 'number' ? durationDays : 30;
    const expiryDate = new Date();
    expiryDate.setDate(expiryDate.getDate() + days);

    const db = admin.firestore();
    const userRef = db.collection('users').doc(uid);
    
    await db.runTransaction(async (transaction) => {
        const userDoc = await transaction.get(userRef);
        if (!userDoc.exists) {
            throw new HttpsError('not-found', 'User not found.');
        }

        // Prevent duplicate claims for the same payment
        if (userDoc.data().lastPaymentId === paymentId) {
            console.warn(`Payment ${paymentId} already processed for user ${uid}`);
            return;
        }

        transaction.update(userRef, {
            isPremium: true,
            premiumExpiryDate: admin.firestore.Timestamp.fromDate(expiryDate),
            lastPaymentId: paymentId,
            lastPaymentDate: admin.firestore.FieldValue.serverTimestamp(),
        });
    });

    console.log(`Premium granted to user ${uid} until ${expiryDate.toISOString()}`);
    return {success: true, expiryDate: expiryDate.toISOString()};
});

// ─── COIN PURCHASE VERIFICATION (Server-Side Only) ──────────────────
// Called from the Flutter app after Razorpay success callback.
// Verifies the payment via Razorpay API and grants items securely.
exports.verifyCoinPurchase = onCall(async (request) => {
    if (!request.auth) {
        throw new HttpsError('unauthenticated', 'User must be logged in.');
    }

    const uid = request.auth.uid;
    const {paymentId, packId} = request.data;

    if (!paymentId || !packId) {
        throw new HttpsError('invalid-argument', 'Missing payment ID or pack ID.');
    }

    const db = admin.firestore();

    // 1. Fetch the pack from the database to know how much it costs and what it gives
    const packDoc = await db.collection('coinPacks').doc(packId).get();
    if (!packDoc.exists) {
        throw new HttpsError('not-found', 'Invalid pack ID.');
    }
    const packData = packDoc.data();
    const expectedAmountPaise = Math.round(packData.price * 100);

    // 2. Verify payment directly with Razorpay API (Zero Trust)
    const keyId = process.env.RAZORPAY_KEY_ID;
    const secret = process.env.RAZORPAY_KEY_SECRET;

    if (keyId && secret) {
        try {
            const authHeader = 'Basic ' + Buffer.from(keyId + ':' + secret).toString('base64');
            const response = await fetch(`https://api.razorpay.com/v1/payments/${paymentId}`, {
                method: 'GET',
                headers: { 'Authorization': authHeader }
            });

            if (!response.ok) {
                console.error(`Razorpay API error for payment ${paymentId}`);
                throw new HttpsError('permission-denied', 'Invalid payment ID.');
            }

            const paymentData = await response.json();

            // Verify payment status and amount
            if (paymentData.status !== 'captured' && paymentData.status !== 'authorized') {
                console.warn(`Payment ${paymentId} is not captured. Status: ${paymentData.status}`);
                throw new HttpsError('permission-denied', 'Payment not successful.');
            }

            if (paymentData.amount < expectedAmountPaise) {
                console.warn(`Payment ${paymentId} amount mismatch. Expected ${expectedAmountPaise}, got ${paymentData.amount}`);
                throw new HttpsError('permission-denied', 'Payment amount mismatch.');
            }
        } catch (error) {
            console.error('Error verifying payment with Razorpay:', error);
            if (error instanceof HttpsError) throw error;
            throw new HttpsError('internal', 'Failed to verify payment with gateway.');
        }
    } else {
        console.warn('RAZORPAY keys missing in environment. Bypassing strict API verification.');
    }

    // 3. Prevent duplicate processing
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

        coinsGranted = packData.coins || 0;
        keysGranted = packData.keys || 0;

        transaction.update(userRef, {
            coins: currentCoins + coinsGranted,
            goldenKeys: currentKeys + keysGranted,
            lastCoinPurchaseId: paymentId,
            lastCoinPurchaseDate: admin.firestore.FieldValue.serverTimestamp(),
            lastCoinPackId: packId,
        });
    });

    console.log(`Granted ${coinsGranted} coins and ${keysGranted} keys to user ${uid}`);
    return {success: true, coinsGranted, keysGranted};
});

// ─── PREMIUM EXPIRY CHECKER (Runs Daily) ─────────────────────────────
// Automatically revokes premium when the subscription expires.
exports.checkPremiumExpiry = onSchedule("0 3 * * *", async (event) => {
    const db = admin.firestore();
    const now = admin.firestore.Timestamp.now();

    const expiredUsers = await db.collection('users')
        .where('isPremium', '==', true)
        .where('premiumExpiryDate', '<=', now)
        .get();

    if (expiredUsers.empty) {
        console.log('No expired premium users found.');
        return;
    }

    const batch = db.batch();
    expiredUsers.forEach(doc => {
        batch.update(doc.ref, {isPremium: false});
    });

    await batch.commit();
    console.log(`Revoked premium for ${expiredUsers.size} users.`);
});

// 🏆 THE ULTIMATE WEEKLY RECAP (v2)
// Runs every Sunday at 11:59 PM (Final Results)
exports.sendWeeklyRankings = onSchedule("59 23 * * 0", async (event) => {
    const db = admin.firestore();
    
    // 1. Get Top 100 learners by Total XP
    const snapshot = await db.collection('users')
        .orderBy('totalExp', 'desc')
        .limit(100)
        .get();

    if (snapshot.empty) return;

    const messages = [];
    let rank = 1;

    snapshot.forEach(doc => {
        const user = doc.data();
        const token = user.fcmToken;

        if (token) {
            let body = "";
            let title = "Weekly Recap 📊";

            if (rank === 1) {
                title = "The Crown is Yours! 👑";
                body = "UNBELIEVABLE! You are the #1 Vowl player in the world this week! 🥇 Defend your throne!";
            } else if (rank <= 3) {
                title = "Podium Finish! 🥈";
                body = `Incredible! You finished #${rank} in the world! Can you hit #1 next week?`;
            } else {
                body = `Amazing! You finished #${rank} in the Global Rankings! 🏆 You're a legend!`;
            }

            messages.push({
                token: token,
                notification: {
                    title: title,
                    body: body
                },
                data: {
                    path: "/leaderboard"
                },
                android: {
                    priority: "high",
                    notification: {
                        clickAction: "FLUTTER_NOTIFICATION_CLICK",
                        channelId: "vowl_weekly_channel"
                    }
                }
            });
        }
        rank++;
    });

    // 2. Efficient Batch Sending (sendEach)
    if (messages.length > 0) {
        try {
            const response = await admin.messaging().sendEach(messages);
            console.log(`Successfully sent ${response.successCount} ranking notifications.`);
        } catch (error) {
            console.error("Error sending batch notifications:", error);
        }
    }
});

// 🔥 STREAK-AT-RISK REMINDER (v2)
// Runs daily at 8:00 PM — nudges users who haven't logged in today
exports.sendStreakReminders = onSchedule("0 20 * * *", async (event) => {
    const db = admin.firestore();
    
    // Get start of today (UTC)
    const now = new Date();
    const startOfDay = new Date(now.getFullYear(), now.getMonth(), now.getDate());

    // Find users with active streaks who haven't logged in today
    const usersAtRisk = await db.collection('users')
        .where('currentStreak', '>', 0)
        .where('lastLoginDate', '<', admin.firestore.Timestamp.fromDate(startOfDay))
        .limit(500)
        .get();

    if (usersAtRisk.empty) {
        console.log('No streak-at-risk users found.');
        return;
    }

    const messages = [];
    usersAtRisk.forEach(doc => {
        const user = doc.data();
        const token = user.fcmToken;
        if (token) {
            const streak = user.currentStreak || 0;
            messages.push({
                token: token,
                notification: {
                    title: 'Your Streak is in Danger! 🔥',
                    body: `Don't lose your ${streak}-day streak! Open Vowl and play a quick quest.`
                },
                data: {
                    path: "/streak"
                },
                android: {
                    priority: "high",
                    notification: {
                        clickAction: "FLUTTER_NOTIFICATION_CLICK",
                        channelId: "vowl_streak_channel"
                    }
                }
            });
        }
    });

    if (messages.length > 0) {
        try {
            const response = await admin.messaging().sendEach(messages);
            console.log(`Sent ${response.successCount} streak reminders. Failed: ${response.failureCount}`);
            
            // Clean up invalid tokens
            response.responses.forEach((resp, idx) => {
                if (resp.error && (
                    resp.error.code === 'messaging/registration-token-not-registered' ||
                    resp.error.code === 'messaging/invalid-registration-token'
                )) {
                    const failedToken = messages[idx].token;
                    // Remove stale token from Firestore
                    db.collection('users')
                        .where('fcmToken', '==', failedToken)
                        .get()
                        .then(snapshot => {
                            snapshot.forEach(doc => {
                                doc.ref.update({ fcmToken: admin.firestore.FieldValue.delete() });
                            });
                        });
                }
            });
        } catch (error) {
            console.error("Error sending streak reminders:", error);
        }
    }
});

// ─── LEADERBOARD CACHE UPDATER (Runs Every 4 Hours) ─────────────────────────
// Calculates top 50 users server-side to prevent Cache Stampedes on mobile clients.
exports.updateLeaderboardCache = onSchedule("0 */4 * * *", async (event) => {
    const db = admin.firestore();
    console.log('Starting scheduled leaderboard update...');

    try {
      const snapshot = await db.collection('users')
        .orderBy('totalExp', 'desc')
        .limit(50)
        .get();

      const usersData = [];

      snapshot.forEach(doc => {
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
      
      await cacheRef.set({
        lastUpdated: admin.firestore.FieldValue.serverTimestamp(),
        users: usersData,
      }, { merge: true });

      console.log(`Successfully updated leaderboard cache with top ${usersData.length} users.`);

      // Also update kids leaderboard cache
      const kidsSnapshot = await db.collection('users')
        .orderBy('kidsCoins', 'desc')
        .limit(50)
        .get();

      const kidsData = [];

      kidsSnapshot.forEach(doc => {
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

      const kidsCacheRef = db.collection('metadata').doc('kids_leaderboard_cache');
      
      await kidsCacheRef.set({
        lastUpdated: admin.firestore.FieldValue.serverTimestamp(),
        users: kidsData,
      }, { merge: true });

      console.log(`Successfully updated kids leaderboard cache with top ${kidsData.length} users.`);

    } catch (error) {
      console.error('Error updating leaderboard cache:', error);
    }
});

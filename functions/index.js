const {onSchedule} = require("firebase-functions/v2/scheduler");
const {onCall, HttpsError} = require("firebase-functions/v2/https");
const admin = require('firebase-admin');
const crypto = require('crypto');
admin.initializeApp();

// ─── PAYMENT VERIFICATION (Server-Side Only) ────────────────────────
// Called from the Flutter app after Razorpay success callback.
// Verifies the payment signature before granting premium status.
exports.verifyPayment = onCall(async (request) => {
    // 1. Auth Check
    if (!request.auth) {
        throw new HttpsError('unauthenticated', 'User must be logged in.');
    }

    const uid = request.auth.uid;
    const {orderId, paymentId, signature, durationDays} = request.data;

    if (!orderId || !paymentId || !signature) {
        throw new HttpsError('invalid-argument', 'Missing payment details.');
    }

    // 2. Verify Razorpay Signature
    // IMPORTANT: Store RAZORPAY_KEY_SECRET in Firebase environment config:
    //   firebase functions:config:set razorpay.secret="YOUR_SECRET_KEY"
    const secret = process.env.RAZORPAY_KEY_SECRET || '';
    if (!secret) {
        console.error('FATAL: RAZORPAY_KEY_SECRET not configured!');
        throw new HttpsError('internal', 'Payment verification unavailable.');
    }

    const expectedSignature = crypto
        .createHmac('sha256', secret)
        .update(`${orderId}|${paymentId}`)
        .digest('hex');

    if (expectedSignature !== signature) {
        console.warn(`Payment verification FAILED for user ${uid}. Possible fraud attempt.`);
        throw new HttpsError('permission-denied', 'Invalid payment signature.');
    }

    // 3. Signature verified — Grant Premium
    const days = typeof durationDays === 'number' ? durationDays : 30;
    const expiryDate = new Date();
    expiryDate.setDate(expiryDate.getDate() + days);

    const db = admin.firestore();
    await db.collection('users').doc(uid).update({
        isPremium: true,
        premiumExpiryDate: admin.firestore.Timestamp.fromDate(expiryDate),
        // Log the payment for audit trail
        lastPaymentId: paymentId,
        lastPaymentDate: admin.firestore.FieldValue.serverTimestamp(),
    });

    console.log(`Premium granted to user ${uid} until ${expiryDate.toISOString()}`);
    return {success: true, expiryDate: expiryDate.toISOString()};
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

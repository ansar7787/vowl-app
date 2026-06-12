# 🔥 Firebase Subscription Plans Setup Guide

**Status:** COMPLETE - Zero Manual Setup Needed ✅

This guide will help you deploy subscription plans to Firebase without any errors.

---

## 📋 Prerequisites Check

Before starting, verify you have:

- ✅ Node.js installed (v14+)
- ✅ Firebase project "vowl-acbc5" set up
- ✅ Firestore database enabled
- ✅ Admin access to Firebase Console

---

## 🚀 Automated Setup (RECOMMENDED - Zero Errors)

### Step 1: Download Firebase Service Account Key

**IMPORTANT:** This key is private. NEVER commit it to GitHub!

1. Go to: **Firebase Console** → **Project Settings** (gear icon)
   - URL: `https://console.firebase.google.com/project/vowl-acbc5/settings/serviceaccounts/adminsdk`

2. Click **"Service Accounts"** tab

3. Click **"Generate New Private Key"**
   - A JSON file will download

4. Save the file as `serviceAccountKey.json` in project root:
   ```
   vowl/
   ├── serviceAccountKey.json    ← Save here
   ├── setup-subscription-plans.js
   ├── firestore.rules
   └── ...
   ```

**Security:** This file is already in `.gitignore` (won't be committed)

---

### Step 2: Install Firebase Admin SDK

Open terminal in project root and run:

```bash
npm install firebase-admin
```

Expected output:
```
added X packages
```

---

### Step 3: Run the Setup Script

```bash
node setup-subscription-plans.js
```

**Expected Output:**
```
🔄 Starting Firebase Subscription Plans setup...

📝 Clearing existing plans...

📝 Adding new subscription plans...
   ✓ Created plan: Weekly (₹39.00)
   ✓ Created plan: Monthly (₹99.00)
   ✓ Created plan: Yearly (₹799.00)

✅ Verifying plans...
   Found 3 plans in Firestore:

   Plan: Weekly
   - Price: ₹39 (was ₹49)
   - Duration: 7 days
   - Tag: FESTIVE OFFER
   - ID: weekly_offer

   ...

✅ ✅ ✅ SUCCESS! All subscription plans added to Firebase
```

---

## ✅ Verification (Always Do This)

### In Firebase Console

1. Go to: **Firestore Database**
2. Click **"subscriptionPlans"** collection
3. Should see **3 documents**:
   - `weekly_offer`
   - `monthly_offer`
   - `yearly_offer`

Each document should have:
```json
{
  "id": "monthly_offer",
  "name": "Monthly",
  "price": 99.0,
  "oldPrice": 149.0,
  "days": 30,
  "tag": "MOST POPULAR",
  "color": "#FF6366F1",
  "displayOrder": 1
}
```

---

### Test in Your App

1. Run app: `flutter run`
2. Open Premium Screen
3. Verify plans load from Firebase
4. No error message should appear

✅ If you see 3 plans displayed → **Setup Success!**
❌ If you see "Failed to load plans" → Check troubleshooting below

---

## 🆘 Troubleshooting

### Error: "serviceAccountKey.json not found"

**Solution:**
1. Download key from Firebase Console (see Step 1 above)
2. Save as `serviceAccountKey.json` in project root
3. Run script again

### Error: "Permission denied" in setup script

**Solution:**
```bash
# Make script executable
chmod +x setup-subscription-plans.js

# Run again
node setup-subscription-plans.js
```

### Error: "PERMISSION_DENIED" in app

**Cause:** Firestore rules not updated correctly

**Solution:**
1. Check `firestore.rules` has subscriptionPlans section
2. Deploy rules: `firebase deploy --only firestore:rules`
3. Wait 1-2 minutes
4. Restart app

### Plans not loading in app

**Checklist:**
- [ ] Plans added to Firestore (verified in console)
- [ ] Firestore rules deployed
- [ ] App authenticated (logged in)
- [ ] Internet connection active
- [ ] App restarted after setup

---

## 📝 Manual Firebase Console Method (If Script Fails)

If the script doesn't work, use this manual method:

### Create Document 1: weekly_offer

1. Firestore → **subscriptionPlans** collection (create if needed)
2. Click **"Add Document"**
3. Set Document ID: `weekly_offer`
4. Add fields:

| Field | Type | Value |
|-------|------|-------|
| id | String | weekly_offer |
| name | String | Weekly |
| price | Number | 39.0 |
| oldPrice | Number | 49.0 |
| days | Number | 7 |
| tag | String | FESTIVE OFFER |
| color | String | #FFF43F5E |
| displayOrder | Number | 0 |

5. Click **"Save"**

### Create Document 2: monthly_offer

Document ID: `monthly_offer`

| Field | Type | Value |
|-------|------|-------|
| id | String | monthly_offer |
| name | String | Monthly |
| price | Number | 99.0 |
| oldPrice | Number | 149.0 |
| days | Number | 30 |
| tag | String | MOST POPULAR |
| color | String | #FF6366F1 |
| displayOrder | Number | 1 |

### Create Document 3: yearly_offer

Document ID: `yearly_offer`

| Field | Type | Value |
|-------|------|-------|
| id | String | yearly_offer |
| name | String | Yearly |
| price | Number | 799.0 |
| oldPrice | Number | 1499.0 |
| days | Number | 365 |
| tag | String | BEST VALUE |
| color | String | #FF10B981 |
| displayOrder | Number | 2 |

---

## 🔄 Updating Plans Later

To change prices or add plans:

### Option 1: Use Script (Recommended)
Edit `setup-subscription-plans.js` → Run again

### Option 2: Firebase Console
- Click document
- Edit any field
- Click **"Save"**
- App fetches new price immediately (within 1 hour)

---

## 🔐 Security Best Practices

✅ **DO:**
- Keep `serviceAccountKey.json` in `.gitignore`
- Use only admin keys for setup scripts
- Verify firestore.rules quarterly
- Monitor Firestore usage in console

❌ **DON'T:**
- Commit `serviceAccountKey.json` to GitHub
- Share the key with others
- Use in production code (only in build scripts)
- Leave it in public repositories

---

## 📞 Quick Reference

| Task | Command |
|------|---------|
| Setup plans | `node setup-subscription-plans.js` |
| Deploy rules | `firebase deploy --only firestore:rules` |
| Check status | Visit Firestore Console → subscriptionPlans |
| Test app | `flutter run` → Open Premium Screen |

---

## ✅ Final Checklist Before Deployment

- [ ] `serviceAccountKey.json` downloaded (not in `.gitignore`)
- [ ] `setup-subscription-plans.js` created in project root
- [ ] Script run successfully (✅ output shown)
- [ ] 3 plans visible in Firebase Console
- [ ] Firestore rules updated with subscriptionPlans access
- [ ] `firestore.rules` deployed
- [ ] App tested on device
- [ ] Plans load and display correctly
- [ ] No errors in console logs

---

**Status:** Ready for Production Deployment ✅

# Ultimate Play Store CI/CD Deployment Guide

This guide covers the start-to-end process of taking your Flutter app to production, securing your code against reverse engineering, and fully automating all future updates.

---

## Phase 1: The Initial Setup (Done Once Manually)
*Google requires the very first upload of any app to be done by a human, not a robot.*

### 1. Update Version Code
Open `pubspec.yaml` and set your initial release version:
```yaml
version: 1.0.0+1
```
*(Every future update must increase the number after the `+`, e.g., `+2`, `+3`)*

### 2. Generate the Security Keystore
Run this in your terminal to generate a digital padlock (`upload-keystore.jks`) that proves you own the app:
```bash
keytool -genkey -v -keystore c:\Users\asus\upload-keystore.jks -storetype JKS -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```
**⚠️ CRITICAL:** Backup this `.jks` file safely. If you lose it, you can never update your app again!

### 3. Configure Android Gradle
Create a file named `android/key.properties` and add your passwords:
```properties
storePassword=YOUR_PASSWORD_HERE
keyPassword=YOUR_PASSWORD_HERE
keyAlias=upload
storeFile=c:/Users/asus/upload-keystore.jks
```

### 4. Build the App (With Obfuscation!)
To protect against reverse engineering, build the app using the obfuscation flags:
```bash
flutter build appbundle --release --obfuscate --split-debug-info=build/app/outputs/symbols
```
This generates your `app-release.aab` file inside `build/app/outputs/bundle/release/`.

### 5. Upload to Play Console
1. Go to the **Google Play Console**.
2. Create your App.
3. Fill in the Store Listing (Name, Description, Screenshots, Privacy Policy URL).
4. Go to **Testing > Internal Testing** and upload your `.aab` file manually.

---

## Phase 2: Building the Robot Bridge
*Allowing GitHub Actions to talk to Google Play.*

### 1. Create a Google Cloud Service Account
1. Go to Google Cloud Console.
2. Navigate to **IAM & Admin > Service Accounts**.
3. Create a new Service Account.
4. Go to the "Keys" tab, click **Add Key > Create new key > JSON**.
5. Download this `.json` file to your computer.

### 2. Grant Play Console Access
1. Go back to the Google Play Console.
2. Go to **Users and Permissions**.
3. Invite the email address of the Service Account you just created.
4. Give it the **"Release Manager"** role.

---

## Phase 3: Securing Passwords in GitHub
*We cannot put passwords in the code. We use GitHub Secrets instead.*

### 1. Base64 Encode your Keystore
Because you can't upload a `.jks` file to GitHub Secrets, you must convert it to a giant string of text. Run this in PowerShell:
```powershell
[Convert]::ToBase64String([IO.File]::ReadAllBytes("c:\Users\asus\upload-keystore.jks")) | Set-Clipboard
```

### 2. Add Secrets to GitHub
Go to your GitHub Repository -> **Settings > Secrets and variables > Actions**. Add these exact secrets:
1. `PLAY_STORE_JSON`: (Paste the entire contents of the `.json` file you downloaded)
2. `KEYSTORE_BASE64`: (Paste the Base64 text you just copied)
3. `KEYSTORE_PASSWORD`: (Your keystore password)
4. `KEY_ALIAS`: upload
5. `KEY_PASSWORD`: (Your key password)

---

## Phase 4: The CI/CD Automation Script
*The final step. Add this to the bottom of your `.github/workflows/flutter_ci.yml`.*

```yaml
  deploy:
    # Only run the deploy job if the build job was successful
    needs: build 
    # Only run this when code is pushed to master
    if: github.ref == 'refs/heads/master'
    runs-on: ubuntu-latest
    
    steps:
      - name: Clone repository
        uses: actions/checkout@v4

      - name: Set up Flutter
        uses: subosito/flutter-action@v2
        with:
          channel: stable
          flutter-version: "3.38.7"
          
      - name: Decode Keystore
        run: |
          echo "${{ secrets.KEYSTORE_BASE64 }}" | base64 --decode > android/app/upload-keystore.jks

      - name: Create key.properties
        run: |
          echo "storePassword=${{ secrets.KEYSTORE_PASSWORD }}" > android/key.properties
          echo "keyPassword=${{ secrets.KEY_PASSWORD }}" >> android/key.properties
          echo "keyAlias=${{ secrets.KEY_ALIAS }}" >> android/key.properties
          echo "storeFile=upload-keystore.jks" >> android/key.properties

      - name: Build and Obfuscate App Bundle
        run: flutter build appbundle --release --obfuscate --split-debug-info=build/app/outputs/symbols

      - name: Upload to Google Play
        uses: r0adkll/upload-google-play@v1
        with:
          serviceAccountJsonPlainText: ${{ secrets.PLAY_STORE_JSON }}
          packageName: com.yourcompany.vowl # Change to your actual package name
          releaseFiles: build/app/outputs/bundle/release/app-release.aab
          track: internal # Sends to Internal Testing. Change to 'production' later!
```

---

## Phase 5: The Magic 🪄
Once this is set up, you never have to do it again. Whenever you want to launch an update:
1. Change `version: 1.0.1+2` in `pubspec.yaml`
2. Push your code to `master`
3. Wait 15 minutes. The robots will securely build, obfuscate, sign, and launch your app!

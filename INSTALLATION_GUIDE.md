# Complete Mobile Phone Installation Guide via GitHub 📱

This guide covers **all the possible ways** to download and install the **Student Expense Manager** app directly onto Android and iOS (iPhone) smartphones using GitHub.

---

## 📑 Summary of All Distribution & Installation Methods

| Method | Target OS | Requirements | Setup Effort | Best For |
| :--- | :--- | :--- | :--- | :--- |
| **1. Direct GitHub Releases APK** | Android | None (Browser) | Instant | All Android users & students |
| **2. Scannable QR Code / Landing Page** | Android / iOS | Phone Camera | Instant | Quick phone download from PC screen |
| **3. Progressive Web App (PWA)** | iOS & Android | Safari / Chrome | 1 Tap | iPhone users & zero-install Android |
| **4. GitHub Actions CI/CD Artifacts** | Android | GitHub Account | Automated | Testers, developers, & pre-releases |
| **5. In-App Auto-Updater via GitHub API** | Android | Already Installed | Built-in | Existing users getting new versions |
| **6. iOS Sideloading (AltStore/SideStore)** | iOS (iPhone) | Free Apple ID | Medium | Native iOS package without App Store |

---

## 🤖 Method 1: Direct GitHub Releases APK Download (Android)

This is the fastest, standard way for Android users to get the native app.

### 📥 Download Link:
👉 **[Download Latest app-release.apk](https://github.com/alemigaedwin/student-expense-manager-/releases/latest/download/app-release.apk)**

### 📱 4-Step Installation Instructions:
1. **Download the APK**: Tap the download link above in Chrome or any browser on your Android smartphone.
2. **Accept Download Prompt**: If your browser shows *"File might be harmful. Do you want to download app-release.apk anyway?"*, tap **"Download anyway"**.
3. **Open the File**: Once downloaded, tap the notification or go to your phone's **Files / Downloads** app and tap `app-release.apk`.
4. **Enable Installation**:
   - If Android prompts *"For your security, your phone is not allowed to install unknown apps from this source"*, tap **Settings**.
   - Toggle **"Allow from this source"** to **ON**.
   - Go back and tap **Install**.
5. **Google Play Protect**: If Play Protect shows *"Unrecognised app"*, tap **"More details"** -> **"Install anyway"**.

---

## 📲 Method 2: Download Landing Page & Instant QR Code

For users browsing on desktop or sharing the app with classmates:

1. Open the mobile download portal:
   👉 **`https://alemigaedwin.github.io/student-expense-manager-/download.html`**
2. Point any smartphone camera at the QR code below to immediately download the APK:

```
[QR Code for Direct APK Download]
URL: https://github.com/alemigaedwin/student-expense-manager-/releases/latest/download/app-release.apk
```

*(You can also generate and display this QR code anywhere using: `https://api.qrserver.com/v1/create-qr-code/?size=250x250&data=https://github.com/alemigaedwin/student-expense-manager-/releases/latest/download/app-release.apk`)*

---

## 🍏 Method 3: Progressive Web App (PWA) on iPhone (iOS) & Android

Because Apple iOS restricts raw APK/IPA sideloading without developer certificates, the **PWA via GitHub Pages** provides a 100% native feel on iPhones with zero app store fees or certificates required.

### 🌐 Live Web App URL:
👉 **[https://alemigaedwin.github.io/student-expense-manager-/](https://alemigaedwin.github.io/student-expense-manager-/)**

### 🍏 On iPhone (iOS Safari):
1. Open the URL in **Safari** on your iPhone.
2. Tap the **Share** button (the square with an arrow pointing up 📤 at the bottom toolbar).
3. Scroll down the actions and tap **"Add to Home Screen"** (➕).
4. Tap **"Add"** in the top-right corner.
5. The **Expense Manager** icon will appear on your iPhone home screen. It opens in full-screen standalone mode and stores student data offline on the phone!

### 🤖 On Android (Google Chrome):
1. Open the URL in **Chrome** on Android.
2. Chrome will display an automatic banner: *"Add Student Expense Manager to Home screen"* (or tap the 3-dots menu -> **"Install app"**).
3. Tap **Install**. It creates a native WebAPK on your phone.

---

## ⚙️ Method 4: Automated CI/CD via GitHub Actions (Zero-Effort Builds)

The repository includes pre-configured GitHub Actions workflows:

### 1. `.github/workflows/build_and_release_apk.yml`
- **Triggers**: Whenever you push code to `main`, push a version tag (`v1.0.0`), or click **"Run workflow"** manually.
- **Actions taken automatically**:
  1. Sets up Java 17 and Flutter.
  2. Runs `flutter pub get`.
  3. Builds `app-release.apk` with debug signing (guaranteed to install on all Android devices without signature errors).
  4. Publishes `app-release.apk` as a new GitHub Release.
  5. Saves the APK as a workflow artifact available under the **Actions** tab.

### How to trigger a build manually:
1. Go to your GitHub repository: `https://github.com/alemigaedwin/student-expense-manager-`
2. Click the **Actions** tab.
3. Select **"Build & Release Android APK"** from the left sidebar.
4. Click **"Run workflow"** -> select branch `main` -> click **"Run workflow"**.
5. Within ~3 minutes, the new APK will be published to your Releases and Artifacts!

---

## 🔄 Method 5: In-App Self-Updating via GitHub API

Once a user has installed the app, they do not need to revisit GitHub manually:

1. **Automatic Check**: The app includes `UpdateService`, which queries GitHub's public API:
   `https://api.github.com/repos/alemigaedwin/student-expense-manager-/releases/latest`
2. **Version Comparison**: If the release tag on GitHub is higher than the installed version (e.g. `1.0.1` vs `1.0.0`), the app displays an update dialog.
3. **Single-Tap Update**: The student taps **"Update Now"**, the APK downloads in the background, and Android opens the package installer to update the app while preserving all local expense records.

---

## 🛠️ Method 6: Sideloading Native IPA on iOS (AltStore / SideStore / Sideloadly)

For users who want the native Flutter iOS app installed without using the App Store:

1. **Build the IPA**:
   - Run `flutter build ipa --no-codesign` on a Mac or macOS GitHub Actions runner.
   - Compress the `.app` payload into `app-release.ipa` and attach to GitHub Releases.
2. **Install via AltStore / SideStore / Sideloadly**:
   - Download [AltStore](https://altstore.io/) or [Sideloadly](https://sideloadly.io/).
   - Open GitHub Releases on the iPhone or PC.
   - Select `app-release.ipa` and sign with your free Apple ID.
   - AltStore refreshes the app automatically over Wi-Fi.

---

## 🔍 Troubleshooting Phone Installations

### Issue: "App not installed" or "Package appears to be corrupt"
- **Solution**: Uninstall any previous development version with conflicting signatures before installing the release APK, or verify that your Android version is Android 5.0 (API 21) or higher.

### Issue: "Blocked by Play Protect"
- **Reason**: The APK is distributed directly via GitHub and has not been submitted through the Google Play Store developer console.
- **Solution**: Tap **"More details"** -> **"Install anyway"**. The app has zero trackers, zero ads, and stores data locally.

### Issue: Download starts as a `.zip` file on some Samsung/Xiaomi browsers
- **Solution**: In the browser's download manager or My Files, rename the file extension from `.zip` to `.apk`, then tap to install.

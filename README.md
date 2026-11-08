# Student Expense Manager 📱💰

A real, modern, cross-platform Flutter application and backend for students to manage daily expenses, income, budgets, notebook entries, and bill reminders.

Designed with an **Offline-First architecture**: all student records are stored locally and securely on the phone with zero internet required, plus automatic over-the-air updates pushed from GitHub!

---

## 📲 All Ways to Download & Install on a Phone

For the complete breakdown of every distribution channel, see the **[Detailed Installation Guide](INSTALLATION_GUIDE.md)**.

### 🌟 Option 1: Direct Android APK Download (Recommended)
👉 **[📥 Click Here to Download app-release.apk](https://github.com/alemigaedwin/student-expense-manager-/releases/latest/download/app-release.apk)**

#### ⚡ 3-Step Installation on Android:
1. Tap the download link above on your phone (or scan the QR code below).
2. Open the downloaded file from your Notifications or **Downloads** folder.
3. Tap **Install** (If your phone says *"Install unknown apps"*, tap **Settings** and turn **Allow from this source** ON. If Google Play Protect asks, choose *"More details"* -> *"Install anyway"*).
4. Tap **Open** and start tracking your student finances offline!

#### 📷 Scan to Download on Phone:
<img src="https://api.qrserver.com/v1/create-qr-code/?size=180x180&data=https://github.com/alemigaedwin/student-expense-manager-/releases/latest/download/app-release.apk" width="180" alt="Scan QR code to download APK" />

---

### 🍏 Option 2: iPhone (iOS) & Universal Web App (PWA)
👉 **[Launch Live App on Mobile Safari](https://alemigaedwin.github.io/student-expense-manager-/)**
👉 **[Mobile Download & Setup Portal](https://alemigaedwin.github.io/student-expense-manager-/download.html)**

1. Open the link above in **Safari** on your iPhone.
2. Tap the **Share** button (📤 at the bottom toolbar).
3. Tap **"Add to Home Screen"** (➕) and tap **"Add"**.
4. The app installs as a native, offline-capable application directly on your iOS home screen!

---

### ⚙️ Option 3: GitHub Actions CI/CD (Automated Builds)
Whenever you push code or trigger a workflow:
- `.github/workflows/build_and_release_apk.yml` automatically compiles `app-release.apk` and publishes it to **GitHub Releases** and **Actions Artifacts**.
- `.github/workflows/deploy-pwa.yml` automatically compiles and deploys the latest PWA to **GitHub Pages**.

---

## 🔄 Automatic In-App Updates from GitHub

When you push updates or new versions to your GitHub repository:
1. **GitHub Actions automatically compiles the new APK** and publishes it to your GitHub Releases and Workflow Artifacts.
2. **In-App Auto-Update Check**: Whenever a user opens the app (or taps *"Check for GitHub Updates"* in Settings), the app checks the GitHub Releases API.
3. If an update is detected, an update window pops up displaying the release notes and a single-tap **"Update Now"** button.
4. Tapping "Update Now" downloads the new APK and prompts Android's package installer to install the update!

---

## 📴 100% Offline Mode & Local Phone Storage

- **Local Storage Engine**: Uses encrypted, ultra-fast **Hive** local storage on the phone.
- **Zero Internet Required**: Works in airplane mode, campus basements, or without mobile data.
- **Immediate Local Persistence**: Every transaction, category, budget, note, and reminder is saved to phone storage the moment you create or edit it.
- **Zero Data Loss**: Closing the app, turning off the phone, or lacking Wi-Fi never loses any data.
- **Real Working Application**: Clean starting database with real student categories and payment methods, without any dummy or sample records.
- **Optional Cloud Backup**: If students ever want cloud backup, they can connect to a MySQL server anytime from **Settings**.

---

## 🌐 Live Web & PWA App on GitHub Pages

You can also use and install the app on any desktop or mobile browser (iPhone, Mac, Windows, Linux, Android):

👉 **[Launch Live App (PWA)](https://alemigaedwin.github.io/student-expense-manager-/)**

- **iPhone (iOS)**: In Safari, tap **Share** -> **"Add to Home Screen"** to install as a native offline app.
- **Windows / Mac**: In Chrome or Edge, click the **"Install App"** icon in the address bar to install as a standalone desktop program.

---

## 🚀 How to Push to GitHub & Trigger the Automatic APK Build

To push your changes to GitHub and trigger the automatic APK build & release:

```bash
git add .
git commit -m "Fix Android APK release build, set minSdk 21, and remove demo content"
git push origin main
```

Once pushed:
1. Open your repository at `https://github.com/alemigaedwin/student-expense-manager-`.
2. Click the **Actions** tab to watch the **Build and Release Android APK** workflow compile `app-release.apk`.
3. Under the **Releases** tab on the right side (and under **Artifacts** in the workflow run), you will see the ready-to-download `app-release.apk`!

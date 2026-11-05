# Student Expense Manager

A complete, cross-platform Flutter application and PHP/MySQL backend for students to manage income, expenses, budgets, notes, and reminders.

---

## 🌐 Live Web Demo on GitHub Pages

You can access and interact with the live system directly in your web browser:

👉 **[Launch Student Expense Manager Live Web App](https://alemigaedwin.github.io/student-expense-manager-/)**

> **Quick Interactive Preview**: When the app opens, click **"Explore Live Demo (Guest Mode)"** to immediately interact with the full dashboard, charts, transactions, budget tracking, and calendar with sample student data!
> You can also connect to your live MySQL backend by tapping the **Server: ...** button at the bottom of the Login screen.

---

## 🚀 How to Publish / Push to Your GitHub Repository

To push this codebase to your repository `https://github.com/alemigaedwin/student-expense-manager-.git` and activate the live link:

### Step 1: Push Code to GitHub
Open your terminal in `c:\xampp\htdocs\student_expense_manager_backend` (or the Terminal tab in Android Studio) and run:

```bash
git init
git remote add origin https://github.com/alemigaedwin/student-expense-manager-.git
git branch -M main
git add .
git commit -m "Deploy Student Expense Manager with GitHub Pages"
git push -u origin main --force
```

### Step 2: Enable GitHub Pages (Takes 30 Seconds)
1. Open your repository in your browser:
   [https://github.com/alemigaedwin/student-expense-manager-](https://github.com/alemigaedwin/student-expense-manager-)
2. Click on **Settings** (top menu bar of your repository).
3. In the left sidebar, click on **Pages**.
4. Under **Build and deployment** > **Source**:
   * Select **GitHub Actions**.
5. Go to the **Actions** tab on your repository:
   * You will see the **"Deploy to GitHub Pages"** workflow running automatically.
   * Once it completes (green checkmark), your app is officially live at:
     **`https://alemigaedwin.github.io/student-expense-manager-/`**

---

## 📱 Device Compatibility & Universal Installation

The project has been configured to build and install on **any smartphone**:
* **Minimum Android SDK**: Set to API 21 (Android 5.0 Lollipop up to Android 15), covering **99.6%+** of all active Android devices worldwide.
* **MultiDex Enabled**: Prevents Android 64k method limit errors.
* **Universal CPU Architecture Support**: Pre-configured for ARM64 (`arm64-v8a`), ARM 32-bit (`armeabi-v7a`), and x86_64.
* **Dynamic Server Configuration**: Change your backend API URL on the fly directly from the **Login** screen or the in-app **Settings** screen with built-in connection testing.

---

## 📲 How to Run and Install from Android Studio

### Method 1: Run directly on your phone via USB
1. On your phone:
   * Go to **Settings** > **About Phone**.
   * Tap **Build Number** 7 times to enable **Developer Options**.
   * Go to **Settings** > **Developer Options** and turn **ON**:
     * **USB Debugging**
     * *(For Xiaomi, Redmi, Poco, Oppo, Vivo, Realme)*: Turn **ON** **Install via USB** and **USB Debugging (Security settings)**.
2. Connect your phone to your computer with a USB cable (choose "File Transfer" mode).
3. On your phone, tap **Allow** when the *"Allow USB debugging?"* popup appears.
4. In **Android Studio**, open this folder:
   `c:\xampp\htdocs\student_expense_manager_backend`
5. Select your phone from the device dropdown and click **Run** (Green Play button). The app will build and open directly on your phone!

### Method 2: Build a Standalone Release APK (Share via WhatsApp / Drive)
Open the terminal in Android Studio and run:
```bash
flutter build apk --release
```
* **Output APK file location**:
  `build/app/outputs/flutter-apk/app-release.apk`
* Copy this file to any smartphone and tap it to install.
* If prompted:
  * Enable **"Install unknown apps"** for your File Manager/Browser.
  * If Google Play Protect warns you, tap **"More details"** > **"Install anyway"**.

---

## 🗄️ Database Auto-Initialization & Backend Communication

The backend features **zero-setup self-healing**:
* When the API receives its first request, it connects to MySQL.
* If the database `student_expense_manager` does not exist, it **creates it automatically**.
* If the database tables do not exist, it **automatically runs `student_expense_manager.sql`** to create all tables (`users`, `sessions`, `accounts`, `categories`, `payment_methods`, `transactions`, `budgets`, `overall_budgets`, `notes`, `reminders`, `user_settings`, `notification_preferences`, `notifications`, `receipts`).

### Quick Verification
Visit in your web browser:
`http://localhost/student_expense_manager_backend/backend/test_db.php`
You will see a JSON diagnostic report verifying that all database tables are created and connected!

---

## 🌐 100% Free Cloud Hosting for 24/7 Live Access

To have your backend live on the internet so your app works anywhere:

### Recommended: Alwaysdata (Free Forever, No Credit Card)
1. Register at [https://admin.alwaysdata.com/](https://admin.alwaysdata.com/).
2. In **Databases** > **MySQL**:
   * Create database `student_expense_manager`.
   * Create a user and password.
3. In **Files** > `www/`:
   * Upload `api.php`, `config.php`, and `student_expense_manager.sql` from the `backend/` folder.
   * Update `config.php` with your Alwaysdata MySQL credentials.
4. Your live API URL will be:
   `https://YOUR_ACCOUNT.alwaysdata.net/api.php`
5. On your phone or the web app, tap **Server: ...** at the bottom of the Login screen, paste your live URL, tap **Test Connection**, and tap **Save**!

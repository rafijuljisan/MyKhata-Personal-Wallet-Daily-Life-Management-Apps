📒 MyKhata - Smart Digital Ledger & Personal Assistant

MyKhata is a comprehensive, offline-first financial management application designed for small business owners and personal use. It replaces traditional paper ledgers ("Khata") with a smart, secure, and analytical mobile solution.

Beyond basic bookkeeping, it acts as a personal assistant with features like Bike Maintenance Tracking, Shopping Lists, Multi-Wallet Management, and PDF Reporting.

---

📱 App Screenshots

Dashboard

Transaction History

Party Ledger

Bike Manager









(Note: Replace these paths with actual screenshots in your assets folder)







---

✨ Key Features

💼 Core Accounting

* **Smart Dashboard:** Real-time view of Cash In Hand, Total Receivables (Pabo), and Total Payables (Dibo).
* **Transaction Tracking:** Record Cash In, Cash Out, Credit Given (Baki), and Credit Received.
* **Edit/Delete:** Long-press any transaction to correct mistakes instantly.

👥 Party Management (Customers & Suppliers)

* **Digital Ledger:** Maintain separate accounts for Customers and Suppliers.
* **Communication:** Call, SMS, or WhatsApp customers directly from the app with one tap.
* **Smart Formatter:** Automatically formats phone numbers for WhatsApp (e.g., adds +880).

💰 Multi-Wallet System

* **Multiple Accounts:** Create separate wallets for Personal, Shop, Bank, or Bkash.
* **Fund Transfer:** Easily transfer money between wallets (e.g., Cash -> Bank) with transaction logging.
* **Wallet Isolation:** Dashboard analytics update based on the currently active wallet.

🛠️ Utility Tools (The "Super App" Features)

🏍️ Bike Manager:

* Track Fuel, Service, and Parts costs.
* Calculate accurate Mileage.
* **Smart Reminders:** Set alerts for Oil Changes based on KM or Date (e.g., "Change Synthetic Oil after 5000km").

🛒 Bazar List (Shopping):

* Create shopping checklists.
* Enter prices while shopping.
* **One-Click Checkout:** Converts your shopping list total directly into an Expense Transaction.

📊 Reports & Analytics

* **Visual Analytics:** Interactive Pie Charts showing expense breakdown by category (Food, Rent, Transport).
* **PDF Reports:** Generate professional PDF reports filtered by Date Range and Transaction Type.
* **Print Ready:** Reports include Shop Name/Business Profile header.

🔒 Security & Backup

* **App Lock:** Secure the app with a 4-Digit PIN.
* **Biometric Auth:** Unlock using Fingerprint or FaceID.
* **Auto Backup:** Automatically saves data to phone storage (Downloads folder) on startup.
* **Auto Cleanup:** Automatically deletes backup files older than 30 days to save space.
* **Manual Backup:** Option to share backup files via WhatsApp/Email.

🌍 Localization

* **Bilingual:** Full support for English and Bangla.
* Dynamic language switching throughout the UI.

---

🛠️ Tech Stack & Architecture

This project follows a Feature-First Architecture for scalability and maintainability.

* **Framework:** Flutter & Dart
* **State Management:** Flutter Riverpod (Generator syntax)
* **Database:** Drift (SQLite ORM)
* **PDF Generation:** pdf & printing
* **Charts:** fl\_chart
* **Security:** local\_auth & shared\_preferences

Folder Structure
lib/src/ ├── features/ │   ├── dashboard/      # Home UI & Logic │   ├── transactions/   # Add/Edit/List Logic │   ├── parties/        # Customer/Supplier Management │   ├── wallets/        # Multi-wallet Logic │   ├── reports/        # PDF Generation │   ├── analytics/      # Charts │   ├── settings/       # Backup, Security, Language │   ├── bike/           # Bike Manager Module │   └── shopping/       # Bazar List Module ├── data/               # Database Schema & Connection └── app.dart            # Main App Entry


---

🚀 Installation & Setup

Follow these steps to run the project locally.

1.  **Prerequisites**

    * Flutter SDK installed ([Guide](https://flutter.dev/docs/get-started/install))
    * Android Studio or VS Code

2.  **Clone the Repo**

    ```bash
    git clone [https://github.com/yourusername/my-khata.git](https://github.com/yourusername/my-khata.git)
    cd my-khata
    ```

3.  **Install Dependencies**

    ```bash
    flutter pub get
    ```

4.  **Generate Database Code (Crucial Step)**

    Since this project uses drift and riverpod\_generator, you must run the build runner to generate the database and provider code.

    ```bash
    dart run build_runner build --delete-conflicting-outputs
    ```

5.  **Run the App**

    ```bash
    flutter run
    ```

### 6. 📦 Generating Release APK/AppBundle

To create a release version of the app for testing on a physical device or uploading to the Play Store, follow these steps:

1.  **Run the Build Command**

    Open your terminal in the project folder (where `pubspec.yaml` is) and run:

    ```bash
    flutter build apk --release
    ```

    *This process usually takes 1-3 minutes.*

2.  **Locate the File**

    Once the command finishes, your APK file will be generated here:

    * **Path:** `[Your_Project_Folder]\build\app\outputs\flutter-apk\app-release.apk`

    You can copy this file to your phone (via USB, WhatsApp, or Google Drive) and install it.

> **Pro Tip: Reduce File Size (Split APKs)**
> The command above creates a "Universal" APK that works on all Android devices (it contains code for all processors), so the file size might be large (e.g., 30MB+).
>
> To generate **smaller APKs** specific to each phone type, use:

    ```bash
    flutter build apk --split-per-abi
    ```

    This will create three files in the output folder:
    * `app-armeabi-v7a-release.apk` (For older/cheap phones)
    * `app-arm64-v8a-release.apk` (For most modern phones - **Use this one mostly**)
    * `app-x86_64-release.apk` (For emulators)

> **Important Note for Play Store**
> If you are planning to upload this to the Google Play Store, do not use the `APK` command. Instead, you must generate an **App Bundle (.aab)**:

    ```bash
    flutter build appbundle
    ```

---

⚠️ Permissions (Android)

This app requires the following permissions (already added to `AndroidManifest.xml`):

* `USE_BIOMETRIC`: For fingerprint unlock.
* `READ/WRITE_EXTERNAL_STORAGE`: For saving PDF reports and Backup files to the Downloads folder.
* `QUERY_ALL_PACKAGES` (Optional): For launching WhatsApp/Dialer.

---

👨‍💻 Developer

Developed by Jisan Sheikh

* **Website:** jisan.technomenia.com
* **Email:** contact@technomenia.com

🤝 Contributing

Contributions are welcome!

* Fork the repository.
* Create a feature branch (`git checkout -b feature/AmazingFeature`).
* Commit your changes.
* Push to the branch.
* Open a Pull Request.

📄 License

This project is licensed under the MIT License - see the `LICENSE` file for details.
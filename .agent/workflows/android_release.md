---
description: Guide to preparing and building the Android app for Google Play Store release.
---

1.  **Prerequisite: Install Android Studio & Tools**
    *   Download and install Android Studio.
    *   Open Android Studio and go to **Settings/Preferences** > **Languages & Frameworks** > **Android SDK**.
    *   Click on the **"SDK Tools"** tab (middle tab).
    *   Check the box for **"Android SDK Command-line Tools (latest)"**.
    *   Click **Apply** to install them.
    *   Run `flutter doctor --android-licenses` to accept licenses.

2.  **Update App Label:** Ensure `android:label` in `android/app/src/main/AndroidManifest.xml` is correct (e.g., "Schweizologie").
2.  **Generate Keystore:**
    Run the following command to generate a new upload keystore:
    ```bash
    keytool -genkey -v -keystore android/app/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
    ```
    *Note: You will be prompted to enter a password and some details. Remember the password!*

3.  **Create `key.properties`:**
    Create a file named `android/key.properties` with the following content (replace `<password>` with the password you chose):
    ```properties
    storePassword=<password>
    keyPassword=<password>
    keyAlias=upload
    storeFile=upload-keystore.jks
    ```

4.  **Build App Bundle:**
    Run the build command:
    ```bash
    flutter build appbundle
    ```

5.  **Locate Bundle:**
    The built bundle will be at `build/app/outputs/bundle/release/app-release.aab`.

6.  **Google Play Console:**
    *   Create an account at [play.google.com/console](https://play.google.com/console).
    *   Create a new app.
    *   Upload the `app-release.aab` file.

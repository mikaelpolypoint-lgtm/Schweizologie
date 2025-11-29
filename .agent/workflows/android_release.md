---
description: Guide to preparing and building the Android app for Google Play Store release.
---

# Android Release Workflow

Follow these steps to turn your Flutter game into a production-ready Android app.

## 1. Change Package Name (Important!)
The default `com.example` package name is **not allowed** on the Play Store.
1.  Open `android/app/build.gradle.kts`.
2.  Find `applicationId` (currently `com.example.schweizologie.schweizologie`).
3.  Change it to something unique, e.g., `com.yourname.schweizologie`.
4.  Also update `namespace` in the same file to match.

## 2. App Icon
1.  Add `flutter_launcher_icons` to `dev_dependencies` in `pubspec.yaml`:
    ```yaml
    dev_dependencies:
      flutter_launcher_icons: ^0.13.1
    ```
2.  Add configuration to `pubspec.yaml`:
    ```yaml
    flutter_launcher_icons:
      android: "launcher_icon"
      ios: true
      image_path: "assets/icon/icon.png" # Make sure you have an icon here!
      min_sdk_android: 21 # android min sdk min:16, default 21
    ```
3.  Run:
    ```bash
    flutter pub get
    flutter pub run flutter_launcher_icons
    ```

## 3. Firebase Configuration (Crucial!)
Since we only configured Web, you need to add Android support.
1.  Go to the [Firebase Console](https://console.firebase.google.com/).
2.  Open your project settings.
3.  Click "Add App" -> **Android**.
4.  Enter the **exact same package name** you chose in Step 1.
5.  Download `google-services.json`.
6.  Place it in `android/app/google-services.json`.

## 4. App Signing
You need a keystore to sign your app for release.
1.  Run this command in your terminal (Mac/Linux):
    ```bash
    # For macOS with Android Studio:
    "/Applications/Android Studio.app/Contents/jbr/Contents/Home/bin/keytool" -genkey -v -keystore android/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload -storepass schweizologie -keypass schweizologie -dname "CN=Mika, OU=Schweizologie, O=Mika, L=Zurich, S=Zurich, C=CH"
    
    # Or if you have Java installed globally:
    # keytool -genkey -v -keystore android/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload -storepass schweizologie -keypass schweizologie -dname "CN=Mika, OU=Schweizologie, O=Mika, L=Zurich, S=Zurich, C=CH"
    ```
2.  Create a file `android/key.properties`:
    ```properties
    storePassword=<password from step 1>
    keyPassword=<password from step 1>
    keyAlias=upload
    storeFile=/Users/<your-username>/upload-keystore.jks
    ```
3.  Update `android/app/build.gradle.kts` to use this key (I can help with the code if you need).

## 5. Build App Bundle
1.  Run:
    ```bash
    flutter build appbundle
    ```
2.  The file will be at `build/app/outputs/bundle/release/app-release.aab`.
3.  Upload this `.aab` file to the Google Play Console!

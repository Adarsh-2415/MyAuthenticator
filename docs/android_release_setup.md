# Android Production Release Signing Setup Guide — MyAuthenticator

This document explains how to set up Android release signing for **MyAuthenticator** when building production APKs or Android App Bundles (`.aab`).

---

## ⚠️ Security Rules — DO NOT VIOLATE

1. **NEVER** commit `key.properties` or `*.keystore` / `*.jks` files to Git or any version control system.
2. **NEVER** share release signing passwords publicly.
3. **STORE BACKUPS SECURELY**: If the private keystore file or password is lost, you will **PERMANENTLY** lose the ability to update MyAuthenticator on the Google Play Store or existing user devices.

---

## Step 1: Generate Release Keystore

Run the following command in your terminal (JDK `keytool` must be installed):

```bash
keytool -genkey -v -keystore android/app/upload-keystore.jks \
  -storetype PKCS12 -keyalg RSA -keysize 2048 -validity 10000 \
  -alias upload
```

You will be prompted to enter a keystore password and organization details.

---

## Step 2: Create `key.properties` File

Create a file named `key.properties` inside the `android/` directory (`android/key.properties`):

```properties
storePassword=<YOUR_KEYSTORE_PASSWORD>
keyPassword=<YOUR_KEY_PASSWORD>
keyAlias=upload
storeFile=upload-keystore.jks
```

*Note: `key.properties` is listed in `.gitignore` and will never be committed to version control.*

---

## Step 3: Gradle Build Configuration

In `android/app/build.gradle.kts`, reference `key.properties` as follows when Android SDK is installed:

```kotlin
import java.io.FileInputStream
import java.util.Properties

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    ...
    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String?
            keyPassword = keystoreProperties["keyPassword"] as String?
            storeFile = keystoreProperties["storeFile"]?.let { file(it) }
            storePassword = keystoreProperties["storePassword"] as String?
        }
    }
    buildTypes {
        release {
            signingConfig = if (keystorePropertiesFile.exists()) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
        }
    }
}
```

---

## Step 4: Build Production Release Bundle

Once Android SDK & Studio are installed and `key.properties` is configured:

```bash
# Build Android App Bundle for Google Play
flutter build appbundle --release

# Build Standalone APK
flutter build apk --release
```

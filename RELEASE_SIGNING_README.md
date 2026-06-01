# 🔐 Release Signing Setup for Google Play Console

## Problem
You received this error from Google Play Console:
> "You uploaded an APK or Android App Bundle that was signed in debug mode. You need to sign your APK or Android App Bundle in release mode."

This means you're uploading a debug build instead of a properly signed release build.

## Solution

### Option 1: Google Play App Signing (Recommended)

1. **Go to Google Play Console**
2. **Navigate to**: Release > Setup > App signing
3. **Choose**: "Let Google manage and protect your app signing key"
4. **Upload your keystore** (if you have one) or let Google create one
5. **Build and upload** your AAB - Google will handle signing automatically

### Option 2: Local Release Signing

If you prefer to sign locally:

#### Step 1: Generate Keystore

**macOS/Linux:**
```bash
cd android
./generate_keystore.sh
```

**Windows:**
```cmd
cd android
generate_keystore.bat
```

**Or run manually:**
```bash
keytool -genkey -v -keystore upload-keystore.jks -storetype JKS -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

#### Step 2: Configure key.properties
Edit `android/key.properties` and replace the placeholder values with your actual passwords:
```
storePassword=YOUR_ACTUAL_STORE_PASSWORD
keyPassword=YOUR_ACTUAL_KEY_PASSWORD
keyAlias=upload
storeFile=../upload-keystore.jks
```

#### Step 3: Build Release AAB
```bash
flutter build appbundle --release
```

#### Step 4: Verify Signing
Check that the build is signed in release mode:
```bash
jarsigner -verify -verbose -certs build/app/outputs/bundle/release/app-release.aab
```

### Keystore PKCS12 migration

`keytool` may warn that JKS is a proprietary format and recommend PKCS12. To migrate in place, run from the `android/` directory. Use your actual keystore password for all four options; if store and key use the same password (e.g. `123456`), use it for `-srcstorepass`, `-deststorepass`, `-srckeypass`, and `-destkeypass`.

**If the keystore is in the project root** (`storeFile=../upload-keystore.jks`):
```bash
cd android
keytool -importkeystore -srckeystore ../upload-keystore.jks -destkeystore ../upload-keystore.jks -deststoretype pkcs12 -srcstorepass 123456 -deststorepass 123456 -srckeypass 123456 -destkeypass 123456
```

**If the keystore is inside `android/`** (`storeFile=upload-keystore.jks`):
```bash
cd android
keytool -importkeystore -srckeystore upload-keystore.jks -destkeystore upload-keystore.jks -deststoretype pkcs12 -srcstorepass 123456 -deststorepass 123456 -srckeypass 123456 -destkeypass 123456
```

To keep a backup of the original JKS before migrating:
```bash
cd android
keytool -importkeystore -srckeystore ../upload-keystore.jks -destkeystore ../upload-keystore.p12 -deststoretype pkcs12 -srcstorepass 123456 -deststorepass 123456 -srckeypass 123456 -destkeypass 123456
mv ../upload-keystore.jks ../upload-keystore.jks.bak
mv ../upload-keystore.p12 ../upload-keystore.jks
```

Replace `123456` with your actual store/key password in all commands.

## Important Security Notes

⚠️ **Never commit these files to version control:**
- `android/key.properties` (contains passwords)
- `android/upload-keystore.jks` (your private key)
- Any `.keystore` or `.jks` files

These are already added to `.gitignore` for your protection.

## Testing Your Setup

### Build Commands
```bash
# Clean build
flutter clean && flutter pub get

# Build release AAB
flutter build appbundle --release

# Build release APK (alternative)
flutter build apk --release
```

### Verify Build Output
After building, check that these files are created:
- `build/app/outputs/bundle/release/app-release.aab` (for Play Store)
- `build/app/outputs/apk/release/app-release.apk` (alternative)

## Troubleshooting

### "key.properties not found"
Make sure you created and configured the `android/key.properties` file with your actual passwords.

### "Keystore was tampered with"
Your keystore password is incorrect. Double-check the passwords in `key.properties`.

### Still getting debug signing error
1. Clean your build: `flutter clean`
2. Delete build artifacts: `rm -rf build/ android/app/build/`
3. Rebuild: `flutter build appbundle --release`

### Gradle issues
If you get Gradle errors, try:
```bash
cd android && ./gradlew clean && cd ..
flutter pub get
flutter build appbundle --release
```

## Upload to Google Play Console

1. Go to Google Play Console
2. Navigate to Release > Production (or Internal/Beta testing)
3. Upload your `app-release.aab` file
4. Complete the store listing and other requirements
5. Publish your app

## Best Practices

- ✅ Use Google Play App Signing when possible
- ✅ Keep your keystore secure and backed up
- ✅ Use strong passwords
- ✅ Never share your keystore or passwords
- ✅ Keep multiple backup copies of your keystore
- ✅ Test your signed builds thoroughly before publishing

## Need Help?

If you encounter issues:
1. Check the terminal output for specific error messages
2. Verify all passwords in `key.properties` are correct
3. Ensure the keystore file exists at the specified location
4. Try building with verbose output: `flutter build appbundle --release --verbose`
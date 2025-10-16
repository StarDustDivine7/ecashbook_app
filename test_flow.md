# EcashBook App Flow Testing Guide

## How to Test the Updated Flow

### Prerequisites
1. Clear app data completely before testing
2. Ensure you have test credentials for login

### Test Scenario 1: First-Time App Launch

**Expected Flow**: Dashboard → Permissions → Lock Setup → Login → Dashboard

1. **Clear App Data**
   ```bash
   flutter clean
   flutter pub get
   ```

2. **Launch App**
   - App should show Dashboard immediately
   - After ~1 second, a dialog should appear: "Welcome to EcashBook!"
   - Dialog should have "Continue Setup" button

3. **Permissions Flow**
   - Tap "Continue Setup"
   - Should navigate to Permissions screen
   - Shows 4 permissions: Location, Camera, Storage, Notification
   - Tap "Allow All"
   - System permission dialogs will appear

4. **Lock Setup Flow**
   - After permissions, should navigate to Lock Setup screen
   - Shows "Set App PIN" 
   - Enter 4-digit PIN (e.g., 1234)
   - Tap "Save PIN"

5. **Login Flow**
   - Should navigate to Login screen
   - Enter valid credentials
   - Tap "Log in"
   - Should navigate to Dashboard

### Test Scenario 2: App Reopen (After First Login)

**Expected Flow**: Lock Screen → Dashboard

1. **Close App Completely**
   - Use recent apps and swipe away
   - Or use back button to exit

2. **Reopen App**
   - Should show Lock Screen (Biometric/PIN)
   - Shows "Enter App PIN" or biometric prompt
   - Enter the PIN you set (e.g., 1234)
   - Should navigate to Dashboard

### Test Scenario 3: App Background/Resume

**Expected Flow**: Background → Resume → Lock Screen → Dashboard

1. **Minimize App**
   - Press home button while app is open
   - Wait a few seconds

2. **Resume App**
   - Tap app icon or use recent apps
   - Should show Lock Screen
   - Enter PIN/biometric
   - Should go to Dashboard

### Test Scenario 4: Notification Bar Exception

**Expected Flow**: Pull notification → No lock screen

1. **Open App**
   - Ensure you're on Dashboard

2. **Pull Down Notification Bar**
   - Swipe down from top
   - Should NOT trigger lock screen

3. **Close Notification Bar**
   - Swipe up or tap outside
   - Should return to Dashboard without lock screen

### Debugging

If flow doesn't work as expected, check these SharedPreferences keys:

```dart
// Check in debug console or using SharedPreferences
is_first_time: true/false
onboarding_completed: true/false  
permissions_granted: true/false
lock_setup_completed: true/false
has_ever_logged_in: true/false
user_logged_in: true/false
app_was_backgrounded: true/false
```

### Debug Commands

```bash
# Clear app data
flutter clean
flutter pub get

# Run with debug output
flutter run --debug

# Check logs
flutter logs
```

### Expected Debug Output

Look for these debug messages:

```
🚀 App Flow Decision:
📱 First time - showing dashboard first
🔐 First time - requesting permissions  
🔒 First time - setting up lock screen
👤 First time - showing login screen
✅ Normal usage - going to dashboard
🔐 Lock screen required - showing biometric
⏸️ App paused (logged in user) - marking for lock requirement
▶️ App resumed (logged in user)
🔐 App was backgrounded - requiring authentication
⏸️ App inactive - ignoring (notification panel or system overlay)
```

This testing guide will help verify that all the flow requirements are working correctly.
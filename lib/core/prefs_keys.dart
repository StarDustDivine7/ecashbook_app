// lib/core/prefs_keys.dart
class PrefKeys {
  // Onboarding & permissions
  static const onboardingCompleted = 'onboarding_completed';
  static const permissionsGranted = 'permissions_granted';

  // Security/App lock
  static const appPasscodeHash = 'app_passcode_hash';

  // Auth/session
  static const authToken = 'authtoken';
  static const tokenType = 'tokentype';
  static const secureHash = 'securehash';
  static const userData = 'userdata';
  static const lastAuthTime = 'lastauthtime';
  static const userLoggedIn = 'userloggedin';
  static const isFirstTime = 'isfirsttime';
  static const deviceToken = 'devicetoken';

  // Biometric/navigation state
  static const lastBiometricAuth = 'lastbiometricauth';
  static const lastActivePage = 'lastactivepage';
  static const backgroundTimestamp = 'backgroundtimestamp';
  static const lastAppCloseTime = 'lastappclosetime';
  static const screenOffTime = 'screenofftime';
  static const appPausedTime = 'apppausedtime';
  static const lastRestartType = 'lastrestarttype';
  static const phoneRestartCount = 'phonerestartcount';
  static const ramClearCount = 'ramclearcount';
  static const screenStateCount = 'screenstatecount';

  // Dashboard
  static const lastEmployeeDetailsDate = 'lastemployeedetailsdate';
  static const punchData = 'punchdata';
  static const lastResetDate = 'lastresetdate';
}

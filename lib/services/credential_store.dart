import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Keeps the student's portal login in the platform keystore.
///
/// The portal's refresh token is the normal way to stay signed in, but it
/// expires too. When it does, the only way to get a new access token without
/// interrupting the student is to replay the original credentials - so they
/// are kept here, in the Android KeyStore / iOS Keychain, never in
/// SharedPreferences alongside ordinary settings.
///
/// Storing them at all is a deliberate trade-off: it buys silent re-login for
/// the live screens (điểm, rèn luyện, học phí). [clear] is called on sign-out,
/// and [enabled] lets the student opt out entirely.
class CredentialStore {
  CredentialStore._();

  static final CredentialStore instance = CredentialStore._();

  // v11's default AndroidOptions already encrypts with AES-GCM behind an
  // RSA-wrapped KeyStore key, so only the Keychain accessibility is worth
  // setting: first_unlock lets a background refresh read the credentials
  // without the phone having to be unlocked at that moment.
  static const _storage = FlutterSecureStorage(
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  static const _kStudentCode = 'tlu_student_code';
  static const _kPassword = 'tlu_password';
  static const _kEnabled = 'tlu_remember_login';

  /// Saves the credentials used for a successful login.
  Future<void> save(String studentCode, String password) async {
    try {
      await _storage.write(key: _kStudentCode, value: studentCode);
      await _storage.write(key: _kPassword, value: password);
      await _storage.write(key: _kEnabled, value: 'true');
    } catch (_) {
      // A device without a working keystore simply means no silent re-login.
    }
  }

  /// Returns (studentCode, password), or null when nothing usable is stored.
  Future<({String studentCode, String password})?> read() async {
    try {
      if (await _storage.read(key: _kEnabled) != 'true') return null;
      final code = await _storage.read(key: _kStudentCode);
      final password = await _storage.read(key: _kPassword);
      if (code == null || code.isEmpty) return null;
      if (password == null || password.isEmpty) return null;
      return (studentCode: code, password: password);
    } catch (_) {
      return null;
    }
  }

  Future<bool> get enabled async {
    try {
      return await _storage.read(key: _kEnabled) == 'true';
    } catch (_) {
      return false;
    }
  }

  /// Turns silent re-login off without signing the student out.
  Future<void> setEnabled(bool value) async {
    try {
      if (value) {
        await _storage.write(key: _kEnabled, value: 'true');
      } else {
        await clear();
      }
    } catch (_) {
      // Ignored - the setting is a convenience, not a correctness concern.
    }
  }

  /// Wipes everything. Called on sign-out.
  Future<void> clear() async {
    try {
      await _storage.delete(key: _kStudentCode);
      await _storage.delete(key: _kPassword);
      await _storage.delete(key: _kEnabled);
    } catch (_) {
      // Nothing more can be done if the keystore is unavailable.
    }
  }
}

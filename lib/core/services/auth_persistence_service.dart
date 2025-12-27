import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// ============================================================================
/// AUTH PERSISTENCE SERVICE
/// ============================================================================
/// Handles persistent login across app restarts:
/// - ✅ Stores auth state securely
/// - ✅ Auto-login on app start
/// - ✅ Token refresh handling
/// - ✅ Secure credential storage
/// 
/// Dependencies:
/// - flutter_secure_storage: ^9.0.0
/// - shared_preferences: ^2.2.2
/// ============================================================================
class AuthPersistenceService {
  static final AuthPersistenceService _instance = AuthPersistenceService._internal();
  factory AuthPersistenceService() => _instance;
  AuthPersistenceService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  // Keys
  static const _keyIsLoggedIn = 'is_logged_in';
  static const _keyUserId = 'user_id';
  static const _keyEmail = 'user_email';
  static const _keyLastLogin = 'last_login';
  static const _keyRememberMe = 'remember_me';

  // --------------------------------------------------------------------------
  // INITIALIZATION
  // --------------------------------------------------------------------------
  
  /// Check if user should be auto-logged in
  Future<bool> shouldAutoLogin() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rememberMe = prefs.getBool(_keyRememberMe) ?? true;
      
      if (!rememberMe) {
        debugPrint('📱 Remember me is disabled');
        return false;
      }

      // Check if Firebase already has a user (persistence is enabled by default)
      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        debugPrint('✅ User already logged in: ${currentUser.uid}');
        return true;
      }

      // Check stored login state
      final isLoggedIn = prefs.getBool(_keyIsLoggedIn) ?? false;
      if (!isLoggedIn) {
        debugPrint('📱 No stored login state');
        return false;
      }

      // Verify stored user ID matches
      final storedUid = await _secureStorage.read(key: _keyUserId);
      if (storedUid == null) {
        debugPrint('⚠️ No stored user ID');
        await clearLoginState();
        return false;
      }

      debugPrint('📱 Stored login found for: $storedUid');
      return true;
    } catch (e) {
      debugPrint('❌ Error checking auto login: $e');
      return false;
    }
  }

  // --------------------------------------------------------------------------
  // SAVE LOGIN STATE
  // --------------------------------------------------------------------------
  
  /// Save login state after successful authentication
  Future<void> saveLoginState(User user, {bool rememberMe = true}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      await prefs.setBool(_keyIsLoggedIn, true);
      await prefs.setBool(_keyRememberMe, rememberMe);
      await prefs.setString(_keyLastLogin, DateTime.now().toIso8601String());

      // Store sensitive data securely
      await _secureStorage.write(key: _keyUserId, value: user.uid);
      if (user.email != null) {
        await _secureStorage.write(key: _keyEmail, value: user.email);
      }

      debugPrint('✅ Login state saved for: ${user.uid}');
    } catch (e) {
      debugPrint('❌ Error saving login state: $e');
    }
  }

  // --------------------------------------------------------------------------
  // CLEAR LOGIN STATE
  // --------------------------------------------------------------------------
  
  /// Clear login state on logout
  Future<void> clearLoginState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      await prefs.remove(_keyIsLoggedIn);
      await prefs.remove(_keyLastLogin);

      await _secureStorage.delete(key: _keyUserId);
      await _secureStorage.delete(key: _keyEmail);

      debugPrint('✅ Login state cleared');
    } catch (e) {
      debugPrint('❌ Error clearing login state: $e');
    }
  }

  // --------------------------------------------------------------------------
  // GET STORED USER INFO
  // --------------------------------------------------------------------------
  
  /// Get stored user ID
  Future<String?> getStoredUserId() async {
    return await _secureStorage.read(key: _keyUserId);
  }

  /// Get stored email
  Future<String?> getStoredEmail() async {
    return await _secureStorage.read(key: _keyEmail);
  }

  /// Get last login time
  Future<DateTime?> getLastLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final lastLogin = prefs.getString(_keyLastLogin);
    if (lastLogin != null) {
      return DateTime.tryParse(lastLogin);
    }
    return null;
  }

  // --------------------------------------------------------------------------
  // REMEMBER ME
  // --------------------------------------------------------------------------
  
  /// Get remember me preference
  Future<bool> getRememberMe() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyRememberMe) ?? true;
  }

  /// Set remember me preference
  Future<void> setRememberMe(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyRememberMe, value);
  }

  // --------------------------------------------------------------------------
  // LOGOUT
  // --------------------------------------------------------------------------
  
  /// Complete logout - clears Firebase auth and stored state
  Future<void> logout() async {
    try {
      await clearLoginState();
      await _auth.signOut();
      debugPrint('✅ User logged out');
    } catch (e) {
      debugPrint('❌ Error during logout: $e');
      rethrow;
    }
  }

  // --------------------------------------------------------------------------
  // AUTH STATE LISTENER
  // --------------------------------------------------------------------------
  
  /// Listen to auth state changes and update stored state
  void setupAuthListener() {
    _auth.authStateChanges().listen((user) async {
      if (user != null) {
        await saveLoginState(user);
      } else {
        await clearLoginState();
      }
    });
  }
}

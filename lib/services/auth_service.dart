import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_user.dart';
import '../models/enums.dart';
import 'db_service.dart';

class AuthService {
  AuthService._();

  static final AuthService instance = AuthService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DbService _db = DbService.instance;

  String? _localUserId;

  User? get currentUser => _auth.currentUser;

  String? get currentUserId => _auth.currentUser?.uid ?? _localUserId;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final firebaseUserId = _auth.currentUser?.uid;
    if (firebaseUserId != null && firebaseUserId.isNotEmpty) {
      _localUserId = firebaseUserId;
      await prefs.setString('localUserId', firebaseUserId);
      return;
    }
    _localUserId = prefs.getString('localUserId');
  }

  Future<AppUser?> getCurrentProfile() async {
    final userId = currentUserId;
    if (userId == null) return null;
    final snapshot = await _db.users.doc(userId).get();
    if (!snapshot.exists || snapshot.data() == null) return null;
    return AppUser.fromMap(snapshot.id, snapshot.data()!);
  }

  Future<AppUser?> findUserByEmail(String email) async {
    final query = await _db.users
        .where('email', isEqualTo: email)
        .limit(1)
        .get();
    if (query.docs.isNotEmpty) {
      final doc = query.docs.first;
      return AppUser.fromMap(doc.id, doc.data());
    }

    // Backward compatibility for old profiles stored with 'phone'.
    final fallback = await _db.users
        .where('phone', isEqualTo: email)
        .limit(1)
        .get();
    if (fallback.docs.isEmpty) return null;
    final doc = fallback.docs.first;
    return AppUser.fromMap(doc.id, doc.data());
  }

  Future<AppUser> registerProfile({
    required String name,
    required String email,
    required String password,
    required UserRole role,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    final existing = await findUserByEmail(normalizedEmail);
    if (existing != null) {
      throw StateError(
        'An account already exists for this email. Please log in.',
      );
    }

    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: normalizedEmail,
        password: password,
      );
      final user = credential.user;
      if (user == null) {
        throw StateError('Unable to create account. Please try again.');
      }

      final profile = AppUser(
        id: user.uid,
        name: name,
        email: normalizedEmail,
        role: role,
        buildingId: null,
      );

      await _db.users.doc(user.uid).set(profile.toMap());
      _localUserId = user.uid;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('localUserId', user.uid);
      return profile;
    } on FirebaseAuthException catch (error) {
      throw StateError(_mapFirebaseAuthError(error));
    }
  }

  Future<AppUser> loginProfile({
    required String email,
    required String password,
    UserRole? expectedRole,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: normalizedEmail,
        password: password,
      );
      final user = credential.user;
      if (user == null) {
        throw StateError('Login failed. Please try again.');
      }

      final snapshot = await _db.users.doc(user.uid).get();
      if (!snapshot.exists || snapshot.data() == null) {
        await _auth.signOut();
        throw StateError('Profile not found for this account.');
      }

      final profile = AppUser.fromMap(snapshot.id, snapshot.data()!);
      if (expectedRole != null && profile.role != expectedRole) {
        await _auth.signOut();
        throw StateError(
          'This account belongs to the ${profile.role.name} portal.',
        );
      }

      _localUserId = profile.id;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('localUserId', profile.id);
      return profile;
    } on FirebaseAuthException catch (error) {
      throw StateError(_mapFirebaseAuthError(error));
    }
  }

  Future<void> updateRole(UserRole role) async {
    final userId = currentUserId;
    if (userId == null) throw StateError('No authenticated user.');
    await _db.users.doc(userId).update({'role': role.name});
  }

  Future<void> setBuildingId(String buildingId) async {
    final userId = currentUserId;
    if (userId == null) throw StateError('No authenticated user.');
    await _db.users.doc(userId).update({'buildingId': buildingId});
  }

  Future<void> signOut() async {
    await _auth.signOut();
    _localUserId = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('localUserId');
  }

  String _mapFirebaseAuthError(FirebaseAuthException error) {
    switch (error.code) {
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'email-already-in-use':
        return 'An account already exists for this email. Please log in.';
      case 'weak-password':
        return 'Password is too weak. Use at least 6 characters.';
      case 'user-not-found':
        return 'No account found for that email.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      default:
        return error.message ?? 'Authentication failed. Please try again.';
    }
  }
}

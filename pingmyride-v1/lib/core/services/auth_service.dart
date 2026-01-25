import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_type.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  UserType? _currentUserType;
  String? _currentUserEmail;
  bool _isAuthenticated = false;

  UserType? get currentUserType => _currentUserType;
  String? get currentUserEmail => _currentUserEmail;
  bool get isAuthenticated => _isAuthenticated;
  User? get currentUser => _auth.currentUser;

  AuthService() {
    // Listen to auth state changes
    _auth.authStateChanges().listen((User? user) {
      if (user != null) {
        _loadUserData(user);
      } else {
        _currentUserType = null;
        _currentUserEmail = null;
        _isAuthenticated = false;
        notifyListeners();
      }
    });
  }

  Future<void> _loadUserData(User user) async {
    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists) {
        final data = doc.data()!;
        _currentUserType = UserType.values.firstWhere(
          (type) => type.name == data['userType'],
          orElse: () => UserType.student,
        );
        _currentUserEmail = user.email;
        _isAuthenticated = true;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
    }
  }

  Future<bool> login(String email, String password, UserType userType) async {
    try {
      // Sign in with Firebase Auth
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        // Check if user type matches
        final doc = await _firestore
            .collection('users')
            .doc(credential.user!.uid)
            .get();

        if (doc.exists) {
          final userData = doc.data()!;
          final storedUserType = UserType.values.firstWhere(
            (type) => type.name == userData['userType'],
            orElse: () => UserType.student,
          );

          if (storedUserType == userType) {
            _currentUserType = userType;
            _currentUserEmail = email;
            _isAuthenticated = true;
            notifyListeners();
            return true;
          } else {
            // Wrong user type, sign out
            await _auth.signOut();
            return false;
          }
        } else {
          // User document doesn't exist, sign out
          await _auth.signOut();
          return false;
        }
      }
      return false;
    } catch (e) {
      debugPrint('Login error: $e');
      return false;
    }
  }

  Future<bool> signUp(
    String name, 
    String email, 
    String password, 
    String phone, 
    String idNumber, 
    UserType userType
  ) async {
    try {
      // Create user with Firebase Auth
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        // Update display name
        await credential.user!.updateDisplayName(name);

        // Save user data to Firestore
        await _firestore.collection('users').doc(credential.user!.uid).set({
          'name': name,
          'email': email,
          'phone': phone,
          'userType': userType.name,
          'createdAt': FieldValue.serverTimestamp(),
        });

        _currentUserType = userType;
        _currentUserEmail = email;
        _isAuthenticated = true;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Sign up error: $e');
      return false;
    }
  }

  Future<void> logout() async {
    try {
      await _auth.signOut();
      _currentUserType = null;
      _currentUserEmail = null;
      _isAuthenticated = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Logout error: $e');
    }
  }

  bool canAccessRole(UserType requiredRole) {
    return _isAuthenticated && _currentUserType == requiredRole;
  }

  // Get current user profile data
  Future<Map<String, dynamic>?> getCurrentUserProfile() async {
    if (_auth.currentUser != null) {
      try {
        final doc = await _firestore
            .collection('users')
            .doc(_auth.currentUser!.uid)
            .get();
        return doc.data();
      } catch (e) {
        debugPrint('Error fetching user profile: $e');
      }
    }
    return null;
  }
}
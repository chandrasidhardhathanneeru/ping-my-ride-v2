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

  Future<Map<String, dynamic>> login(String email, String password, UserType userType) async {
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
            // Check email verification for students and drivers
            if ((userType == UserType.student || userType == UserType.driver) && !credential.user!.emailVerified) {
              await _auth.signOut();
              return {
                'success': false,
                'error': 'email_not_verified',
                'message': 'Please verify your email before logging in. Check your inbox for verification link.',
              };
            }

            _currentUserType = userType;
            _currentUserEmail = email;
            _isAuthenticated = true;
            notifyListeners();
            return {'success': true};
          } else {
            // Wrong user type, sign out
            await _auth.signOut();
            return {
              'success': false,
              'error': 'wrong_user_type',
              'message': 'Invalid credentials for this user type',
            };
          }
        } else {
          // User document doesn't exist, sign out
          await _auth.signOut();
          return {
            'success': false,
            'error': 'user_not_found',
            'message': 'User account not found',
          };
        }
      }
      return {
        'success': false,
        'error': 'unknown',
        'message': 'Login failed',
      };
    } catch (e) {
      debugPrint('Login error: $e');
      return {
        'success': false,
        'error': 'exception',
        'message': e.toString(),
      };
    }
  }

  Future<Map<String, dynamic>> signUp(
    String name, 
    String email, 
    String password, 
    String phone, 
    String idNumber, 
    UserType userType
  ) async {
    try {
      // Block admin signups - admins cannot sign up through the app
      if (userType == UserType.admin) {
        return {
          'success': false,
          'message': 'Admin accounts cannot be created through signup. Please contact system administrator.',
        };
      }
      
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

        // Send email verification for students and drivers
        if (userType == UserType.student || userType == UserType.driver) {
          await credential.user!.sendEmailVerification();
          // Don't set authenticated state until verified
          await _auth.signOut();
          return {
            'success': true,
            'requiresVerification': true,
            'message': 'Verification email sent! Please check your inbox and verify your email before logging in.',
          };
        }

        // For admins only, proceed as normal
        _currentUserType = userType;
        _currentUserEmail = email;
        _isAuthenticated = true;
        notifyListeners();
        return {
          'success': true,
          'requiresVerification': false,
        };
      }
      return {
        'success': false,
        'message': 'Failed to create account',
      };
    } catch (e) {
      debugPrint('Sign up error: $e');
      return {
        'success': false,
        'message': e.toString(),
      };
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

  // Set admin login state for hardcoded admin
  void setAdminLogin(String email) {
    _currentUserType = UserType.admin;
    _currentUserEmail = email;
    _isAuthenticated = true;
    notifyListeners();
  }

  // Get current user profile data
  Future<Map<String, dynamic>?> getCurrentUserProfile() async {
    // Handle hardcoded admin login
    if (_currentUserType == UserType.admin && _auth.currentUser == null) {
      // Return hardcoded admin profile data
      return {
        'name': 'TANNEERU CHANDRA SIDHARDHA',
        'email': _currentUserEmail ?? 'chandrasidhardhatanneeru@gmail.com',
        'phone': '7204940447',
        'userType': 'admin',
      };
    }
    
    // For regular Firebase users (students/drivers)
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
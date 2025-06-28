import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import 'data_provider.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  
  User? _user;
  UserModel? _userModel;
  bool _isLoading = false;
  String? _error;
  DataProvider? _dataProvider;

  User? get user => _user;
  UserModel? get userModel => _userModel;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;

  AuthProvider() {
    _authService.authStateChanges.listen(_onAuthStateChanged);
  }

  void setDataProvider(DataProvider dataProvider) {
    _dataProvider = dataProvider;
  }

  void _onAuthStateChanged(User? user) async {
    _user = user;
    print('Auth state changed: ${user?.uid}'); // Debug log
    if (user != null) {
      await _loadUserData(user.uid);
      // Start real-time listeners for user data
      _dataProvider?.startUserListener(user.uid);
      _dataProvider?.startOrdersListener(user.uid);
      _dataProvider?.loadUserData(user.uid);
    } else {
      _userModel = null;
      _dataProvider?.clearData();
    }
    notifyListeners();
    print('Auth provider notified listeners, isAuthenticated: $isAuthenticated'); // Debug log
  }

  Future<void> _loadUserData(String uid) async {
    try {
      _userModel = await _authService.getUserData(uid);
    } catch (e) {
      _error = e.toString();
    }
  }

  Future<bool> signIn(String email, String password) async {
    _setLoading(true);
    _clearError();
    
    try {
      final result = await _authService.signInWithEmailAndPassword(email, password);
      return result != null;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> signUp(
    String email,
    String password,
    String firstName,
    String lastName,
    String? phoneNumber,
  ) async {
    _setLoading(true);
    _clearError();
    
    try {
      print('Starting signup for: $email'); // Debug log
      final result = await _authService.createUserWithEmailAndPassword(
        email,
        password,
        firstName,
        lastName,
        phoneNumber,
      );
      final success = result != null;
      print('Signup result: $success, user: ${result?.user?.uid}'); // Debug log
      return success;
    } catch (e) {
      print('Signup error: $e'); // Debug log
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signOut() async {
    _setLoading(true);
    try {
      await _authService.signOut();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> signInWithGoogle() async {
    _setLoading(true);
    _clearError();
    
    try {
      final result = await _authService.signInWithGoogle();
      return result != null;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> sendPasswordResetEmail(String email) async {
    _setLoading(true);
    _clearError();
    
    try {
      await _authService.sendPasswordResetEmail(email);
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateUserData(UserModel updatedUser) async {
    try {
      await _authService.updateUserData(updatedUser);
      _userModel = updatedUser;
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }

  void clearError() => _clearError();
}
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  AuthService(this._auth);

  final FirebaseAuth _auth;

  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = credential.user;
    if (user == null || !_isPasswordAccount(user)) {
      return credential;
    }

    await user.reload();
    final refreshed = _auth.currentUser;
    if (refreshed != null && !refreshed.emailVerified) {
      await refreshed.sendEmailVerification();
      await _auth.signOut();
      throw FirebaseAuthException(
        code: 'email-not-verified',
        message: 'Please verify your email before signing in.',
      );
    }

    return credential;
  }

  Future<UserCredential> register({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = credential.user;
    if (user != null && _isPasswordAccount(user)) {
      await user.sendEmailVerification();
      await _auth.signOut();
    }
    return credential;
  }

  Future<UserCredential> signInWithGoogle() async {
    final googleUser = await GoogleSignIn().signIn();
    if (googleUser == null) {
      throw FirebaseAuthException(
        code: 'google-sign-in-cancelled',
        message: 'Google sign-in was cancelled.',
      );
    }

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    return _auth.signInWithCredential(credential);
  }

  Future<void> sendPasswordResetEmail({required String email}) {
    return _auth.sendPasswordResetEmail(email: email.trim());
  }

  Future<void> resendEmailVerificationForCurrentUser() async {
    final user = _auth.currentUser;
    if (user != null && _isPasswordAccount(user) && !user.emailVerified) {
      await user.sendEmailVerification();
    }
  }

  Future<void> reloadCurrentUser() async {
    await _auth.currentUser?.reload();
  }

  Future<void> signOut() async {
    await _auth.signOut();
    try {
      await GoogleSignIn().signOut();
    } catch (_) {
      // Ignore if Google session is not active.
    }
  }

  bool _isPasswordAccount(User user) {
    if (user.providerData.isEmpty) {
      return user.email != null;
    }
    return user.providerData.any(
      (provider) => provider.providerId == EmailAuthProvider.PROVIDER_ID,
    );
  }
}

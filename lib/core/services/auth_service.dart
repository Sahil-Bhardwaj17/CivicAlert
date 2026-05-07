import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Google Sign-In
  Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth =
      await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      return await _auth.signInWithCredential(credential);
    } catch (e) {
      throw Exception('Google Sign-In failed: $e');
    }
  }

  // Create or update user in Firestore
  Future<CivicUser> createOrUpdateUser(User firebaseUser) async {
    final docRef = _firestore.collection('users').doc(firebaseUser.uid);
    final doc = await docRef.get();

    if (doc.exists) {
      await docRef.update({'lastActiveAt': FieldValue.serverTimestamp()});
      return CivicUser.fromFirestore(doc);
    } else {
      final newUser = CivicUser(
        uid: firebaseUser.uid,
        phoneNumber: firebaseUser.phoneNumber ?? '',
        displayName: firebaseUser.displayName ?? 'Civic Citizen',
        photoUrl: firebaseUser.photoURL,
        email: firebaseUser.email,
        joinedAt: DateTime.now(),
        lastActiveAt: DateTime.now(),
      );
      await docRef.set(newUser.toFirestore());
      return newUser;
    }
  }

  // Get current user data
  Future<CivicUser?> getCurrentUserData() async {
    final user = currentUser;
    if (user == null) return null;
    final doc = await _firestore.collection('users').doc(user.uid).get();
    if (!doc.exists) return null;
    return CivicUser.fromFirestore(doc);
  }

  // Update user profile
  Future<void> updateUserProfile({
    required String uid,
    String? displayName,
    String? email,
    bool? isVolunteer,
    String? preferredLanguage,
    double? homeLatitude,
    double? homeLongitude,
    String? homeArea,
  }) async {
    final updates = <String, dynamic>{};
    if (displayName != null) updates['displayName'] = displayName;
    if (email != null) updates['email'] = email;
    if (isVolunteer != null) updates['isVolunteer'] = isVolunteer;
    if (preferredLanguage != null) updates['preferredLanguage'] = preferredLanguage;
    if (homeLatitude != null) updates['homeLatitude'] = homeLatitude;
    if (homeLongitude != null) updates['homeLongitude'] = homeLongitude;
    if (homeArea != null) updates['homeArea'] = homeArea;
    await _firestore.collection('users').doc(uid).update(updates);
  }

  // Sign out
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  // Add points
  Future<void> addPoints(String uid, int points) async {
    await _firestore.collection('users').doc(uid).update({
      'totalPoints': FieldValue.increment(points),
      'monthlyPoints': FieldValue.increment(points),
    });
  }

  // Get leaderboard
  Future<List<CivicUser>> getLeaderboard({int limit = 10}) async {
    final snapshot = await _firestore
        .collection('users')
        .orderBy('monthlyPoints', descending: true)
        .limit(limit)
        .get();
    return snapshot.docs.map((doc) => CivicUser.fromFirestore(doc)).toList();
  }
}
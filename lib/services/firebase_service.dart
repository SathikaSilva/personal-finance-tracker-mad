import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/subscription.dart';

/// Firebase Service with Cloud Firestore & Authentication
/// Clean, beginner-friendly (lecturer style)
class AppFirebaseService {
  static final AppFirebaseService _instance = AppFirebaseService._internal();
  factory AppFirebaseService() => _instance;
  AppFirebaseService._internal();

  static bool isFirebaseInitialized = false;
  static String currentUserName = "User";
  static String currentUserEmail = "";

  FirebaseAuth get _auth => FirebaseAuth.instance;
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  // In-memory list for demo/preview when Firebase is not connected
  final List<Subscription> _previewList = [];
  final StreamController<List<Subscription>> _previewStream = StreamController<List<Subscription>>.broadcast();

  // ================= HELPER: FORMAT / RESOLVE USER NAME =================
  static String formatName(User? user, [String? dbName]) {
    // 1. Check if database has a custom name
    if (dbName != null && dbName.trim().isNotEmpty && dbName.trim().toLowerCase() != "user") {
      return dbName.trim();
    }
    // 2. Check if Firebase Auth has a display name
    if (user?.displayName != null && user!.displayName!.trim().isNotEmpty && user.displayName!.trim().toLowerCase() != "user") {
      return user.displayName!.trim();
    }
    // 3. Check cached currentUserName
    if (currentUserName.isNotEmpty && currentUserName.toLowerCase() != "user") {
      return currentUserName;
    }
    // 4. Derive clean name from email (e.g., sathika@gmail.com -> Sathika)
    final email = user?.email ?? currentUserEmail;
    if (email.isNotEmpty && email.contains('@')) {
      final prefix = email.split('@').first;
      final clean = prefix.replaceAll(RegExp(r'\d+'), '');
      final parts = clean.split(RegExp(r'[._]'));
      final formatted = parts
          .where((p) => p.isNotEmpty)
          .map((p) => '${p[0].toUpperCase()}${p.substring(1)}')
          .join(' ');
      if (formatted.isNotEmpty) return formatted;
      return prefix;
    }
    return "User";
  }

  // ================= AUTH =================
  User? get currentUser => isFirebaseInitialized ? _auth.currentUser : null;
  Stream<User?> get authStateChanges => isFirebaseInitialized ? _auth.authStateChanges() : Stream.value(null);

  Future<void> registerUser({required String name, required String email, required String password}) async {
    currentUserName = name.trim();
    currentUserEmail = email.trim();
    if (!isFirebaseInitialized) return;
    final res = await _auth.createUserWithEmailAndPassword(email: email.trim(), password: password.trim());
    await res.user?.updateDisplayName(name.trim());
    if (res.user != null) {
      await _firestore.collection('users').doc(res.user!.uid).set({
        'name': name.trim(),
        'email': email.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> loginUser({required String email, required String password}) async {
    currentUserEmail = email.trim();
    if (!isFirebaseInitialized) return;
    final res = await _auth.signInWithEmailAndPassword(email: email.trim(), password: password.trim());
    if (res.user != null) {
      String? foundName;
      if (res.user!.displayName != null && res.user!.displayName!.isNotEmpty && res.user!.displayName != "User") {
        foundName = res.user!.displayName;
      } else {
        final profile = await getUserProfile(res.user!.uid);
        if (profile != null && profile['name'] != null && profile['name'].toString().isNotEmpty && profile['name'].toString() != "User") {
          foundName = profile['name'].toString();
        }
      }
      currentUserName = formatName(res.user, foundName);
      if (res.user!.displayName == null || res.user!.displayName!.isEmpty || res.user!.displayName == "User") {
        try {
          await res.user!.updateDisplayName(currentUserName);
          await _firestore.collection('users').doc(res.user!.uid).set({
            'name': currentUserName,
            'email': email.trim(),
          }, SetOptions(merge: true));
        } catch (_) {}
      }
    }
  }

  Future<void> updateDisplayName(String newName) async {
    currentUserName = newName.trim();
    if (!isFirebaseInitialized || _auth.currentUser == null) return;
    try {
      await _auth.currentUser!.updateDisplayName(newName.trim());
      await _firestore.collection('users').doc(_auth.currentUser!.uid).update({'name': newName.trim()});
    } catch (_) {}
  }

  Future<void> updatePassword(String newPassword) async {
    if (!isFirebaseInitialized) return;
    if (_auth.currentUser != null) {
      await _auth.currentUser!.updatePassword(newPassword.trim());
    }
  }

  Future<void> sendPasswordReset(String email) async {
    if (!isFirebaseInitialized) return;
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  Future<void> signOut() async {
    currentUserName = "User";
    currentUserEmail = "";
    if (isFirebaseInitialized) await _auth.signOut();
  }

  Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    if (!isFirebaseInitialized) return null;
    final doc = await _firestore.collection('users').doc(uid).get();
    return (doc.exists && doc.data() != null) ? doc.data() : null;
  }

  // ================= CLOUD FIRESTORE CRUD =================

  // CREATE
  Future<void> addSubscription(String uid, Subscription sub) async {
    if (!isFirebaseInitialized) {
      _previewList.insert(0, sub.copyWith(id: DateTime.now().millisecondsSinceEpoch.toString()));
      _previewStream.add(List.unmodifiable(_previewList));
      return;
    }
    // Store in Firestore: users/{uid}/subscriptions
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('subscriptions')
        .add(sub.toMap());
  }

  // READ (Real-time Stream)
  Stream<List<Subscription>> getSubscriptionsStream(String uid) {
    if (!isFirebaseInitialized) {
      Future.microtask(() => _previewStream.add(List.unmodifiable(_previewList)));
      return _previewStream.stream;
    }
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('subscriptions')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Subscription.fromMap(doc.id, doc.data())).toList();
    });
  }

  // UPDATE
  Future<void> updateSubscription(String uid, Subscription sub) async {
    if (!isFirebaseInitialized) {
      final index = _previewList.indexWhere((s) => s.id == sub.id);
      if (index != -1) {
        _previewList[index] = sub;
        _previewStream.add(List.unmodifiable(_previewList));
      }
      return;
    }
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('subscriptions')
        .doc(sub.id)
        .update(sub.toMap());
  }

  // DELETE
  Future<void> deleteSubscription(String uid, String subId) async {
    if (!isFirebaseInitialized) {
      _previewList.removeWhere((s) => s.id == subId);
      _previewStream.add(List.unmodifiable(_previewList));
      return;
    }
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('subscriptions')
        .doc(subId)
        .delete();
  }
}

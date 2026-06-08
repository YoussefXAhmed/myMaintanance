import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import 'firebase_service.dart';
import 'local_store.dart';

/// Best-effort mirror of local data to Firestore under
/// `users/{uid}/{collection}/{id}`. Reads stay local (offline-first); this just
/// keeps the cloud copy in step and seeds a new device on login.
class CloudSync {
  CloudSync._();
  static final CloudSync instance = CloudSync._();

  bool get _enabled => FirebaseService.isAvailable && FirebaseAuth.instance.currentUser != null;
  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  CollectionReference<Map<String, dynamic>>? _col(String collection) {
    if (!_enabled) return null;
    return FirebaseFirestore.instance.collection('users').doc(_uid).collection(collection);
  }

  Future<void> upsert(String collection, String id, Map<String, dynamic> json) async {
    try {
      await _col(collection)?.doc(id).set(json, SetOptions(merge: true));
    } catch (e) {
      if (kDebugMode) debugPrint('cloud upsert skipped: $e');
    }
  }

  Future<void> remove(String collection, String id) async {
    try {
      await _col(collection)?.doc(id).delete();
    } catch (_) {}
  }

  /// Pulls every collection for the signed-in user into the local store.
  Future<void> pullAll() async {
    if (!_enabled) return;
    const collections = [
      LocalStore.vehicles,
      LocalStore.maintenance,
      LocalStore.fuel,
      LocalStore.expenses,
      LocalStore.documents,
    ];
    for (final c in collections) {
      try {
        final snap = await _col(c)!.get();
        for (final doc in snap.docs) {
          await LocalStore.instance.put(c, doc.id, doc.data());
        }
      } catch (e) {
        if (kDebugMode) debugPrint('cloud pull skipped ($c): $e');
      }
    }
  }
}

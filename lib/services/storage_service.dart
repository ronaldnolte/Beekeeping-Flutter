import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/apiary.dart';
import '../models/hive.dart';

class StorageService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<String> _getUserId() async {
    User? user = _auth.currentUser;
    if (user == null) {
      throw Exception("User is not logged in");
    }
    return user.uid;
  }

  // --- Apiaries ---

  Future<List<Apiary>> getApiaries() async {
    try {
      final uid = await _getUserId();
      print("storage: getApiaries for user $uid");

      final snapshot = await _db
          .collection('users')
          .doc(uid)
          .collection('apiaries')
          .get();
      
      print("storage: found ${snapshot.docs.length} apiaries");
      return snapshot.docs.map((doc) => Apiary.fromJson(doc.data())).toList();
    } catch (e) {
      print("Error fetching apiaries: $e");
      throw Exception("Failed to load apiaries: $e");
    }
  }

  Future<void> addApiary(Apiary apiary) async {
    final uid = await _getUserId();
    print("storage: addApiary ${apiary.name} for user $uid");
    
    await _db
        .collection('users')
        .doc(uid)
        .collection('apiaries')
        .doc(apiary.id)
        .set(apiary.toJson())
        .timeout(const Duration(seconds: 5));
    print("storage: addApiary complete");
  }

  Future<void> removeApiary(String id) async {
    final uid = await _getUserId();

    await _db
        .collection('users')
        .doc(uid)
        .collection('apiaries')
        .doc(id)
        .delete();
  }

  Future<void> updateApiary(Apiary apiary) async {
    final uid = await _getUserId();
    
    await _db
        .collection('users')
        .doc(uid)
        .collection('apiaries')
        .doc(apiary.id)
        .set(apiary.toJson());
  }
  
  // --- Hives ---

  Future<List<Hive>> getHives() async {
    final uid = await _getUserId();

    try {
      final snapshot = await _db
          .collection('users')
          .doc(uid)
          .collection('hives')
          .get();

      return snapshot.docs.map((doc) => Hive.fromJson(doc.data())).toList();
    } catch (e) {
      print("Error fetching hives: $e");
      return [];
    }
  }

  Future<void> addHive(Hive hive) async {
    final uid = await _getUserId();
    print("storage: addHive ${hive.name} for user $uid");

    await _db
        .collection('users')
        .doc(uid)
        .collection('hives')
        .doc(hive.id)
        .set(hive.toJson())
        .timeout(const Duration(seconds: 5));
    print("storage: addHive complete");
  }

  Future<void> updateHive(Hive updatedHive) async {
    final uid = await _getUserId();

    // We use set with SetOptions(merge: true) or just set to overwrite the doc
    // distinct from strict update() which needs fields. 
    // Since we store the whole object as json, .set() is cleaner for full replacement.
    await _db
        .collection('users')
        .doc(uid)
        .collection('hives')
        .doc(updatedHive.id)
        .set(updatedHive.toJson());
  }

  Future<void> deleteHive(String id) async {
    final uid = await _getUserId();

    await _db
        .collection('users')
        .doc(uid)
        .collection('hives')
        .doc(id)
        .delete();
  }
}

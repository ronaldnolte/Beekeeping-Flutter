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

    // 1. Check for hives in this apiary
    final hivesSnapshot = await _db
        .collection('users')
        .doc(uid)
        .collection('hives')
        .where('location', isEqualTo: id)
        .get();

    if (hivesSnapshot.docs.isNotEmpty) {
      print("storage: removeApiary found ${hivesSnapshot.docs.length} hives to move");
      
      // 2. Find or Create Default Apiary (Zip 00000)
      String targetApiaryId;
      
      final defaultApiarySnap = await _db
          .collection('users')
          .doc(uid)
          .collection('apiaries')
          .where('zipCode', isEqualTo: '00000')
          .get();

      if (defaultApiarySnap.docs.isNotEmpty) {
        targetApiaryId = defaultApiarySnap.docs.first.id;
      } else {
        // Create it
        final newApiary = Apiary(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: "Unassigned",
          zipCode: "00000",
          createdAt: DateTime.now().millisecondsSinceEpoch,
        );
        await addApiary(newApiary);
        targetApiaryId = newApiary.id;
      }

      // 3. Move hives
      final batch = _db.batch();
      for (var doc in hivesSnapshot.docs) {
        // We need to parse to Hive object to update correctly? 
        // Actually we can just update the 'location' field if we trust the structure,
        // but since we store full JSON objects, we should read-modify-write or just update the field if Firestore allows partial updates on map/json fields.
        // Our 'updateHive' uses .set(), replacing the whole doc.
        // Using .update({'location': targetApiaryId}) is safer/faster for this specific field change.
        batch.update(doc.reference, {'location': targetApiaryId});
      }
      await batch.commit();
    }

    // 4. Delete the apiary
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

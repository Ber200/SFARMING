import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../models/detection_model.dart';
import '../models/treatment_model.dart';
import '../models/soil_data_model.dart';
import '../models/trained_model_info.dart';
import 'cloudinary_service.dart';

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  // Auth Methods
  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserCredential> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
          email: email, password: password);
    } catch (e) {
      throw Exception('Sign in failed: $e');
    }
  }

  Future<UserCredential> registerWithEmailAndPassword(
    String email,
    String password,
    String name,
    String role,
    String? farmLocation,
  ) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Create user profile
      await _database.child('users').child(credential.user!.uid).set({
        'name': name,
        'email': email,
        'role': role,
        'farmLocation': farmLocation,
        'createdAt': DateTime.now().millisecondsSinceEpoch,
      });

      return credential;
    } catch (e) {
      throw Exception('Registration failed: $e');
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      throw Exception('Password reset failed: $e');
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw Exception('Sign out failed: $e');
    }
  }

  // Check if current user is admin
  Future<bool> isCurrentUserAdmin() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final userData = await getUserData(user.uid);
      return userData?.isAdmin ?? false;
    } catch (e) {
      return false;
    }
  }

  // User Methods
  Future<void> updateUserProfile({
    required String userId,
    required String name,
    String? farmLocation,
  }) async {
    try {
      final updates = <String, dynamic>{
        'name': name,
        if (farmLocation != null) 'farmLocation': farmLocation,
      };
      await _database.child('users').child(userId).update(updates);
    } catch (e) {
      throw Exception('Failed to update user profile: $e');
    }
  }

  Future<UserModel?> getUserData(String userId) async {
    try {
      final snapshot = await _database.child('users').child(userId).get();
      if (snapshot.exists) {
        return UserModel.fromMap(
          Map<String, dynamic>.from(snapshot.value as Map),
          userId,
        );
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get user data: $e');
    }
  }

  Stream<UserModel?> getUserDataStream(String userId) {
    return _database.child('users').child(userId).onValue.map((event) {
      if (event.snapshot.exists) {
        return UserModel.fromMap(
          Map<String, dynamic>.from(event.snapshot.value as Map),
          userId,
        );
      }
      return null;
    });
  }

  Future<void> updateUserData(String userId, Map<String, dynamic> data) async {
    try {
      await _database.child('users').child(userId).update(data);
    } catch (e) {
      throw Exception('Failed to update user data: $e');
    }
  }

  Future<void> deleteUserData(String userId) async {
    try {
      await _database.child('users').child(userId).remove();
    } catch (e) {
      throw Exception('Failed to delete user data: $e');
    }
  }

  // Detection Methods
  Future<String> saveDetection(DetectionModel detection) async {
    try {
      if (detection.disease.trim().isEmpty) {
        throw Exception('Invalid submission: Disease name cannot be empty.');
      }
      if (detection.userId.trim().isEmpty) {
        throw Exception('Invalid submission: Unauthenticated farmer ID.');
      }
      if (detection.latitude != null && (detection.latitude! < -90 || detection.latitude! > 90)) {
        throw Exception('Invalid coordinates: Latitude out of range [-90, 90].');
      }
      if (detection.longitude != null && (detection.longitude! < -180 || detection.longitude! > 180)) {
        throw Exception('Invalid coordinates: Longitude out of range [-180, 180].');
      }

      final ref = _database.child('detections').push();
      await ref.set(detection.toMap());
      return ref.key!;
    } catch (e) {
      throw Exception('Failed to save detection: $e');
    }
  }

  Stream<List<DetectionModel>> getDetectionsByUser(String userId) {
    return _database
        .child('detections')
        .orderByChild('userId')
        .equalTo(userId)
        .onValue
        .map((event) {
      if (event.snapshot.exists) {
        final Map<dynamic, dynamic> data = event.snapshot.value as Map;
        return data.entries.map((entry) {
          return DetectionModel.fromMap(
            Map<String, dynamic>.from(entry.value as Map),
            entry.key.toString(),
          );
        }).toList()
          ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
      }
      return <DetectionModel>[];
    });
  }

  Stream<List<DetectionModel>> getAllDetections() {
    return _database.child('detections').onValue.map((event) {
      if (event.snapshot.exists) {
        final Map<dynamic, dynamic> data = event.snapshot.value as Map;
        return data.entries.map((entry) {
          return DetectionModel.fromMap(
            Map<String, dynamic>.from(entry.value as Map),
            entry.key.toString(),
          );
        }).toList()
          ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
      }
      return <DetectionModel>[];
    });
  }

  /// Admin Map filter: detections whose `timestamp` (ms since epoch) falls
  /// within the inclusive [startMs, endMs] range. Filtered on the server via
  /// the `timestamp` index so the whole history is never pulled to the client.
  Stream<List<DetectionModel>> getDetectionsInRange(int startMs, int endMs) {
    return _database
        .child('detections')
        .orderByChild('timestamp')
        .startAt(startMs)
        .endAt(endMs)
        .onValue
        .map((event) {
      if (event.snapshot.exists) {
        final Map<dynamic, dynamic> data = event.snapshot.value as Map;
        return data.entries.map((entry) {
          return DetectionModel.fromMap(
            Map<String, dynamic>.from(entry.value as Map),
            entry.key.toString(),
          );
        }).toList()
          ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
      }
      return <DetectionModel>[];
    });
  }
  
  Future<void> archiveDetection(String detectionId) async {
    try {
      await _database
          .child('detections')
          .child(detectionId)
          .update({'isArchived': true});
    } catch (e) {
      throw Exception('Failed to archive detection: $e');
    }
  }

  Future<void> unarchiveDetection(String detectionId) async {
    try {
      await _database
          .child('detections')
          .child(detectionId)
          .update({'isArchived': false});
    } catch (e) {
      throw Exception('Failed to restore detection: $e');
    }
  }

  Future<void> deleteDetection(String detectionId) async {
    try {
      await _database.child('detections').child(detectionId).remove();
    } catch (e) {
      throw Exception('Failed to delete detection: $e');
    }
  }


  // Treatment Methods
  Future<String> saveTreatment(TreatmentModel treatment) async {
    try {
      final ref = _database.child('treatments').push();
      await ref.set(treatment.toMap());
      return ref.key!;
    } catch (e) {
      throw Exception('Failed to save treatment: $e');
    }
  }

  Future<bool> hasDuplicateTreatment({
    required String userId,
    required String type,
    required String disease,
    required DateTime scheduleDate,
  }) async {
    final snapshot = await _database
        .child('treatments')
        .orderByChild('userId')
        .equalTo(userId)
        .get();
    if (!snapshot.exists) return false;
    final value = snapshot.value;
    if (value is! Map) return false;

    final targetTime = scheduleDate.millisecondsSinceEpoch;
    for (final item in value.values) {
      if (item is! Map) continue;
      final entry = Map<String, dynamic>.from(item);
      final sameType = (entry['type'] ?? '') == type;
      final sameDisease = (entry['disease'] ?? '') == disease;
      final sameSchedule = (entry['scheduleDate'] ?? 0) == targetTime;
      final archived = entry['archived'] as bool? ?? false;
      final status = (entry['status'] ?? '') as String;
      final activeStatus = status != 'cancelled';
      if (sameType && sameDisease && sameSchedule && !archived && activeStatus) {
        return true;
      }
    }
    return false;
  }

  /// Admin: Add treatment/fertilization schedule for all farmers
  Future<void> addTreatmentForAllFarmers(TreatmentModel template) async {
    final usersSnapshot = await _database.child('users').get();
    if (!usersSnapshot.exists) return;
    final users = usersSnapshot.value as Map<dynamic, dynamic>;
    final farmerIds = <String>[];
    for (final entry in users.entries) {
      final userData = Map<String, dynamic>.from(entry.value as Map);
      if (userData['role'] == 'farmer') {
        farmerIds.add(entry.key.toString());
      }
    }
    await addTreatmentForFarmers(template, farmerIds);
  }

  /// Admin: Add treatment/fertilization for specific farmer(s).
  /// [farmerIds] - list of user IDs; if empty, assigns to all farmers.
  Future<void> addTreatmentForFarmers(
      TreatmentModel template, List<String> farmerIds) async {
    try {
      List<String> targetIds = farmerIds;
      if (targetIds.isEmpty) {
        final usersSnapshot = await _database.child('users').get();
        if (!usersSnapshot.exists) return;
        final users = usersSnapshot.value as Map<dynamic, dynamic>;
        targetIds = users.entries
            .where((e) =>
                (e.value as Map)['role'] == 'farmer')
            .map((e) => e.key.toString())
            .toList();
      }
      final now = DateTime.now();
      for (final userId in targetIds) {
        final treatment = TreatmentModel(
          id: '',
          userId: userId,
          disease: template.disease,
          remedy: template.remedy,
          scheduleDate: template.scheduleDate,
          status: 'approved',
          notes: template.notes,
          type: template.type,
          createdAt: now,
          synced: true,
        );
        final ref = _database.child('treatments').push();
        await ref.set(treatment.copyWith(id: ref.key!).toMap());
      }
    } catch (e) {
      throw Exception('Failed to add treatment for farmers: $e');
    }
  }

  Future<void> deleteTreatment(String treatmentId) async {
    try {
      await _database.child('treatments').child(treatmentId).remove();
    } catch (e) {
      throw Exception('Failed to delete treatment: $e');
    }
  }

  Future<void> updateTreatmentStatus(String treatmentId, String status) async {
    try {
      await _database
          .child('treatments')
          .child(treatmentId)
          .update({'status': status});
    } catch (e) {
      throw Exception('Failed to update treatment: $e');
    }
  }

  Future<void> updateTreatment({
    required String treatmentId,
    String? status,
    String? photoProofUrl,
    String? remedy,
    bool? archived,
    double? latitude,
    double? longitude,
    int? completedAt,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (status != null) updates['status'] = status;
      if (photoProofUrl != null) updates['photoProofUrl'] = photoProofUrl;
      if (remedy != null) updates['remedy'] = remedy;
      if (archived != null) updates['archived'] = archived;
      if (latitude != null) updates['latitude'] = latitude;
      if (longitude != null) updates['longitude'] = longitude;
      if (completedAt != null) updates['completedAt'] = completedAt;
      if (updates.isEmpty) return;
      await _database.child('treatments').child(treatmentId).update(updates);
    } catch (e) {
      throw Exception('Failed to update treatment: $e');
    }
  }

  Future<void> archiveTreatment(String treatmentId) async {
    try {
      await _database
          .child('treatments')
          .child(treatmentId)
          .update({'archived': true});
    } catch (e) {
      throw Exception('Failed to archive treatment: $e');
    }
  }

  Future<void> unarchiveTreatment(String treatmentId) async {
    try {
      await _database
          .child('treatments')
          .child(treatmentId)
          .update({'archived': false});
    } catch (e) {
      throw Exception('Failed to restore treatment: $e');
    }
  }

  Future<void> updateTreatmentSchedule(
      String treatmentId, DateTime newDate) async {
    try {
      await _database.child('treatments').child(treatmentId).update({
        'scheduleDate': newDate.millisecondsSinceEpoch,
      });
    } catch (e) {
      throw Exception('Failed to reschedule treatment: $e');
    }
  }

  Stream<List<TreatmentModel>> getTreatmentsByUser(String userId) {
    return _database
        .child('treatments')
        .orderByChild('userId')
        .equalTo(userId)
        .onValue
        .map((event) {
      if (event.snapshot.exists) {
        final Map<dynamic, dynamic> data = event.snapshot.value as Map;
        return data.entries.map((entry) {
          return TreatmentModel.fromMap(
            Map<String, dynamic>.from(entry.value as Map),
            entry.key.toString(),
          );
        }).toList();
      }
      return <TreatmentModel>[];
    });
  }

  /// Upload photo proof and return download URL
  Future<String> uploadPhotoProof(
      String treatmentId, Uint8List imageBytes) async {
    try {
      final cloudinaryService = CloudinaryService();
      return await cloudinaryService.uploadImage(imageBytes, 'treatment_$treatmentId');
    } catch (cError) {
      try {
        final ref = FirebaseStorage.instance
            .ref()
            .child('treatment_proofs')
            .child('$treatmentId-${DateTime.now().millisecondsSinceEpoch}.jpg');
        final uploadTask = ref.putData(imageBytes);
        final snapshot = await uploadTask;
        return await snapshot.ref.getDownloadURL();
      } catch (e) {
        throw Exception('Failed to upload photo proof: $cError | $e');
      }
    }
  }

  /// Upload a sensor-screen scan image and return its download URL.
  /// Uses Cloudinary first, falling back to Firebase Storage.
  Future<String?> uploadSoilScanImage(String userId, Uint8List imageBytes) async {
    try {
      final cloudinaryService = CloudinaryService();
      return await cloudinaryService.uploadImage(imageBytes, 'soil_scan_$userId');
    } catch (_) {
      try {
        final ref = FirebaseStorage.instance
            .ref()
            .child('soil_scans')
            .child('$userId-${DateTime.now().millisecondsSinceEpoch}.jpg');
        final uploadTask = ref.putData(imageBytes);
        final snapshot = await uploadTask;
        return await snapshot.ref.getDownloadURL();
      } catch (e) {
        return null;
      }
    }
  }

  Stream<List<TreatmentModel>> getAllTreatments() {
    return _database.child('treatments').onValue.map((event) {
      final value = event.snapshot.value;
      if (value == null || value is! Map) return <TreatmentModel>[];
      final Map<dynamic, dynamic> data = value;
      return data.entries.map((entry) {
        if (entry.value is! Map) return null;
        return TreatmentModel.fromMap(
          Map<String, dynamic>.from(entry.value as Map),
          entry.key.toString(),
        );
      }).whereType<TreatmentModel>().toList();
    });
  }

  // Soil Data Methods
  Future<void> saveSoilData(SoilDataModel soilData) async {
    try {
      await _database
          .child('soil_data')
          .child(soilData.userId)
          .set(soilData.toMap());
    } catch (e) {
      throw Exception('Failed to save soil data: $e');
    }
  }

  Future<void> updateSoilDataForUser({
    required String userId,
    double? ph,
    double? moisture,
    String? status,
    String? description,
  }) async {
    try {
      final updates = <String, dynamic>{
        'userId': userId,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };

      if (ph != null) updates['ph'] = ph;
      if (moisture != null) updates['moisture'] = moisture;
      if (status != null) updates['status'] = status;
      if (description != null) updates['description'] = description;

      await _database.child('soil_data').child(userId).update(updates);
    } catch (e) {
      throw Exception('Failed to update soil data: $e');
    }
  }

  Future<SoilDataModel?> getSoilData(String userId) async {
    try {
      final snapshot = await _database.child('soil_data').child(userId).get();
      if (snapshot.exists) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        return SoilDataModel.fromMap(data);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get soil data: $e');
    }
  }

  Stream<SoilDataModel?> getSoilDataStream(String userId) {
    return _database.child('soil_data').child(userId).onValue.map((event) {
      if (event.snapshot.exists) {
        final data = Map<String, dynamic>.from(event.snapshot.value as Map);
        return SoilDataModel.fromMap(data);
      }
      return null;
    });
  }

  // Admin: Get soil data for any user
  Future<SoilDataModel?> getSoilDataForUser(String userId) async {
    try {
      final snapshot = await _database.child('soil_data').child(userId).get();
      if (snapshot.exists) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        return SoilDataModel.fromMap(data);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get soil data: $e');
    }
  }

  // Admin Methods
  Stream<List<UserModel>> getAllUsers() {
    return _database.child('users').onValue.map((event) {
      if (event.snapshot.exists) {
        final Map<dynamic, dynamic> data = event.snapshot.value as Map;
        return data.entries.map((entry) {
          return UserModel.fromMap(
            Map<String, dynamic>.from(entry.value as Map),
            entry.key.toString(),
          );
        }).toList();
      }
      return <UserModel>[];
    }).handleError((error) {
      throw Exception('Failed to fetch users: $error');
    });
  }

  // Admin Map Boundary
  Future<void> saveAdminMapBoundary(List<Map<String, double>> points) async {
    try {
      await _database.child('admin_settings').child('map_boundary').set(points);
    } catch (e) {
      throw Exception('Failed to save map boundary: $e');
    }
  }

  Future<List<Map<String, double>>?> getAdminMapBoundary() async {
    try {
      final snapshot = await _database.child('admin_settings').child('map_boundary').get();
      if (!snapshot.exists || snapshot.value == null) return null;
      
      List<dynamic> items = [];
      if (snapshot.value is List) {
        items = snapshot.value as List;
      } else if (snapshot.value is Map) {
        items = (snapshot.value as Map).values.toList();
      }

      return items.where((e) => e != null).map((e) {
        final m = Map<dynamic, dynamic>.from(e as Map);
        return {
          'lat': (m['lat'] as num).toDouble(),
          'lng': (m['lng'] as num).toDouble(),
        };
      }).toList();
    } catch (e) {
      return null;
    }
  }

  // Deployed ML model (admin Model Trainer)
  /// Upload a trained [tfliteBytes] + [labelsBytes] model and activate it.
  Future<TrainedModelInfo> uploadTrainedModel({
    required Uint8List tfliteBytes,
    required Uint8List labelsBytes,
    required List<String> classNames,
  }) async {
    try {
      final version = 'model_${DateTime.now().millisecondsSinceEpoch}';
      final dir = FirebaseStorage.instance.ref().child('models').child(version);
      final modelSnapshot = await dir.child('model.tflite').putData(tfliteBytes);
      final labelsSnapshot = await dir.child('labels.txt').putData(labelsBytes);
      final modelUrl = await modelSnapshot.ref.getDownloadURL();
      final labelsUrl = await labelsSnapshot.ref.getDownloadURL();

      final info = TrainedModelInfo(
        version: version,
        timestamp: DateTime.now().millisecondsSinceEpoch,
        classes: classNames,
        modelUrl: modelUrl,
        labelsUrl: labelsUrl,
        active: true,
      );

      await _database.child('admin_settings').child('model').set(info.toMap());
      return info;
    } catch (e) {
      throw Exception('Failed to deploy trained model: $e');
    }
  }

  /// One-shot read of the currently active deployed model (if any).
  Future<TrainedModelInfo?> getActiveModelOnce() async {
    try {
      final snapshot = await _database.child('admin_settings').child('model').get();
      if (!snapshot.exists || snapshot.value == null) return null;
      final map = Map<String, dynamic>.from(snapshot.value as Map);
      return TrainedModelInfo.fromMap(map, map['version'] as String? ?? '');
    } catch (e) {
      debugPrint('[FirebaseService] Failed to read active model: $e');
      return null;
    }
  }
}

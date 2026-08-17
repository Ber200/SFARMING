import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/detection_model.dart';
import '../models/treatment_model.dart';
import '../models/soil_data_model.dart';

// Helper to convert DateTime to Firestore Timestamp
Timestamp _dateTimeToTimestamp(DateTime dateTime) {
  return Timestamp.fromDate(dateTime);
}

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // User Methods
  Future<UserModel?> getUserData(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        final data = doc.data()!;
        // Convert Firestore Timestamp to milliseconds for compatibility
        if (data['createdAt'] is Timestamp) {
          data['createdAt'] =
              (data['createdAt'] as Timestamp).millisecondsSinceEpoch;
        }
        return UserModel.fromMap(data, doc.id);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get user data: $e');
    }
  }

  Stream<UserModel?> getUserDataStream(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .snapshots()
        .map((snapshot) {
      if (snapshot.exists) {
        final data = snapshot.data()!;
        // Convert Firestore Timestamp to milliseconds for compatibility
        if (data['createdAt'] is Timestamp) {
          data['createdAt'] =
              (data['createdAt'] as Timestamp).millisecondsSinceEpoch;
        }
        return UserModel.fromMap(data, snapshot.id);
      }
      return null;
    });
  }

  Future<void> updateUserData(String userId, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('users').doc(userId).update(data);
    } catch (e) {
      throw Exception('Failed to update user data: $e');
    }
  }

  // Detection Methods
  Future<String> saveDetection(DetectionModel detection) async {
    try {
      final data = detection.toMap();
      // Convert milliseconds to Firestore Timestamp
      data['timestamp'] = _dateTimeToTimestamp(detection.timestamp);
      final docRef = await _firestore.collection('detections').add(data);
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to save detection: $e');
    }
  }

  Stream<List<DetectionModel>> getDetectionsByUser(String userId) {
    return _firestore
        .collection('detections')
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        // Convert Firestore Timestamp to milliseconds for compatibility
        if (data['timestamp'] is Timestamp) {
          data['timestamp'] =
              (data['timestamp'] as Timestamp).millisecondsSinceEpoch;
        }
        return DetectionModel.fromMap(data, doc.id);
      }).toList();
    });
  }

  Stream<List<DetectionModel>> getAllDetections() {
    return _firestore
        .collection('detections')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        // Convert Firestore Timestamp to milliseconds for compatibility
        if (data['timestamp'] is Timestamp) {
          data['timestamp'] =
              (data['timestamp'] as Timestamp).millisecondsSinceEpoch;
        }
        return DetectionModel.fromMap(data, doc.id);
      }).toList();
    });
  }

  // Treatment Methods
  Future<String> saveTreatment(TreatmentModel treatment) async {
    try {
      final data = treatment.toMap();
      // Convert milliseconds to Firestore Timestamp
      data['scheduleDate'] = _dateTimeToTimestamp(treatment.scheduleDate);
      data['createdAt'] = _dateTimeToTimestamp(treatment.createdAt);
      final docRef = await _firestore.collection('treatments').add(data);
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to save treatment: $e');
    }
  }

  Future<void> updateTreatmentStatus(String treatmentId, String status) async {
    try {
      await _firestore
          .collection('treatments')
          .doc(treatmentId)
          .update({'status': status});
    } catch (e) {
      throw Exception('Failed to update treatment: $e');
    }
  }

  Stream<List<TreatmentModel>> getTreatmentsByUser(String userId) {
    return _firestore
        .collection('treatments')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        // Convert Firestore Timestamps to milliseconds for compatibility
        if (data['scheduleDate'] is Timestamp) {
          data['scheduleDate'] =
              (data['scheduleDate'] as Timestamp).millisecondsSinceEpoch;
        }
        if (data['createdAt'] is Timestamp) {
          data['createdAt'] =
              (data['createdAt'] as Timestamp).millisecondsSinceEpoch;
        }
        return TreatmentModel.fromMap(data, doc.id);
      }).toList();
    });
  }

  Stream<List<TreatmentModel>> getAllTreatments() {
    return _firestore.collection('treatments').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        // Convert Firestore Timestamps to milliseconds for compatibility
        if (data['scheduleDate'] is Timestamp) {
          data['scheduleDate'] =
              (data['scheduleDate'] as Timestamp).millisecondsSinceEpoch;
        }
        if (data['createdAt'] is Timestamp) {
          data['createdAt'] =
              (data['createdAt'] as Timestamp).millisecondsSinceEpoch;
        }
        return TreatmentModel.fromMap(data, doc.id);
      }).toList();
    });
  }

  // Soil Data Methods
  Future<void> saveSoilData(SoilDataModel soilData) async {
    try {
      final data = soilData.toMap();
      // Convert milliseconds to Firestore Timestamp
      data['timestamp'] = _dateTimeToTimestamp(soilData.timestamp);
      await _firestore
          .collection('soil_data')
          .doc(soilData.userId)
          .set(data, SetOptions(merge: true));
    } catch (e) {
      throw Exception('Failed to save soil data: $e');
    }
  }

  Future<SoilDataModel?> getSoilData(String userId) async {
    try {
      final doc = await _firestore.collection('soil_data').doc(userId).get();
      if (doc.exists) {
        final data = doc.data()!;
        // Convert Firestore Timestamp to milliseconds for compatibility
        if (data['timestamp'] is Timestamp) {
          data['timestamp'] =
              (data['timestamp'] as Timestamp).millisecondsSinceEpoch;
        }
        return SoilDataModel.fromMap(data);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get soil data: $e');
    }
  }

  Stream<SoilDataModel?> getSoilDataStream(String userId) {
    return _firestore
        .collection('soil_data')
        .doc(userId)
        .snapshots()
        .map((snapshot) {
      if (snapshot.exists) {
        final data = snapshot.data()!;
        // Convert Firestore Timestamp to milliseconds for compatibility
        if (data['timestamp'] is Timestamp) {
          data['timestamp'] =
              (data['timestamp'] as Timestamp).millisecondsSinceEpoch;
        }
        return SoilDataModel.fromMap(data);
      }
      return null;
    });
  }

  // Admin Methods
  Stream<List<UserModel>> getAllUsers() {
    return _firestore.collection('users').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        // Convert Firestore Timestamp to milliseconds for compatibility
        if (data['createdAt'] is Timestamp) {
          data['createdAt'] =
              (data['createdAt'] as Timestamp).millisecondsSinceEpoch;
        }
        return UserModel.fromMap(data, doc.id);
      }).toList();
    });
  }
}

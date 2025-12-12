import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';

class StoreLocation {
  final String id;
  final String name;
  final String category;
  final String description;
  final LatLng location;

  StoreLocation({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    required this.location,
  });

  Map<String, dynamic> toMap() => {
        'name': name,
        'category': category,
        'description': description,
        'lat': location.latitude,
        'lng': location.longitude,
        'createdAt': FieldValue.serverTimestamp(),
      };

  factory StoreLocation.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return StoreLocation(
      id: doc.id,
      name: data['name'] ?? '',
      category: data['category'] ?? '',
      description: data['description'] ?? '',
      location: LatLng(
        (data['lat'] ?? 0).toDouble(),
        (data['lng'] ?? 0).toDouble(),
      ),
    );
  }
}

class StoreService {
  final _col = FirebaseFirestore.instance.collection('stores');

  Stream<List<StoreLocation>> streamStores() =>
      _col.orderBy('createdAt', descending: true).snapshots().map(
            (snap) => snap.docs.map(StoreLocation.fromDoc).toList(),
          );

  Future<void> addStore(StoreLocation store) async {
    await _col.add(store.toMap());
  }
}
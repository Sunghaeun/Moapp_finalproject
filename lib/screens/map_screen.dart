import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({Key? key}) : super(key: key);

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  
  // 서울 시내 선물 매장 위치들
  final List<StoreLocation> _stores = [
    StoreLocation(
      name: '현대백화점 본점',
      location: const LatLng(37.5665, 126.9780),
      category: '백화점',
      description: '다양한 브랜드와 선물 아이템을 만날 수 있는 프리미엄 백화점',
    ),
    StoreLocation(
      name: '롯데백화점 명동점',
      location: const LatLng(37.5665, 126.9780),
      category: '백화점',
      description: '명동 중심가에 위치한 대형 백화점',
    ),
    StoreLocation(
      name: '홍대 와우산로',
      location: const LatLng(37.5563, 126.9236),
      category: '쇼핑거리',
      description: '젊고 트렌디한 선물 아이템이 가득한 홍대 거리',
    ),
    StoreLocation(
      name: '강남역 지하상가',
      location: const LatLng(37.4979, 127.0276),
      category: '지하상가',
      description: '다양한 액세서리와 소품을 저렴하게 구매할 수 있는 곳',
    ),
    StoreLocation(
      name: '이태원 앤티크샵',
      location: const LatLng(37.5345, 126.9947),
      category: '앤티크샵',
      description: '독특하고 특별한 빈티지 선물을 찾을 수 있는 곳',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '🎁 선물 매장 지도',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF012D5C),
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF012D5C),
        elevation: 2,
        centerTitle: true,
      ),
      body: FlutterMap(
        mapController: _mapController,
        options: const MapOptions(
          initialCenter: LatLng(37.5665, 126.9780), // 서울 중심
          initialZoom: 12.0,
          minZoom: 10.0,
          maxZoom: 18.0,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.moapp_finalproject',
          ),
          MarkerLayer(
            markers: _stores.map((store) => Marker(
              point: store.location,
              width: 50,
              height: 50,
              child: GestureDetector(
                onTap: () => _showStoreInfo(context, store),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF463F),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.store,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            )).toList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _moveToCurrentLocation(),
        backgroundColor: const Color(0xFF51934C),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.my_location),
        label: const Text('내 위치'),
      ),
    );
  }

  void _showStoreInfo(BuildContext context, StoreLocation store) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF463F),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      store.category,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                store.name,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF012D5C),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                store.description,
                style: TextStyle(
                  fontSize: 14,
                  color: const Color(0xFF012D5C).withOpacity(0.7),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _moveToStore(store);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF51934C),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.directions),
                      SizedBox(width: 8),
                      Text(
                        '이 매장으로 이동',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _moveToStore(StoreLocation store) {
    _mapController.move(store.location, 15.0);
  }

  void _moveToCurrentLocation() {
    // 서울 시청 기준으로 이동 (실제 앱에서는 위치 권한을 받아 현재 위치로 이동)
    _mapController.move(const LatLng(37.5665, 126.9780), 14.0);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('📍 현재 위치 기준으로 이동했습니다'),
        backgroundColor: Color(0xFF51934C),
      ),
    );
  }
}

class StoreLocation {
  final String name;
  final LatLng location;
  final String category;
  final String description;

  StoreLocation({
    required this.name,
    required this.location,
    required this.category,
    required this.description,
  });
}
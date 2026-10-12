import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../widgets/animated_premium_background.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Salon Konumları Harita Sayfası
class SalonMapPage extends StatefulWidget {
  const SalonMapPage({super.key});

  @override
  State<SalonMapPage> createState() => _SalonMapPageState();
}

class _SalonMapPageState extends State<SalonMapPage> {
  final MapController _mapController = MapController();
  
  // Salon konumları (İstanbul bölgesi)
  static final List<SalonLocation> _salons = [
    SalonLocation(
      name: 'ENES KUAFÖR',
      coordinates: LatLng(41.0082, 28.9784),
      address: 'Sultanahmet, İstanbul',
      color: const Color(0xFF00D4FF),
    ),
    SalonLocation(
      name: 'BERBER RAGO',
      coordinates: LatLng(40.9922, 28.8400),
      address: 'Bakırköy, İstanbul',
      color: const Color(0xFFFFD700),
    ),
    SalonLocation(
      name: 'Hamza Image Maker',
      coordinates: LatLng(41.0151, 29.1245),
      address: 'Kadıköy, İstanbul',
      color: const Color(0xFF00FF88),
    ),
  ];

  int? _selectedSalonIndex;

  @override
  Widget build(BuildContext context) {
    return AnimatedPremiumBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF00D4FF), Color(0xFF00FF88)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00D4FF).withOpacity(0.4),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: const Icon(Icons.map, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 12),
              const Text(
                'Salon Konumları',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Column(
          children: [
            // Harita
            Expanded(
              flex: 3,
              child: Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00D4FF).withOpacity(0.2),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: const LatLng(41.0082, 28.9784),
                      initialZoom: 11.0,
                      minZoom: 10.0,
                      maxZoom: 18.0,
                      onTap: (_, __) {
                        setState(() {
                          _selectedSalonIndex = null;
                        });
                      },
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.kestirme.app',
                      ),
                      
                      MarkerLayer(
                        markers: _salons.asMap().entries.map((entry) {
                          final index = entry.key;
                          final salon = entry.value;
                          final isSelected = _selectedSalonIndex == index;
                          
                          return Marker(
                            point: salon.coordinates,
                            width: isSelected ? 100 : 80,
                            height: isSelected ? 100 : 80,
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedSalonIndex = index;
                                });
                                _mapController.move(salon.coordinates, 14.0);
                              },
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          salon.color,
                                          salon.color.withOpacity(0.7),
                                        ],
                                      ),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 3,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: salon.color.withOpacity(0.6),
                                          blurRadius: isSelected ? 20 : 15,
                                          spreadRadius: isSelected ? 3 : 1,
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      Icons.content_cut,
                                      color: Colors.white,
                                      size: isSelected ? 28 : 24,
                                    ),
                                  ),
                                  if (isSelected) ...[
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.8),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: salon.color,
                                          width: 1,
                                        ),
                                      ),
                                      child: Text(
                                        salon.name,
                                        style: TextStyle(
                                          color: salon.color,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            // Salon listesi
            Expanded(
              flex: 2,
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                itemCount: _salons.length,
                itemBuilder: (context, index) {
                  final salon = _salons[index];
                  final isSelected = _selectedSalonIndex == index;
                  
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? salon.color.withOpacity(0.15)
                          : Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? salon.color
                            : Colors.white.withOpacity(0.1),
                        width: isSelected ? 2 : 1,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: salon.color.withOpacity(0.3),
                                blurRadius: 15,
                                spreadRadius: 1,
                              ),
                            ]
                          : null,
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () {
                          setState(() {
                            _selectedSalonIndex = index;
                          });
                          _mapController.move(salon.coordinates, 14.0);
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      salon.color,
                                      salon.color.withOpacity(0.7),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: salon.color.withOpacity(0.4),
                                      blurRadius: 10,
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.content_cut,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      salon.name,
                                      style: TextStyle(
                                        color: isSelected
                                            ? salon.color
                                            : Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.location_on,
                                          size: 14,
                                          color: Colors.white.withOpacity(0.5),
                                        ),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            salon.address,
                                            style: TextStyle(
                                              color: Colors.white.withOpacity(0.6),
                                              fontSize: 12,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.arrow_forward_ios,
                                color: isSelected
                                    ? salon.color
                                    : Colors.white.withOpacity(0.3),
                                size: 16,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ).animate().fadeIn(delay: Duration(milliseconds: 100 * index)).slideX();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Salon konumu modeli
class SalonLocation {
  final String name;
  final LatLng coordinates;
  final String address;
  final Color color;

  SalonLocation({
    required this.name,
    required this.coordinates,
    required this.address,
    required this.color,
  });
}

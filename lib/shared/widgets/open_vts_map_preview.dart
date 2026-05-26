import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../models/vehicle_summary.dart';

class OpenVtsMapPreview extends StatelessWidget {
  const OpenVtsMapPreview({
    required this.vehicles,
    super.key,
  });

  final List<VehicleSummary> vehicles;

  @override
  Widget build(BuildContext context) {
    final center = vehicles.isNotEmpty
        ? LatLng(vehicles.first.latitude, vehicles.first.longitude)
        : const LatLng(28.6139, 77.2090);

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: FlutterMap(
        options: MapOptions(
          initialCenter: center,
          initialZoom: 11,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.openvts.mobile',
          ),
          MarkerLayer(
            markers: vehicles
                .map(
                  (vehicle) => Marker(
                    point: LatLng(vehicle.latitude, vehicle.longitude),
                    width: 48,
                    height: 48,
                    child: const Icon(Icons.location_on, size: 34),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

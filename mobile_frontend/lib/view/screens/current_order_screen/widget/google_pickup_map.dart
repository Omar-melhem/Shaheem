// The Google Maps adapter of the pickup map (D-A62, D-A81).

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mobile_frontend/domain/entities/active_order.dart';
import 'package:mobile_frontend/helper/translation/l10n_extension.dart';
import 'package:mobile_frontend/theme/app_color.dart';
import 'package:mobile_frontend/view/screens/current_order_screen/widget/pickup_map.dart';

/// Whether the Google Maps native keys were provisioned for this build
/// (`--dart-define=SHAHM_GOOGLE_MAPS=true`, set together with the
/// `SHAHM_GOOGLE_MAPS_API_KEY` Gradle property / Xcode build setting).
/// Without it no Google map is ever built, so a key-less build cannot
/// crash or show a blank map pretending to work.
const bool googleMapsConfigured = bool.fromEnvironment('SHAHM_GOOGLE_MAPS');

/// The [PickupMapBuilder] to use: the Google map when configured, else
/// null (the screen then says the map is unavailable).
const PickupMapBuilder? configuredPickupMapBuilder = googleMapsConfigured
    ? googlePickupMapBuilder
    : null;

/// [PickupMapBuilder] that builds a [GooglePickupMap].
Widget googlePickupMapBuilder(BuildContext context, PickupMapData data) =>
    GooglePickupMap(data: data);

/// The merchant marker, the captain marker when known, and the road route
/// when the routing source returned one. The camera fits the points once
/// per order / captain-presence change, never on unrelated rebuilds. No app
/// control is drawn over the map, so Google's logo and attribution stay
/// visible; the map owns its controller and disposes it with this widget
/// (leaving the pickup leg removes it from the tree).
class GooglePickupMap extends StatefulWidget {
  const GooglePickupMap({super.key, required this.data});

  final PickupMapData data;

  @override
  State<GooglePickupMap> createState() => _GooglePickupMapState();
}

class _GooglePickupMapState extends State<GooglePickupMap> {
  GoogleMapController? _controller;

  /// What the camera was last fitted for.
  String? _fittedFor;

  static LatLng _latLng(GeoPoint p) => LatLng(p.latitude, p.longitude);

  String get _fitKey =>
      '${widget.data.orderId}|${widget.data.captainLocation != null}';

  Future<void> _fit() async {
    final controller = _controller;
    if (controller == null || _fittedFor == _fitKey) return;
    _fittedFor = _fitKey;
    final pickup = widget.data.pickup;
    final captain = widget.data.captainLocation;
    if (captain == null) {
      await controller.moveCamera(
        CameraUpdate.newLatLngZoom(_latLng(pickup), 15),
      );
      return;
    }
    final south = pickup.latitude < captain.latitude
        ? pickup.latitude
        : captain.latitude;
    final north = pickup.latitude < captain.latitude
        ? captain.latitude
        : pickup.latitude;
    final west = pickup.longitude < captain.longitude
        ? pickup.longitude
        : captain.longitude;
    final east = pickup.longitude < captain.longitude
        ? captain.longitude
        : pickup.longitude;
    await controller.moveCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(south, west),
          northeast: LatLng(north, east),
        ),
        48,
      ),
    );
  }

  @override
  void didUpdateWidget(GooglePickupMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_fitKey != _fittedFor) _fit();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final data = widget.data;
    final captain = data.captainLocation;
    final route = data.routePath;
    return Semantics(
      label: l10n.pickupMapSemantics(data.restaurantName),
      child: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: _latLng(data.pickup),
          zoom: 15,
        ),
        onMapCreated: (controller) {
          _controller = controller;
          _fit();
        },
        markers: {
          Marker(
            markerId: const MarkerId('pickup'),
            position: _latLng(data.pickup),
            infoWindow: InfoWindow(title: data.restaurantName),
          ),
          if (captain != null)
            Marker(
              markerId: const MarkerId('captain'),
              position: _latLng(captain),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueAzure,
              ),
              infoWindow: InfoWindow(title: l10n.captainMarkerTitle),
            ),
        },
        polylines: {
          if (route != null && route.length >= 2)
            Polyline(
              polylineId: const PolylineId('route'),
              points: [for (final p in route) _latLng(p)],
              color: AppColor.primary,
              width: 5,
            ),
        },
        myLocationButtonEnabled: false,
        mapToolbarEnabled: false,
        zoomControlsEnabled: true,
        compassEnabled: true,
      ),
    );
  }
}

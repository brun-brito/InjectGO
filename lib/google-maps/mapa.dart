// ignore_for_file: library_private_types_in_public_api, avoid_print
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late GoogleMapController mapController;
  final Set<Marker> _markers = {};
  int id = 1;

 @override
  void initState() {
    super.initState();
    _getLocations();
  }

  Future<void> _getLocations() async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('maquinas').get();
      for (var doc in snapshot.docs) {
        if (doc.exists) {
          try {
            double latitude = doc['latitude'];
            double longitude = doc['longitude'];
            String cidade = doc['cidade'];
            String estado = doc['estado'];
            String endereco = doc['endereco'];

            // ignore: unnecessary_null_comparison
            if (latitude != null && longitude != null) {
              setState(() {
                _markers.add(
                  Marker(
                    markerId: MarkerId(doc.id),
                    position: LatLng(latitude, longitude),
                    infoWindow: InfoWindow(
                      title: '$cidade - $estado',
                      snippet: endereco,
                      onTap: () {
                        copiaEndereco(endereco);
                      }
                    ),
                    icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
                  ), 
                );
              });
            }
          } catch (e) {
            print('Erro ao processar documento ${doc.id}: $e');
          }
        }
      }
    } catch (e) {
      print('Erro ao carregar localizações: $e');
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  void copiaEndereco(String endereco){
    Clipboard.setData(ClipboardData(text: endereco));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Endereço copiado!'))
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Localização das nossas máquinas'),
      ),
      body: GoogleMap(
        onMapCreated: _onMapCreated,
        initialCameraPosition: const CameraPosition(
          target: LatLng(-14.235004, -51.925280),
          zoom: 4.0,
        ),
        markers: _markers,
      ),
    );
  }
}
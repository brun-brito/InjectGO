// ignore_for_file: library_private_types_in_public_api
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/services.dart';


class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late GoogleMapController mapController;
  final Set<Marker> _markers = {};
  int id = 1;

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
    _onAddMarkerButtonPressed(
      -3.7492340963758783,-38.52882451827645,
      'Máquina 1 - Fortaleza',
      'Edifício Business Center - Av. Treze de Maio, 1096 - Fátima, Fortaleza - CE, 60040-530',
    );
    // PARA ADD OUTRA MÁQUINA:
    // _onAddMarkerButtonPressed(
    //   -23.550520, -46.633308,
    //   'Máquina 2 - Sao paulo',
    //   'Edifício Business Center - Av. Treze de Maio, 1096 - Fátima, Fortaleza - CE, 60040-530',
    // );
  }

  void _onAddMarkerButtonPressed(double latitude, double longitude, String titulo, String descricao) {
    id++;
    setState(() {
      _markers.add(
        Marker(
          markerId: MarkerId('id-$id'),
          position: LatLng(latitude, longitude), 
          infoWindow: InfoWindow(
            title: titulo,
            snippet: descricao,
            onTap: () {
              copiaEndereco(descricao);
            }
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
      );
    });
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
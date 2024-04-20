import 'package:flutter/material.dart';
import 'package:inject_go/screens/token.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Profile Screen with Google Map',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: ProfileScreen(),
    );
  }
}

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late GoogleMapController mapController;

  final LatLng _center = const LatLng(-19.92450, -43.93524); // Coordenadas de Belo Horizonte

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            _buildHeader(),
            _buildProfileSection(),
            _buildMapSection(), // Inserindo o mapa aqui
            _buildMenu(),
            // _buildFacialAnalysis(),
            _buildBottomNavigationBar(),
          ],
        ),
      ),
    );
  }

Widget _buildMapSection() {
    return Container(
      height: 200, // Altura desejada para o mapa
      child: GoogleMap(
        onMapCreated: _onMapCreated,
        initialCameraPosition: CameraPosition(
          target: _center,
          zoom: 11.0,
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.only(top: 50),
      alignment: Alignment.center,
      child: Text(
        'InjectGO',
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, height: 2),
      ),
    );
  }

Widget _buildProfileSection() {
  return ListTile(
    leading: Stack(
      alignment: Alignment.bottomRight,
      children: <Widget>[
        const CircleAvatar(
          radius: 30,
          backgroundImage: NetworkImage('https://link-to-your-image.com/image.jpg'),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.blue,
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white,
              width: 2,
            ),
          ),
          child: IconButton(
            icon: Icon(Icons.add, color: Colors.white),
            onPressed: () {
              // TODO: Implementar funcionalidade de adicionar foto
            },
          ),
        ),
      ],
    ),
    title: Text('Dra. Joana'),
    subtitle: Text('Biomédica, 30 anos, reside em Belo Horizonte'),
  );
}



  Widget _buildMenu() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: <Widget>[
        _buildMenuButton(Icons.check_circle, 'Avaliações/Agenda'),
        _buildMenuButton(Icons.shopping_cart, 'Mercado'),
        _buildMenuButton(Icons.more_horiz, 'Mais'),
      ],
    );
  }

  Widget _buildMenuButton(IconData icon, String label) {
    return Column(
      children: <Widget>[
        Icon(icon, size: 30),
        Text(label),
      ],
    );
  }

  Widget _buildFacialAnalysis(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: <Widget>[
          Image.asset('assets/images/logoInject.jpeg'),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: () =>  
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => RandomNumberScreen())
            ),
            child: Text('Gerar Token'),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      items: const <BottomNavigationBarItem>[
        BottomNavigationBarItem(
          icon: Icon(Icons.dashboard),
          label: 'Dashboard',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.timeline),
          label: 'Atividade',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Perfil',
        ),
      ],
    );
  }
}

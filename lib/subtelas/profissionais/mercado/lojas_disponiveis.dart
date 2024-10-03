// ignore_for_file: library_private_types_in_public_api, curly_braces_in_flow_control_structures

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:geolocator/geolocator.dart';
import 'package:inject_go/screens/profile_screen.dart';
import 'package:inject_go/subtelas/profissionais/mercado/exibe_produtos.dart';

class MercadoScreen extends StatefulWidget {
  final Position userPosition;
  final String email;

  const MercadoScreen({required this.userPosition, required this.email, super.key});

  @override
  _MercadoScreenState createState() => _MercadoScreenState();
}

class _MercadoScreenState extends State<MercadoScreen> {
  final TextEditingController _searchController = TextEditingController();
  String searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lojas Disponíveis'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => ProfileScreen(username: widget.email)),
            );
          },
        ),
      ),
      body: Column(
        children: [
          // Campo de busca
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar lojas...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            searchQuery = '';
                            _searchController.clear();
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
              ),
              onChanged: (value) {
                setState(() {
                  searchQuery = value.toLowerCase();
                });
              },
            ),
          ),
          Expanded(
            child: _buildDistribuidoresGrid(),
          ),
        ],
      ),
    );
  }

  // Função que constrói o grid dos distribuidores (lojas)
   Widget _buildDistribuidoresGrid() {
    final double screenWidth = MediaQuery.of(context).size.width;
    const double itemWidth = 150.0;
    final int crossAxisCount = screenWidth ~/ itemWidth;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('distribuidores')
          .where('pagamento_em_dia', isEqualTo: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator(color: Color.fromARGB(255, 236, 63, 121)));
        }

        var distribuidores = snapshot.data!.docs;
        return FutureBuilder<List<Map<String, dynamic>>>(
          future: _calculateDistanceForDistribuidores(distribuidores),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator(color: Color.fromARGB(255, 236, 63, 121)));
            }
            var distribuidoresFiltrados = snapshot.data!.where((distribuidor) {
              return distribuidor['razaoSocial'].toLowerCase().contains(searchQuery);
            }).toList();

            distribuidoresFiltrados.sort((a, b) => a['distanceText'].compareTo(b['distanceText']));

            if (distribuidoresFiltrados.isEmpty) {
              return const Center(child: Text('Nenhuma loja encontrada.'));
            }

            return GridView.builder(
              padding: const EdgeInsets.all(8.0),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 10.0,
                mainAxisSpacing: 10.0,
                childAspectRatio: 0.8,
              ),
              itemCount: distribuidoresFiltrados.length,
              itemBuilder: (context, index) {
                var distribuidor = distribuidoresFiltrados[index];
                return _buildDistributorCard(distribuidor);
              },
            );
          },
        );
      },
    );
  }

  Future<List<Map<String, dynamic>>> _calculateDistanceForDistribuidores(List<QueryDocumentSnapshot> distribuidores) async {
    String apiKey = '';
    if (Theme.of(context).platform == TargetPlatform.android)
      apiKey = dotenv.env['API_KEY_GEO_ANDROID']!;
    else if (Theme.of(context).platform == TargetPlatform.iOS)
      apiKey = dotenv.env['API_KEY_GEO_IOS']!;
    List<Map<String, dynamic>> result = [];

    for (var distribuidor in distribuidores) {
      final url = 'https://maps.googleapis.com/maps/api/directions/json?origin=${widget.userPosition.latitude},${widget.userPosition.longitude}&destination=${distribuidor['latitude']},${distribuidor['longitude']}&key=$apiKey&mode=driving';
      final response = await http.get(Uri.parse(url));
      final data = jsonDecode(response.body);

      if (data['status'] == 'OK') {
        var legs = data['routes'][0]['legs'][0];
        result.add({
          'distribuidorId': distribuidor.id,
          'razaoSocial': distribuidor['razao_social'],
          'distanceText': legs['distance']['text'].replaceAll(',', ''),
          'latitude': distribuidor['latitude'],
          'longitude': distribuidor['longitude'],
        });
      }
    }
    return result;
  }

  Widget _buildDistributorCard(Map<String, dynamic> distribuidor) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProdutosDistribuidores(
              distribuidorId: distribuidor['distribuidorId'],
              distribuidorNome: distribuidor['razaoSocial'],
              emailProfissional: widget.email,
              posicao: widget.userPosition,
            ),
          ),
        );
      },
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(10),
                  topRight: Radius.circular(10),
                ),
                child: FutureBuilder<String>(
                  future: _getDistributorPhotoUrl(distribuidor['distribuidorId']),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(color: Color.fromARGB(255, 236, 63, 121)),
                      );
                    } else if (snapshot.hasError || !snapshot.hasData) {
                      return Image.network('https://via.placeholder.com/150', fit: BoxFit.cover);
                    } else {
                      return Image.network(
                        snapshot.data!,
                        fit: BoxFit.cover,
                    );
                  }
                },
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  distribuidor['razaoSocial'],
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                const Row(
                  children: [
                    Icon(Icons.star, color: Colors.yellow, size: 16),
                    Icon(Icons.star, color: Colors.yellow, size: 16),
                    Icon(Icons.star, color: Colors.yellow, size: 16),
                    Icon(Icons.star, color: Colors.yellow, size: 16),
                    Icon(Icons.star, color: Colors.yellow, size: 16),
                    Text(' (5)'),
                  ],
                ),
                Text('Distância: ${distribuidor['distanceText']}'),
                const SizedBox(height: 4),

                // Verificação se a distância é menor ou igual a 30 km
                if (_isFreteGratis(distribuidor['distanceText']))
                  const Text(
                    'Frete Grátis',
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
          )
        ],
      ),
    ),
  );
}

bool _isFreteGratis(String distanceText) {
  String standardizedDistance = distanceText.replaceAll(',', '').replaceAll(' ', '');
  double distanceInKm = double.tryParse(standardizedDistance.split('km')[0]) ?? 0.0;

  return distanceInKm <= 30.0;
}

  // Função para buscar a URL da foto do distribuidor no Firebase Storage
  Future<String> _getDistributorPhotoUrl(String distribuidorId) async {
    try {
      final ref = FirebaseStorage.instance.ref().child('distribuidores/$distribuidorId/foto-perfil.jpg');
      String url = await ref.getDownloadURL();
      return url;
    } catch (e) {
      return 'https://via.placeholder.com/150'; // Placeholder se não encontrar a imagem
    }
  }
}

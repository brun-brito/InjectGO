// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geolocator/geolocator.dart' as geo;
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

        // Lista que armazenará distribuidores e suas distâncias
        List<Map<String, dynamic>> distribuidoresComDistancia = [];

        // Calcula a distância entre o profissional e cada distribuidor
        for (var distribuidor in distribuidores) {
          String distribuidorId = distribuidor.id;
          String razaoSocial = distribuidor['razao_social'];
          double distribuidorLatitude = distribuidor['latitude'];
          double distribuidorLongitude = distribuidor['longitude'];

          // Calcula a distância entre o profissional e o distribuidor
          double distanceInMeters = geo.Geolocator.distanceBetween(
            widget.userPosition.latitude,
            widget.userPosition.longitude,
            distribuidorLatitude,
            distribuidorLongitude,
          );

          double distanceInKm = distanceInMeters / 1000;

          // Adiciona o distribuidor e a distância calculada à lista
          distribuidoresComDistancia.add({
            'distribuidorId': distribuidorId,
            'razaoSocial': razaoSocial,
            'distanceInKm': distanceInKm,
            'latitude': distribuidorLatitude,
            'longitude': distribuidorLongitude,
          });
        }

        // Filtra a lista de distribuidores com base no campo de busca
        var distribuidoresFiltrados = distribuidoresComDistancia.where((distribuidor) {
          String razaoSocial = distribuidor['razaoSocial'].toLowerCase();
          return razaoSocial.contains(searchQuery);
        }).toList();

        // Ordena a lista de distribuidores pela distância (mais perto primeiro)
        distribuidoresFiltrados.sort((a, b) => a['distanceInKm'].compareTo(b['distanceInKm']));

        if (distribuidoresFiltrados.isEmpty) {
          return const Center(child: Text('Nenhuma loja encontrada.'));
        }

        return GridView.builder(
          padding: const EdgeInsets.all(8.0),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 10.0,
            mainAxisSpacing: 10.0,
            childAspectRatio: 0.8, // Define a proporção dos cards
          ),
          itemCount: distribuidoresFiltrados.length,
          itemBuilder: (context, index) {
            var distribuidor = distribuidoresFiltrados[index];
            String distribuidorId = distribuidor['distribuidorId'];
            String razaoSocial = distribuidor['razaoSocial'];
            double distanceInKm = distribuidor['distanceInKm'];

            return FutureBuilder<String>(
              future: _getDistributorPhotoUrl(distribuidorId),
              builder: (context, photoSnapshot) {
                if (!photoSnapshot.hasData) {
                  return const Center(child: CircularProgressIndicator(color: Color.fromARGB(255, 236, 63, 121)));
                }

                return GestureDetector(
                  onTap: () {
                    // Ao clicar em uma loja, navega para a página de produtos do distribuidor
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProdutosDistribuidores(
                          distribuidorId: distribuidorId,
                          distribuidorNome: razaoSocial,
                          emailProfissional: widget.email,
                          posicao: widget.userPosition
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
                            child: Image.network(
                              photoSnapshot.data!,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                razaoSocial,
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
                              const SizedBox(height: 4),
                              Text('Distância: ${distanceInKm.toStringAsFixed(2)} km'),
                              const Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16), // Seta de indicação
                                ],
                              ),
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
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

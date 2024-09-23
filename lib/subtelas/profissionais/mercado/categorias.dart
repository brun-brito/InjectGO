// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:inject_go/subtelas/profissionais/mercado/pesquisa_produtos.dart';

class CategoriasScreen extends StatelessWidget {
  final String emailProfissional;
  final Position userPosition;

  const CategoriasScreen({
    super.key,
    required this.emailProfissional,
    required this.userPosition,
  });

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    const double itemWidth = 150.0;
    final int crossAxisCount = screenWidth ~/ itemWidth;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Categorias'),
        centerTitle: true,
      ),
      body: GridView(
        padding: const EdgeInsets.all(10),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          childAspectRatio: 0.75,
          crossAxisSpacing: 10.0,
          mainAxisSpacing: 10.0,
        ),
        children: [
          _buildCategoryCard(
            context,
            'Bioestimuladores',
            'assets/images/bioestimuladores.jpg', // Imagem de exemplo
            'Bioestimulador',
          ),
          _buildCategoryCard(
            context,
            'Toxinas',
            'assets/images/toxinas.jpg', // Imagem de exemplo
            'Toxina',
          ),
          _buildCategoryCard(
            context,
            'Fios PDO',
            'assets/images/fios-pdo.jpg', // Imagem de exemplo
            'Fio',
          ),
          _buildCategoryCard(
            context,
            'Preenchedores',
            'assets/images/preenchedores.jpg', // Imagem de exemplo
            'Preenchedor',
          ),
          // _buildCategoryCard(
          //   context,
          //   'Ácido Hialurônico',
          //   'assets/images/acido-hialuronico.jpg', // Imagem de exemplo
          //   'Acido',
          // ),
        ],
      ),
    );
  }

  // Função que cria os cards de categorias
  Widget _buildCategoryCard(BuildContext context, String title, String imagePath, String categoria) {
    return GestureDetector(
      onTap: () {
        // Redireciona para a tela de pesquisa com a categoria filtrada
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PesquisaProdutosScreen(
              emailProfissional: emailProfissional,
              posicao: userPosition,
              categoriaFiltrada: categoria, // Passa a categoria selecionada
            ),
          ),
        );
      },
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Image.asset(
                imagePath,
                fit: BoxFit.cover,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

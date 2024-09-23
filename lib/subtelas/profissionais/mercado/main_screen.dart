// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:inject_go/subtelas/profissionais/mercado/categorias.dart';
import 'package:inject_go/subtelas/profissionais/mercado/lojas_disponiveis.dart';
import 'package:inject_go/subtelas/profissionais/mercado/pesquisa_produtos.dart';
import 'package:inject_go/subtelas/profissionais/mercado/minhas_compras.dart';

class MainScreen extends StatefulWidget {
  final Position userPosition; // Coordenadas do usuário atual
  final String email;
  final int? initialIndex;

  const MainScreen({super.key, required this.userPosition, required this.email, this.initialIndex});

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late int _selectedIndex;
  late List<Widget> _widgetOptions;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex ?? 0;

    // Inicializa os widgets das telas
    _widgetOptions = <Widget>[
      MercadoScreen(userPosition: widget.userPosition, email: widget.email), // "Início"
      PesquisaProdutosScreen(emailProfissional: widget.email, posicao: widget.userPosition), // "Pesquisar Produtos"
      CategoriasScreen(emailProfissional: widget.email, userPosition: widget.userPosition), // "Categorias"
      MinhasComprasScreen(userEmail: widget.email), // "Meus Pedidos"
    ];
  }

  // Função para alterar a aba selecionada
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex, // Exibe a tela correspondente ao índice selecionado
        children: _widgetOptions, // A lista de telas
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed, // Para forçar a exibição dos quatro botões
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.store),
            label: 'Início',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Pesquisar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.category),
            label: 'Categorias',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: 'Meus Pedidos',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.pink,
        onTap: _onItemTapped, // Chama a função quando uma aba é selecionada
      ),
    );
  }
}
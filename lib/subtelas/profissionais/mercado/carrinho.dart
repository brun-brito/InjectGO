// ignore_for_file: library_private_types_in_public_api, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:inject_go/subtelas/profissionais/mercado/formulario_endereco.dart';

class CarrinhoScreen extends StatefulWidget {
  final List<DocumentSnapshot> cartProducts;
  final String email;
  final Position posicao;

  const CarrinhoScreen({super.key, required this.cartProducts, required this.email, required this.posicao,});

  @override
  _CarrinhoScreenState createState() => _CarrinhoScreenState();
}

class _CarrinhoScreenState extends State<CarrinhoScreen> {
  final Map<DocumentSnapshot, int> _productQuantities = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Inicializa as quantidades com 1 para cada produto no carrinho
    for (var product in widget.cartProducts) {
      _productQuantities[product] = 1; // Inicialmente, todos com quantidade 1
    }
  }

  // Função que calcula o valor total do carrinho
  double _calcularTotalCarrinho() {
    double total = 0.0;
    for (var product in widget.cartProducts) {
      int quantity = _productQuantities[product] ?? 1;
      double price = (product['price'] as num).toDouble();

      total += price * quantity;
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Carrinho'),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Mensagem no topo
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Obrigado por escolher a InjectGO!',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 10),
                Text(
                  'Abaixo estão os itens do seu carrinho. Por favor, defina as quantidades desejada para os produtos selecionados, e siga para a próxima tela.',
                  style: TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
          // Verificação se o carrinho está vazio
          widget.cartProducts.isEmpty
              ? const Center(
                  child: Text(
                    'Seu carrinho está vazio!',
                    style: TextStyle(fontSize: 18),
                  ),
                )
              : Expanded(
                  child: ListView.builder(
                    itemCount: widget.cartProducts.length,
                    itemBuilder: (context, index) {
                      var product = widget.cartProducts[index];
                      int quantity = _productQuantities[product] ?? 1;

                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        child: ListTile(
                          leading: Image.network(
                            product['imageUrl'],
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                          ),
                          title: Text(
                            product['name'],
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('R\$ ${product['price'].toStringAsFixed(2)}'),
                              const SizedBox(height: 5),
                              Row(
                                children: [
                                  IconButton(
                                    icon: Icon(Icons.remove_circle_outline, color: (quantity > 1) ? Colors.red : Colors.grey),
                                    onPressed: () {
                                      setState(() {
                                        if (quantity > 1) {
                                          _productQuantities[product] = quantity - 1;
                                        }
                                      });
                                    },
                                  ),
                                  Text('$quantity', style: const TextStyle(fontSize: 16)),
                                  IconButton(
                                    icon: const Icon(Icons.add_circle_outline, color: Colors.green),
                                    onPressed: () {
                                      setState(() {
                                        _productQuantities[product] = quantity + 1;
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () {
                              setState(() {
                                widget.cartProducts.removeAt(index);
                                _productQuantities.remove(product);
                              });
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
          // Exibir o total do carrinho
          widget.cartProducts.isNotEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Subtotal:',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'R\$ ${_calcularTotalCarrinho().toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green),
                      ),
                    ],
                  ),
                )
              : const SizedBox.shrink(),
        ],
      ),
      bottomNavigationBar: widget.cartProducts.isNotEmpty
          ? Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                onPressed: _isLoading
                    ? null
                    : () async {
                        setState(() {
                          _isLoading = true; // Inicia o loading
                        });
                        try {
                          await _verificarDisponibilidade();
                        } catch (e) {
                          setState(() {
                            _isLoading = false;
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  'Erro ao processar compra. Por favor, tente novamente mais tarde, ou entre em contato conosco.'),
                            ),
                          );
                        } finally {
                          setState(() {
                            _isLoading = false;
                          });
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pink,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(
                        color: Colors.white,
                      )
                    : const Text(
                        'Avançar',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
              ),
            )
          : null,
    );
  }

  Future<void> _verificarDisponibilidade() async {
    bool todosProdutosDisponiveis = true;
    for (var product in widget.cartProducts) {
      var quantidadeRequisitada = _productQuantities[product] ?? 1;

      // Buscar a quantidade disponível do produto no Firebase
      DocumentSnapshot produtoFirebase = await FirebaseFirestore.instance
          .collection('distribuidores')
          .doc(product.reference.parent.parent!.id)
          .collection('produtos')
          .doc(product.id)
          .get();

      int quantidadeDisponivel = produtoFirebase['quantidade_disponivel'];
      bool disponivel = produtoFirebase['disponivel'];

      // Se o produto ficou indisponível durante o processo
      if (!disponivel || quantidadeDisponivel <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('O produto não está mais disponível.'),
          ),
        );
        return;
      }

      // Verifica se a quantidade disponível é suficiente
      if (quantidadeRequisitada > quantidadeDisponivel) {
        todosProdutosDisponiveis = false;

        // Exibir o diálogo informando a quantidade disponível
        _mostrarDialogoQuantidadeInsuficiente(
            product, quantidadeDisponivel, quantidadeRequisitada);
        break; // Para ao encontrar o primeiro produto com problema
      }
    }

    if (todosProdutosDisponiveis) {
      // Se todos os produtos têm quantidade suficiente, prosseguir para a próxima tela
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AddressFormScreen(
            cartProducts: widget.cartProducts,
            email: widget.email,
            posicao: widget.posicao,
            productQuantities: _productQuantities, // Passar as quantidades para a próxima tela
                    ),
        ),
      );
    }
  }

  void _mostrarDialogoQuantidadeInsuficiente(DocumentSnapshot product, int quantidadeDisponivel, int quantidadeRequisitada) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Quantidade Indisponível'),
          content: Text(
            'O produto "${product['name']}" possui apenas $quantidadeDisponivel unidade(s) disponível(is). '
            'Você requisitou $quantidadeRequisitada. Por favor, escolha uma quantidade entre 1 e $quantidadeDisponivel.',
          ),
          actions: [
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                // Ajustar a quantidade para o máximo disponível
                setState(() {
                  _productQuantities[product] = quantidadeDisponivel;
                });
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}

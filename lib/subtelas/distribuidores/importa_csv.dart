// ignore_for_file: library_private_types_in_public_api, use_build_context_synchronously

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:csv/csv.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:inject_go/formatadores/formata_string.dart';
import 'package:http/http.dart' as http;
import 'package:inject_go/subtelas/distribuidores/meus_produtos.dart';

class ImportCSVScreen extends StatefulWidget {
  final String username;
  final String doc;

  const ImportCSVScreen({super.key, required this.username, required this.doc});

  @override
  _ImportCSVScreenState createState() => _ImportCSVScreenState();
}
class _ImportCSVScreenState extends State<ImportCSVScreen> {
  String? _selectedFilePath;
  List<List<dynamic>> _csvData = [];
  bool _isLoading = false;

  // URL padrão da imagem, já armazenada no Firebase Storage
  final String defaultImageUrl = dotenv.env['PATH_IMAGE_DEFAULT'] ?? '';

  Future<void> _selectFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _selectedFilePath = result.files.single.path;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Arquivo '${_selectedFilePath!.split('/').last}' foi anexado.")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nenhum arquivo foi selecionado ou arquivo inválido.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao selecionar arquivo: $e')),
      );
    }
  }

  Future<bool> validarImagemUrl(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      return response.statusCode == 200;  // Retorna true se a URL for válida
    } catch (e) {
      return false;   // Retorna false se houver erro
    }
  }

  Future<void> _importFile() async {
    if (_selectedFilePath != null) {
      setState(() {
        _isLoading = true;
      });

      try {
        final file = File(_selectedFilePath!);
        String content;

        try {
          // Tentar ler o arquivo como UTF-8
          content = await file.readAsString(encoding: utf8);
        } catch (e) {
          // Se falhar, tenta com latin1
          content = await file.readAsString(encoding: latin1);
        }

        // Converte o conteúdo CSV usando o delimitador ';'
        List<List<dynamic>> csvTable = const CsvToListConverter(fieldDelimiter: ';').convert(content);
        setState(() {
          _csvData = csvTable;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Arquivo CSV importado com sucesso! Iniciando cadastro...')),
        );

        await _cadastrarProdutos();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao importar arquivo: $e')),
        );
      }

      setState(() {
        _isLoading = false;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, selecione um arquivo CSV primeiro.')),
      );
    }
  }

  Future<void> _cadastrarProdutos() async {
    List<String> produtosComErro = [];
    List<String> produtosCadastradosIds = [];
    int totalProdutos = _csvData.length - 1;
    int produtosCadastrados = 0;
    bool temErro = false;
    bool cancelarProcesso = false;
    StreamController<double> progressStream = StreamController<double>();

    // Exibir o diálogo com a barra de progresso e opção de cancelar
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Cadastrando Produtos'),
          content: StreamBuilder<double>(
            stream: progressStream.stream,
            builder: (context, snapshot) {
              double progress = snapshot.data ?? 0;
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Produtos cadastrados: $produtosCadastrados / $totalProdutos'),
                  const SizedBox(height: 20),
                  LinearProgressIndicator(
                    value: progress,
                    color: const Color.fromARGB(255, 236, 63, 121),
                    backgroundColor: Colors.grey[300],
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                cancelarProcesso = true;
              },
              child: const Text('Cancelar', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    try {
      for (var i = 1; i < _csvData.length && !cancelarProcesso; i++) {
        final row = _csvData[i];

        // Verificar se todos os campos necessários estão preenchidos
        if (row.length < 11 || row.any((campo) => campo == null || campo.toString().trim().isEmpty)) {
          temErro = true;
          produtosComErro.add("Linha com dados insuficientes na posição $i: $row");
          continue; // Pular para a próxima linha sem tentar cadastrar este produto
        }

        final productName = row[0].toString();
        final productDescription = row[1].toString();
        final productBrand = row[2].toString();
        final productCategory = row[3].toString();
        final productPrice = double.tryParse(row[4].toString().replaceAll(',', '.'));
        final String imageUrl = row[5].toString();
        final int quantidadeDisponivel = int.tryParse(row[6].toString()) ?? 1;  // Captura a quantidade disponível
        final int productLength = int.tryParse(row[7].toString()) ?? 0;  // Comprimento
        final int productWidth = int.tryParse(row[8].toString()) ?? 0;   // Largura
        final int productHeight = int.tryParse(row[9].toString()) ?? 0;  // Altura
        final double productWeight = double.tryParse(row[10].toString()) ?? 0.0; // Peso

        // Verifica se o preço é válido
        if (productPrice == null || productPrice <= 0) {
          temErro = true;
          produtosComErro.add("Preço inválido na posição $i: $row");
          continue; // Pular esta linha se o preço for inválido
        }

        // Verificar se a URL da imagem é válida
        bool imagemValida = await validarImagemUrl(imageUrl);
        String finalImageUrl = imagemValida ? imageUrl : defaultImageUrl;

        // Pegar dados do distribuidor
        var distribuidorSnapshot = await FirebaseFirestore.instance
            .collection('distribuidores')
            .where('email', isEqualTo: widget.username)
            .limit(1)
            .get();

        if (distribuidorSnapshot.docs.isNotEmpty) {
          var distribuidorData = distribuidorSnapshot.docs.first.data();
          String razaoSocialCnpj = '${distribuidorData['razao_social']} - ${distribuidorData['cnpj']}';
          String productId = FirebaseFirestore.instance.collection('distribuidores/$razaoSocialCnpj/produtos').doc().id;

          // Realizar cadastro do produto
          try {
            await FirebaseFirestore.instance.collection('distribuidores/$razaoSocialCnpj/produtos').doc(productId).set({
              'id': productId,
              'name': primeiraMaiuscula(productName.trim()),  // Formata o nome para começar com letra maiúscula
              'description': productDescription,
              'marca': primeiraMaiuscula(productBrand.trim()),  // Formata a marca para começar com letra maiúscula
              'categoria': primeiraMaiuscula(productCategory.trim()),  // Formata a categoria para começar com letra maiúscula
              'price': productPrice,
              'imageUrl': finalImageUrl,
              'username': widget.username,
              'createdAt': Timestamp.now(),
              'quantidade_disponivel': quantidadeDisponivel,
              'comprimento': productLength,  // Novo campo comprimento
              'largura': productWidth,       // Novo campo largura
              'altura': productHeight,       // Novo campo altura
              'peso': productWeight,         // Novo campo peso
              'disponivel': quantidadeDisponivel > 0,  // Define se o produto está disponível baseado na quantidade
            });

            // Adiciona o ID do produto para possível exclusão posterior
            produtosCadastradosIds.add(productId);

            // Atualizar o progresso
            produtosCadastrados++;
            double progress = produtosCadastrados / totalProdutos;
            progressStream.add(progress);

            // Delay para permitir que a UI seja atualizada entre as iterações
            await Future.delayed(const Duration(milliseconds: 100));
          } catch (e) {
            temErro = true;
            produtosComErro.add("Erro ao cadastrar o produto na posição $i: $e");
            continue; // Continuar mesmo com erro no cadastro
          }
        } else {
          temErro = true;
          produtosComErro.add("Distribuidor não encontrado na posição $i");
        }
      }

      // Mostrar resultado final com base em sucesso ou erro
      if (temErro && produtosCadastrados > 0) {
        await _mostrarDialogParcial(produtosComErro); // Produtos parcialmente cadastrados
      } else if (produtosComErro.isNotEmpty) {
        await _mostrarDialogErro(produtosComErro); // Todos os produtos com erro
      } else if (!temErro && !cancelarProcesso) {
        await _mostrarDialogSucesso(); // Todos os produtos cadastrados com sucesso
      }
    } catch (e) {
      await _mostrarDialogErro(["Erro geral ao cadastrar produtos: $e"]); // Erro geral
    } finally {
      Navigator.of(context).pop();
      progressStream.close();

      if (cancelarProcesso) {
        // Excluir os produtos já cadastrados em caso de cancelamento
        for (String productId in produtosCadastradosIds) {
          await FirebaseFirestore.instance.collection('distribuidores/${widget.doc}/produtos').doc(productId).delete();
        }

        await _mostrarDialogCancelado();   
      }
    }
  }

  Future<void> _mostrarDialogParcial(List<String> produtosComErro) async {
    await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Row(
                children: [
                  Icon(
                    Icons.warning,
                    color: Colors.orange,
                    size: 40,
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text('Processo parcialmente\n concluído...',
                      style: TextStyle(fontSize: 18),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              content: const Text(
                "Alguns produtos foram cadastrados com sucesso, mas houveram erros em alguns itens.",
                style: TextStyle(fontSize: 16),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    // Mostra os erros ao clicar no botão "Ver Erros"
                    _mostrarDialogErro(produtosComErro);
                  },
                  child: const Text('Ver Erros', style: TextStyle(color: Colors.red)),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => MyProductsScreen(username: widget.username)));
                  },
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
  }

  Future<void> _mostrarDialogErro(List<String> erros) async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.error, color: Colors.red, size: 40),
              SizedBox(width: 10),
              Expanded(
                child: Text('Erros no Processo'),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: erros.map((erro) {
                // Separar o texto da posição e os dados da linha
                final erroParts = erro.split(': ');

                return RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: '${erroParts[0]}: ', // Exibe a mensagem de erro
                        style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                      ),
                      TextSpan(
                        text: erroParts.length > 1 ? erroParts[1] : '', // Exibe os dados da linha em preto
                        style: const TextStyle(color: Colors.black),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Fecha o diálogo de erros
              },
              child: const Text('Fechar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _mostrarDialogSucesso() async {
    await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 40,
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text('Processo concluído!',
                      style: TextStyle(fontSize: 18),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              content: const Text(
                "Todos os produtos foram cadastrados com sucesso!",
                style: TextStyle(fontSize: 16),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => MyProductsScreen(username: widget.username)));
                  },
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
  }

  Future<void> _mostrarDialogCancelado() async{
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.error, color: Colors.red, size: 40),
                SizedBox(width: 10),
                Expanded(
                  child: Text('Processo cancelado'),
                ),
              ],
            ),
            content: const Text('O processo foi cancelado com sucesso e os dados inseridos foram excluídos.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Fecha o aviso de cancelamento
                },
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Importar CSV'),
        elevation: 0,
        centerTitle: true,
      ),
      body: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: const BoxDecoration(
          color: Colors.white
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Importar Arquivo CSV',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color.fromARGB(255, 123, 31, 162), // Cor roxa escura
                ),
              ),
              const SizedBox(height: 20),
              if (_selectedFilePath != null)
                Text(
                  'Arquivo selecionado: ${_selectedFilePath!.split('/').last}',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color.fromARGB(255, 76, 175, 80), // Cor verde
                    fontStyle: FontStyle.italic,
                  ),
                )
              else
                const Text(
                  'Nenhum arquivo selecionado.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Color.fromARGB(255, 183, 28, 28), // Cor vermelha
                  ),
                ),
              const SizedBox(height: 30),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 236, 63, 121), // Cor do botão
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30), // Botão arredondado
                  ),
                ),
                onPressed: _selectFile,
                icon: const Icon(Icons.file_upload),
                label: const Text(
                  'Selecionar arquivo CSV',
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: (_selectedFilePath == null || !_selectedFilePath!.endsWith('.csv') || _isLoading)
                      ? Colors.grey // Desativa se não estiver pronto
                      : const Color.fromARGB(255, 236, 63, 121),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                onPressed: (_selectedFilePath == null || !_selectedFilePath!.endsWith('.csv') || _isLoading)
                    ? null 
                    : _importFile,
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Color.fromARGB(255, 255, 255, 255)),
                          strokeWidth: 2.0,
                        ),
                      )
                    : const Icon(Icons.upload),
                label: _isLoading
                    ? const Text('Importando...')
                    : const Text('Importar e cadastrar produtos', style: TextStyle(fontSize: 16, color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }

}

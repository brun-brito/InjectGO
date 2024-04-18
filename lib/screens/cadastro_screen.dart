// ignore_for_file: library_private_types_in_public_api, curly_braces_in_flow_control_structures
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'login_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:intl/intl.dart'; 
import 'package:http/http.dart' as http;
import 'dart:convert';


void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: SignUpScreen(),
    );
  }
}

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _councilNumberController = TextEditingController();
  final TextEditingController _cpfController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _municipioController = TextEditingController();
  final TextEditingController _imageController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final picker = ImagePicker();
  final ImagePicker _picker = ImagePicker(); 
  String dateFormatted = DateFormat('dd-MM-yyyy').format(DateTime.now());
  String token = 'pxXxdW4xqw12EMWEEtMMNq8V8_0EJ3E46mD_TT78';
  String? _selectedProfession;
  String? _selectedState;
  String? _selectedCategory;
  String? _senha;
  XFile? _selfie;
  XFile? _image;
  bool _isLoading = false;
  bool _isLoadingLupa = false;
  bool _mostrarCamposFarmaceutico = false;
  Color _statusColor =Colors.black;
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Tela de Cadastro'),
      ),
            body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            TextFormField(
              decoration: InputDecoration(
                labelText: 'Anexe uma foto da sua carteirinha*',
                suffixIcon: IconButton(
                  icon: Icon(Icons.file_upload),
                  onPressed: () async {
                    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
                    setState(() {
                      _image = pickedFile;
                    });
                    _imageController.clear();
                  },
                ),
              ),
              readOnly: true,
              validator: (value) => _image == null ? 'Por favor, anexe uma foto de sua carteirinha' : null,
            ),
            if (_image != null)
              Stack(
                alignment: Alignment.topRight,
                children: [
                  Container(
                    height: 200,
                    child: Image.file(File(_image!.path)),
                  ),
                  IconButton(
                    icon: Icon(Icons.cancel),
                    color: Colors.red,
                    onPressed: () {
                      setState(() {
                        _image = null;
                      });
                    },
                  ),
                ],
              ),

            TextFormField(
              controller: _imageController,
              decoration: InputDecoration(
                labelText: 'Selfie segurando a carteirinha*',
                suffixIcon: IconButton(
                  icon: Icon(Icons.camera_alt),
                  onPressed: _takeSelfie,
                ),
              ),
              readOnly: true,
              validator: (value) => _selfie == null ? 'Por favor, anexe uma selfie segurando a carteirinha' : null,
            ),
            if (_selfie != null)
              Stack(
                alignment: Alignment.topRight,
                children: [
                  Container(
                    height: 200,
                    child: Image.file(File(_selfie!.path)),
                  ),
                  IconButton(
                    icon: Icon(Icons.cancel),
                    color: Colors.red,
                    onPressed: () {
                      setState(() {
                        _selfie = null;
                      });
                    },
                  ),
                ],
              ),

            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Primeiro nome*'),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z]')),
                FilteringTextInputFormatter.singleLineFormatter, 
              ],
              validator: (value) {
                if (value == null || value.trim().isEmpty) { // Garante que espaços em branco não sejam considerados como nome válido
                  return 'Por favor, preencha seu nome';
                }
                return null;
              },
            ),

            TextFormField(
              controller: _lastNameController,
              decoration: const InputDecoration(labelText: 'Sobrenome*'),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z-\s]')),
              ],
              validator: (value) {
                if (value == null || value.trim().isEmpty) { // Garante que espaços em branco não sejam considerados como nome válido
                  return 'Por favor, preencha seu sobrenome';
                }
                return null;
              },
            ),
            
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Profissão*'),
              value: _selectedProfession,
              items: <String>['Dentista', 'Biomédico', 'Farmacêutico', 'Enfermeiro', 'Fisioterapeuta']
                  .map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedProfession = newValue;
                  _mostrarCamposFarmaceutico = newValue == 'Farmacêutico';  // muda pra true se for farmaceutico
                });
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor, selecione sua profissão';
                }
                return null;
              },
            ),
            if (_mostrarCamposFarmaceutico) ...[
              TextFormField(
                controller: _municipioController,
                decoration: const InputDecoration(
                  labelText: 'Município*',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) { 
                    return 'Por favor, preencha seu município';
                  }
                  return null;
                },
              ),

              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Categoria*'),
                value: _selectedCategory,
                items: <String>['farmaceutico', 'tecnico']
                    .map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedCategory = newValue;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, selecione sua categoria';
                  }
                  return null;
                },
              ),
            ],

            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Estado do Conselho*'),
              value: _selectedState,
              items: <String>[
                'AC', 'AL', 'AP', 'AM', 'BA', 'CE', 'DF', 'ES', 'GO',
                'MA', 'MT', 'MS', 'MG', 'PA', 'PB', 'PR', 'PE', 'PI',
                'RJ', 'RN', 'RS', 'RO', 'RR', 'SC', 'SP', 'SE', 'TO'
              ].map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (newValue) {
                setState(() {
                  _selectedState = newValue;
                });
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor, selecione o estado do seu conselho';
                }
                return null;
              },
            ),

            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _councilNumberController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Número de conselho*',
                    ),
                    style: TextStyle(
                      color: _statusColor,  // Cor do texto baseado no estado
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor, preencha seu número de conselho';
                      }
                      return null;
                    },
                  ),
                ),
                IconButton(
                  icon: _isLoadingLupa 
                    ? const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.blue)) 
                    : const Icon(Icons.search),
                  onPressed: _isLoadingLupa ? null : () async {
                    var funcao;
                    if (_selectedProfession == 'Dentista')
                      funcao = existeCRO();
                    if (_selectedProfession == 'Biomédico') 
                      funcao = existeCFBM();                    
                    if (_selectedProfession == 'Farmacêutico') 
                      funcao = existeCFF();                    
                    setState(() => _isLoadingLupa = true);
                    try {
                      if(await funcao){
                        setState(() => _statusColor = Colors.green);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Número de conselho validado!")));
                      }
                      else{
                        setState(() => _statusColor = Colors.red);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Dados não correspondem ao número de conselho.")));
                      }
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                         SnackBar(content: Text("Erro inesperado.: ${e.toString()}"))
                  );
                    } finally {
                      setState(() => _isLoadingLupa = false);
                    }
                  },
                ),
              ],
            ),


            TextFormField(
              controller: _cpfController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'CPF (apenas números)*'),
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly, 
                LengthLimitingTextInputFormatter(11), 
              ],
              validator: (value) {
                if (value == null || value.isEmpty || !isValidCPF(value)) {
                  return 'Por favor, preencha um CPF válido';
                }
                return null;
              },
            ),

            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Telefone (apenas números)*',
                hintText: '85999999999'
              ),
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(11),
              ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, preencha seu telefone';
                  }
                  else if (value.length != 11) {
                    return 'Por favor, preencha um telefone válido';
                  }
                  return null;
                },
            ),

            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'E-mail*',
                prefixIcon: Tooltip(
                  message: 'Pode ser o mesmo da última tela',
                  child: Icon(Icons.info_outline),
                ),
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9-.-@]')),
                FilteringTextInputFormatter.singleLineFormatter,
              ],
              validator: (value) {
                if (value == null || value.isEmpty || !value.contains('@') || !value.contains('.')) {
                  return 'Por favor, preencha seu e-mail corretamente';
                }

                return null;
              },
            ),

            TextFormField(
              controller: _usernameController,
              decoration: const InputDecoration(labelText: 'Crie um usuário*'),
              inputFormatters: [
                FilteringTextInputFormatter.singleLineFormatter, 
                FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9\s\!\@\#\$\%\^\&\*\(\)\-\=\+\[\]\{\}\;\:\",<>\.\/\?\|\\_`~]')),
                LengthLimitingTextInputFormatter(15),
              ],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor, preencha seu usuário';
                }

                return null;
              },
            ),

            TextFormField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Senha*'),
              obscureText: true, 
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor, preencha sua senha';
                }                
                else if (value.length < 6 ) {
                  return 'A senha deve ter ao menos 6 caracteres';
                }
                _senha = value; 
                return null;
              },
            ),

            TextFormField(
              decoration: const InputDecoration(labelText: 'Repetir senha*'),
              obscureText: true,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor, repita sua senha';
                }
                if (value != _senha) {
                  return 'As senhas não coincidem';
                }
                return null;
              },
            ),
              
            const SizedBox(height: 8.0),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.pink,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                if (_formKey.currentState!.validate() && _statusColor == Colors.green) {
                  setState(() {
                    _isLoading = true; // Inicia o carregamento
                  });
                  try {
                    await addUserWithFirebase({});
                    await cadastrarAuth(_emailController.text, _passwordController.text);
                    await uploadCarteira();
                    await uploadSelfie();
                    mensagemSucesso();
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Falha ao registrar: ${e.toString()}"))
                    );
                  } finally {
                    setState(() {
                      _isLoading = false; // Termina o carregamento
                    });
                  }
                }
                else if (!_formKey.currentState!.validate() && (_statusColor == Colors.red || _statusColor == Colors.black)){
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Insira um número de conselho válido e clique na lupa para verificar!"))
                    );
                }
                else if (!_formKey.currentState!.validate() && (_selfie == null || _image == null)){
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Carregue as fotos antes de concluir o cadastro."))
                    );
                }
                else{
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Campos obrigatórios não foram preenchidos!"))
                  );  
                }
              },
              child: _isLoading
                  ? CircularProgressIndicator(color: Colors.white) // Indica carregamento
                  : const Text('Cadastrar'),
            ),


          ],
        ),
      ),
    );
  }


Future<void> addUserWithFirebase(Map<String, dynamic> userData) async {
  String nome = _nameController.text;
  String sobrenome = _lastNameController.text;
  String cpf = _cpfController.text;
  String telefone = _phoneController.text;
  String email = _emailController.text;
  String usuario = _usernameController.text;
  String conselho = _councilNumberController.text;

  // Primeiro, verifica se já existe algum usuário com os mesmos dados.
  var cpfQuery = await firestore
    .collection('users')
    .where('cpf', isEqualTo: cpf)
    .limit(1)
    .get();
  var usernameQuery = await firestore
    .collection('users')
    .where('usuario', isEqualTo: usuario)
    .limit(1)
    .get();
  var telQuery = await firestore
    .collection('users')
    .where('telefone', isEqualTo: telefone)
    .limit(1)
    .get();
  var emailQuery = await firestore
    .collection('users')
    .where('email', isEqualTo: email)
    .limit(1)
    .get();
  var conselhoQuery = await firestore
    .collection('users')
    .where('conselho', isEqualTo: conselho)
    .limit(1)
    .get();

  // Verifica se os documentos retornaram algum resultado
  if (cpfQuery.docs.isNotEmpty) {
    throw Exception("Cliente com este CPF já cadastrado.");
  }
  if (usernameQuery.docs.isNotEmpty) {
    throw Exception("Cliente com este usuário já cadastrado.");
  }
  if (telQuery.docs.isNotEmpty) {
    throw Exception("Cliente com este telefone já cadastrado.");
  }
  if (emailQuery.docs.isNotEmpty) {
    throw Exception("Cliente com este e-mail já cadastrado.");
  }
  if (conselhoQuery.docs.isNotEmpty) {
    throw Exception("Cliente com este número de conselho já cadastrado.");
  }

  // Nome completo + cpf vai ser chave
  String cliente = '$nome $sobrenome - $cpf';
  String randomId = firestore.collection('users').doc().id;

  // Define os dados que serão inseridos
  Map<String, dynamic> fullUserData = {
    'idUser': randomId,
    'nome': _nameController.text,
    'sobrenome': _lastNameController.text,
    'profissao': _selectedProfession,
    'conselho': _councilNumberController.text,
    'estadoConselho': _selectedState,
    'cpf': _cpfController.text,
    'telefone': _phoneController.text,
    'email': _emailController.text,
    'usuario': _usernameController.text,
    'senha': _passwordController.text,
  };

  // Insere os dados no Firestore
  await firestore
    .collection('users')
    .doc(cliente)
    .set(fullUserData, SetOptions(merge: false));
}

  Future<void> cadastrarAuth(String email, String password) async {
    final _firebaseAuth = FirebaseAuth.instance;
    try {
      await _firebaseAuth.createUserWithEmailAndPassword(email: email, password: password);
      } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Senha deve ter no mínimo 6 caracteres"))
        );  
      } else if (e.code == 'email-already-in-use') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Cliente com este e-mail já cadastrado."))
        );  
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message.toString()))
        );  
      }
      throw e;
    } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Um erro ocorreu: $e'))
        );  
      throw e;
    }
  }

void mensagemSucesso() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Sucesso! Você será direcionado para a página de login"),
          actions: <Widget>[
            TextButton(
              child: const Text("Ok"),
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => LoginForm()),
                  (Route<dynamic> route) => false,
                );
              },
            ),
          ],
        );
      },
    );
  }

bool isValidCPF(String cpf) {
  cpf = cpf.replaceAll(RegExp(r'\D'), '');

  if (cpf.length != 11) return false;

  if (RegExp(r'^(\d)\1*$').hasMatch(cpf)) return false;

  int calculateDigit(String cpf, int length) {
    int sum = 0;
    for (int i = 0; i < length; i++) {
      sum += int.parse(cpf[i]) * (length + 1 - i);
    }
    int digit = 11 - (sum % 11);
    return digit >= 10 ? 0 : digit;
  }

  int firstDigit = calculateDigit(cpf, 9);
  int secondDigit = calculateDigit(cpf.substring(0, 9) + firstDigit.toString(), 10);

  return cpf.substring(9) == firstDigit.toString() + secondDigit.toString();
}

Future<void> _takeSelfie() async {
  final XFile? photo = await _picker.pickImage(
    source: ImageSource.camera,
    preferredCameraDevice: CameraDevice.front
  );
  setState(() => _selfie = photo);
}

Future<void> _uploadCard() async {
  final XFile? photo = await _picker.pickImage(source: ImageSource.gallery);
  setState(() => _image = photo);
}

Future uploadSelfie() async {
  if (_selfie == null) return;
  final file = File(_selfie!.path);
  String nome = _nameController.text;
  List<String> sobrenome = _lastNameController.text.split(' ');
  String primSobrenome = sobrenome[0];

  String fileName = 'selfie-$nome-$primSobrenome-$dateFormatted.jpg'; 

  try {
    await FirebaseStorage.instance
      .ref('selfies/$fileName') 
      .putFile(file);
  } catch (e) {
      throw('Erro ao salvar selfie: $e');
  }
}

Future uploadCarteira() async {
  if (_image == null) return;
  final file = File(_image!.path);
  String nome = _nameController.text;
  List<String> sobrenome = _lastNameController.text.split(' ');
  String primSobrenome = sobrenome[0];

  String fileName = 'carteira-$nome-$primSobrenome-$dateFormatted.jpg'; 

  try {
    await FirebaseStorage.instance
      .ref('fotos-carteirinhas/$fileName') 
      .putFile(file);
  } catch (e) {
      throw('Erro ao salvar carteirinha: $e');
  }
}

Future<bool> existeCRO() async {
  String nroCconselho = _councilNumberController.text;

  var url = Uri.parse('https://api.infosimples.com/api/v2/consultas/cro/cadastro?inscricao=$nroCconselho&token=$token&uf=$_selectedState');
    // print(url);
  var response = await http.post(url);

  if (response.statusCode == 200) {
    var jsonResponse = json.decode(response.body);
    List<dynamic> dataList = jsonResponse['data'];
    return dataList.any((dataItem) {
      var firstName = (dataItem['nome'] as String).split(' ')[0].toLowerCase();
      var situacao = (dataItem['situacao'] as String);
      enviaConselho();
      return firstName == _nameController.text.toLowerCase() && situacao == 'ATIVO';
    });
  } else {
    throw Exception('Erro ao verificar conselho');
  }
}

Future<bool> existeCFBM() async {
  String nroCconselho = _councilNumberController.text;

  var url = Uri.parse('https://api.infosimples.com/api/v2/consultas/cfbm/cadastro?token=$token&registro=$nroCconselho');
      // print(url);
  var response = await http.post(url);

  if (response.statusCode == 200) {
    var jsonResponse = json.decode(response.body);
    List<dynamic> dataList = jsonResponse['data'][0]['lista_registros'] as List;
    return dataList.any((dataItem) {
      var firstName = (dataItem['nome_razao_social'] as String).split(' ')[0].toLowerCase();
      var situacao = (dataItem['situacao'] as String);
      enviaConselho();
      return firstName == _nameController.text.toLowerCase() && situacao == 'ATIVO';
    });
  } else {
    throw Exception('Erro ao verificar conselho');
  }

}

Future<bool> existeCFF() async {
  String nroCconselho = _councilNumberController.text;
  String vlrMunicipio = (_municipioController.text.replaceAll(' ', '%20')) ?? 'todos';
  String selectedState = _selectedState ?? 'CE';  
  String selectedCategory = _selectedCategory ?? 'farmaceutico';  

  var url = Uri.parse('https://api.infosimples.com/api/v2/consultas/cff/cadastro?token=$token&uf=$selectedState&municipio=$vlrMunicipio&categoria=$selectedCategory&crf=$nroCconselho');
  // print(url);
  var response = await http.post(url);

  if (response.statusCode == 200) {
    var jsonResponse = json.decode(response.body);
    if (jsonResponse['data'] != null && jsonResponse['data'].isNotEmpty) {
      var resultList = jsonResponse['data'][0]['resultado'] as List;
      return resultList.any((dataItem) {
        String? nomeAPI = dataItem['nome'];
        String situacao = dataItem['situacao'] ?? '';
        List<String> nameParts = nomeAPI?.split(' ') ?? [];
        String firstNameAPI = nameParts.isNotEmpty ? nameParts[0].toLowerCase() : '';
        String firstNameUser = (_nameController.text.split(' ')[0]).toLowerCase();
        enviaConselho();
        return firstNameUser == firstNameAPI && situacao == 'Definitivo';
        
      });
    }
    return false;
  } else {
    throw Exception('Erro ao verificar conselho');
  }
}


Future<void> enviaConselho() async{
  String? nome = _nameController.text;
  String? conselho = _councilNumberController.text;
  String? profissao = _selectedProfession;
  
  Map<String, dynamic> conselhoUser = {
    'conselho': conselho,
    'cliente': nome,
    'profissao': profissao,
  };
  
  String cliente = '$nome - $conselho';
  await firestore
    .collection('conselhos-validos-$profissao')
    .doc(cliente)
    .set(conselhoUser, SetOptions(merge: false));
}

}

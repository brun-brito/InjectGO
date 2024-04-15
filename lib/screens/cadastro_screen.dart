// ignore_for_file: library_private_types_in_public_api
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:inject_go/screens/welcome_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'login_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


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
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _birthDateController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String? _senha;
  final _formKey = GlobalKey<FormState>();
  XFile? _image;
  final picker = ImagePicker();
  String? _selectedProfession;
  String? _selectedState;

  Future getImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    setState(() {
      if (pickedFile != null) {
        _image = pickedFile;
      } else {
          const Text('No image selected.');
        }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back), //seta pra voltar
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const WelcomePage()),
                );
              },
        ),
        title: const Text('Tela de Cadastro'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Nome*'),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor, preencha seu nome';
                }
                return null;
              },
            ),

            TextFormField(
              controller: _lastNameController,
              decoration: const InputDecoration(labelText: 'Sobrenome'),
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
                });
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor, selecione sua profissão';
                }
                return null;
              },
            ),

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

            TextFormField(
              controller: _councilNumberController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Número de conselho*'),
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly, 
              ],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor, preencha seu nome';
                }
                return null;
              },
            ),
            
            TextFormField(
              controller: _cpfController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'CPF*'),
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly, 
                LengthLimitingTextInputFormatter(11), 
              ],
              validator: (value) {
                if (value == null || value.isEmpty /*|| !isValidCPF(value)*/) {
                  return 'Por favor, preencha um CPF válido';
                }
                return null;
              },
            ),
            
            TextFormField(
              // controller: ,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.camera_enhance),
                labelText: 'Foto'
              ),
              readOnly: true,
              onTap: () async {
                final pickedFile = await picker.pickImage(source: ImageSource.gallery);
                setState(() {
                  _image = pickedFile;
                });
              },
            ),
              if (_image != null)
                Stack(
                  alignment: Alignment.topRight,
                  children: [
                    Container(
                      height: 200,
                      alignment: Alignment.center, // Define um tamanho para a prévia
                      child: Image.file(File(_image!.path)),
                    ),
                    IconButton(
                      icon: const Icon(Icons.cancel),
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
              controller: _addressController,
              decoration: const InputDecoration(labelText: 'Endereço*'),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor, preencha seu Endereço';
                }
                return null;
              },
            ),

            TextFormField(
              controller: _birthDateController,
              keyboardType: TextInputType.datetime,
              decoration: const InputDecoration(
                            labelText: 'Data de Nascimento*',
                            hintText: 'DD/MM/AAAA'
                          )
              ,              
              inputFormatters: [
                LengthLimitingTextInputFormatter(10), 
              ],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor, preencha sua Data de Nascimento';
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
                FilteringTextInputFormatter.digitsOnly, // Opcional, se você deseja permitir apenas dígitos
                LengthLimitingTextInputFormatter(11), // Limita a entrada a 11 caracteres
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
              decoration: const InputDecoration(labelText: 'E-mail (pode ser o mesmo da última tela)*'),
              inputFormatters: [
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
              obscureText: true, // Esconde a senha
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor, preencha sua senha';
                }
                _senha = value; // Armazena a senha para comparar depois
                return null;
              },
            ),

            TextFormField(
              decoration: const InputDecoration(labelText: 'Repetir senha*'),
              obscureText: true, // Esconde a senha
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
                if (_formKey.currentState!.validate()) {
                  try {
                    await addUserWithName(_nameController.text,
                     _lastNameController.text, _cpfController.text, _emailController.text, _usernameController.text,{});
                    await cadastrarAuth();
                    mensagemSucesso();
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Falha ao registrar: ${e.toString()}"))
                    );
                  }
                }
              },
              child: const Text('Cadastrar'),
            ),
          ],
        ),
      ),
    );
  }


Future<void> addUserWithName(
  String nome,
  String sobrenome,
  String cpf,
  String email,
  String usuario,
  Map<String, dynamic> userData
) async {
  FirebaseFirestore firestore = FirebaseFirestore.instance;

  // Primeiro, verifica se já existe algum usuário com o mesmo CPF ou nome de usuário.
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
  var emailQuery = await firestore
    .collection('users')
    .where('email', isEqualTo: email)
    .limit(1)
    .get();

  // Verifica se os documentos retornaram algum resultado
  if (cpfQuery.docs.isNotEmpty) {
    throw Exception("Cliente com este CPF já cadastrado.");
  }
  if (usernameQuery.docs.isNotEmpty) {
    throw Exception("Cliente com este usuário já existe.");
  }
  if (emailQuery.docs.isNotEmpty) {
    throw Exception("Cliente com este e-mail já existe.");
  }

  // Nome completo + cpf
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
    'endereco': _addressController.text,
    'dataNasc': _birthDateController.text,
    'telefone': _phoneController.text,
    'email': _emailController.text,
    'usuario': _usernameController.text,
    'senha': _passwordController.text,
    'caminhoFoto': _image?.path  
  };

  // Insere os dados no Firestore
  await firestore
    .collection('users')
    .doc(cliente)
    .set(fullUserData, SetOptions(merge: false));
}

cadastrarAuth() async{
  final _firebaseAuth = FirebaseAuth.instance;
  _firebaseAuth.createUserWithEmailAndPassword(email: _emailController.text, password: _passwordController.text);
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
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => LoginForm()),
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

  // Função para calcular dígito verificador
  int calculateDigit(String cpf, int length) {
    int sum = 0;
    for (int i = 0; i < length; i++) {
      sum += int.parse(cpf[i]) * (length + 1 - i);
    }
    int digit = 11 - (sum % 11);
    return digit >= 10 ? 0 : digit;
  }

  // Calcula e verifica os dígitos verificadores
  int firstDigit = calculateDigit(cpf, 9);
  int secondDigit = calculateDigit(cpf.substring(0, 9) + firstDigit.toString(), 10);

  return cpf.substring(9) == firstDigit.toString() + secondDigit.toString();
}
}

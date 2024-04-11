import 'dart:io';
import 'package:inject_go/screens/welcomeScreen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'loginScreen.dart';
// import 'package:intl/intl.dart';


void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: SignUpScreen(),
    );
  }
}

class SignUpScreen extends StatefulWidget {
  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  String? _senha;
  final _formKey = GlobalKey<FormState>();
  XFile? _image;
  final picker = ImagePicker();
  String? _selectedProfession;

  Future getImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    setState(() {
      if (pickedFile != null) {
        _image = pickedFile;
      } else {
        print('No image selected.');
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
                  MaterialPageRoute(builder: (context) => WelcomePage()),
                );
              },
        ),
        title: Text('Tela de Cadastro'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.all(16),
          children: <Widget>[
            TextFormField(
              decoration: InputDecoration(labelText: 'Nome*'),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor, preencha seu nome';
                }
                return null;
              },
            ),

            TextFormField(
              decoration: InputDecoration(labelText: 'Sobrenome'),
            ),
            
            DropdownButtonFormField<String>(
              decoration: InputDecoration(labelText: 'Profissão*'),
              value: _selectedProfession,
              items: <String>['Dentista', 'Biomédico']
                  .map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (newValue) {
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

            TextFormField(
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: 'Número de conselho*'),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor, preencha seu nome';
                }
                return null;
              },
            ),
            
            TextFormField(
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: 'CPF*'),
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
                          height: 200, // Define um tamanho para a prévia
                          child: Image.file(File(_image!.path)),
                          alignment: Alignment.center,
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
              decoration: InputDecoration(labelText: 'Endereço*'),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor, preencha seu Endereço';
                }
                return null;
              },
            ),

            TextFormField(
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
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Telefone (apenas números)*',
              ),
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly, // Opcional, se você deseja permitir apenas dígitos
                LengthLimitingTextInputFormatter(11), // Limita a entrada a 11 caracteres
              ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, preencha seu telefone';
                  }
                  return null;
                },
            ),

            TextFormField(
              decoration: InputDecoration(labelText: 'Crie um usuário*'),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor, preencha seu usuário';
                }
                return null;
              },
            ),

            TextFormField(
              decoration: InputDecoration(labelText: 'Senha*'),
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
              decoration: InputDecoration(labelText: 'Repetir senha*'),
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
              
              
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => LoginScreen()),
                      );
                  }
                },
              child: Text('Cadastrar'),
            ),
          ],
        ),
      ),
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

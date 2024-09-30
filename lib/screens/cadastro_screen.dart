// ignore_for_file: library_private_types_in_public_api, curly_braces_in_flow_control_structures, use_build_context_synchronously, prefer_typing_uninitialized_variables, unused_field
import 'dart:async';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:image_picker/image_picker.dart';
import 'package:inject_go/screens/welcome_screen.dart';
import 'login_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:intl/intl.dart'; 
import 'package:http/http.dart' as http;
import 'dart:convert';

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
  final TextEditingController _imageController = TextEditingController();
  final TextEditingController _certidaoController = TextEditingController();
  final TextEditingController _cnpjController = TextEditingController();
  final TextEditingController _razaoSocialController = TextEditingController();
  final TextEditingController _cnaeController = TextEditingController();
  final TextEditingController _cepController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final picker = ImagePicker();
  final ImagePicker _picker = ImagePicker(); 
  String dateFormatted = DateFormat('dd-MM-yyyy').format(DateTime.now());
  String? token = dotenv.env['TOKEN_INFOSIMPLES'];
  String? _selectedProfession;
  String? _selectedState;
  String? _sexo;
  String? _senha;
  XFile? _selfie;
  XFile? _image;
  bool _isLoading = false;
  bool _isLoadingVerify = false;
  bool _isLoadingCnpj = false;
  bool _isCnpjDisabled = false;
  bool _isObscure = true;
  bool _isObscure2 = true;
  Color _statusColor = Colors.black;
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  var funcao;  
  String? _userType;
  bool _formSubmitted = false;
  String? _errorMessage;
  String? apiKey;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const WelcomePage()),
          ),
        ),
        title: const Text('Cadastro'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            const Text(
              '- Campos com * são obrigatórios',
              style: TextStyle(
                color: Colors.grey,
                fontStyle: FontStyle.italic,
              ),
            ),
            _buildUserTypeDropdown(),
            const SizedBox(height: 16),

            if (_userType == 'Profissional') _buildProfessionalFields(),
            if (_userType == 'Distribuidor') _buildDistributorFields(),

            if (_userType != null) _buildSubmitButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildUserTypeDropdown() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(5),
      ),
      child: DropdownButtonFormField<String>(
        decoration: const InputDecoration(
          labelText: 'Selecione o tipo de usuário*',
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 10),
        ),
        value: _userType,
        items: <String>['Profissional', 'Distribuidor']
            .map<DropdownMenuItem<String>>((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(value),
          );
        }).toList(),
        onChanged: (String? newValue) {
          setState(() {
            _userType = newValue;
            _resetFields();
            _formSubmitted = false;
          });
        },
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Por favor, selecione o tipo de usuário';
          }
          return null;
        },
      ),
    );
  }

   Widget _buildProfessionalFields() {
    return Column(
      children: [
        // Adicione aqui todos os campos específicos de Profissional
        Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey), 
                borderRadius: BorderRadius.circular(5), 
              ),
              child: TextFormField(
                controller: _imageController,
                decoration: InputDecoration(
                  labelText: 'Selfie segurando a carteirinha*',
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.camera_alt),
                    onPressed: _takeSelfie,
                  ),
                  border: InputBorder.none, 
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10), 
                ),
                readOnly: true,
                validator: (value) {
                  if (_selfie == null) {
                    return 'Por favor, anexe uma selfie segurando a carteirinha';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(height: 8),

            if (_selfie != null)
              Stack(
                alignment: Alignment.topRight,
                children: [
                  SizedBox(
                    height: 200,
                    child: Image.file(File(_selfie!.path)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.cancel),
                    color: Colors.red,
                    onPressed: () {
                      setState(() {
                        _selfie = null;
                      });
                    },
                  ),
                ],
              ),
            if (_selfie != null)
              const SizedBox(height: 8),

            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey), 
                borderRadius: BorderRadius.circular(5), 
              ),
              child: TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Primeiro nome*',
                  border: InputBorder.none, 
                  contentPadding: EdgeInsets.symmetric(horizontal: 10), 
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.deny(RegExp(r'\s')),
                  FilteringTextInputFormatter.singleLineFormatter,
                  LengthLimitingTextInputFormatter(15),
                  TextInputFormatter.withFunction((oldValue, newValue) {
                    if (newValue.text.isNotEmpty) {
                      return TextEditingValue(
                        text: newValue.text.substring(0, 1).toUpperCase() + newValue.text.substring(1).toLowerCase(),
                        selection: TextSelection.collapsed(offset: newValue.text.length),
                      );
                    }
                    return newValue;
                  }),
                ],
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Por favor, preencha seu nome';
                  }
                  return null;
                },
                onChanged: (value) {
                  setState(() {
                    _statusColor = Colors.black;
                  });
                },
              ),
            ),
            const SizedBox(height: 8),
            
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey), 
                borderRadius: BorderRadius.circular(5), 
              ),
              child: TextFormField(
                controller: _lastNameController,
                decoration: const InputDecoration(
                  labelText: 'Sobrenome completo*',
                  border: InputBorder.none, 
                  contentPadding: EdgeInsets.symmetric(horizontal: 10), 
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[a-zA-ZáÁÃãéÉíÍóÓÕõúÚâÂêÊîÎôÔûÛàÀèÈìÌòÒùÙçÇñÑ-\s]')),
                  TextInputFormatter.withFunction((oldValue, newValue) {
                    if (newValue.text.isNotEmpty) {
                      final List<String> parts = newValue.text.split(' ');
                      final List<String> capitalizedParts = parts.map((part) {
                        if (part.isNotEmpty) {
                          return part.substring(0, 1).toUpperCase() + part.substring(1).toLowerCase();
                        }
                        return part;
                      }).toList();
                      final String result = capitalizedParts.join(' ');
                      return TextEditingValue(
                        text: result,
                        selection: TextSelection.collapsed(offset: result.length),
                      );
                    }
                    return newValue;
                  }),
                ],
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Por favor, preencha seu sobrenome';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(height: 8),
            
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey), 
              borderRadius: BorderRadius.circular(5), 
            ),
            child: DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Especialidade*',
                border: InputBorder.none, 
                contentPadding: EdgeInsets.symmetric(horizontal: 10), 
              ),
              value: _selectedProfession,
              items: <String>['Biomédico', 'Dentista', 'Médico', 'Farmacêutico']
                  .map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedProfession = newValue;
                  _statusColor = Colors.black;
                });
                if (_selectedProfession != 'Farmacêutico') _removeCertidaoImage();
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor, selecione sua profissão';
                }
                return null;
              },
            ),
          ),
          const SizedBox(height: 8),

          if (_selectedProfession == 'Farmacêutico')
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey), 
                borderRadius: BorderRadius.circular(5), 
              ),
              child: TextFormField(
                controller: _certidaoController,
                decoration: InputDecoration(
                  labelText: 'Certidão de Regularidade Técnica*',
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.file_upload),
                    onPressed: _pickCertidaoImage,
                  ),
                  border: InputBorder.none, 
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10), 
                ),
                readOnly: true,
                validator: (value) {
                  if (_image == null) {
                    return 'Por favor, faça upload da certidão de regularidade técnica';
                  }
                  return null;
                },
              ),
            ),

          if (_image != null)
            Stack(
              alignment: Alignment.topRight,
              children: [
                SizedBox(
                  height: 200,
                  child: Image.file(File(_image!.path)),
                ),
                IconButton(
                  icon: const Icon(Icons.cancel),
                  color: Colors.red,
                  onPressed: _removeCertidaoImage,
                ),
              ],
            ),
          if (_selectedProfession == 'Farmacêutico')
            const SizedBox(height: 8),
            
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey), 
                borderRadius: BorderRadius.circular(5), 
              ),
              child: DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Estado do Conselho*',
                  border: InputBorder.none, 
                  contentPadding: EdgeInsets.symmetric(horizontal: 10), 
                ),
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
                    _statusColor = Colors.black;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, selecione o estado do seu conselho';
                  }
                  return null;
                },
              ),
            ),
            
            const SizedBox(height: 8),

            Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: TextFormField(
                      controller: _councilNumberController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Número de conselho*',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 10),
                      ),
                      style: TextStyle(
                        color: _statusColor, 
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
                      onChanged: (value) {
                        setState(() {
                          _statusColor = Colors.black;
                        });
                      },
                    ),
                  ),
                ),
                IconButton(
                  icon: _isLoadingVerify
                    ? const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Color.fromARGB(255, 236, 63, 121)/*Color(0xFFf6cbc2)*/)) 
                    :  Icon(Icons.person_search_rounded, color: _statusColor),
                    onPressed: _isLoadingVerify ? null : () async {
                      if (_councilNumberController.text.isEmpty ||
                          _nameController.text.isEmpty ||
                          _selectedProfession == null ||
                          _selectedState == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text(
                                    "Preencha seu nome, especialidade, Estado e conselho, antes de verificar")));
                        return;
                      }

                      Future<bool> Function() funcao;

                      if (_selectedProfession == 'Dentista')
                        funcao = existeCRO;
                      else if (_selectedProfession == 'Biomédico')
                        funcao = existeCFBM;
                      else if (_selectedProfession == 'Médico')
                        funcao = existeCRM;
                      else if (_selectedProfession == 'Farmacêutico')
                        funcao = existeCFF;
                      else
                        return;

                      setState(() => _isLoadingVerify = true);
                      try {
                        if (await funcao()) {
                          setState(() => _statusColor = Colors.green);
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text(
                                      "Número de conselho validado!")));
                        } else {
                          setState(() => _statusColor = Colors.red);
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text(
                                      "Não foi encontrado nenhum resultado válido. Por favor, confira os dados informados ou tente novamente mais tarde.")));
                        }
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text(
                                    "Erro inesperado. Tente novamente mais tarde.")));
                      } finally {
                        setState(() => _isLoadingVerify = false);
                      }
                    },
                ),
              ],
            ),
            const SizedBox(height: 8),

            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey), 
                borderRadius: BorderRadius.circular(5), 
              ),
              child: DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Sexo*',
                  border: InputBorder.none, 
                  contentPadding: EdgeInsets.symmetric(horizontal: 10), 
                ),
              value: _sexo,
              items: <String>['Feminino', 'Masculino', 'Prefiro não informar']
                  .map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _sexo = newValue;
                });
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor, selecione uma das opções';
                }
                return null;
              },
            ),
            ),
            const SizedBox(height: 8),

            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(5),
                border: Border.all(color: Colors.grey),
              ),
              child: TextFormField(
                controller: _cpfController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'CPF (apenas números)*',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 10),
                ),
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
            ),
            const SizedBox(height: 8),

            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(5),
                border: Border.all(color: Colors.grey),
              ),
              child: TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Telefone (apenas números)*',
                  hintText: '85999999999',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 10),
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(11),
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, preencha seu telefone';
                  } else if (value.length != 11) {
                    return 'Por favor, preencha um telefone válido';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(height: 8),

            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(5),
                border: Border.all(color: Colors.grey),
              ),
              child: TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'E-mail*',
                  hintText: 'email@exemplo.com',
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                  prefixIcon: IconButton(
                    icon: const Icon(Icons.info_outline),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Informação'),
                          content: const Text(
                            'Esse campo pode ser preenchido com o mesmo e-mail informado na última tela, ou outro que você preferir.',
                            style: TextStyle(fontSize: 17),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                              child: const Text('OK'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                keyboardType: TextInputType.emailAddress,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                      RegExp(r'[a-zA-Z0-9\!\@\#\$\%\^\&\*\(\)\-\=\+\[\]\{\}\;\:\",<>\.\/\?\|\\_~]')),
                  FilteringTextInputFormatter.singleLineFormatter,
                ],
                validator: (value) {
                  if (value == null || value.isEmpty || !value.contains('@') || !value.contains('.')) {
                    return 'Por favor, preencha seu e-mail corretamente';
                  }

                  return null;
                },
              ),
            ),
            const SizedBox(height: 8),

            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(5),
                border: Border.all(color: Colors.grey),
              ),
              child: TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: 'Crie um usuário*',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 10),
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.singleLineFormatter,
                  FilteringTextInputFormatter.allow(
                      RegExp(r'[a-zA-Z0-9\!\@\#\$\%\^\&\*\(\)\-\=\+\[\]\{\}\;\:\",<>\.\?\|\\_~]')),
                  LengthLimitingTextInputFormatter(15),
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, preencha seu usuário';
                  }

                  return null;
                },
              ),
            ),
            const SizedBox(height: 8),

            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(5),
                border: Border.all(color: Colors.grey),
              ),
              child: TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Senha*',
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.visibility),
                    onPressed: () {
                      setState(() {
                        _isObscure = !_isObscure;
                      });
                    },
                  ),
                ),
                obscureText: _isObscure,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, preencha sua senha';
                  } else if (value.length < 6) {
                    return 'A senha deve ter ao menos 6 caracteres';
                  }
                  _senha = value;
                  return null;
                },
              ),
            ),
            const SizedBox(height: 8),
            
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(5),
                border: Border.all(color: Colors.grey),
              ),
              child: TextFormField(
                decoration: InputDecoration(
                  labelText: 'Repetir senha*',
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.visibility),
                    onPressed: () {
                      setState(() {
                        _isObscure2 = !_isObscure2;
                      });
                    },
                  ),
                ),
                obscureText: _isObscure2,
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
            ),
            const SizedBox(height: 8),
      ],
    );
  }

  // Método para construir os campos de distribuidor
  Widget _buildDistributorFields() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: TextFormField(
                  controller: _cnpjController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'CNPJ (apenas números)*',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 10),
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(14),
                  ],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, preencha o CNPJ';
                    }
                    return null;
                  },
                  enabled: !_isCnpjDisabled,  // Controla habilitação do campo CNPJ
                ),
              ),
            ),
            IconButton(
              icon: _isLoadingCnpj
                  ? const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Color.fromARGB(255, 236, 63, 121)))
                  : const Icon(Icons.search),
              onPressed: _isLoadingCnpj  // Verifica também se o botão já foi desabilitado
                  ? null
                  : () async {
                      setState(() {
                        _isLoadingCnpj = true;
                      });
                      try {
                        await _buscaCnpj(_cnpjController.text);
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text(
                                  "Erro ao buscar CNPJ. Tente novamente mais tarde.")),
                        );
                        setState(() {
                        });
                      } finally {
                        setState(() {
                          _isLoadingCnpj = false;  // Finaliza o carregamento
                        });
                      }
                    },
            ),
          ],
        ),
        const SizedBox(height: 8),
        
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(5),
          ),
          child: TextFormField(
            controller: _razaoSocialController,
            decoration: const InputDecoration(
              labelText: 'Razão Social*',
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 10),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Por favor, clique no ícone ao lado do campo CNPJ';
              }
              return null;
            },
            enabled: false, 
          ),
        ),
        const SizedBox(height: 8),

        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(5),
          ),
          child: TextFormField(
            controller: _cnaeController,
            decoration: const InputDecoration(
              labelText: 'Número CNAE Principal*',
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 10),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Por favor, clique no ícone ao lado do campo CNPJ';
              }
              return null;
            },
            enabled: false, 
        ),
        ),        
        const SizedBox(height: 8),

        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(5),
          ),
          child: 
            TextFormField(
              controller: _cepController,
              decoration: const InputDecoration(
                labelText: 'CEP para entrega*',
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 10),
              ),
              inputFormatters: [
                LengthLimitingTextInputFormatter(8),
              ],
              validator: (value) {
                if (value == null || value.isEmpty || value.length < 8) {
                  return 'Por favor, insira um CEP válido com apenas números';
                }
                return null;
              },
          ),
        ),        
        const SizedBox(height: 8),

        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(5),
            border: Border.all(color: Colors.grey),
          ),
          child: TextFormField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Telefone (apenas números)*',
              hintText: '85999999999',
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 10),
            ),
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(11),
            ],
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Por favor, preencha seu telefone';
              } else if (value.length != 11) {
                return 'Por favor, preencha um telefone válido';
              }
              return null;
            },
          ),
        ),
        const SizedBox(height: 8),

        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(5),
            border: Border.all(color: Colors.grey),
          ),
          child: TextFormField(
            controller: _emailController,
            decoration: InputDecoration(
              labelText: 'E-mail*',
              hintText: 'email@exemplo.com',
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 10),
              prefixIcon: IconButton(
                icon: const Icon(Icons.info_outline),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Informação'),
                      content: const Text(
                        'Esse campo pode ser preenchido com o mesmo e-mail informado na última tela, ou outro que você preferir.',
                        style: TextStyle(fontSize: 17),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: const Text('OK'),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            keyboardType: TextInputType.emailAddress,
            inputFormatters: [
              FilteringTextInputFormatter.allow(
                  RegExp(r'[a-zA-Z0-9\!\@\#\$\%\^\&\*\(\)\-\=\+\[\]\{\}\;\:\",<>\.\/\?\|\\_~]')),
              FilteringTextInputFormatter.singleLineFormatter,
            ],
            validator: (value) {
              if (value == null || value.isEmpty || !value.contains('@') || !value.contains('.')) {
                return 'Por favor, preencha seu e-mail corretamente';
              }

              return null;
            },
          ),
        ),
        const SizedBox(height: 8),

        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(5),
            border: Border.all(color: Colors.grey),
          ),
          child: TextFormField(
            controller: _usernameController,
            decoration: const InputDecoration(
              labelText: 'Crie um usuário*',
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 10),
            ),
            inputFormatters: [
              FilteringTextInputFormatter.singleLineFormatter,
              FilteringTextInputFormatter.allow(
                  RegExp(r'[a-zA-Z0-9\!\@\#\$\%\^\&\*\(\)\-\=\+\[\]\{\}\;\:\",<>\.\?\|\\_~]')),
              LengthLimitingTextInputFormatter(15),
            ],
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Por favor, preencha seu usuário';
              }

              return null;
            },
          ),
        ),
        const SizedBox(height: 8),

        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(5),
            border: Border.all(color: Colors.grey),
          ),
          child: TextFormField(
            controller: _passwordController,
            decoration: InputDecoration(
              labelText: 'Senha*',
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 10),
              suffixIcon: IconButton(
                icon: const Icon(Icons.visibility),
                onPressed: () {
                  setState(() {
                    _isObscure = !_isObscure;
                  });
                },
              ),
            ),
            obscureText: _isObscure,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Por favor, preencha sua senha';
              } else if (value.length < 6) {
                return 'A senha deve ter ao menos 6 caracteres';
              }
              _senha = value;
              return null;
            },
          ),
        ),
        const SizedBox(height: 8),
        
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(5),
            border: Border.all(color: Colors.grey),
          ),
          child: TextFormField(
            decoration: InputDecoration(
              labelText: 'Repetir senha*',
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 10),
              suffixIcon: IconButton(
                icon: const Icon(Icons.visibility),
                onPressed: () {
                  setState(() {
                    _isObscure2 = !_isObscure2;
                  });
                },
              ),
            ),
            obscureText: _isObscure2,
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
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  // Método para construir o botão de submissão
 Widget _buildSubmitButton() {
  return Column(
    children: [
      const SizedBox(height: 16),
      ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color.fromARGB(255, 236, 63, 121),
          foregroundColor: Colors.white,
        ),
        onPressed: () async {
          if (!_isLoading) {  // Evita múltiplos cliques enquanto carregando
            setState(() {
              _isLoading = true;
              _formSubmitted = true; // Marca o formulário como submetido
            });

            if (_formKey.currentState!.validate()) {
              try {
                if (_userType == 'Profissional') {
                  if (_statusColor == Colors.green && _selfie != null) {
                    // Lógica para profissionais
                    await addUserWithFirebase({});
                    await cadastrarAuth(_emailController.text, _passwordController.text);
                    await uploadCertidao();
                    await uploadSelfie();

                    mensagemSucesso();
                  } else {
                    if (_statusColor == Colors.red || _statusColor == Colors.black) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Insira um número de conselho válido e clique no ícone ao lado do campo para verificar!"),
                        ),
                      );
                    } else if (_selfie == null || _image == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Carregue a(s) foto(s) antes de concluir o cadastro."),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Campos obrigatórios não foram preenchidos!"),
                        ),
                      );
                    }
                  }
                } else if (_userType == 'Distribuidor') {
                  // Lógica para distribuidores
                  String cep = _cepController.text.trim();

                  // Valida o CEP antes de adicionar no banco
                  if (cep.isEmpty || cep.length != 8) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Por favor, insira um CEP válido."),
                      ),
                    );
                  } else {
                    // Busca as coordenadas com base no CEP informado
                    Map<String, double>? coordinates = await _getCoordinatesFromCep(cep);

                    if (coordinates != null) {
                      // Se as coordenadas forem encontradas, prossegue com o cadastro
                      await addDistribuidorWithFirebase({
                        'latitude': coordinates['latitude'],
                        'longitude': coordinates['longitude'],
                      });
                      await cadastrarAuth(_emailController.text, _passwordController.text);

                      mensagemSucesso();
                    } else {
                      // Exibe mensagem de erro caso as coordenadas não sejam encontradas
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Não foi possível encontrar o endereço do CEP informado."),
                        ),
                      );
                    }
                  }
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Falha ao registrar ${_userType?.toLowerCase()}: ${e.toString()}")),
                );
              } finally {
                setState(() {
                  _isLoading = false;  // Desativa o loading no final de tudo
                });
              }
            } else {
              setState(() {
                _isLoading = false;  // Desativa o loading se a validação falhar
              });
            }
          }
        },
        child: _isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text('Cadastrar'),
      ),
      Center(
        child: TextButton(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const WelcomePage()),
          ),
          child: const Text('Cancelar', style: TextStyle(color: Colors.red)),
        ),
      ),
      SelectableText.rich(
        TextSpan(
          text: 'Se estiver enfrentando alguma dificuldade em se cadastrar, envie um e-mail para ',
          style: const TextStyle(
            fontStyle: FontStyle.normal,
            fontSize: 14.5,
          ),
          children: [
            TextSpan(
              text: 'suporte@injectgo.com.br',
              style: const TextStyle(
                color: Colors.blue,
                decoration: TextDecoration.underline,
              ),
              recognizer: TapGestureRecognizer()
                ..onTap = () {
                  Clipboard.setData(const ClipboardData(text: 'suporte@injectgo.com.br'));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('E-mail copiado para a área de transferência')),
                  );
                },
            ),
            const TextSpan(
              text: ', que iremos lhe ajudar!',
              style: TextStyle(
                fontStyle: FontStyle.normal,
                fontSize: 14.5,
              ),
            ),
          ],
        ),
      )
    ],
  );
}

  void _resetFields() {
    _nameController.clear();
    _lastNameController.clear();
    _councilNumberController.clear();
    _cpfController.clear();
    _phoneController.clear();
    _emailController.clear();
    _usernameController.clear();
    _passwordController.clear();
    _imageController.clear();
    _certidaoController.clear();
    _cnpjController.clear();
    _razaoSocialController.clear();
    _cnaeController.clear();
    _cepController.clear();
    _selectedProfession = null;
    _selectedState = null;
    _isCnpjDisabled = false;
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
    var emailQuery2 = await firestore
      .collection('distribuidores')
      .where('email', isEqualTo: email)
      .limit(1)
      .get();
    var conselhoQuery = await firestore
      .collection('users')
      .where('conselho', isEqualTo: conselho).where('nome', isEqualTo: nome)
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
    if (emailQuery.docs.isNotEmpty || emailQuery2.docs.isNotEmpty) {
      throw Exception("Cliente com este e-mail já cadastrado.");
    }
    if (conselhoQuery.docs.isNotEmpty) {
      throw Exception("Cliente com este mesmo número de conselho e nome já cadastrado.");
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
      'sexo': _sexo,
      'bio': '',
      'viu-tutorial': false,
    };

    // Insere os dados no Firestore
    await firestore
      .collection('users')
      .doc(cliente)
      .set(fullUserData, SetOptions(merge: false));
  }

  Future<void> addDistribuidorWithFirebase(Map<String, dynamic> userData) async {
    String razao = _razaoSocialController.text;
    String cnpj = _cnpjController.text;
    String telefone = _phoneController.text;
    String email = _emailController.text;
    String usuario = _usernameController.text;
    String cnae = _cnaeController.text;
    String cep = _cepController.text;

    // Primeiro, verifica se já existe algum usuário com os mesmos dados.
    var cnpjQuery = await firestore
      .collection('distribuidores')
      .where('cnpj', isEqualTo: cnpj)
      .limit(1)
      .get();
    var usernameQuery = await firestore
      .collection('distribuidores')
      .where('usuario', isEqualTo: usuario)
      .limit(1)
      .get();
    var telQuery = await firestore
      .collection('distribuidores')
      .where('telefone', isEqualTo: telefone)
      .limit(1)
      .get();
    var emailQuery = await firestore
      .collection('distribuidores')
      .where('email', isEqualTo: email)
      .limit(1)
      .get();
    var emailQuery2 = await firestore
      .collection('users')
      .where('email', isEqualTo: email)
      .limit(1)
      .get();

    // Verifica se os documentos retornaram algum resultado
    if (cnpjQuery.docs.isNotEmpty) {
      throw Exception("Distribuidor com este CNPJ já cadastrado.");
    }
    if (usernameQuery.docs.isNotEmpty) {
      throw Exception("Distribuidor com este usuário já cadastrado.");
    }
    if (telQuery.docs.isNotEmpty) {
      throw Exception("Distribuidor com este telefone já cadastrado.");
    }
    if (emailQuery.docs.isNotEmpty || emailQuery2.docs.isNotEmpty) {
      throw Exception("Usuário com este e-mail já cadastrado.");
    }

    // razão social + cnpj vai ser chave
    String cliente = '$razao - $cnpj';
    String randomId = firestore.collection('distribuidores').doc().id;
    double latitude = userData['latitude'] ?? 0.0; // Define um valor padrão caso latitude não seja fornecida
    double longitude = userData['longitude'] ?? 0.0;

    // Define os dados que serão inseridos
    Map<String, dynamic> fullUserData = {
      'idUser': randomId,
      'razao_social': razao,
      'cnpj': cnpj,
      'telefone': telefone,
      'email': email,
      'usuario': usuario,
      'senha': _passwordController.text,
      'cnae': cnae,
      'cep': cep,
      'latitude': latitude,
      'longitude': longitude,
      'pagamento_em_dia': false,
    };

    // Insere os dados no Firestore
    await firestore
      .collection('distribuidores')
      .doc(cliente)
      .set(fullUserData, SetOptions(merge: false));
  }

  Future<void> cadastrarAuth(String email, String password) async {
    final firebaseAuth = FirebaseAuth.instance;
    try {
      await firebaseAuth.createUserWithEmailAndPassword(email: email, password: password);
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
      rethrow;
    } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Um erro ocorreu: $e'))
        );  
      rethrow;
    }
  }

  void mensagemSucesso() {
    showDialog(
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
                child: Text(
                  "Cadastro realizado\n com sucesso!",
                  style: TextStyle(fontSize: 18),
                  overflow: TextOverflow.ellipsis, 
                ),
              ),
            ],
          ),
          content: const Text(
            "Você será direcionado para a página de login.",
            style: TextStyle(fontSize: 16),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text("Ok", style: TextStyle(fontSize: 16)),
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginForm()),
                  (Route<dynamic> route) => false,
                );
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _buscaCnpj(String cnpj) async {
    if (cnpj.length != 14) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('O CNPJ deve conter 14 números.')),
      );
      return;
    }

    setState(() {
      _isLoadingCnpj = true;
    });

    final url = 'https://open.cnpja.com/office/$cnpj';
    final headers = {
      'Authorization': '0cdf6d17-8007-4769-a2fd-7e374d40f198-d718a448-1ce5-44a1-949a-201730bee40c',
    };

    try {
      final response = await http.get(Uri.parse(url), headers: headers);

      if (response.statusCode != 200) {
        throw Exception('CNPJ não encontrado. Tente novamente!');
      }

      final data = jsonDecode(response.body);

      final companyName = data['company']?['name'];
      final mainActivity = data['mainActivity'] != null
          ? '${data['mainActivity']['id']} - ${data['mainActivity']['text']}'
          : null;

      // Atualiza os campos do formulário com os dados recebidos
      setState(() {
        _razaoSocialController.text = companyName!;
        _cnaeController.text = mainActivity!;
        _isCnpjDisabled = true;  // Desabilita o campo CNPJ após a busca bem-sucedida
      });

    } catch (error) {
      String errorMessage;

      if (error is SocketException) {
        errorMessage = 'Não foi possível conectar ao servidor. Verifique sua conexão com a internet.';
      } else if (error is TimeoutException) {
        errorMessage = 'A solicitação demorou muito para responder. Tente novamente mais tarde.';
      } else {
        errorMessage = 'CNPJ não encontrado. Tente novamente!';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );

      setState(() {
        _razaoSocialController.clear();
        _cnaeController.clear();
        _isCnpjDisabled = false;  // Reabilita o campo CNPJ em caso de erro
      });
    } finally {
      setState(() {
        _isLoadingCnpj = false;
      });
    }
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

  Future<void> uploadSelfie() async {
    if (_selfie == null) return;
    final file = File(_selfie!.path);
    String nome = _nameController.text;
    List<String> sobrenome = _lastNameController.text.split(' ');
    String primSobrenome = sobrenome[0];
    String cpf = _cpfController.text;

    String fileName = 'selfie-$nome-$primSobrenome.jpg'; 

    try {
      await FirebaseStorage.instance
        .ref('profissionais/$nome-$cpf/$fileName') 
        .putFile(file);
    } catch (e) {
      throw('Erro ao salvar selfie: $e');
    }
  }


void _pickCertidaoImage() async {
  final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
  setState(() {
    if (pickedFile != null) {
      _image = pickedFile;
    }
  });
}

void _removeCertidaoImage() {
  setState(() {
    _image = null;
    _certidaoController.clear();
  });
}

  Future<void> uploadCertidao() async {
    if (_image == null) return;
    final file = File(_image!.path);
    String nome = _nameController.text;
    List<String> sobrenome = _lastNameController.text.split(' ');
    String primSobrenome = sobrenome[0];
    String cpf = _cpfController.text;
    String fileName = 'certidao-$nome-$primSobrenome.jpg'; 
    try {
      await FirebaseStorage.instance
        .ref('profissionais/$nome-$cpf/$fileName') 
        .putFile(file);
    } catch (e) {
      throw('Erro ao salvar certidão: $e');
    }
  }

  Future<bool> existeCRO() async {
    String nroCconselho = _councilNumberController.text;

    var url = Uri.parse('https://api.infosimples.com/api/v2/consultas/cro/cadastro?inscricao=$nroCconselho&token=$token&uf=$_selectedState');
    var response = await http.post(url);

    if (response.statusCode == 200) {
      var jsonResponse = json.decode(response.body);
      List<dynamic> dataList = jsonResponse['data'];
      return dataList.any((dataItem) {
        var firstName = (dataItem['nome'] as String).split(' ')[0].toLowerCase();
        var situacao = (dataItem['situacao'] as String);
        var verificaCons = (dataItem['inscricao'] as String);
        if(firstName == _nameController.text.toLowerCase() && situacao == 'ATIVO' && verificaCons == nroCconselho){
          enviaConselho();
          return true;
        }
        else
          return false;
      });
    } else {
      throw Exception('Erro ao verificar conselho');
    }
  }

  Future<bool> existeCFBM() async {
    String nroCconselho = _councilNumberController.text;

    var url = Uri.parse('https://api.infosimples.com/api/v2/consultas/cfbm/cadastro?token=$token&registro=$nroCconselho');
    var response = await http.post(url);

    if (response.statusCode == 200) {
      var jsonResponse = json.decode(response.body);
      List<dynamic> dataList = jsonResponse['data'][0]['lista_registros'] as List;
      return dataList.any((dataItem) {
        var firstName = (dataItem['nome_razao_social'] as String).split(' ')[0].toLowerCase();
         var situacao = (dataItem['situacao'] as String);
        var verificaCons = (dataItem['numero_registro'] as String).trim();
        if(firstName == _nameController.text.toLowerCase() && situacao == 'ATIVO' && verificaCons == nroCconselho){
          enviaConselho();
          return true;
        }
        else
          return false;
      });
    } else {
      throw Exception('Erro ao verificar conselho');
    }
  }

  Future<bool> existeCRM() async {
    String nroCconselho = _councilNumberController.text;
    var url = Uri.parse('https://api.infosimples.com/api/v2/consultas/cfm/cadastro?inscricao=$nroCconselho&token=$token&uf=$_selectedState');
    var response = await http.post(url);

    if (response.statusCode == 200) {
      var jsonResponse = json.decode(response.body);
      List<dynamic> dataList = jsonResponse['data'];
      return dataList.any((dataItem) {
        var firstName = (dataItem['nome'] as String).split(' ')[0].toLowerCase();
        var situacao = (dataItem['situacao'] as String);
        var verificaCons = (dataItem['inscricao'] as String);
        if(firstName == _nameController.text.toLowerCase() && situacao == 'Regular' && verificaCons == nroCconselho){
          enviaConselho();
          return true;
        }
        else
          return false;
      });
    } else {
      throw Exception('Erro ao verificar conselho');
    }
  }

  Future<bool> existeCFF() async {
    String nroCconselho = _councilNumberController.text;
    String vlrMunicipio = 'todos';
    String selectedState = _selectedState ?? 'CE';  
    String selectedCategory = 'farmaceutico';  
    var url = Uri.parse('https://api.infosimples.com/api/v2/consultas/cff/cadastro?token=$token&uf=$selectedState&municipio=$vlrMunicipio&categoria=$selectedCategory&crf=$nroCconselho');
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
          var verificaCons = (dataItem['crf'] as String);
          enviaConselho();
          return firstNameUser == firstNameAPI && situacao == 'Definitivo' && verificaCons == nroCconselho;
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
      .set(conselhoUser, SetOptions(merge: true)); 
  }

  Future<Map<String, double>?> _getCoordinatesFromCep(String cep) async {
    if (Platform.isAndroid) apiKey  = dotenv.env['API_KEY_GEO_ANDROID'];
    else if (Platform.isIOS) apiKey  = dotenv.env['API_KEY_GEO_IOS'];
    else apiKey = '';
    final String url = 'https://maps.googleapis.com/maps/api/geocode/json?address=$cep&key=$apiKey';
    
    try {
      final response = await http.get(Uri.parse(url));
      final data = jsonDecode(response.body);

      if (data['status'] == 'OK') {
        var location = data['results'][0]['geometry']['location'];
        return {
          'latitude': location['lat'],
          'longitude': location['lng'],
        };
      } else {
        setState(() {
          _errorMessage = "CEP inválido ou não encontrado.";
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Erro ao buscar coordenadas.";
      });
    }
    return null;
  }
}

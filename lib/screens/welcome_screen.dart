// ignore_for_file: file_names, use_build_context_synchronously, library_private_types_in_public_api
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/gestures.dart';
import 'login_screen.dart';
import 'cadastro_screen.dart';
import 'package:inject_go/main.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'InjectGO',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const WelcomePage(),
    );
  }
}

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  _WelcomePageState createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  final TextEditingController _emailController = TextEditingController();
  bool _isButtonEnabled = false; 
  bool _isLoading = false;
  String? _selectedState;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back), 
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const Home()),
                );
              },
        ),
        title: const Text('Seja bem-vindo(a)!'), 
        centerTitle: true,
      ),
       body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
         child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.stretch,
          children: <Widget>[
            Align(
              alignment:
              Alignment.topCenter, 
              child: Image.asset(
                  'assets/images/logoInject.jpeg', //logo-distribuidora.jpeg',
                fit: BoxFit.fitWidth,
                width: 250,//300
                height: 150, 
              ),
            ),

            const Text(
              'Crie sua conta', 
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 16.0),
            TextFormField(
              controller: _emailController,
              decoration: 
                const InputDecoration(
                  labelText: 'Digite seu melhor e-mail',
                  prefixIcon: Icon(Icons.mail),
                  hintText: 'email@exemplo.com',
                ),
            ),

            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'UF de atuação',
                prefixIcon: Icon(Icons.maps_home_work_outlined),
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
                  _isButtonEnabled = _emailController.text.isNotEmpty &&
                    _emailController.text.contains('@') &&
                    _emailController.text.contains('.') &&
                    _selectedState != null;
                });
              },
            ),

          const SizedBox(height: 8.0),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _isButtonEnabled ? const Color.fromARGB(255, 236, 63, 121)/*Color(0xFFf6cbc2)*/ : Colors.grey,
              foregroundColor: Colors.white,
            ),
            onPressed: _isLoading ? null : () async {
              setState(() => _isLoading = true); 
              try {
                await onContinuePressed();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Erro inesperado: ${e.toString()}"))
                );
              } finally {
                setState(() => _isLoading = false);  
              }
            },
            child: _isLoading 
              ? const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white)
                )
              : const Text('Avançar'),
          ),


            const SizedBox(height: 16.0),
            RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: const TextStyle(color: Color.fromARGB(255, 64, 62, 62), fontSize: 14.0),
              children: <TextSpan>[
                const TextSpan(text: 'Ao se inscrever, você concorda com os\n'),
                TextSpan(
                  text: 'Termos de Serviço',
                  style: const TextStyle(decoration: TextDecoration.underline, color:  Color.fromARGB(255, 236, 63, 121)),
                  recognizer: TapGestureRecognizer()..onTap = () {
                    _showTermsDialog(context);
                  },
                ),
                const TextSpan(text: ' da InjectGO'),
              ],
            ),
          ),
          
            const SizedBox(height: 25.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                const Text('Já possui conta? Faça '),
                InkWell(
                  child: const Text(
                    'Login',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 25.0, fontWeight: FontWeight.bold,decoration: TextDecoration.underline, color:  Color.fromARGB(255, 236, 63, 121),
                      decorationColor: Color.fromARGB(255, 236, 63, 121),),
                  ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const LoginForm()),
                      );
                    }
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

 @override
  void initState() {
    super.initState();
    _emailController.addListener(_validateEmail);
  }

  void _validateEmail() {
    setState(() {
      _isButtonEnabled = _emailController.text.isNotEmpty &&
        _emailController.text.contains('@') &&
        _emailController.text.contains('.') &&
        _selectedState != null;
    });
  }

  Future<void> _showTermsDialog(BuildContext context) async {
    String terms;
    try {
      terms = await rootBundle.loadString('assets/terms/termoServico.txt');
    } catch (e) {
      terms = 'Não foi possível carregar os termos de serviço.';
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Termos de Serviço InjectGO'),
          content: SingleChildScrollView(
            child: Text(terms),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Fechar'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

Future<void> onContinuePressed() async {
 if (_isButtonEnabled) {
    if(await verificaEmail(_emailController.text)){
      addEmail(_emailController.text,_selectedState!,{}); 
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) =>  const SignUpScreen()),
      );
    }
    else{
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Seu e-mail já foi cadastrado, por favor, faça o login."),
          duration: Duration(seconds: 5),
        ),
      );
    }
  }
  else if (_emailController.text.isNotEmpty && _selectedState == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Por favor, selecione uma UF."),
        duration: Duration(seconds: 5),
      ),
    );
  }
  // else if (_emailController.text.isNotEmpty /*&& _selectedState != 'CE'*/) {
  //   if(await verificaEmail2(_emailController.text)){
  //     addEmailIndisponivel(_emailController.text,_selectedState!,{});
  //   }else{
  //     _showIneligibilityMessage();  
  //   }  
  // }
  else{
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Por favor, preencha o campo de e-mail corretamente antes de continuar."),
        duration: Duration(seconds: 5),
      ),
    );
  }
}

  // void _showIneligibilityMessage() {
  //   showDialog(
  //     context: context,
  //     builder: (BuildContext context) {
  //       return AlertDialog(
  //         title: const Text("Aviso"),
  //         content: const SingleChildScrollView(
  //           child: ListBody(
  //             children: <Widget>[
  //             Text(
  //               "Infelizmente o nosso app não chegou na sua região ainda 😭\nMas não se preocupe! Nós iremos te mandar um e-mail, assim que o App estiver disponível para te atender 🥳",
  //               style: TextStyle(
  //                 fontSize: 20, 
  //               ),
  //             ),
  //           ]
  //           ),
  //         ),
  //         actions: <Widget>[
  //           TextButton(
  //             child: const Text('OK'),
  //             onPressed: () {
  //               Navigator.of(context).pop();
  //             },
  //           ),
  //         ],
  //       );
  //     },
  //   );
  // }

Future<bool> verificaEmail(String email) async{
  // var emailQuery = await firestore
  //   .collection('email-uf')
  //   .where('email', isEqualTo: email)
  //   .limit(1)
  //   .get();
    
  var cadastroQuery = await firestore
    .collection('users')
    .where('email', isEqualTo: email)
    .limit(1)
    .get();

  if (/*emailQuery.docs.isNotEmpty && */cadastroQuery.docs.isNotEmpty) {
    return false;
  }
  return true;
}

Future<void> addEmail(String email, String uf, Map<String, dynamic> userData) async {  
    Map<String, dynamic> fullUserData = {
      'email': email,  
      'UF': uf,
    };

    var emailQuery = await firestore
    .collection('email-uf')
    .where('email', isEqualTo: email).where('UF', isEqualTo: uf)
    .limit(1)
    .get();

    if(emailQuery.docs.isEmpty){
      await firestore
        .collection('email-uf')
        .doc()
        .set(fullUserData, SetOptions(merge: true));
    }
}

// Future<bool> verificaEmail2(String email) async{
//   var emailQuery = await firestore
//     .collection('email-uf-indisponivel')
//     .where('email', isEqualTo: email)
//     .limit(1)
//     .get();
//   if (emailQuery.docs.isNotEmpty) {
//     return false;
//   }
//   return true;
// }
// Future<void> addEmailIndisponivel(String email, String uf, Map<String, dynamic> userData) async {  
//   Map<String, dynamic> fullUserData = {
//     'email': email,  
//     'UF': uf,
//   };
//   await firestore
//     .collection('email-uf-indisponivel')
//     .doc()
//     .set(fullUserData, SetOptions(merge: false));
// }


}
// ignore_for_file: use_build_context_synchronously, depend_on_referenced_packages, library_private_types_in_public_api

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:inject_go/subtelas/tutorial_speaker.dart';
import 'package:bubble/bubble.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:http/http.dart' as http;
import 'dart:convert';
// import 'package:chat_gpt_sdk/chat_gpt_sdk.dart';
// import 'package:openai_dart/openai_dart.dart' hide Image;

class ChatPage extends StatefulWidget {
  final String username;
  final String? nome;
  final String? cpf;
  const ChatPage({super.key, required this.username, this.nome, this.cpf});

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> with SingleTickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, String>> _messages = [];
  bool _isLoading = false;
  late AnimationController _animationController;
  late Animation<int> _dotsAnimation;
  final String _loadingText = "Speaker está digitando";
  late String assistantId;
  late String token;
  late String orgId;
  String? tempImageUrl;   
  bool _isUploadingImage = false;
  String? _threadId;
  // late OpenAI openAI;
  // late OpenAIClient client;


  @override
  void initState() {
    super.initState();
    dotenv.load().then((_) {
      token = dotenv.get('API_GPT');
      orgId = dotenv.get('ORG_ID');
      assistantId = dotenv.get('ASSISTANT_ID');
      // client = OpenAIClient(
      //   apiKey: token,
      //   organization: orgId,
      // );
      // openAI = OpenAI.instance.build(
      //   token: token,
      //   orgId: orgId,
      //   baseOption: HttpSetup(receiveTimeout: const Duration(seconds: 5)),
      //   enableLog: true,
      // );
    });

    _animationController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat();
    _dotsAnimation = StepTween(begin: 0, end: 3).animate(_animationController);
  }

  @override
  void dispose() {
    _controller.dispose();
    _animationController.dispose();
    super.dispose();
  }

/*  Future<void> _sendMessage2() async {
    String message = _controller.text;
    String? imageUrl = tempImageUrl;
    _controller.clear(); 

    setState(() {
      if (message.isNotEmpty) {
        _messages.add({'role': 'user', 'content': message, 'type': 'text'});
      }
      if (imageUrl != null) {
        _messages.add({'role': 'user', 'content': imageUrl, 'type': 'image'});
        tempImageUrl = null; 
      }
      _isLoading = true;
    });

    final List<Map<String, dynamic>> content = [];

    if (message.isNotEmpty) {
      content.add({"type": "text", "text": message});
    }
    if (imageUrl != null) {
      content.add({
        "type": "image_url",
        "image_url": {"url": imageUrl}
      });
    }

    final request = CreateThreadAndRun(assistantId: assistantId, thread: {
      "messages": [
        {
          "role": "user",
          "content": content
        }
      ],
    });

    try {
      final response = await openAI.threads.runs.createThreadAndRun(request: request);

      while (response.status != 'completed') {
        await Future.delayed(const Duration(seconds: 1));
        final updatedResponse = await openAI.threads.runs.retrieveRun(
          threadId: response.threadId,
          runId: response.id,
        );
        response.status = updatedResponse.status;
      }

      final listaMensagens = await openAI.threads.messages.listMessage(threadId: response.threadId);
      final responseData = listaMensagens.data[0].content[0].text?.value;

      setState(() {
        _messages.add({'role': 'bot', 'content': responseData ?? 'Erro ao buscar resposta. Tente novamente ou volte mais tarde!', 'type': 'text'});
        _isLoading = false;
      });
    } catch (error) {
      setState(() {
        _messages.add({
          'role': 'bot',
          'content': 'Erro ao se comunicar com o Speaker. Tente novamente mais tarde.',
          'type': 'text'
        });
        _isLoading = false;
      });
    }
  }
*/
  
  Future<void> _sendMessage() async {
    String message = _controller.text;
    String? imageUrl = tempImageUrl;
    _controller.clear();

    setState(() {
      if (message.isNotEmpty) {
        _messages.add({'role': 'user', 'content': message, 'type': 'text'});
      }
      if (imageUrl != null) {
        _messages.add({'role': 'user', 'content': imageUrl, 'type': 'image'});
        tempImageUrl = null;
      }
      _isLoading = true;
    });

    final List<Map<String, dynamic>> content = [];
    final Map<String, String> headers = {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'OpenAI-Beta': 'assistants=v2'
        };

    if (message.isNotEmpty) {
      content.add({"type": "text", "text": message});
    }
    if (imageUrl != null) {
      content.add({
        "type": "image_url",
        "image_url": {"url": imageUrl}
      });
    }

    String apiUrl = 'https://api.openai.com/v1/threads';

    try {
      // Passo 1: Se não tiver criado, criar a thread
      if (_threadId == null){
        final createThreadResponse = await http.post(
          Uri.parse(apiUrl),
          headers: headers,
          body: jsonEncode({}),
        );

        if (createThreadResponse.statusCode != 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Erro inesperado, tente novamente mais tarde.")),
          );
        }

        final threadData = jsonDecode(createThreadResponse.body);
        _threadId = threadData['id'];
      }

      // Passo 2: Criar a mensagem
      final createMessageResponse = await http.post(
        Uri.parse('$apiUrl/$_threadId/messages'),
        headers: headers,
        body: jsonEncode({
          'role': 'user',
          'content': content,
        }),
      );

      if (createMessageResponse.statusCode != 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Erro inesperado, tente novamente mais tarde.")),
        );
      }

      // Passo 3: Criar a run
      final createRunResponse = await http.post(
        Uri.parse('$apiUrl/$_threadId/runs'),
        headers: headers,
        body: jsonEncode({
          'assistant_id': assistantId,
        }),
      );
      if (createRunResponse.statusCode != 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Erro inesperado, tente novamente mais tarde.")),
        );
      }
      // Aguardar a conclusão da run, ate ficar 'completed'
      String runStatus = jsonDecode(createRunResponse.body)['status'];
      String runId = jsonDecode(createRunResponse.body)['id'];
      while (runStatus != 'completed') {
        await Future.delayed(const Duration(seconds: 2));
        final updatedRunResponse = await http.get(
          Uri.parse('$apiUrl/$_threadId/runs/$runId'),
          headers: {
            'Authorization': 'Bearer $token',
            'OpenAI-Beta': 'assistants=v2'
          },
        );
        runStatus = jsonDecode(updatedRunResponse.body)['status'];
      }
      // Passo 4: Pegar a lista de mensagens
      final getMessagesResponse = await http.get(
        Uri.parse('$apiUrl/$_threadId/messages'),
        headers: headers,
      );

      if (getMessagesResponse.statusCode != 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Erro inesperado, tente novamente mais tarde.")),
        );
      }

      final listaMensagens = jsonDecode(getMessagesResponse.body);
      final responseData = utf8.decode(listaMensagens['data'][0]['content'][0]['text']['value'].runes.toList());

      setState(() {
        _messages.add({
          'role': 'bot',
          'content': responseData,// ?? 'Erro ao buscar resposta. Tente novamente ou volte mais tarde!',
          'type': 'text'
        });
        _isLoading = false;
      });
    } catch (error) {
      setState(() {
        _messages.add({
          'role': 'bot',
          'content': 'Erro ao se comunicar com o Speaker. Tente novamente mais tarde.',
          'type': 'text'
        });
        _isLoading = false;
      });
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      _uploadImage(File(pickedFile.path));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Erro inesperado ao selecionar foto da galeria")),
      );
    }
  }

  Future<void> _uploadImage(File selectedImage) async {
    setState(() {
      _isUploadingImage = true;
    });
    
    String fileName = path.basename(selectedImage.path);
    String? nome = widget.nome;
    String? cpf = widget.cpf;
    String folderPath = "$nome-$cpf";
    Reference ref = FirebaseStorage.instance.ref().child('$folderPath/speaker/$fileName');

    UploadTask uploadTask = ref.putFile(selectedImage);
    TaskSnapshot taskSnapshot = await uploadTask.whenComplete(() => {});
    String urlImage = await taskSnapshot.ref.getDownloadURL();

    setState(() {
      tempImageUrl = urlImage;
      _isUploadingImage = false;
    });
  }

  void _removeImage() {
    setState(() {
      tempImageUrl = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text('Speaker InjectGO'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TutorialCarousel(username: widget.username),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _messages.length + (_isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (_isLoading && index == _messages.length) {
                  return ListTile(
                    title: Row(
                      children: [
                        AnimatedBuilder(
                          animation: _dotsAnimation,
                          builder: (context, child) {
                            return Text('$_loadingText${'.' * _dotsAnimation.value}');
                          },
                        ),
                      ],
                    ),
                    subtitle: const Text('Speaker InjectGO'),
                    tileColor: Colors.green[50],
                  );
                }
                final message = _messages[index];
                final isUserMessage = message['role'] == 'user';
                return Column(
                  children: [
                    Bubble(
                      alignment: isUserMessage ? Alignment.topRight : Alignment.topLeft,
                      nip: isUserMessage ? BubbleNip.rightTop : BubbleNip.leftTop,
                      color: isUserMessage ? const Color(0xFFFF007F) : Colors.black,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (message['type'] == 'text')
                            SelectableText(
                              message['content']!,
                              style: TextStyle(
                                color: isUserMessage ? Colors.black : Colors.white,
                              ),
                            ),
                          if (message['type'] == 'image')
                            Image.network(message['content']!),
                          Text(
                            isUserMessage ? 'Você' : 'Speaker InjectGO',
                            style: TextStyle(
                              color: isUserMessage ? Colors.grey : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                );
              },
            ),
          ),
          if (_isUploadingImage)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(color:Color.fromARGB(255, 236, 63, 121)),
            ),
          if (tempImageUrl != null)
            Container(
              margin: const EdgeInsets.all(8.0),
              width: 150,
              height: 150,
              child: Stack(
                alignment: Alignment.topRight,
                children: [
                  Image.network(tempImageUrl!, fit: BoxFit.cover), 
                  IconButton(
                    icon: const Icon(Icons.cancel, color: Colors.red),
                    onPressed: _removeImage,
                  ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.photo),
                  onPressed: _pickImage,
                ),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: 'Digite sua mensagem',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _isLoading
                      ? null
                      : _sendMessage,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

// ignore_for_file: library_private_types_in_public_api, use_build_context_synchronously, depend_on_referenced_packages

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:chat_gpt_sdk/chat_gpt_sdk.dart';
import 'package:inject_go/screens/profile_screen.dart';
import 'package:inject_go/subtelas/tutorial_speaker.dart';
import 'package:bubble/bubble.dart';

class ChatPage extends StatefulWidget {
  final String username;
  const ChatPage({super.key, required this.username});

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> with SingleTickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, String>> _messages = [];
  late OpenAI openAI;
  bool _isLoading = false;
  late AnimationController _animationController;
  late Animation<int> _dotsAnimation;
  final String _loadingText = "Speaker está digitando";

  @override
  void initState() {
    super.initState();
    dotenv.load().then((_) {
      String token = dotenv.get('API_GPT');
      String orgId = dotenv.get('ORG_ID');
      openAI = OpenAI.instance.build(
        token: token,
        orgId: orgId,
        baseOption: HttpSetup(receiveTimeout: const Duration(seconds: 5)),
        enableLog: true,
      );
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

  Future<void> _sendMessage(String message) async {
    setState(() {
      _messages.add({'role': 'user', 'content': message, 'type': 'text'});
      _isLoading = true;
    });

    try {
      String assistantId = dotenv.get('ASSISTANT_ID');
      final thread = await openAI.threads.createThread(request: ThreadRequest());
      final requestMessage = CreateMessage(
        role: 'user',
        content: message,
      );
      await openAI.threads.messages.createMessage(
        threadId: thread.id,
        request: requestMessage,
      );

      final request = CreateRun(assistantId: assistantId);

      final CreateRunResponse responseRun = await openAI.threads.runs.createRun(
        threadId: thread.id,
        request: request,
      );

      String status = '';
      while (status != 'completed') {
        await Future.delayed(const Duration(seconds: 5));
        final mRunSteps = await openAI.threads.runs.retrieveRun(
          threadId: thread.id,
          runId: responseRun.id,
        );
        status = mRunSteps.status;
      }

      final mmRunSteps = await openAI.threads.messages.listMessage(threadId: thread.id);
      final responseData = mmRunSteps.data[0].content[0].text?.value;

      setState(() {
        _messages.add({'role': 'bot', 'content': responseData ?? 'No response', 'type': 'text'});
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _messages.add({
          'role': 'bot',
          'content': 'Erro ao se comunicar com o Speaker. Tente mais tarde novamente',
          'type': 'text'
        });
        _isLoading = false;
      });
    }
  }

  /*Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      String extension = path.extension(pickedFile.path).toLowerCase();
      if (['.jpeg', '.jpg', '.gif', '.png'].contains(extension)) {
      }
    }
  }*/

  @override
  Widget build(BuildContext context) {
    return Scaffold(
    appBar: AppBar(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProfileScreen(username: widget.username),
            ),
          );
        },
      ),
        title: const Text('Speaker InjectGO'),actions: [
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
                          if (message['type'] == 'image')
                            Image.file(File(message['path']!)),
                          if (message['type'] == 'text')
                            Text(
                              message['content']!,
                              style: TextStyle(
                                color: isUserMessage ? Colors.black : Colors.white,
                              ),
                            ),
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
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                // IconButton(
                //   icon: const Icon(Icons.photo),
                //   onPressed: _pickImage,
                // ),
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
                      : () {
                          if (_controller.text.isNotEmpty) {
                            _sendMessage(_controller.text);
                            _controller.clear();
                          }
                        },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

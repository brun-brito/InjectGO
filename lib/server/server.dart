import 'dart:io';
import 'dart:async';
import 'dart:math';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';

String currentNumber = generateRandomNumber();

// Função para gerar um número aleatório de 6 dígitos
String generateRandomNumber() {
  return (Random().nextInt(900000) + 100000).toString();
}

void main(List<String> args) async {
  // Atualizar o número aleatório a cada 30 segundos
  Timer.periodic(Duration(seconds: 30), (timer) {
    currentNumber = generateRandomNumber();
    print('Número atualizado: $currentNumber'); // Para verificação de log
  });

  final router = Router()
    ..get('/random-number', (Request request) {
      return Response.ok(currentNumber);
    });

  final handler = Pipeline()
      .addMiddleware(logRequests())
      .addHandler(router);

  final port = int.parse(Platform.environment['PORT'] ?? '8080');
  final server = await shelf_io.serve(handler, '0.0.0.0', port);
  print('Servidor rodando na porta ${server.port}, pronto para uso.');
}

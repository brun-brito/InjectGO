import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'dart:async';

String formatDate(Timestamp? timestamp) {
  if (timestamp == null) return 'Data não disponível';
  final date = timestamp.toDate();
  return '${date.day}/${date.month}/${date.year}';
}

String formatDataHoraTimestp(Timestamp timestamp) {
  DateTime dateTime = timestamp.toDate();
  return DateFormat('dd/MM/yyyy HH:mm').format(dateTime);
}

String formataDdMmYyyy(String dateStr) {
  try {
    DateTime parsedDate = DateTime.parse(dateStr);
    return DateFormat('dd/MM/yyyy').format(parsedDate);
  } catch (e) {
    return 'N/A';
  }
}

String formatDataHora(String isoDate) {
  DateTime dateTime = DateTime.parse(isoDate);
  return DateFormat('dd/MM/yyyy HH:mm').format(dateTime);
}

String calculaDiferencaTempo(Timestamp timestamp) {
  DateTime dataMaxima = timestamp.toDate();
  DateTime agora = DateTime.now();

  Duration diferenca = dataMaxima.difference(agora);

  int dias = diferenca.inDays;
  int horas = diferenca.inHours % 24;
  int minutos = diferenca.inMinutes % 60;

  String dataFormatada = formatDataHoraTimestp(timestamp);
  if (dias > 0) {
    return '$dataFormatada (${dias}d ${horas}h ${minutos}m)';
  } else if (horas > 0) {
    return '$dataFormatada (${horas}h ${minutos}m)';
  } else {
    return '$dataFormatada (${minutos}m)';
  }
}

Stream<String> timeStream(Timestamp timestamp) async* {
  // Emite o valor inicial imediatamente
  yield calculaDiferencaTempo(timestamp);

  // Continua emitindo valores a cada minuto
  yield* Stream.periodic(const Duration(minutes: 1), (_) {
    return calculaDiferencaTempo(timestamp);
  });
}
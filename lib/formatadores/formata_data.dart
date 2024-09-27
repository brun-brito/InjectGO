import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

String formatDate(Timestamp? timestamp) {
  if (timestamp == null) return 'Data não disponível';
  final date = timestamp.toDate();
  return '${date.day}/${date.month}/${date.year}';
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
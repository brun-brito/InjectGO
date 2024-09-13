  import 'package:cloud_firestore/cloud_firestore.dart';

String formatDate(Timestamp? timestamp) {
    if (timestamp == null) return 'Data não disponível';
    final date = timestamp.toDate();
    return '${date.day}/${date.month}/${date.year}';
  }
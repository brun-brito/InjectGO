  import 'package:flutter/material.dart';

Widget buildRichText(String titulo, String valor) {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: titulo,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          TextSpan(
            text: valor,
          ),
        ],
      ),
    );
  }

  Widget buildRichTextColor(String title, String value, [Color? color]) {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          TextSpan(
            text: value,
            style: TextStyle(fontSize: 16, color: color ?? Colors.black87),
          ),
        ],
      ),
    );
  }
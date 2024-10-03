import 'dart:convert';

String primeiraMaiuscula(String input) {
  if (input.isEmpty) return input;
  return input[0].toUpperCase() + input.substring(1).toLowerCase();
}

String removeAcento(String str) {
  const comAcento = 'ÀÁÂÃÄÅàáâãäåÈÉÊËèéêëÌÍÎÏìíîïÒÓÔÕÖØòóôõöøÙÚÛÜùúûüÇçÑñ';
  const semAcento = 'AAAAAAaaaaaaEEEEeeeeIIIIiiiiOOOOOOooooooUUUUuuuuCcNn';

  for (int i = 0; i < comAcento.length; i++) {
    str = str.replaceAll(comAcento[i], semAcento[i]);
  }

  return str;
}

String decodeUtf8String(String input) {
  return utf8.decode(input.runes.toList());
}


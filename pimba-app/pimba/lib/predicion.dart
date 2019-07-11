import 'package:flutter/material.dart';

class Prediccion{
  String etiqueta;
  double probabilidad;
  Prediccion({@required this.etiqueta,@required this.probabilidad });

  factory Prediccion.fromJson(
    Map<String, dynamic> parsedJson,
  ){
    return Prediccion(
      etiqueta: parsedJson['label'],
      probabilidad: parsedJson['probability']
    );
  }

}
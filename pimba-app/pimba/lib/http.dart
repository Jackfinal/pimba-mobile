import 'dart:convert';
import 'dart:core';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:pimba/predicion.dart';


class PimbaService{
  
  final String _dominio = "http://172.29.66.97";

  Future <Prediccion>predecirImagen(List<int> imagen)async{

        var url = Uri.parse("$_dominio/api/v3/predecir");
        var peticion = new http.MultipartRequest("POST",url);
        Prediccion prediccion;
        peticion.files.add(
            new http.MultipartFile.fromBytes("imagen", imagen, contentType: new MediaType('image', 'png'),filename: "fto")

        );

        var datos = await peticion.send();
         datos.stream.transform(utf8.decoder).listen(
          (data){
            var datos = json.decode(data)['resultados'];
            prediccion = new Prediccion.fromJson(datos);      
          },cancelOnError: true,onDone: (){print("Prediccion: ${prediccion.etiqueta}");}
        );

      return prediccion;
    }
}
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import '../predicion.dart';
import '../utils.dart';
import 'dart:convert';
import 'dart:core';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:pimba/predicion.dart';
import 'package:pimba/utils.dart';


// Camara Widget
class Camara extends StatefulWidget {
    final List<CameraDescription> listaCamaras;
    Camara({@required this.listaCamaras});
    @override
    _CamaraState createState() => new _CamaraState();
}

class _CamaraState extends State<Camara>with WidgetsBindingObserver{

    CameraController controlador;
    String rutaImagen;
    bool _emitiendo = false;
    String timestamp() => DateTime.now().millisecondsSinceEpoch.toString();
    Uint8List imagenActual;
    String _prediccion = "";
    final String _dominio = "http://172.29.66.99";


    Future<String> tomarFoto() async {
    
      final Directory extDir = await getApplicationDocumentsDirectory();
      final String dirPath = '${extDir.path}/Pictures/flutter_test';
      await Directory(dirPath).create(recursive: true);
      final String filePath = '$dirPath/${timestamp()}.jpg';

      if (controlador.value.isTakingPicture) {
        // A capture is already pending, do nothing.
        return null;
      }

      try { 
        await controlador.takePicture(filePath);
      } on CameraException catch (e) {
        return null;
      }
      return filePath;
  }

    // Desactivar camara
    void _desactivarCamara(){
      setState(() {
       this.controlador = null; 
      });
    }

    // Activar camara
    void _activarCamara(){
        controlador = new CameraController(widget.listaCamaras[0], ResolutionPreset.medium);
        controlador.initialize().then((_){
        if(!mounted){
          return;   
        }
        setState(() {
        
        });
      });

     }

    // Gestion del ciclo de vida de la app.
    @override
    void didChangeAppLifecycleState(AppLifecycleState state){
        if(state == AppLifecycleState.suspending ){
          _desactivarCamara();
        }
        if(state==AppLifecycleState.inactive){
          print("Inactivo Camara");
          _desactivarCamara();
        }
        if(state == AppLifecycleState.resumed){
            print("Se resumio Camara");
            _activarCamara();
        }

        if(state == AppLifecycleState.paused){
            print("Se pauso Camara");
            _desactivarCamara();
        }
    }


    @override
    void initState() {
      super.initState();
      _activarCamara();
      WidgetsBinding.instance.addObserver(this);
    }


    @override
    void dispose() {
      WidgetsBinding.instance.removeObserver(this);
      super.dispose();
    }

    @override
    Widget build(BuildContext context) {
      return  ListView(scrollDirection: Axis.vertical,shrinkWrap: true,
            children: this.controlador != null?
            <Widget>[ 
              new Stack(
                children: <Widget>[
                  _visorCamaraWidget(),
                  this._emitiendo?_iconoStreaming():Container(),
                  _barraAcciones(),
                ],
              ),
              this.rutaImagen!=null?
              _fotoTomada():Container(),
            ]:<Widget>[_activadorVisor()],
      );
    }

    // Accion a realizar cuando se toma una foto
    void _tomarFoto(){
      print("Tomando Foto");
      tomarFoto().then(
        (String filePath) async{
          if (mounted) {
              setState(() {
              rutaImagen = filePath;
              _prediccion = "Prediciendo..";
            }
          );
          if (filePath != null){
              print("Imagen guardada");
              var _img = File(filePath).readAsBytesSync();
              await predecirImagen(_img);
          }
        }
      });
    }


    Widget _activadorVisor(){
      return new Container(child: RaisedButton(child: Text("Activa Camara"),onPressed: (){_activarCamara();},),);
    }
    // Visor de la camara
    Widget _visorCamaraWidget(){
      return AspectRatio(
        aspectRatio: controlador.value.aspectRatio,
        child: CameraPreview(controlador)
      );
    }

    // Barra de botones de acciones de la camara
    Widget _barraAcciones(){
      return new Container( padding: const EdgeInsets.only(top: 450),
        child:new Row(
        children: <Widget>[
          this._emitiendo==false?
          IconButton(
              color: Colors.green,
              iconSize: 75,
              icon: Icon(Icons.satellite),
              onPressed: (){
                //empezarStreaming(camera: controlador);
              },
              splashColor: Colors.indigo,
            ): 
              IconButton(icon: Icon(Icons.stop),
                onPressed: ()=>detenerStreaming(camera: controlador),
                iconSize: 75,
                color: Colors.greenAccent,
                splashColor: Colors.indigo,
              ),
          this._emitiendo==false?
          IconButton(
              color: Colors.red,
              iconSize: 75,
              icon: Icon(Icons.camera_alt),
              onPressed: (){_tomarFoto();},
  
            ): SizedBox(),
        ],
      )
      );
    }

    // Foto que se ha tomado y la prediccion
    Widget _fotoTomada(){
      return new ListTile(
        leading:CircleAvatar(
                  backgroundImage: MemoryImage(File(rutaImagen).readAsBytesSync()),
                  backgroundColor: Colors.transparent,
                  radius: 30.0,
          ) ,
        
        title: new Text("$_prediccion"),
      );
      //return Image.file(File(rutaImagen), width: 100, height: 100,);
    }

    // Icono de Streaming
    Widget _iconoStreaming(){
        return Row(
          children: <Widget>[
            Icon(Icons.fiber_manual_record,color: Colors.red, size: 75,),
            Text(_prediccion, style: new TextStyle(color: Colors.black),),
          ],
        );
    }


    void empezarStreaming({@required CameraController camera}){
      print("Empezando streaming....");

      
      setState(() {
            this._emitiendo= true; 
      });
      camera.startImageStream( (CameraImage image) async{
          
          // Llamar al servicio
          /*setState(() {
            I.Image _img = I.decodeImage(concatenatePlanes(image.planes));
             imagenActual = _img.getBytes(); 
             print(imagenActual);
          });*/
          var _img = await convertYUV420toImageColor(image);
          
          await predecirImagen(_img); 
          
          
          if (!this._emitiendo){
             await camera.stopImageStream();
          }
      });
    }

    void detenerStreaming({@required CameraController camera})async{
      setState(() {
          this._emitiendo = false; 
      });
    }


    Future <void>predecirImagen(List<int> imagen)async{

        var url = Uri.parse("$_dominio/api/v3/predecir");
        var peticion = new http.MultipartRequest("POST",url);
        peticion.files.add(
            new http.MultipartFile.fromBytes("imagen", imagen, contentType: new MediaType('image', 'png'),filename: "fto")

        );
        Prediccion respuesta;
        var datos = await peticion.send();
        //respuesta = json.decode(datos)['resultados'];
         datos.stream.transform(utf8.decoder).listen(
          (data){
            var datos = json.decode(data)['resultados'];
            respuesta = new Prediccion.fromJson(datos);      
            setState(() {
                    this._prediccion = respuesta.etiqueta;
            }); 
          },cancelOnError: true,onDone: (){print("Se ${respuesta.etiqueta}");}
        );
    }

}

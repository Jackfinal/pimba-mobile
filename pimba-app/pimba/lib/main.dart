import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:pimba/widgets/pantalla_camara.dart';



List<CameraDescription> camaras;

Future <void> main() async{
	camaras = await availableCameras();
  	runApp(PimbaApp());
}


class PimbaApp extends StatefulWidget {

	PimbaApp({ Key key}):super(key: key);

  	@override
  	_PimbaAppState createState() => new _PimbaAppState();
	
	
 
 }


final key = new GlobalKey<_PimbaAppState>();

class _PimbaAppState extends State<PimbaApp> with WidgetsBindingObserver{


	@override
  	void initState() {
    	WidgetsBinding.instance.addObserver(this);
    	super.initState();
  	}

  	@override
  	void dispose() {
    	WidgetsBinding.instance.removeObserver(this);
    	super.dispose();
  	}

	@override
    void didChangeAppLifecycleState(AppLifecycleState state){
		print('state = $state');

        if(state == AppLifecycleState.suspending ){
			print("Pausa");
        }
        if(state==AppLifecycleState.inactive){
          print("Inactivo");
        }else{
          if(state == AppLifecycleState.resumed){
            print("Se resumio");
          }
        }
    }

 	 @override
  	Widget build(BuildContext context) {
   		return new MaterialApp(title: "Pimba",
		  home: new Scaffold(
			 	appBar: new AppBar(
					 title: const Text("Pimba BETA"),
				 ),
				 body: Center(
					 child: 
						 	Camara(listaCamaras: camaras,)
				),
			),
		);
  	}
}
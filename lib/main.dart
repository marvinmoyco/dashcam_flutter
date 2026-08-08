import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../screen/dashcam_screen.dart';
import 'package:toastification/toastification.dart';

final navigatorKey = GlobalKey<NavigatorState>();
late List<CameraDescription> cameraList;

Future<void> main() async {
  
  try{
    WidgetsFlutterBinding.ensureInitialized();
    cameraList = await availableCameras();

  }
  on CameraException catch(e)
  {
    print('Error in fetching available cameras: $e');
  }
  runApp(DashCamApp());
}

class DashCamApp extends StatelessWidget{

  /// Default Constructor
  const DashCamApp({super.key});

  @override
  Widget build(BuildContext context){
    return ToastificationWrapper(child: MaterialApp(
      title: 'DashCam',
      theme: ThemeData(primarySwatch: Colors.purple),
      home: DashCamScreen(),

    ));
  }
}

import 'dart:async';

import 'package:flutter/services.dart';

import '../../main.dart';
import '../../recorder.dart';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:gal/gal.dart';


/// DashCamScreen is the Main Application.
class DashCamScreen extends StatefulWidget {
  /// Default Constructor
  const DashCamScreen({super.key});

  @override
  State<DashCamScreen> createState() => _DashCamScreenState();
}

class _DashCamScreenState extends State<DashCamScreen> with WidgetsBindingObserver{
  
  CameraController? controller;
  bool _isCameraInitialized = false;
  late Future<void> _initializeControllerFuture;
  ResolutionPreset currentPreset = ResolutionPreset.high;
  Recorder recorder = Recorder();
  Map<ResolutionPreset, String> resolutionPresets = {};

  void onNewCameraSelected(CameraDescription camDesc) async {
    final prevCamController = controller;
    if (resolutionPresets.isEmpty)
    {
      for(ResolutionPreset preset in ResolutionPreset.values)
      {
        if(preset == ResolutionPreset.low)
        {
          resolutionPresets[preset] = "240p";
        }
        else if(preset == ResolutionPreset.medium)
        {
          resolutionPresets[preset] = "480p";
        }
        else if(preset == ResolutionPreset.high)
        {
          resolutionPresets[preset] = "720p";
        }
        else if(preset == ResolutionPreset.veryHigh)
        {
          resolutionPresets[preset] = "1080p";
        }
        else if(preset == ResolutionPreset.ultraHigh)
        {
          resolutionPresets[preset] = "2160p";
        }
        else{
          resolutionPresets[preset] = "max";
        }
      }
    }
    
    DropdownButton<ResolutionPreset>(
      dropdownColor: Colors.black87,
      underline: Container(),
      value: currentPreset,
      items: [
        for (ResolutionPreset preset
            in resolutionPresets.keys)
          DropdownMenuItem(
            value: preset,
            child: Text(
              resolutionPresets[preset]!,
              style:
                  TextStyle(color: Colors.white),
            ),
          )
      ],
      onChanged: (value) {
        setState(() {
                value: currentPreset = value!;
                _isCameraInitialized = false;
        });
        onNewCameraSelected(controller!.description);
      },
      hint: Text("Select item"),
    );




    final CameraController camController = CameraController(camDesc, currentPreset, imageFormatGroup: ImageFormatGroup.jpeg);

    //Dispose of previouse controller
    await prevCamController?.dispose();

    //Set the new controller
    if(mounted){
      setState(() => controller = camController);
    }

    camController.addListener(() {
      if(mounted) setState((){});
    });

    try{
      await camController.initialize(); 
    }
    on CameraException catch (e){
      print('Error initializing cameras: $e');
    }

    if(mounted){
      setState(() => _isCameraInitialized = controller!.value.isInitialized);
    }


    //Set the zoom level to the ultra wide angle if available
    await camController.setZoomLevel(await camController.getMinZoomLevel());
  }


  @override
  void initState() {

    //Hide the system status bar
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    onNewCameraSelected(cameraList[0]);
    super.initState();
    
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state)
  {
    final CameraController? camController = controller;

    if(camController == null || !camController.value.isInitialized) return;

    if(state == AppLifecycleState.inactive){ camController.dispose(); }
    else if(state == AppLifecycleState.resumed){ onNewCameraSelected(camController.description); }


      

  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  Future<void> toggleRecording() async{
    try{
      
    }
    catch(e){
      debugPrint("Ërror recording: $e");
    }
  }


  

  void showSnackbar() {
    final context = navigatorKey.currentContext;
    if (context == null || !context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: const Text('Saved! ✅'),
      action: SnackBarAction(
        label: 'Gallery ->',
        onPressed: () async => Gal.open(),
      ),
    ));
  }

  
  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: Colors.black,
      body: _isCameraInitialized ? Column(
        children:[
          AspectRatio(aspectRatio: 1 / controller!.value.aspectRatio, child: Stack(children: [controller!.buildPreview(),
          Padding(padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Column(crossAxisAlignment: CrossAxisAlignment.end, 
                          children: [
                              Align(alignment: Alignment.topRight,
                              child: Container(decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(10),),
                                      child: Padding(padding: const EdgeInsets.only(left: 8, right: 8),
                                              child: DropdownButton<ResolutionPreset>(
                                                dropdownColor: Colors.black87,
                                                underline: Container(),
                                                value: currentPreset,
                                                items: [for (ResolutionPreset preset in resolutionPresets.keys) 
                                                            DropdownMenuItem(value: preset,
                                                                            child: Text(resolutionPresets[preset]!,
                                                                                    style: TextStyle(color: Colors.white), )
                                                                                    )],
                                                onChanged: (value){setState((){
                                                                   currentPreset = value!;
                                                                   _isCameraInitialized = false;});
                                                                    onNewCameraSelected(controller!.description);
                                                },
                                                hint: Text('Select preset'),
                                              ),
                                            ),
                                        ),
                                    ), 
                          ]),
          ),

          ])),

          Row(children: [Expanded(child: Padding(padding: const EdgeInsets.only(left: 8, right: 4),
                            child: TextButton(onPressed: () {recorder.toggleLoopRecording(controller);}, 
                            style: TextButton.styleFrom(foregroundColor: !recorder.isRecording ? Colors.black : Colors.grey, backgroundColor: !recorder.isRecording ? Colors.white : Colors.white30),
                            child: Text('Toggle Loop Recording'))))]),
          
        ]
      ) : Container()
      
      
      
      

    );
  }
}
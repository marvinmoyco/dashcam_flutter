import 'package:flutter/services.dart';

import '../../main.dart';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:intl/intl.dart';

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
  bool _isRecording = false;
  ResolutionPreset currentPreset = ResolutionPreset.high;

  

  void onNewCameraSelected(CameraDescription camDesc) async {
    final prevCamController = controller;
    DropdownButton<ResolutionPreset>(
      dropdownColor: Colors.black87,
      underline: Container(),
      value: currentPreset,
      items: [
        for (ResolutionPreset preset
            in ResolutionPreset.values)
          DropdownMenuItem(
            value: preset,
            child: Text(
              preset
                  .toString()
                  .split('.')[1]
                  .toUpperCase(),
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
  }


  @override
  void initState() {

    //Hide the system status bar
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.leanBack);
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
      await _initializeControllerFuture;

      //Stop recording 
      if(_isRecording)
      {
        String? albumName = "DashCam_Recordings";
        XFile recordedFile = await renameRecording(await controller!.stopVideoRecording(),"Rear");
        //Save to gallery
        await Gal.putVideo(recordedFile.path, album: albumName);
        setState(() => _isRecording = false);
        //Print where the file is saved
        debugPrint("Video saved to: ${recordedFile.path}");

      }
      //Start recording
      else{

        await controller!.startVideoRecording();
        setState(() => _isRecording=true);
      }
    }
    catch(e){
      debugPrint("Ërror recording: $e");
    }
  }


  Future<XFile> renameRecording(XFile initialVideo, String cameraType) async {
    
    //Convert XFile to File class to rename it
    File origFile = File(initialVideo.path);

    //Get the timestamp and file extension
    String formattedDateTime = DateFormat('yyyyMMdd_hhmmss').format(DateTime.now());
    String fileExtension = path.extension(initialVideo.path);
    
    //Create a new string combining all the extracted info
    String newFileName = '${formattedDateTime}_$cameraType$fileExtension';
    String newFilePath = path.join(path.dirname(initialVideo.path), newFileName);

    //Rename the file
    File renamedFile = await origFile.rename(newFilePath);

    //Return the renamed file as an XFile
    return XFile(renamedFile.path);

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

      body: _isCameraInitialized ? AspectRatio(aspectRatio: 1 / controller!.value.aspectRatio, child: controller!.buildPreview()) : Container(),

    );
  }
}
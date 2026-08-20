import 'dart:async';

import 'package:flutter/services.dart';
import 'dart:io';
import '../../main.dart';
import '../../recorder.dart';
import 'package:path_provider/path_provider.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';

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
  //Duration selectedDuration = Duration(minutes: 3);
  bool tonalSelected = false;
  late bool showSettingDrawer;
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

  void openDrawer()
  {
    scaffoldKey.currentState?.openEndDrawer();
    //setState(() => tonalSelected = !tonalSelected);
  }
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
    recorder.storageInfo.fetchStorageInfo();
    if(recorder.storageInfo.consumedSpace > recorder.settings.recordingStorageLimit)
    {
      setState(() => recorder.settings.setParameter("storage_limit", recorder.storageInfo.consumedSpace));
    }
    recorder.settings.initializeSettings();

    super.initState();

    
  }

  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state)
  {
    final CameraController? camController = controller;

    if(camController == null || !camController.value.isInitialized) return;

    if(state == AppLifecycleState.inactive){ camController.dispose(); }
    else if(state == AppLifecycleState.resumed){ onNewCameraSelected(camController.description); }
    super.didChangeAppLifecycleState(state);
  }

  @override
  void dispose() {
    recorder.cleanup();
    controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    showSettingDrawer = MediaQuery.widthOf(context) >= 450;
  }
  @override
  Widget build(BuildContext context) {

    return Scaffold(
      key: scaffoldKey,
      backgroundColor: Colors.black,
      body: _isCameraInitialized ? Column(
        children:[
          AspectRatio(aspectRatio: 1 / controller!.value.aspectRatio, child: Stack(children: [controller!.buildPreview(),
          Padding(padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
            child: Column(crossAxisAlignment: CrossAxisAlignment.center, 
                          children: [Row( mainAxisAlignment: .spaceBetween,
                              children:[Align(alignment: Alignment.topLeft,
                              child: Container(decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(10),),
                                      child: Padding(padding: const EdgeInsets.only(left: 8, right: 5),
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
                              Align(alignment: Alignment.topRight,
                              child: IconButton.filled(
                                isSelected: tonalSelected,
                                icon: const Icon(Icons.settings_outlined),
                                selectedIcon: const Icon(Icons.settings),
                                onPressed: openDrawer,
                              ))
             
          ])]),
          ),

          ])),

          Row(children: [Expanded(child: Padding(padding: const EdgeInsets.only(left: 8, right: 4),
                            child: TextButton(onPressed: () {recorder.toggleLoopRecording(controller);}, 
                            style: TextButton.styleFrom(foregroundColor: !recorder.isRecording ? Colors.black : Colors.grey, backgroundColor: !recorder.isRecording ? Colors.white : Colors.white30),
                            child: Text('Toggle Loop Recording', style: TextStyle(color: Colors.deepPurple)))))]),
          Row(children: [ Expanded(child: Column( children: [ Text('Loop Recording Duration (minutes)', style: TextStyle(color: Colors.white)),
                          SegmentedButton<int>( style: SegmentedButton.styleFrom( backgroundColor: Colors.white, foregroundColor: Colors.deepPurple, selectedBackgroundColor: Colors.white30, selectedForegroundColor: Colors.amber),
                          segments: <ButtonSegment<int>>[
                            ButtonSegment<int>(value: 0, label: Text('.5'), enabled: !recorder.isRecording),
                            ButtonSegment<int>(value: 1, label: Text('1'), enabled: !recorder.isRecording),
                            ButtonSegment<int>(value: 2, label: Text('2'), enabled: !recorder.isRecording),
                            ButtonSegment<int>(value: 3, label: Text('3'), enabled: !recorder.isRecording),
                            ButtonSegment<int>(value: 4, label: Text('4'), enabled: !recorder.isRecording),
                            ButtonSegment<int>(value: 5, label: Text('5'), enabled: !recorder.isRecording),
                          ],
                          selected: <int>{recorder.settings.loopRecordingDuration},
                          onSelectionChanged: (Set<int> newSelection) {

                              setState(() {
                                debugPrint('recorder.isRecording: ${recorder.isRecording}');
                                if(!recorder.isRecording)
                                {

                                  recorder.settings.loopRecordingDuration = newSelection.first;
                                  recorder.settings.setParameter("loop_recording_duration", recorder.settings.loopRecordingDuration);
                                  if(newSelection.first == 0)
                                  {
                                    recorder.loopTime = Duration(seconds: 30);
                                  }
                                  else{
                                    recorder.loopTime = Duration(minutes: recorder.settings.loopRecordingDuration);
                                  }
                                }
                                
                              });
                                
                            
                          },),
                          ]))
          ]),
        ]
      ) : Container(),
      endDrawer: NavigationDrawer(

        children:<Widget>[
          Padding(padding: .fromLTRB(28,16,16, 10), child: null),
          NavigationDrawerDestination(icon: Icon(Icons.settings), label: Text("Settings")),
          Padding(padding: .fromLTRB(28, 16, 28, 10), child: Divider()),
          //Place settings here
          Padding(padding: .fromLTRB(28,10,16, 10), child: Text('Storage Capacity: ${recorder.storageInfo.consumedSpace} GB of ${recorder.storageInfo.totalDiskSpace} GB used (${recorder.storageInfo.freeDiskSpace} GB free)')),
          Padding(padding: .fromLTRB(28,10,16, 10), child: Text('Storage Limit: ${recorder.storageInfo.consumedVideoSpace.toStringAsFixed(2)} GB of ${recorder.settings.recordingStorageLimit.toStringAsFixed(2)}  used')),
          Slider(value: recorder.settings.recordingStorageLimit, min: 0, max: recorder.storageInfo.freeDiskSpace, label: recorder.settings.recordingStorageLimit.toStringAsFixed(2), onChanged: (double newVal){ setState(()
          {
            if(newVal >= recorder.storageInfo.consumedVideoSpace)
            {
              recorder.settings.recordingStorageLimit = newVal;
              recorder.settings.setParameter("storage_limit", recorder.settings.recordingStorageLimit);
            }
            
            
          }); }),
          Padding(padding: .fromLTRB(28,10,16, 10), child: Row(children:[Text('Run in background: '), Switch(value: recorder.settings.runInBackground, onChanged: (bool newVal){setState(()
          {
            recorder.settings.runInBackground = newVal;
            recorder.settings.setParameter("enable_running_in_background", recorder.settings.runInBackground);
          });},) ])),
          Padding(padding: .fromLTRB(28,10,16, 10), child: Row(children:[Text('Save to Ext. Storage: '), Switch(value: recorder.settings.useExtStorage, onChanged: (bool newVal){setState(()
          {
            if(newVal == true && Platform.isAndroid)
            {
              //Check here if SD card is detected (Updates useExtStorage in Settings)
              recorder.settings.isExtStoragePresent();
              //Show toastification if SD card is missing
              if(recorder.settings.useExtStorage == false)
              {
                //Show the notification
                toastification.show(
                  type: ToastificationType.error,
                  style: ToastificationStyle.flat,
                  title: Text('Settings Notification'),
                  autoCloseDuration: const Duration(seconds: 8),
                  description: Text('External Storage (SD Card) is not detected.'),
                  alignment: Alignment.bottomCenter,
                  );
              }

            }
            else if(newVal == true && Platform.isIOS)
            {
              //Show the notification
                toastification.show(
                  type: ToastificationType.error,
                  style: ToastificationStyle.flat,
                  title: Text('Settings Notification'),
                  autoCloseDuration: const Duration(seconds: 8),
                  description: Text('This feature is only available in Android.'),
                  alignment: Alignment.bottomCenter,
                  );
            }
            else{
              recorder.settings.useExtStorage = newVal;
            }
            recorder.settings.setParameter("use_external_storage", recorder.settings.useExtStorage);
            
          });}) ])),
        ]),
      
  
      

    );
  }
}
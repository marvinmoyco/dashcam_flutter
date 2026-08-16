
import 'dart:async';

import 'package:gal/gal.dart';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:intl/intl.dart';
import 'package:camera/camera.dart';
import 'package:toastification/toastification.dart';
import 'package:flutter/material.dart';
import 'utilities.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';


class Recorder{
  //Initialize parameters
  late DateTime startTimeStamp;
  late DateTime endTimeStamp;
  Duration loopTime = Duration(minutes: 3);
  late XFile recordedFile;
  String albumName = "DashCam_Recordings";
  late Timer recordingTimer;
  bool isRecording = false;
  final List<Future<void>> pendingSaves = [];
  StorageInfo storageInfo = StorageInfo();
  Settings settings = Settings();


  //Constructor
  Recorder();
  
  void updateAlbumName(String newName)
  {
    albumName = newName;
  }


  Future<XFile> renameRecording(XFile initialVideo, String cameraType) async {
    
    //Convert XFile to File class to rename it
    File origFile = File(initialVideo.path);

    //Get the timestamp and file extension
    String formattedDateTime = DateFormat('yyyyMMdd_hhmmss').format(startTimeStamp);
    String fileExtension = path.extension(initialVideo.path);
    
    //Create a new string combining all the extracted info
    String newFileName = '${formattedDateTime}_$cameraType$fileExtension';
    String newFilePath = path.join(path.dirname(initialVideo.path), newFileName);
    
    //Rename the file
    File renamedFile = await origFile.rename(newFilePath);

    //Return the renamed file as an XFile
    return XFile(renamedFile.path);

  }

  void queueSave(XFile videoFile, String camType)
  {
    final newSave = endRecording(videoFile, camType);
    pendingSaves.add(newSave);
    newSave.whenComplete(() => pendingSaves.remove(newSave));
  }

  Future<void> cleanup() async
  {
    recordingTimer.cancel();
    await Future.wait(pendingSaves);
  }
  Future<void> endRecording(XFile videoFile, String camType) async
  {

    //Rename the video file
    recordedFile = await renameRecording( videoFile,camType );
    try{
      //Recompile using ffmpeg to insert timestamp in each frame
      await addLiveTimestampAndReplace(recordedFile.path);

      if(settings.useExtStorage)
      { //use dart:io for external storage (SD card)

      }
      else{ //Use Gal for internal gallery
        if(await Gal.hasAccess())
        {
          //await Future.delayed(const Duration(seconds:3));
          //Copy the recorded file to the Gallery (DCIM folder)
          await Gal.putVideo(recordedFile.path,album: albumName);

          //Delete the old file (in the internal folder) to prevent wasted space
          File oldFile = File(recordedFile.path);
          if( await oldFile.exists())
          {
            await oldFile.delete();
          }
        }
      }
      
      //Show the notification
      toastification.show(
        type: ToastificationType.info,
        style: ToastificationStyle.flat,
        title: Text('Recording Notification'),
        autoCloseDuration: const Duration(seconds: 5),
        description: Text('Saved ${recordedFile.name}'),
        alignment: Alignment.bottomCenter,
        );

      
    }
    on GalException catch (e)
    {
      debugPrint("ERROR IN RUNTIME: ");
      debugPrint(e.toString());
    }

  }

  void toggleLoopRecording(CameraController? camController) async
  {
    
    if(isRecording) //End the loop recording
    {
      //Check if the timer is running
      if(recordingTimer.isActive)
      {
        //End the timer
        recordingTimer.cancel();
        
        if(camController!.value.isRecordingVideo)
        {
          //Save the recording
          XFile originalFile = await camController.stopVideoRecording();
          //Update endTimeStamp and end stopwatch
          endTimeStamp = DateTime.now();
          queueSave(originalFile, "Rear"); 

          //Update storage info
          storageInfo.fetchStorageInfo();
        }
        
      }

      isRecording = false;
    }
    else{ //Start the loop recording
      isRecording = true;

      //Start the recording
      startTimeStamp = DateTime.now();
      await camController!.prepareForVideoRecording();
      await camController.startVideoRecording();

      //Re-initialize timer
      recordingTimer = Timer.periodic(loopTime, (timer) async{

        if(camController.value.isRecordingVideo)
        {
          //End the recording
          XFile originalFile = await camController.stopVideoRecording();
          //Update endTimeStamp and end stopwatch
          endTimeStamp = DateTime.now();
          queueSave(originalFile, "Rear"); 

          //Update storage info
          storageInfo.fetchStorageInfo();
          
        }
        
        
        

        //Start the recording
        startTimeStamp = DateTime.now();
        camController.prepareForVideoRecording();
        camController.startVideoRecording();
      });
    }
    

    
    
  }

  Future<void> addLiveTimestampAndReplace(String videoPath) async {
  // 1. Establish the base metadata time before changing any files
  DateTime baseDate = startTimeStamp;
  int baseEpochSeconds = baseDate.millisecondsSinceEpoch ~/ 1000;
  
  // 2. Generate a temporary path in the same directory to write to
  String tempOutputPath = "${videoPath}_temp.mp4";

  // 3. Define the filter and command (writing out to the temporary file)
  String filter = "drawtext=fontfile='/system/fonts/Roboto-Regular.ttf':"
                  "text='%{pts\\:localtime\\:$baseEpochSeconds\\:%Y-%m-%d %H\\\\\\:%M\\\\\\:%S}':"
                  "x=10:y=10:fontsize=24:fontcolor=white:box=1:boxcolor=black@0.5";
  List<String> arguments  = ['-y', '-i', videoPath, '-vf', filter];
          
  // 2. Dynamically swap codecs & bitrate constraints per OS platform
  if (Platform.isAndroid) {
    arguments.addAll([
      '-pix_fmt', 'nv12',
      '-c:v', 'h264_mediacodec', 
      '-b:v', '10M',
      '-g', '30'
    ]);
  } else if (Platform.isIOS) {
    arguments.addAll([
      '-c:v', 'h264_videotoolbox', 
      '-b:v', '10M'
    ]);
  } else {
    arguments.addAll([
      '-c:v', 'libx264', 
      '-preset', 'ultrafast', 
      '-crf', '22'
    ]);
  }

  arguments.addAll(['-c:a', 'copy', tempOutputPath]);
  
  
  // 4. Run FFmpeg Kit
  final session = await FFmpegKit.executeWithArguments(arguments);
  final returnCode = await session.getReturnCode();
  debugPrint('FFMPEG RETURNCODE: ${returnCode?.getValue()} ============================================================================================================================================================================');
  if (returnCode?.isValueSuccess() == true) {
    try {
      // 5. Safely replace the old file with the new fild
      final tempFile = File(tempOutputPath);

      if (await tempFile.exists()) {
        await tempFile.rename(videoPath); // Rename the temporary file to match original path
      }
      
      
      debugPrint("File successfully updated and replaced at: $videoPath");
      
    } catch (e) {
      debugPrint("Error replacing original file: $e");
    }
  } else {
    final failStackTrace = await session.getFailStackTrace();
    debugPrint("FFmpeg encoding failed: $failStackTrace");
    debugPrint('%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%');
    debugPrint("FFMPEG Logs: ${await session.getAllLogsAsString()}");
    
    // Clean up temp file if something went wrong during video processing
    final tempFile = File(tempOutputPath);
    if (await tempFile.exists()) {
      await tempFile.delete();
    }
  }
}


}

